#include "tray.h"

#include <flutter/standard_method_codec.h>
#include <shellapi.h>
#include <windowsx.h>

#include "resource.h"

namespace {

constexpr UINT kIconMessage = WM_APP + 1;
constexpr UINT kIconId = 1;
enum : UINT { kOpen = 1, kStart, kStop, kQuit };

std::wstring Wide(const std::string& s) {
  if (s.empty()) return L"";
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], n);
  return w;
}

}  // namespace

UINT Tray::ShowMessage() {
  static UINT m = RegisterWindowMessageW(L"WaaiyaShowWindow");
  return m;
}

Tray::Tray(HWND window, flutter::BinaryMessenger* messenger)
    : window_(window), taskbar_created_(RegisterWindowMessageW(L"TaskbarCreated")) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "waaiya/tray", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    if (call.method_name() == "update") {
      if (const auto* menu = std::get_if<flutter::EncodableMap>(call.arguments())) Update(*menu);
      result->Success();
    } else {
      result->NotImplemented();
    }
  });
}

Tray::~Tray() {
  channel_->SetMethodCallHandler(nullptr);
  Remove();
  if (icon_) DestroyIcon(icon_);
}

void Tray::Update(const flutter::EncodableMap& menu) {
  auto text = [&](const char* key, std::wstring* out) {
    auto it = menu.find(flutter::EncodableValue(key));
    if (it != menu.end())
      if (const auto* s = std::get_if<std::string>(&it->second)) *out = Wide(*s);
  };
  auto flag = [&](const char* key) {
    auto it = menu.find(flutter::EncodableValue(key));
    const bool* b = it != menu.end() ? std::get_if<bool>(&it->second) : nullptr;
    return b && *b;
  };
  text("tooltip", &tooltip_);
  text("open", &open_);
  text("start", &start_);
  text("stop", &stop_);
  text("quit", &quit_);
  on_ = flag("on");
  rtl_ = flag("rtl");
  active_ = true;
  if (!shown_) {
    Add();
    return;
  }
  NOTIFYICONDATAW d = {sizeof d};
  d.hWnd = window_;
  d.uID = kIconId;
  d.uFlags = NIF_TIP | NIF_SHOWTIP;
  wcsncpy_s(d.szTip, tooltip_.c_str(), _TRUNCATE);
  Shell_NotifyIconW(NIM_MODIFY, &d);
}

bool Tray::Add() {
  if (!icon_) {
    UINT dpi = GetDpiForWindow(window_);
    int cx = GetSystemMetricsForDpi(SM_CXSMICON, dpi), cy = GetSystemMetricsForDpi(SM_CYSMICON, dpi);
    icon_ = (HICON)LoadImageW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON, cx, cy, 0);
  }
  NOTIFYICONDATAW d = {sizeof d};
  d.hWnd = window_;
  d.uID = kIconId;
  d.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP | NIF_SHOWTIP;
  d.uCallbackMessage = kIconMessage;
  d.hIcon = icon_;
  wcsncpy_s(d.szTip, tooltip_.c_str(), _TRUNCATE);
  if (!Shell_NotifyIconW(NIM_ADD, &d)) return false;
  d.uVersion = NOTIFYICON_VERSION_4;
  Shell_NotifyIconW(NIM_SETVERSION, &d);
  shown_ = true;
  return true;
}

void Tray::Remove() {
  if (!shown_) return;
  NOTIFYICONDATAW d = {sizeof d};
  d.hWnd = window_;
  d.uID = kIconId;
  Shell_NotifyIconW(NIM_DELETE, &d);
  shown_ = false;
}

void Tray::ShowWindowNow() {
  if (IsIconic(window_)) ShowWindow(window_, SW_RESTORE);
  else ShowWindow(window_, SW_SHOW);
  SetForegroundWindow(window_);
}

void Tray::SendAction(const char* action) {
  channel_->InvokeMethod("action", std::make_unique<flutter::EncodableValue>(action));
}

void Tray::ShowMenu(int x, int y) {
  HMENU m = CreatePopupMenu();
  AppendMenuW(m, MF_STRING, kOpen, open_.c_str());
  SetMenuDefaultItem(m, kOpen, FALSE);
  AppendMenuW(m, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(m, MF_STRING, on_ ? kStop : kStart, (on_ ? stop_ : start_).c_str());
  AppendMenuW(m, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(m, MF_STRING, kQuit, quit_.c_str());
  SetForegroundWindow(window_);  // or the menu does not close when clicking elsewhere
  UINT flags = TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_BOTTOMALIGN | (rtl_ ? TPM_LAYOUTRTL | TPM_LEFTALIGN : TPM_RIGHTALIGN);
  UINT cmd = TrackPopupMenuEx(m, flags, x, y, window_, nullptr);
  PostMessageW(window_, WM_NULL, 0, 0);
  DestroyMenu(m);
  switch (cmd) {
    case kOpen:
      ShowWindowNow();
      break;
    case kStart:
      SendAction("start");
      break;
    case kStop:  // in the window: the waiting period or the PIN may ask something there
      ShowWindowNow();
      SendAction("stop");
      break;
    case kQuit:
      quitting_ = true;
      PostMessageW(window_, WM_CLOSE, 0, 0);
      break;
  }
}

std::optional<LRESULT> Tray::HandleMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (message == ShowMessage()) {
    ShowWindowNow();
    return 0;
  }
  if (message == taskbar_created_) {  // Explorer started again: the icon is gone
    if (shown_) {
      shown_ = false;
      Add();
    }
    return std::nullopt;
  }
  switch (message) {
    case kIconMessage:
      switch (LOWORD(lparam)) {
        case NIN_SELECT:
        case NIN_KEYSELECT:
          ShowWindowNow();
          return 0;
        case WM_CONTEXTMENU:
          ShowMenu(GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam));
          return 0;
      }
      return 0;
    case WM_CLOSE:
      if (active_ && shown_ && !quitting_) {
        ShowWindow(hwnd, SW_HIDE);
        return 0;
      }
      return std::nullopt;
    case WM_ENDSESSION:  // signing out, or Windows closing the app (update): quit, no hiding
      if (wparam) quitting_ = true;
      return std::nullopt;
  }
  return std::nullopt;
}
