#ifndef DISPLAY_DETECTION_H_
#define DISPLAY_DETECTION_H_

#include <windows.h>

#include <functional>

// Scans connected displays using Win32 APIs.
// Reports whether an external display is connected, whether wireless mirroring
// (Miracast) is active, and the total display count.
class DisplayDetection {
 public:
  struct Result {
    bool is_external_connected;
    bool is_screen_mirrored;
    int display_count;
  };

  using ChangeCallback = std::function<void(const Result&)>;

  explicit DisplayDetection(ChangeCallback callback);
  ~DisplayDetection();

  void Start();
  void Stop();

 private:
  static void CALLBACK PollTimerProc(HWND hwnd, UINT msg, UINT_PTR id,
                                     DWORD time);

  Result Scan();

  ChangeCallback callback_;
  UINT_PTR timer_id_ = 0;
  Result last_result_{false, false, 1};
};

#endif  // DISPLAY_DETECTION_H_
