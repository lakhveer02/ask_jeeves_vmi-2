import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  private var screenshotProtectionHandler: ScreenshotProtectionHandler?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up screenshot protection handler
    if let controller = window?.rootViewController as? FlutterViewController {
      screenshotProtectionHandler = ScreenshotProtectionHandler.setupMethodChannel(controller: controller)
      debugPrint("[iOS] ✅ Screenshot protection handler initialized")
    } else {
      debugPrint("[iOS] ⚠️ Failed to initialize screenshot protection - no FlutterViewController")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Clean up screenshot protection
    screenshotProtectionHandler?.cleanup()
    debugPrint("[iOS] 🧹 Screenshot protection cleaned up on app termination")
    super.applicationWillTerminate(application)
  }
}
