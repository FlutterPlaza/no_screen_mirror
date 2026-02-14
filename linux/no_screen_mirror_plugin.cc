#include "include/no_screen_mirror/no_screen_mirror_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include "no_screen_mirror_plugin_private.h"
#include "display_detection.h"

#define NO_SCREEN_MIRROR_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), no_screen_mirror_plugin_get_type(), \
                              NoScreenMirrorPlugin))

static const char kMethodChannelName[] =
    "com.flutterplaza.no_screen_mirror_methods";
static const char kEventChannelName[] =
    "com.flutterplaza.no_screen_mirror_streams";

G_DEFINE_TYPE(NoScreenMirrorPlugin, no_screen_mirror_plugin, g_object_get_type())

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

gchar* build_mirror_event_json(gboolean is_screen_mirrored,
                               gboolean is_external_display_connected,
                               gint display_count,
                               gboolean is_screen_shared) {
  return g_strdup_printf(
      "{\"is_screen_mirrored\":%s,\"is_external_display_connected\":%s,"
      "\"display_count\":%d,\"is_screen_shared\":%s}",
      is_screen_mirrored ? "true" : "false",
      is_external_display_connected ? "true" : "false",
      display_count,
      is_screen_shared ? "true" : "false");
}

static void update_shared_state(NoScreenMirrorPlugin* self,
                                gboolean is_external_connected,
                                gint display_count,
                                gboolean is_screen_shared) {
  // Linux: is_screen_mirrored is always false (no kernel mirroring concept)
  g_autofree gchar* json =
      build_mirror_event_json(FALSE, is_external_connected, display_count,
                              is_screen_shared);

  if (g_strcmp0(json, self->last_event_json) != 0) {
    g_free(self->last_event_json);
    self->last_event_json = g_strdup(json);
    self->has_pending_event = TRUE;
  }
}

// ---------------------------------------------------------------------------
// Display detection callback
// ---------------------------------------------------------------------------

static void on_display_changed(gboolean is_external_connected,
                               gint display_count,
                               gboolean is_screen_shared,
                               gpointer user_data) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(user_data);
  update_shared_state(self, is_external_connected, display_count,
                      is_screen_shared);
}

// ---------------------------------------------------------------------------
// Method channel handler
// ---------------------------------------------------------------------------

static void handle_method_call(FlMethodChannel* channel,
                               FlMethodCall* method_call,
                               gpointer user_data) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(user_data);
  const gchar* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = NULL;

  if (g_strcmp0(method, "startListening") == 0) {
    guint poll_interval_ms = 2000;
    const gchar** custom_processes = NULL;
    guint custom_count = 0;

    FlValue* args = fl_method_call_get_args(method_call);
    if (args != NULL && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* interval_val = fl_value_lookup_string(args, "pollingIntervalMs");
      if (interval_val != NULL && fl_value_get_type(interval_val) == FL_VALUE_TYPE_INT) {
        gint64 val = fl_value_get_int(interval_val);
        if (val > 0) poll_interval_ms = (guint)val;
      }

      FlValue* processes_val = fl_value_lookup_string(args, "customProcesses");
      if (processes_val != NULL && fl_value_get_type(processes_val) == FL_VALUE_TYPE_LIST) {
        custom_count = fl_value_get_length(processes_val);
        if (custom_count > 0) {
          custom_processes = g_new0(const gchar*, custom_count + 1);
          for (guint i = 0; i < custom_count; i++) {
            FlValue* item = fl_value_get_list_value(processes_val, i);
            custom_processes[i] = fl_value_get_string(item);
          }
          custom_processes[custom_count] = NULL;
        }
      }
    }

    if (!self->is_listening) {
      self->is_listening = TRUE;
      display_detection_start(self->detection, poll_interval_ms, custom_processes);
    }

    g_free(custom_processes);

    g_autoptr(FlValue) msg = fl_value_new_string("Listening started");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(msg));

  } else if (g_strcmp0(method, "stopListening") == 0) {
    if (self->is_listening) {
      self->is_listening = FALSE;
      display_detection_stop(self->detection);
    }
    g_autoptr(FlValue) msg = fl_value_new_string("Listening stopped");
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(msg));

  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, NULL);
}

// ---------------------------------------------------------------------------
// Event channel (stream) handler
// ---------------------------------------------------------------------------

static gboolean stream_tick(gpointer user_data) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(user_data);

  if (self->has_pending_event && self->event_sink != NULL) {
    g_autoptr(FlValue) value = fl_value_new_string(self->last_event_json);
    fl_event_sink_success(self->event_sink, value, NULL);
    self->has_pending_event = FALSE;
  }

  return G_SOURCE_CONTINUE;
}

static FlMethodErrorResponse* on_listen(FlEventChannel* channel,
                                        FlValue* args,
                                        FlEventSink* event_sink,
                                        gpointer user_data) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(user_data);
  self->event_sink = event_sink;

  if (self->stream_timer_id == 0) {
    self->stream_timer_id = g_timeout_add(1000, stream_tick, self);
  }

  return NULL;
}

static FlMethodErrorResponse* on_cancel(FlEventChannel* channel,
                                        FlValue* args,
                                        gpointer user_data) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(user_data);
  self->event_sink = NULL;

  if (self->stream_timer_id != 0) {
    g_source_remove(self->stream_timer_id);
    self->stream_timer_id = 0;
  }

  return NULL;
}

// ---------------------------------------------------------------------------
// GObject lifecycle
// ---------------------------------------------------------------------------

static void no_screen_mirror_plugin_dispose(GObject* object) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(object);

  if (self->stream_timer_id != 0) {
    g_source_remove(self->stream_timer_id);
    self->stream_timer_id = 0;
  }

  g_clear_object(&self->method_channel);
  g_clear_object(&self->event_channel);

  display_detection_free(self->detection);
  self->detection = NULL;

  g_free(self->last_event_json);
  self->last_event_json = NULL;

  G_OBJECT_CLASS(no_screen_mirror_plugin_parent_class)->dispose(object);
}

static void no_screen_mirror_plugin_class_init(NoScreenMirrorPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = no_screen_mirror_plugin_dispose;
}

static void no_screen_mirror_plugin_init(NoScreenMirrorPlugin* self) {
  self->is_listening = FALSE;
  self->last_event_json = NULL;
  self->has_pending_event = FALSE;
  self->stream_timer_id = 0;
  self->event_sink = NULL;
  self->detection = NULL;
}

// ---------------------------------------------------------------------------
// Plugin registration
// ---------------------------------------------------------------------------

void no_screen_mirror_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  NoScreenMirrorPlugin* self = NO_SCREEN_MIRROR_PLUGIN(
      g_object_new(no_screen_mirror_plugin_get_type(), NULL));

  self->registrar = registrar;

  // Display detection subsystem
  self->detection = display_detection_new(on_display_changed, self);

  // Method channel
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->method_channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), kMethodChannelName,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->method_channel, handle_method_call, g_object_ref(self),
      g_object_unref);

  // Event channel
  g_autoptr(FlStandardMethodCodec) event_codec =
      fl_standard_method_codec_new();
  self->event_channel = fl_event_channel_new(
      fl_plugin_registrar_get_messenger(registrar), kEventChannelName,
      FL_METHOD_CODEC(event_codec));
  fl_event_channel_set_stream_handlers(self->event_channel, on_listen,
                                       on_cancel, g_object_ref(self),
                                       g_object_unref);

  // Initial state push
  update_shared_state(self, FALSE, 1, FALSE);

  g_object_unref(self);
}
