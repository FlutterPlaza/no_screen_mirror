#ifndef DISPLAY_DETECTION_H_
#define DISPLAY_DETECTION_H_

#include <glib.h>

G_BEGIN_DECLS

typedef struct _DisplayDetection DisplayDetection;

typedef void (*DisplayChangeCallback)(gboolean is_external_connected,
                                      gint display_count,
                                      gpointer user_data);

DisplayDetection* display_detection_new(DisplayChangeCallback callback,
                                        gpointer user_data);

void display_detection_start(DisplayDetection* detection);
void display_detection_stop(DisplayDetection* detection);
void display_detection_free(DisplayDetection* detection);

G_END_DECLS

#endif  // DISPLAY_DETECTION_H_
