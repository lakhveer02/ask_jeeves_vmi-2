package com.askjeeves.vmi

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private lateinit var lifecycleHandler: AppLifecycleHandler
    private lateinit var screenshotProtectionHandler: ScreenshotProtectionHandler
    private val BACK_BUTTON_CHANNEL = "com.ask_jeeves.vmi/back_button"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Apply FLAG_SECURE to block screenshots on ALL devices
        // This makes screenshots show a blank/black screen
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        android.util.Log.d("MainActivity", "🔒 FLAG_SECURE applied - screenshots blocked on all devices")
        android.util.Log.d("MainActivity", "📸 Screenshots will show blank screen")
        
        // For Android 13+ (API 33+), disable predictive back animation
        // This ensures Flutter's PopScope gets priority
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            android.util.Log.d("MainActivity", "🔧 Android 13+ detected - Flutter will handle back button")
            // The enableOnBackInvokedCallback will be handled by Flutter framework
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up app lifecycle handler for cleanup on force-close
        lifecycleHandler = AppLifecycleHandler(this)
        lifecycleHandler.setupMethodChannel(flutterEngine)
        
        // Set up screenshot protection handler (for detection only)
        screenshotProtectionHandler = ScreenshotProtectionHandler(this)
        screenshotProtectionHandler.setupMethodChannel(flutterEngine)
        
        // Set up back button channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACK_BUTTON_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shouldExit" -> {
                    // Let Flutter handle the double-back logic
                    // Don't exit immediately
                    result.success(false)
                }
                "exitApp" -> {
                    // Flutter confirmed - exit now
                    android.util.Log.d("MainActivity", "🚪 Flutter confirmed exit - finishing activity")
                    finish()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}