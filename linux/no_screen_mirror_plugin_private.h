#ifndef NO_SCREEN_MIRROR_PLUGIN_PRIVATE_H_
#define NO_SCREEN_MIRROR_PLUGIN_PRIVATE_H_

#include <flutter_linux/flutter_linux.h>

#include "display_detection.h"

G_BEGIN_DECLS

struct _NoScreenMirrorPlugin {
  GObject parent_instance;

  FlPluginRegistrar* registrar;
  FlMethodChannel* method_channel;
  FlEventChannel* event_channel;

  // State
  gboolean is_listening;

  // Event stream
  gchar* last_event_json;
  gboolean has_pending_event;
  guint stream_timer_id;
  FlEventSink* event_sink;

  // Display detection
  DisplayDetection* detection;
};

gchar* build_mirror_event_json(gboolean is_screen_mirrored,
                               gboolean is_external_display_connected,
                               gint display_count);

G_END_DECLS

#endif  // NO_SCREEN_MIRROR_PLUGIN_PRIVATE_H_
