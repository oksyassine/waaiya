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
    // Sessions that play nothing yet (no output stream: an app that only records the speakers, a closed app's
    // leftover session) are watched, not lowered: lowering one would lower what it records. This lowers those that
    // started playing since. Cheap; the main loop calls it every 50 ms.
    void poll_quiet();
    // Gives every running app its level back; the levels of apps not running stay in the store (restore-only mode
    // gives them back later). Switches to restore-only mode.
    void restore_all();
    // Back to lowering every session (after restore_all, when the filter runs again).
    void lower_all();

    int lowered() const;  // sessions lowered by us now
    int pending() const;  // levels in the store not given back (restore-only mode is done when this is 0)
    Mode mode() const { return mode_; }
    std::string last_error() const;

    // Signalled when a session or an output appears (the main loop then calls scan()).
    HANDLE wake = CreateEventW(nullptr, FALSE, FALSE, nullptr);

    // Log lines (wfilter.cpp's logf); may be null.
    void (*log)(const char *fmt, ...) = nullptr;

    // called by the watchers (any thread)
    void on_session(IAudioSessionControl *ctl);
    void on_volume(SessionEvents *s, float v, LPCGUID ctx);
    void on_gone(SessionEvents *s);

  private:
    struct Tracked {
        SessionEvents *events = nullptr; // our IAudioSessionEvents, registered on ctl
        Com<IAudioSessionControl2> ctl;
        Com<ISimpleAudioVolume> vol;
        std::wstring id;
        DWORD pid = 0;
        bool dead = false;    // the session ended; unwatched by the next scan
        bool lowered = false; // false: it plays nothing yet (see poll_quiet)
    };
    struct Output {
        std::wstring id;
        Com<IAudioSessionManager2> mgr;
        SessionWatch *watch = nullptr;
    };

    void add_outputs();
    void apply(IAudioSessionControl *ctl, bool track); // mutex held
    void lower(ISimpleAudioVolume *vol, const std::wstring &id, DWORD pid, AudioSessionState st, float cur,
               bool track); // mutex held
    void save();                            // mutex held
    void load();
    void drop(Tracked &t);

    const float att_;
    const std::wstring store_path_;
    const DWORD self_;
    Mode mode_ = ATTENUATE;
    mutable std::recursive_mutex mu_;
    Com<IMMDeviceEnumerator> devices_;
    DeviceWatch *device_watch_ = nullptr;
    std::vector<Output> outputs_;
    std::vector<Tracked> tracked_;
    std::map<std::wstring, float> store_; // session identifier -> the user's level
    std::string error_;
};

// The context passed with every volume we set, to tell our changes from the user's.
extern const GUID IM_VOLUME_CONTEXT;
