import Flutter
import UIKit

public class NoScreenMirrorPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private static var methodChannel: FlutterMethodChannel? = nil
    private static var eventChannel: FlutterEventChannel? = nil
    private var eventSink: FlutterEventSink? = nil
    private var lastEventJson: String = ""
    private var hasPendingEvent: Bool = false
    private var isListening: Bool = false

    private static let methodChannelName = "com.flutterplaza.no_screen_mirror_methods"
    private static let eventChannelName = "com.flutterplaza.no_screen_mirror_streams"

    public static func register(with registrar: FlutterPluginRegistrar) {
        methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())

        let instance = NoScreenMirrorPlugin()

        registrar.addMethodCallDelegate(instance, channel: methodChannel!)
        eventChannel?.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startListening":
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
            selector: #selector(screenDidChange),
            name: UIScreen.didConnectNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: UIScreen.didDisconnectNotification,
            object: nil
        )

        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenDidChange),
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
        }

        updateState()
    }

    private func stopDetection() {
        guard isListening else { return }
        isListening = false

        NotificationCenter.default.removeObserver(self, name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIScreen.didDisconnectNotification, object: nil)

        if #available(iOS 11.0, *) {
            NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
        }
    }

    @objc private func screenDidChange() {
        updateState()
    }

    private func updateState() {
        let screens = UIScreen.screens
        let displayCount = screens.count
        var isExternalDisplayConnected = displayCount > 1
        var isScreenMirrored = false

        // Check for mirroring via UIScreen.mirrored property
        for screen in screens {
            if screen.mirrored != nil {
                isScreenMirrored = true
            }
        }

        // iOS 11+: isCaptured detects AirPlay mirroring
        if #available(iOS 11.0, *) {
            if UIScreen.main.isCaptured && displayCount <= 1 {
                isScreenMirrored = true
            }
        }

        let map: [String: Any] = [
            "is_screen_mirrored": isScreenMirrored,
            "is_external_display_connected": isExternalDisplayConnected,
            "display_count": displayCount
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
