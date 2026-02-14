#include "display_detection.h"

#include <tlhelp32.h>
#include <wingdi.h>

// Static instance pointer for the timer callback (no this-capture in WinAPI
// timer procs). Safe because Flutter Windows runs one engine per process.
static DisplayDetection* g_detection_instance = nullptr;

DisplayDetection::DisplayDetection(ChangeCallback callback)
    : callback_(std::move(callback)) {
  g_detection_instance = this;
}

DisplayDetection::~DisplayDetection() {
  Stop();
  if (g_detection_instance == this) {
    g_detection_instance = nullptr;
  }
}

// -------------------------------------------------------------------------
// Display scanning
// -------------------------------------------------------------------------

static BOOL CALLBACK MonitorEnumProc(HMONITOR monitor, HDC hdc, LPRECT rect,
                                     LPARAM data) {
  auto* count = reinterpret_cast<int*>(data);
  (*count)++;
  return TRUE;
}

static const wchar_t* kDefaultProcessNames[] = {
    L"Zoom.exe",    L"CptHost.exe", L"Teams.exe",  L"ms-teams.exe",
    L"slack.exe",   L"Discord.exe", L"obs64.exe",  L"obs32.exe",
    L"ffmpeg.exe",
};

bool DisplayDetection::IsScreenSharingProcessRunning() {
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return false;

  PROCESSENTRY32W entry;
  entry.dwSize = sizeof(entry);

  if (Process32FirstW(snapshot, &entry)) {
    do {
      // Check default process names
      for (const auto* name : kDefaultProcessNames) {
        if (_wcsicmp(entry.szExeFile, name) == 0) {
          CloseHandle(snapshot);
          return true;
        }
      }
      // Check custom process names
      for (const auto& name : custom_processes_) {
        if (_wcsicmp(entry.szExeFile, name.c_str()) == 0) {
          CloseHandle(snapshot);
          return true;
        }
      }
    } while (Process32NextW(snapshot, &entry));
  }

  CloseHandle(snapshot);
  return false;
}

DisplayDetection::Result DisplayDetection::Scan() {
  Result result{false, false, 1, false};

  // 1. Count monitors via EnumDisplayMonitors
  int monitor_count = 0;
  EnumDisplayMonitors(nullptr, nullptr, MonitorEnumProc,
                      reinterpret_cast<LPARAM>(&monitor_count));
  if (monitor_count > 0) {
    result.display_count = monitor_count;
  }

  // External display: more than one monitor means an external is connected.
  if (monitor_count > 1) {
    result.is_external_connected = true;
  }

  // 2. Check for Miracast / wireless displays via QueryDisplayConfig
  UINT32 path_count = 0;
  UINT32 mode_count = 0;
  LONG qdc_result = GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS,
                                                &path_count, &mode_count);
  if (qdc_result == ERROR_SUCCESS && path_count > 0) {
    std::vector<DISPLAYCONFIG_PATH_INFO> paths(path_count);
    std::vector<DISPLAYCONFIG_MODE_INFO> modes(mode_count);
    qdc_result = QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, &path_count,
                                    paths.data(), &mode_count, modes.data(),
                                    nullptr);
    if (qdc_result == ERROR_SUCCESS) {
      for (UINT32 i = 0; i < path_count; i++) {
        if (paths[i].targetInfo.outputTechnology ==
            DISPLAYCONFIG_OUTPUT_TECHNOLOGY_MIRACAST) {
          result.is_screen_mirrored = true;
          break;
        }
      }
    }
  }

  result.is_screen_shared = IsScreenSharingProcessRunning();

  return result;
}

// -------------------------------------------------------------------------
// Timer-based polling
// -------------------------------------------------------------------------

void CALLBACK DisplayDetection::PollTimerProc(HWND /*hwnd*/, UINT /*msg*/,
                                              UINT_PTR /*id*/,
                                              DWORD /*time*/) {
  if (g_detection_instance == nullptr) return;
  auto* self = g_detection_instance;

  Result current = self->Scan();
  if (current.is_external_connected != self->last_result_.is_external_connected ||
      current.is_screen_mirrored != self->last_result_.is_screen_mirrored ||
      current.display_count != self->last_result_.display_count ||
      current.is_screen_shared != self->last_result_.is_screen_shared) {
    self->last_result_ = current;
    if (self->callback_) {
      self->callback_(current);
    }
  }
}

void DisplayDetection::Start(UINT poll_interval_ms,
                             const std::vector<std::wstring>& custom_processes) {
  if (timer_id_ != 0) return;

  custom_processes_ = custom_processes;

  // Initial scan
  last_result_ = Scan();
  if (callback_) {
    callback_(last_result_);
  }

  // Configurable poll timer
  if (poll_interval_ms == 0) poll_interval_ms = 2000;
  timer_id_ = SetTimer(nullptr, 0, poll_interval_ms, PollTimerProc);
}

void DisplayDetection::Stop() {
  if (timer_id_ != 0) {
    KillTimer(nullptr, timer_id_);
    timer_id_ = 0;
  }
}
