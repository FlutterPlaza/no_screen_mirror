//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <no_screen_mirror/no_screen_mirror_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) no_screen_mirror_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NoScreenMirrorPlugin");
  no_screen_mirror_plugin_register_with_registrar(no_screen_mirror_registrar);
}
