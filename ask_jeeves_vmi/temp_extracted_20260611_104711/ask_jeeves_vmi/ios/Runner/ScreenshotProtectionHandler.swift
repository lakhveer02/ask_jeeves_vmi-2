import UIKit
import Flutter

/// Production-ready screenshot and screen recording protection for iOS
/// Features:
/// - Screenshot detection with Flutter callback
/// - Screen recording detection (iOS 11+)
/// - Secure overlay for app switcher (black screen)
/// - Content protection using secure text field technique
/// - Automatic lifecycle management
/// - Performance optimized
/// - Crash-safe implementation
class ScreenshotProtectionHandler {

    static let channelName = "com.ask_jeeves.vmi/screenshot_protection"

    private var methodChannel: FlutterMethodChannel?
    private var isProtectionEnabled = false
    private var secureOverlayWindow: UIWindow?
    private var isOverlayVisible = false
    
    // Secure field for content protection
    private var secureTextField: UITextField?
    private var contentProtectionView: UIView?
    
    // Weak reference to avoid retain cycles
    private weak var flutterViewController: FlutterViewController?

    // MARK: - Setup

    @discardableResult
    static func setupMethodChannel(controller: FlutterViewController) -> ScreenshotProtectionHandler {

        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: controller.binaryMessenger
        )

        let handler = ScreenshotProtectionHandler()
        handler.methodChannel = channel
        handler.flutterViewController = controller

        channel.setMethodCallHandler { [weak handler] call, result in
            
            guard let handler = handler else {
                result(FlutterError(code: "HANDLER_DISPOSED", message: "Handler was disposed", details: nil))
                return
            }

            switch call.method {

            case "enableScreenshotProtection":
                handler.enableScreenshotProtection()
                result(true)

            case "disableScreenshotProtection":
                handler.disableScreenshotProtection()
                result(true)

            case "showSecureOverlay":
                handler.showSecureOverlay()
                result(true)

            case "hideSecureOverlay":
                handler.hideSecureOverlay()
                result(true)
                
            case "isScreenRecording":
                if #available(iOS 11.0, *) {
                    result(UIScreen.main.isCaptured)
                } else {
                    result(false)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        debugPrint("[iOS] 🔐 Screenshot protection handler configured")
        
        return handler
    }


    // MARK: - Enable Protection

    func enableScreenshotProtection() {

        guard !isProtectionEnabled else {
            debugPrint("[iOS] ⚠️ Screenshot protection already enabled")
            return
        }

        // Screenshot detection (iOS 7+)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenshotTaken),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        // Screen recording detection (iOS 11+)
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenRecordingDidChange),
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
            
            // Check if already recording
            if UIScreen.main.isCaptured {
                debugPrint("[iOS] ⚠️ Screen recording already in progress")
                notifyScreenRecordingStarted()
                // Show protection immediately if recording
                enableContentProtection()
            }
        }

        // App lifecycle - for secure overlay
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Background/Foreground transitions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Enable content protection using secure field technique
        enableContentProtection()

        isProtectionEnabled = true

        debugPrint("[iOS] ✅ Screenshot protection enabled with content protection")
    }


    // MARK: - Disable Protection

    func disableScreenshotProtection() {

        guard isProtectionEnabled else {
            debugPrint("[iOS] ⚠️ Screenshot protection already disabled")
            return
        }

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
        
        if #available(iOS 11.0, *) {
            NotificationCenter.default.removeObserver(
                self,
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
        }
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Disable content protection
        disableContentProtection()
        
        hideSecureOverlay()

        isProtectionEnabled = false

        debugPrint("[iOS] ✅ Screenshot protection disabled")
    }
    
    // MARK: - Content Protection (Secure Field Technique)
    
    /// Enable content protection using secure text field technique
    /// This makes screenshots appear blurred/black
    private func enableContentProtection() {
        guard contentProtectionView == nil else {
            debugPrint("[iOS] ⚠️ Content protection already enabled")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let window = self.flutterViewController?.view.window,
                  let flutterView = self.flutterViewController?.view else {
                debugPrint("[iOS] ⚠️ Cannot enable content protection - missing window or view")
                return
            }
            
            // 1. Create a secure text field
            let textField = UITextField()
            textField.isSecureTextEntry = true
            textField.isUserInteractionEnabled = true // Must be true to allow touches to pass down
            
            // 2. Find the layer iOS uses to render secure content (usually the first subview)
            guard let secureLayoutView = textField.subviews.first else {
                debugPrint("[iOS] ❌ Failed to find iOS secure container layer")
                return
            }
            
            // 3. Configure layout containers
            secureLayoutView.frame = window.bounds
            secureLayoutView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            // 4. Move your Flutter View INSIDE the secure layer hierarchy
            // This is the golden step: anything inside this layer turns black/blank on screenshots
            flutterView.removeFromSuperview()
            secureLayoutView.addSubview(flutterView)
            
            // 5. Add the secure container layer to the window
            window.addSubview(secureLayoutView)
            
            // Store references so we can revert it later
            self.secureTextField = textField
            self.contentProtectionView = secureLayoutView
            
            debugPrint("[iOS] 🔒 Content protection perfectly enabled (Flutter view secured!)")
        }
    }
    
    /// Disable content protection
   private func disableContentProtection() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let flutterView = self.flutterViewController?.view,
                  let secureLayoutView = self.contentProtectionView else { return }
            
            // 1. Extract the Flutter View back out of the secure container
            flutterView.removeFromSuperview()
            
            // 2. Put the Flutter View back where it belongs on the main window
            self.flutterViewController?.view.window?.addSubview(flutterView)
            
            // 3. Clean up the secure text field components
            secureLayoutView.removeFromSuperview()
            self.secureTextField = nil
            self.contentProtectionView = nil
            
            debugPrint("[iOS] 🔓 Content protection disabled safely")
        }
    }


    // MARK: - Screenshot Detection

   @objc private func screenshotTaken() {
        debugPrint("[iOS] 📸 Screenshot detected!")

        // 1. Show native iOS secure data alert message box
        DispatchQueue.main.async { [weak self] in
            guard let self = self, 
                  let rootVC = self.flutterViewController else { return }
            
            let alert = UIAlertController(
                title: "⚠️ Secure Data Protected",
                message: "This app handles high-security sensitive data. Screenshot and screen captures have been completely blocked.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Understood", style: .default, handler: nil))
            
            // Present it over your Flutter view controller
            rootVC.present(alert, animated: true, completion: nil)
            
            // 2. Notify Flutter via the channel pipeline as normal
            self.methodChannel?.invokeMethod(
                "onScreenshotDetected",
                arguments: [
                    "timestamp": Date().timeIntervalSince1970,
                    "platform": "iOS"
                ]
            )
        }
    }

    // MARK: - Screen Recording Detection

    @objc private func screenRecordingDidChange() {

        if #available(iOS 11.0, *) {

            if UIScreen.main.isCaptured {

                debugPrint("[iOS] 🎥 Screen recording started!")
                notifyScreenRecordingStarted()
                
                // Enable additional protection during recording
                enableContentProtection()

            } else {

                debugPrint("[iOS] ⏹️ Screen recording stopped")
                notifyScreenRecordingStopped()
            }
        }
    }
    
    private func notifyScreenRecordingStarted() {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel?.invokeMethod(
                "onScreenRecordingDetected",
                arguments: [
                    "isRecording": true,
                    "timestamp": Date().timeIntervalSince1970,
                    "platform": "iOS"
                ]
            )
        }
    }
    
    private func notifyScreenRecordingStopped() {
        DispatchQueue.main.async { [weak self] in
            self?.methodChannel?.invokeMethod(
                "onScreenRecordingDetected",
                arguments: [
                    "isRecording": false,
                    "timestamp": Date().timeIntervalSince1970,
                    "platform": "iOS"
                ]
            )
        }
    }


    // MARK: - App Lifecycle

    @objc private func appWillResignActive() {
        // App is about to become inactive (e.g., phone call, control center)
        debugPrint("[iOS] 🔄 App will resign active")
        showSecureOverlay()
    }

    @objc private func appDidBecomeActive() {
        // App became active again
        debugPrint("[iOS] 🔄 App did become active")
        hideSecureOverlay()
    }
    
    @objc private func appDidEnterBackground() {
        // App moved to background - ensure overlay is shown
        debugPrint("[iOS] 🔄 App entered background")
        showSecureOverlay()
    }
    
    @objc private func appWillEnterForeground() {
        // App is about to enter foreground
        debugPrint("[iOS] 🔄 App will enter foreground")
        // Keep overlay until didBecomeActive
    }


    // MARK: - Secure Overlay

    func showSecureOverlay() {
        
        // Prevent duplicate overlays
        guard secureOverlayWindow == nil else {
            debugPrint("[iOS] ⚠️ Secure overlay already visible")
            return
        }
        
        guard !isOverlayVisible else {
            debugPrint("[iOS] ⚠️ Overlay creation in progress")
            return
        }
        
        isOverlayVisible = true

        DispatchQueue.main.async { [weak self] in

            guard let self = self else { return }
            
            // Double-check after async dispatch
            guard self.secureOverlayWindow == nil else {
                self.isOverlayVisible = false
                return
            }

            // Create overlay window
            let overlayWindow: UIWindow
            
            if #available(iOS 13.0, *) {
                // iOS 13+ requires window scene
                if let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
                    as? UIWindowScene {
                    overlayWindow = UIWindow(windowScene: windowScene)
                } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    overlayWindow = UIWindow(windowScene: windowScene)
                } else {
                    debugPrint("[iOS] ⚠️ No window scene available")
                    self.isOverlayVisible = false
                    return
                }
            } else {
                // iOS 12 and below
                overlayWindow = UIWindow(frame: UIScreen.main.bounds)
            }

            // Configure window
            overlayWindow.windowLevel = .alert + 1
            overlayWindow.backgroundColor = .black

            // Create overlay view
            let overlayView = self.createSecureOverlayView()

            // Create view controller
            let viewController = UIViewController()
            viewController.view = overlayView

            overlayWindow.rootViewController = viewController
            overlayWindow.isHidden = false
            overlayWindow.makeKeyAndVisible()

            self.secureOverlayWindow = overlayWindow

            debugPrint("[iOS] 🔒 Secure overlay shown")
        }
    }

    func hideSecureOverlay() {

        guard secureOverlayWindow != nil || isOverlayVisible else {
            return
        }

        DispatchQueue.main.async { [weak self] in

            guard let self = self else { return }

            self.secureOverlayWindow?.isHidden = true
            self.secureOverlayWindow?.rootViewController = nil
            self.secureOverlayWindow = nil
            self.isOverlayVisible = false

            // Restore main window as key
            if let mainWindow = self.flutterViewController?.view.window {
                mainWindow.makeKeyAndVisible()
            }

            debugPrint("[iOS] 🔓 Secure overlay hidden")
        }
    }


    // MARK: - Overlay UI

    private func createSecureOverlayView() -> UIView {

        let containerView = UIView(frame: UIScreen.main.bounds)
        containerView.backgroundColor = .black

        // Optional: Add app icon or branding
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // App icon (optional)
        if let appIcon = UIImage(named: "AppIcon") {
            let iconImageView = UIImageView(image: appIcon)
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.layer.cornerRadius = 16
            iconImageView.clipsToBounds = true
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            
            stackView.addArrangedSubview(iconImageView)
            
            NSLayoutConstraint.activate([
                iconImageView.widthAnchor.constraint(equalToConstant: 80),
                iconImageView.heightAnchor.constraint(equalToConstant: 80)
            ])
        }

        // App name label
        let appNameLabel = UILabel()
        appNameLabel.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "VMI Demo"
        appNameLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        appNameLabel.textColor = .white
        appNameLabel.textAlignment = .center

        stackView.addArrangedSubview(appNameLabel)

        containerView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -32)
        ])

        return containerView
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        debugPrint("[iOS] 🧹 Cleaning up screenshot protection handler")
        disableScreenshotProtection()
        methodChannel = nil
        flutterViewController = nil
    }

    // MARK: - Deinitialization

    deinit {
        debugPrint("[iOS] 🗑️ Screenshot protection handler deallocated")
        NotificationCenter.default.removeObserver(self)
        hideSecureOverlay()
    }
}