import UIKit
import Flutter

/// Handles app lifecycle events including force-close cleanup
class AppLifecycleHandler {
    static let channelName = "com.ask_jeeves.vmi/app_lifecycle"
    
    static func setupMethodChannel(controller: FlutterViewController) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )
        
        // Set up handler for Flutter to call native code
        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            // Handle any Flutter -> Native calls here if needed
            result(nil)
        }
        
        // Set up app termination observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            debugPrint("[iOS] App will terminate - invoking cleanup")
            channel.invokeMethod("onAppTerminating", arguments: nil) { _ in
                debugPrint("[iOS] Cleanup invoked")
            }
        }
    }
}
