#include "startup.h"

#include <flutter/standard_method_codec.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.h>

#include <string>
#include <thread>

namespace {

constexpr UINT kAnswerMessage = WM_APP + 2;
constexpr wchar_t kTaskId[] = L"WaaiyaFilter";

using Result = flutter::MethodResult<flutter::EncodableValue>;

struct Answer {
  std::unique_ptr<Result> result;
  std::string state;
};

std::string Name(winrt::Windows::ApplicationModel::StartupTaskState s) {
  using winrt::Windows::ApplicationModel::StartupTaskState;
  switch (s) {
    case StartupTaskState::Enabled:
      return "enabled";
    case StartupTaskState::Disabled:
      return "disabled";
    case StartupTaskState::DisabledByUser:
      return "disabledByUser";
    case StartupTaskState::DisabledByPolicy:
      return "disabledByPolicy";
    case StartupTaskState::EnabledByPolicy:
      return "enabledByPolicy";
  }
  return "unknown";
}

// On a helper thread: the task's state, after asking Windows to enable it when [request].
std::string Query(bool request) {
  try {
    winrt::init_apartment(winrt::apartment_type::multi_threaded);
    auto task = winrt::Windows::ApplicationModel::StartupTask::GetAsync(kTaskId).get();
    auto state = task.State();
    if (request && state == winrt::Windows::ApplicationModel::StartupTaskState::Disabled)
      state = task.RequestEnableAsync().get();
    return Name(state);
  } catch (...) {
    return "none";  // no package identity (a plain install), or no such task
  }
}

}  // namespace

Startup::Startup(HWND window, flutter::BinaryMessenger* messenger) : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "waaiya/startup", &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, std::unique_ptr<Result> result) {
    const std::string& m = call.method_name();
    if (m != "state" && m != "request") {
      result->NotImplemented();
      return;
    }
    bool request = m == "request";
    auto* answer = new Answer{std::move(result), ""};
    HWND w = window_;
    std::thread([w, answer, request] {
      answer->state = Query(request);
      if (!PostMessageW(w, kAnswerMessage, 0, reinterpret_cast<LPARAM>(answer))) delete answer;
    }).detach();
  });
}

Startup::~Startup() { channel_->SetMethodCallHandler(nullptr); }

std::optional<LRESULT> Startup::HandleMessage(HWND, UINT message, WPARAM, LPARAM lparam) {
  if (message != kAnswerMessage) return std::nullopt;
  std::unique_ptr<Answer> answer(reinterpret_cast<Answer*>(lparam));
  answer->result->Success(flutter::EncodableValue(answer->state));
  return 0;
}
