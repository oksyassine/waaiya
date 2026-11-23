#ifndef RUNNER_STARTUP_H_
#define RUNNER_STARTUP_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>

// The Microsoft Store package's startup task (desktop/windows/msix/AppxManifest.xml, "WaaiyaFilter"), for "Start at
// login" (desktop/lib/windows_engine.dart, channel "waaiya/startup"):
//   "state"    its state: enabled, disabled, disabledByUser, disabledByPolicy, enabledByPolicy; "none" outside the
//              package (a plain install uses the Run key)
//   "request"  asks Windows to let it run (Windows' own "start at login?" question when it is "disabled"), then its
//              state. A task the user turned off in Settings > Apps > Startup can only be turned on there.
// The WinRT calls run on a helper thread; their answer comes back to the window's thread.
class Startup {
 public:
  Startup(HWND window, flutter::BinaryMessenger* messenger);
  ~Startup();

  std::optional<LRESULT> HandleMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

 private:
  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_STARTUP_H_
