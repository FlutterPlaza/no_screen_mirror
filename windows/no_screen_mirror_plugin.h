#ifndef FLUTTER_PLUGIN_NO_SCREEN_MIRROR_PLUGIN_H_
#define FLUTTER_PLUGIN_NO_SCREEN_MIRROR_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>

#include "display_detection.h"

namespace no_screen_mirror {

class NoScreenMirrorPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  NoScreenMirrorPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~NoScreenMirrorPlugin();

  NoScreenMirrorPlugin(const NoScreenMirrorPlugin&) = delete;
  NoScreenMirrorPlugin& operator=(const NoScreenMirrorPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void OnDisplayChanged(const DisplayDetection::Result& detection_result);

  static void CALLBACK StreamTimerProc(HWND hwnd, UINT msg, UINT_PTR id,
                                       DWORD time);

  std::string BuildEventJson(bool is_screen_mirrored,
                             bool is_external_connected, int display_count);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;

  bool is_listening_ = false;
  std::string last_event_json_;
  bool has_pending_event_ = false;
  UINT_PTR stream_timer_id_ = 0;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  std::unique_ptr<DisplayDetection> detection_;
};

}  // namespace no_screen_mirror

#endif  // FLUTTER_PLUGIN_NO_SCREEN_MIRROR_PLUGIN_H_
