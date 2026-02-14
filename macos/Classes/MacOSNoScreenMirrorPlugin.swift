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
        "com.loom.desktop"
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
        let allBundleIDs = MacOSNoScreenMirrorPlugin.defaultScreenSharingBundleIDs
            .union(customScreenSharingBundleIDs)

        for app in NSWorkspace.shared.runningApplications {
            if let bundleID = app.bundleIdentifier,
               allBundleIDs.contains(bundleID) {
                return true
            }
        }
        return false
    }

    private func updateState() {
        let screens = NSScreen.screens
        let displayCount = screens.count
        var isExternalDisplayConnected = false
        var isScreenMirrored = false

        for screen in screens {
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0

            if CGDisplayIsBuiltin(screenNumber) == 0 {
                isExternalDisplayConnected = true
            }

            if CGDisplayMirrorsDisplay(screenNumber) != kCGNullDirectDisplay {
                isScreenMirrored = true
            }
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
