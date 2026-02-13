#include "include/no_screen_mirror/no_screen_mirror_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "no_screen_mirror_plugin.h"

void NoScreenMirrorPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  no_screen_mirror::NoScreenMirrorPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
