#include "display_detection.h"

#include <dirent.h>
#include <stdio.h>
#include <string.h>

struct _DisplayDetection {
  DisplayChangeCallback callback;
  gpointer user_data;
  guint poll_timer_id;
  gboolean last_external_connected;
  gint last_display_count;
};

static gboolean is_builtin_connector(const gchar* name) {
  return (g_str_has_prefix(name, "eDP") || g_str_has_prefix(name, "LVDS") ||
          g_str_has_prefix(name, "DSI"));
}

static gboolean is_display_connector(const gchar* name) {
  return (g_str_has_prefix(name, "HDMI") || g_str_has_prefix(name, "DP") ||
          g_str_has_prefix(name, "VGA") || g_str_has_prefix(name, "DVI") ||
          g_str_has_prefix(name, "eDP") || g_str_has_prefix(name, "LVDS") ||
          g_str_has_prefix(name, "DSI"));
}

static void scan_connectors(gboolean* out_external_connected,
                             gint* out_display_count) {
  gboolean external_connected = FALSE;
  gint display_count = 0;

  // Scan /sys/class/drm/ for card*-* connector directories
  DIR* drm_dir = opendir("/sys/class/drm");
  if (drm_dir == NULL) {
    *out_external_connected = FALSE;
    *out_display_count = 1;
    return;
  }

  struct dirent* entry;
  while ((entry = readdir(drm_dir)) != NULL) {
    // Only look at card*-ConnectorName entries (e.g. card0-HDMI-A-1)
    if (strncmp(entry->d_name, "card", 4) != 0) continue;
    const char* dash = strchr(entry->d_name + 4, '-');
    if (dash == NULL) continue;
    const gchar* connector_name = dash + 1;

    if (!is_display_connector(connector_name)) continue;

    // Read the status file
    g_autofree gchar* status_path = g_strdup_printf(
        "/sys/class/drm/%s/status", entry->d_name);

    g_autofree gchar* status_content = NULL;
    if (!g_file_get_contents(status_path, &status_content, NULL, NULL))
      continue;

    g_strstrip(status_content);
    if (g_strcmp0(status_content, "connected") == 0) {
      display_count++;
      if (!is_builtin_connector(connector_name)) {
        external_connected = TRUE;
      }
    }
  }
  closedir(drm_dir);

  // Ensure at least 1 display
  if (display_count == 0) display_count = 1;

  *out_external_connected = external_connected;
  *out_display_count = display_count;
}

static gboolean poll_tick(gpointer user_data) {
  DisplayDetection* self = (DisplayDetection*)user_data;

  gboolean external_connected = FALSE;
  gint display_count = 0;
  scan_connectors(&external_connected, &display_count);

  if (external_connected != self->last_external_connected ||
      display_count != self->last_display_count) {
    self->last_external_connected = external_connected;
    self->last_display_count = display_count;

    if (self->callback != NULL) {
      self->callback(external_connected, display_count, self->user_data);
    }
  }

  return G_SOURCE_CONTINUE;
}

DisplayDetection* display_detection_new(DisplayChangeCallback callback,
                                        gpointer user_data) {
  DisplayDetection* self = g_new0(DisplayDetection, 1);
  self->callback = callback;
  self->user_data = user_data;
  self->poll_timer_id = 0;
  self->last_external_connected = FALSE;
  self->last_display_count = 1;
  return self;
}

void display_detection_start(DisplayDetection* self) {
  if (self == NULL) return;
  if (self->poll_timer_id != 0) return;

  // Initial scan
  scan_connectors(&self->last_external_connected, &self->last_display_count);
  if (self->callback != NULL) {
    self->callback(self->last_external_connected, self->last_display_count,
                   self->user_data);
  }

  // 2s poll timer
  self->poll_timer_id = g_timeout_add(2000, poll_tick, self);
}

void display_detection_stop(DisplayDetection* self) {
  if (self == NULL) return;
  if (self->poll_timer_id != 0) {
    g_source_remove(self->poll_timer_id);
    self->poll_timer_id = 0;
  }
}

void display_detection_free(DisplayDetection* self) {
  if (self == NULL) return;
  display_detection_stop(self);
  g_free(self);
}
