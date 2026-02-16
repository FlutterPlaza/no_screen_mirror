import Cocoa
import FlutterMacOS

public class MacOSNoScreenMirrorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    private var eventSink: FlutterEventSink? = nil
    private var lastEventJson: String = ""
    private var hasPendingEvent: Bool = false
    private var isListening: Bool = false
    private var pollingIntervalSec: Double = 2.0
    private var screenSharingTimer: Timer? = nil

    private static let methodChannelName = "com.flutterplaza.no_screen_mirror_methods"
    private static let eventChannelName = "com.flutterplaza.no_screen_mirror_streams"

    private static var defaultScreenSharingBundleIDs: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams",
        "com.microsoft.teams2",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "com.obsproject.obs-studio",
        "com.apple.QuickTimePlayerX",
        "com.loom.desktop",
        "com.apple.FaceTime",
        "com.apple.ScreenSharing",
        "com.cisco.webexmeetingsapp",
        "com.webex.meetingmanager",
        "com.gotomeeting",
        "com.logmein.GoToMeeting",
        "com.ringcentral.RingCentral",
        "com.bluejeans.BlueJeans",
        "com.whereby.app",
        "com.pop.pop.app",
        "com.crowdcast.Crowdcast",
        "com.around.Around",
        "com.livestorm.app",
    ]

    private var customScreenSharingBundleIDs: Set<String> = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger)
        eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger)

        let instance = MacOSNoScreenMirrorPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startListening":
            if let args = call.arguments as? [String: Any] {
                if let intervalMs = args["pollingIntervalMs"] as? Int, intervalMs > 0 {
                    pollingIntervalSec = Double(intervalMs) / 1000.0
                }
                if let processes = args["customProcesses"] as? [String] {
                    customScreenSharingBundleIDs = Set(processes)
                }
            }
            startDetection()
            result("Listening started")
        case "stopListening":
            stopDetection()
            result("Listening stopped")
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startDetection() {
        guard !isListening else { return }
        isListening = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        updateState()

        // Periodic timer for screen sharing process detection
        screenSharingTimer = Timer.scheduledTimer(withTimeInterval: pollingIntervalSec, repeats: true) { [weak self] _ in
            self?.updateState()
        }
    }

    private func stopDetection() {
        guard isListening else { return }
        isListening = false

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        screenSharingTimer?.invalidate()
        screenSharingTimer = nil
    }

    @objc private func screenParametersDidChange() {
        updateState()
    }

    private func isScreenSharingActive() -> Bool {
        // Check macOS system-level screen sharing via session dictionary.
        // This detects macOS built-in Screen Sharing (Remote Management).
        if let sessionDict = CGSessionCopyCurrentDictionary() as? [String: Any],
           let isShared = sessionDict["CGSSessionScreenIsShared"] as? Bool,
           isShared {
            return true
        }

        // Check if known screen sharing apps are running
        let allBundleIDs = MacOSNoScreenMirrorPlugin.defaultScreenSharingBundleIDs
            .union(customScreenSharingBundleIDs)

        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if let bundleID = app.bundleIdentifier,
               allBundleIDs.contains(bundleID) {
                return true
            }
        }

        // Detect screen capture via the macOS Control Center indicator.
        // When any app (including browsers) captures the screen, macOS
        // shows an "AudioVideoModule" status bar item in Control Center.
        // This reliably detects browser-based screen sharing (Google Meet,
        // Zoom web, etc.) as well as any other screen capture.
        if isScreenCaptureIndicatorVisible() {
            return true
        }

        return false
    }

    /// Checks CGWindowList for the Control Center "AudioVideoModule"
    /// window, which macOS shows whenever screen capture/recording is active.
    private func isScreenCaptureIndicatorVisible() -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }

        for window in windowList {
            let ownerName = window[kCGWindowOwnerName as String] as? String ?? ""
            let windowName = window[kCGWindowName as String] as? String ?? ""

            if ownerName == "Control Center" && windowName == "AudioVideoModule" {
                return true
            }
        }

        return false
    }

    private func updateState() {
        var isExternalDisplayConnected = false
        var isScreenMirrored = false

        // Use CGGetOnlineDisplayList to get ALL displays, including mirrored ones.
        // NSScreen.screens excludes mirrored displays, so it can't detect mirroring.
        var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
        var onlineCount: UInt32 = 0
        CGGetOnlineDisplayList(16, &onlineDisplays, &onlineCount)

        var activeCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &activeCount)

        let displayCount = Int(onlineCount)

        for i in 0..<Int(onlineCount) {
            let displayID = onlineDisplays[i]

            if CGDisplayIsBuiltin(displayID) == 0 {
                isExternalDisplayConnected = true
            }

            if CGDisplayMirrorsDisplay(displayID) != kCGNullDirectDisplay {
                isScreenMirrored = true
            }
        }

        // If online displays > active displays, mirroring is active
        // (active list excludes mirrors, online list includes them)
        if onlineCount > activeCount {
            isScreenMirrored = true
        }

        let isScreenShared = isScreenSharingActive()

        let map: [String: Any] = [
            "is_screen_mirrored": isScreenMirrored,
            "is_external_display_connected": isExternalDisplayConnected,
            "display_count": displayCount,
            "is_screen_shared": isScreenShared
        ]
        let jsonString = convertMapToJsonString(map)

        if lastEventJson != jsonString {
            lastEventJson = jsonString
            hasPendingEvent = true
        }
    }

    private func convertMapToJsonString(_ map: [String: Any]) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: map, options: []) {
            return String(data: jsonData, encoding: .utf8) ?? ""
        }
        return ""
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.mirrorStream()
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    private func mirrorStream() {
        if hasPendingEvent {
            eventSink?(lastEventJson)
            hasPendingEvent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.mirrorStream()
        }
    }
}
