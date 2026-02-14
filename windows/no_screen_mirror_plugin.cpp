#include "no_screen_mirror_plugin.h"

#include <flutter/encodable_value.h>

#include <sstream>

namespace no_screen_mirror {

static const char kMethodChannelName[] =
    "com.flutterplaza.no_screen_mirror_methods";
static const char kEventChannelName[] =
    "com.flutterplaza.no_screen_mirror_streams";

// Static instance pointer for SetTimer callback (no this-capture).
// Safe: Flutter Windows runs one engine per process.
static NoScreenMirrorPlugin* g_plugin_instance = nullptr;

// -------------------------------------------------------------------------
// Registration
// -------------------------------------------------------------------------

// static
void NoScreenMirrorPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto plugin = std::make_unique<NoScreenMirrorPlugin>(registrar);
  g_plugin_instance = plugin.get();
  registrar->AddPlugin(std::move(plugin));
}

// -------------------------------------------------------------------------
// Constructor / Destructor
// -------------------------------------------------------------------------

NoScreenMirrorPlugin::NoScreenMirrorPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar) {
  // Method channel
  method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kMethodChannelName,
          &flutter::StandardMethodCodec::GetInstance());
  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  // Event channel
  event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
          registrar->messenger(), kEventChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto handler =
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          // OnListen
          [this](const flutter::EncodableValue* arguments,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
                     events)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_ = std::move(events);
            if (stream_timer_id_ == 0) {
              stream_timer_id_ =
                  SetTimer(nullptr, 0, 1000, StreamTimerProc);
            }
            return nullptr;
          },
          // OnCancel
          [this](const flutter::EncodableValue* arguments)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            event_sink_ = nullptr;
            if (stream_timer_id_ != 0) {
              KillTimer(nullptr, stream_timer_id_);
              stream_timer_id_ = 0;
            }
            return nullptr;
          });
  event_channel_->SetStreamHandler(std::move(handler));

  // Display detection
  detection_ = std::make_unique<DisplayDetection>(
      [this](const DisplayDetection::Result& r) { OnDisplayChanged(r); });

  // Initial state
  last_event_json_ = BuildEventJson(false, false, 1, false);
  has_pending_event_ = true;
}

NoScreenMirrorPlugin::~NoScreenMirrorPlugin() {
  if (stream_timer_id_ != 0) {
    KillTimer(nullptr, stream_timer_id_);
    stream_timer_id_ = 0;
  }
  if (g_plugin_instance == this) {
    g_plugin_instance = nullptr;
  }
}

// -------------------------------------------------------------------------
// Method channel handler
// -------------------------------------------------------------------------

void NoScreenMirrorPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = method_call.method_name();

  if (method == "startListening") {
    UINT poll_interval_ms = 2000;
    std::vector<std::wstring> custom_processes;

    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args != nullptr) {
      auto interval_it = args->find(flutter::EncodableValue("pollingIntervalMs"));
      if (interval_it != args->end()) {
        const auto* val = std::get_if<int32_t>(&interval_it->second);
        if (val != nullptr && *val > 0) {
          poll_interval_ms = static_cast<UINT>(*val);
        }
      }

      auto processes_it = args->find(flutter::EncodableValue("customProcesses"));
      if (processes_it != args->end()) {
        const auto* list = std::get_if<flutter::EncodableList>(&processes_it->second);
        if (list != nullptr) {
          for (const auto& item : *list) {
            const auto* str = std::get_if<std::string>(&item);
            if (str != nullptr) {
              // Convert UTF-8 string to wide string
              int size_needed = MultiByteToWideChar(CP_UTF8, 0, str->c_str(),
                                                    static_cast<int>(str->size()), nullptr, 0);
              std::wstring wstr(size_needed, 0);
              MultiByteToWideChar(CP_UTF8, 0, str->c_str(),
                                  static_cast<int>(str->size()), &wstr[0], size_needed);
              custom_processes.push_back(std::move(wstr));
            }
          }
        }
      }
    }

    if (!is_listening_) {
      is_listening_ = true;
      detection_->Start(poll_interval_ms, custom_processes);
    }
    result->Success(flutter::EncodableValue("Listening started"));
  } else if (method == "stopListening") {
    if (is_listening_) {
      is_listening_ = false;
      detection_->Stop();
    }
    result->Success(flutter::EncodableValue("Listening stopped"));
  } else {
    result->NotImplemented();
  }
}

// -------------------------------------------------------------------------
// Display change callback
// -------------------------------------------------------------------------

void NoScreenMirrorPlugin::OnDisplayChanged(
    const DisplayDetection::Result& detection_result) {
  std::string json = BuildEventJson(detection_result.is_screen_mirrored,
                                    detection_result.is_external_connected,
                                    detection_result.display_count,
                                    detection_result.is_screen_shared);
  if (json != last_event_json_) {
    last_event_json_ = json;
    has_pending_event_ = true;
  }
}

// -------------------------------------------------------------------------
// Stream timer (1s polling to deliver events to Dart)
// -------------------------------------------------------------------------

// static
void CALLBACK NoScreenMirrorPlugin::StreamTimerProc(HWND /*hwnd*/,
                                                     UINT /*msg*/,
                                                     UINT_PTR /*id*/,
                                                     DWORD /*time*/) {
  if (g_plugin_instance == nullptr) return;
  auto* self = g_plugin_instance;

  if (self->has_pending_event_ && self->event_sink_) {
    self->event_sink_->Success(
        flutter::EncodableValue(self->last_event_json_));
    self->has_pending_event_ = false;
  }
}

// -------------------------------------------------------------------------
// JSON builder
// -------------------------------------------------------------------------

std::string NoScreenMirrorPlugin::BuildEventJson(bool is_screen_mirrored,
                                                  bool is_external_connected,
                                                  int display_count,
                                                  bool is_screen_shared) {
  std::ostringstream oss;
  oss << "{\"is_screen_mirrored\":" << (is_screen_mirrored ? "true" : "false")
      << ",\"is_external_display_connected\":"
      << (is_external_connected ? "true" : "false")
      << ",\"display_count\":" << display_count
      << ",\"is_screen_shared\":" << (is_screen_shared ? "true" : "false")
      << "}";
  return oss.str();
}

}  // namespace no_screen_mirror
