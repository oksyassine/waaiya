#ifndef RUNNER_TRAY_H_
#define RUNNER_TRAY_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <string>

// The icon next to the clock (the notification area): a click shows the window; the menu has Open Waaiya,
// Start or Stop filtering, and Quit. While it is there, closing the window only hides it.
//
// The menu's texts and whether the filter is on come from the shared screens (ui/lib/src/tray.dart, channel
// "waaiya/tray", method "update"); Start and Stop go back to them ("action"), so that Stop passes the waiting period
// and the PIN like the power button. The icon appears with the first "update": until then the window closes as
// before (the app quits).
class Tray {
 public:
  // A message no other part of the app uses, sent by a second start of the app: show the window.
  static UINT ShowMessage();

  Tray(HWND window, flutter::BinaryMessenger* messenger);
  ~Tray();

  // Handles the window's messages it is about (the icon, the menu, closing, Explorer restarting).
  std::optional<LRESULT> HandleMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  void ShowWindowNow();

 private:
  void Update(const flutter::EncodableMap& menu);
  bool Add();
  void Remove();
  void ShowMenu(int x, int y);
  void SendAction(const char* action);

  HWND window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HICON icon_ = nullptr;
  bool shown_ = false;     // the icon is in the notification area
  bool active_ = false;    // the screens sent the menu: closing the window hides it
  bool quitting_ = false;  // Quit was chosen: closing the window quits
  bool on_ = false;
  bool rtl_ = false;
  std::wstring tooltip_ = L"Waaiya", open_ = L"Open Waaiya", start_ = L"Start filtering",
               stop_ = L"Stop filtering", quit_ = L"Quit";
  UINT taskbar_created_;
};

#endif  // RUNNER_TRAY_H_
