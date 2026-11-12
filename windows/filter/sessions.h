// Turns every other app's audio session down to `att` times the user's level (about -80 dB), so that only the
// filtered copy we play is heard, and gives the user's levels back on stop.
//
// Windows keeps an app's session volume after the app ends, keyed by its session identifier (app + device). So a
// level we lowered outlives the app, and the next run of the app starts lowered: while filtering, that is what we
// want (no unfiltered onset); after a stop, the app would stay near silent. The user's levels are therefore kept
// in a file (store), and a level not given back at stop (the app was not running) is given back the next time its
// session shows up, by this process running in restore-only mode (reports/desktop_windows_macos_scope.md 2.4).
#pragma once

#include "../common/wasapi.h"

#include <atomic>
#include <map>
#include <mutex>
#include <string>
#include <vector>

class SessionEvents;
class SessionWatch;
class DeviceWatch;

class Sessions {
  public:
    enum Mode { ATTENUATE, RESTORE_ONLY };

    Sessions(float att, std::wstring store_path, DWORD self_pid);
    ~Sessions();

    // Reads the store, finds the outputs, applies the mode to every session there now and watches for new ones.
    // S_OK, or why the audio service could not be asked.
    HRESULT start(Mode mode);
    // Applies the mode to every session again (also picks up new outputs). Called by the main loop when `wake` is
    // signalled, and on a timer.
    void scan();
    // Gives every running app its level back; the levels of apps not running stay in the store (restore-only mode
    // gives them back later). Switches to restore-only mode.
    void restore_all();
    // Back to lowering every session (after restore_all, when the filter runs again).
    void lower_all();

    // "pid 123 lowered 2ch peak 0.2100, ..." for every watched session (diagnostics)
    std::string meters() const;

    int lowered() const;  // sessions lowered by us now
    int pending() const;  // levels in the store not given back (restore-only mode is done when this is 0)
    Mode mode() const { return (Mode)mode_.load(); }
    std::string last_error() const;

    // Signalled when a session or an output appears (the main loop then calls scan()).
    HANDLE wake = CreateEventW(nullptr, FALSE, FALSE, nullptr);

    // Programs never lowered (lower-case file names, e.g. "obs64.exe"): apps that record the speakers and should
    // record the originals. Their sound is not filtered either, if they play any. Set before start().
    std::vector<std::wstring> leave_alone;

    // Log lines (wfilter.cpp's logf); may be null.
    void (*log)(const char *fmt, ...) = nullptr;

    // called by the watchers on Windows' threads: never take mu_ (see SessionEvents)
    void on_session(IAudioSessionControl *ctl);
    void on_volume(const std::wstring &id, ISimpleAudioVolume *vol, float v);

  private:
    struct Tracked {
        SessionEvents *events = nullptr; // our IAudioSessionEvents, registered on ctl
        Com<IAudioSessionControl2> ctl;
        Com<ISimpleAudioVolume> vol;
        std::wstring id;
        DWORD pid = 0;
    };
    struct Output {
        std::wstring id;
        Com<IAudioSessionManager2> mgr;
        SessionWatch *watch = nullptr;
    };

    void add_outputs();
    bool left_alone(const std::wstring &id) const;
    void apply(IAudioSessionControl *ctl, bool track); // track: main thread, mu_ held
    void lower(ISimpleAudioVolume *vol, const std::wstring &id, DWORD pid, AudioSessionState st, float cur,
               bool track); // any thread; takes store_mu_
    void give_back(ISimpleAudioVolume *vol, const std::wstring &id, DWORD pid, AudioSessionState st, float cur);
    void save(); // store_mu_ held
    void load();
    void drop(Tracked &t);

    const float att_;
    const std::wstring store_path_;
    const DWORD self_;
    std::atomic<int> mode_{ATTENUATE};
    mutable std::recursive_mutex mu_; // main thread only: outputs_, tracked_, devices_
    mutable std::mutex store_mu_;     // store_ (any thread); never held during an audio call
    Com<IMMDeviceEnumerator> devices_;
    DeviceWatch *device_watch_ = nullptr;
    std::vector<Output> outputs_;
    std::vector<Tracked> tracked_;
    std::vector<Tracked> no_tracked_; // what a notification looks through instead of tracked_ (always empty)
    std::map<std::wstring, float> store_; // session identifier -> the user's level
    std::string error_;
};

// The context passed with every volume we set, to tell our changes from the user's.
extern const GUID IM_VOLUME_CONTEXT;
