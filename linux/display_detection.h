#ifndef DISPLAY_DETECTION_H_
#define DISPLAY_DETECTION_H_

#include <glib.h>

G_BEGIN_DECLS

typedef struct _DisplayDetection DisplayDetection;

typedef void (*DisplayChangeCallback)(gboolean is_external_connected,
                                      gint display_count,
                                      gboolean is_screen_shared,
                                      gpointer user_data);

DisplayDetection* display_detection_new(DisplayChangeCallback callback,
                                        gpointer user_data);

void display_detection_start(DisplayDetection* detection,
                             guint poll_interval_ms,
                             const gchar* const* custom_processes);
void display_detection_stop(DisplayDetection* detection);
void display_detection_free(DisplayDetection* detection);

G_END_DECLS

#endif  // DISPLAY_DETECTION_H_
