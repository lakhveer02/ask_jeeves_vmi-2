package com.askjeeves.vmi

import android.app.Activity
import android.content.ContentResolver
import android.database.ContentObserver
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles screenshot and screen recording protection
 * 
 * Features:
 * - FLAG_SECURE: Prevents screenshots (shows blank/black screen)
 * - Secure Overlay: Shows security warning when app is backgrounded/in recent apps
 * - Screenshot Detection: Monitors and logs screenshot attempts
 */
class ScreenshotProtectionHandler(private val activity: Activity) {
    companion object {
        private const val CHANNEL_NAME = "com.askjeeves.vmi/screenshot_protection"
        private const val TAG = "ScreenshotProtection"
    }

    private var methodChannel: MethodChannel? = null
    private var contentObserver: ContentObserver? = null
    private var isProtectionEnabled = false
    private var secureOverlayView: View? = null

    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)

        methodChannel?.setMethodCallHandler { call, result: MethodChannel.Result ->
            when (call.method) {
                "enableScreenshotProtection" -> {
                    enableScreenshotProtection()
                    result.success(null)
                }
                "disableScreenshotProtection" -> {
                    disableScreenshotProtection()
                    result.success(null)
                }
                "showSecureOverlay" -> {
                    showSecureOverlay()
                    result.success(null)
                }
                "hideSecureOverlay" -> {
                    hideSecureOverlay()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enableScreenshotProtection() {
        if (isProtectionEnabled) return

        Log.d(TAG, "Enabling screenshot protection...")

        // Apply FLAG_SECURE to prevent screenshots
        // This makes screenshots show a blank/black screen on ALL devices
        activity.window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        Log.d(TAG, "✅ FLAG_SECURE applied - screenshots blocked on ALL devices")

        // Monitor screenshot files for detection/logging
        monitorScreenshots()

        isProtectionEnabled = true
        Log.d(TAG, "✅ Screenshot protection enabled (monitoring active)")
        Log.d(TAG, "🔒 Screenshots will show blank screen on ALL devices")
    }

    private fun disableScreenshotProtection() {
        if (!isProtectionEnabled) return

        // DO NOT remove FLAG_SECURE - keep screenshots blocked at all times
        // activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        Log.d(TAG, "⚠️ Screenshot protection cannot be disabled - FLAG_SECURE remains active")

        // Stop monitoring
        contentObserver?.let {
            activity.contentResolver.unregisterContentObserver(it)
        }

        // Remove secure overlay if present
        hideSecureOverlay()

        isProtectionEnabled = false
        Log.d(TAG, "Screenshot protection disabled")
    }

    private fun monitorScreenshots() {
        val contentResolver: ContentResolver = activity.contentResolver
        val screenshotsUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

        contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                Log.d(TAG, "📸 Screenshot attempt detected!")
                Log.d(TAG, "⚠️ Screenshot will show blank screen with warning")
                methodChannel?.invokeMethod("onScreenshotDetected", null)
            }
        }

        contentResolver.registerContentObserver(
            screenshotsUri,
            true,
            contentObserver!!
        )
    }

    /**
     * Show secure overlay when app goes to background or recent apps
     * This ensures no sensitive data is visible in app switcher
     */
    private fun showSecureOverlay() {
        activity.runOnUiThread {
            if (secureOverlayView != null) {
                Log.d(TAG, "Secure overlay already visible")
                return@runOnUiThread
            }

            try {
                val rootView = activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
                
                // Create overlay container
                val overlayContainer = FrameLayout(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                    setBackgroundColor(Color.BLACK)
                    elevation = 1000f // Ensure it's on top
                }

                // Create content container
                val contentLayout = LinearLayout(activity).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    layoutParams = FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        gravity = Gravity.CENTER
                    }
                    setPadding(dpToPx(32), dpToPx(32), dpToPx(32), dpToPx(32))
                }

                // Lock icon (using Unicode lock symbol)
              //  val lockIcon = TextView(activity).apply {
                  //  text = "🔒"
                 //   textSize = 64f
                //    gravity = Gravity.CENTER
                 //   layoutParams = LinearLayout.LayoutParams(
                  //      LinearLayout.LayoutParams.WRAP_CONTENT,
                  //        LinearLayout.LayoutParams.WRAP_CONTENT
                    //  ).apply {
                    //      bottomMargin = dpToPx(24)
                //      }
               //   }

                // Title
              //    val titleText = TextView(activity).apply {
                 //     text = "Content Protected"
              //        textSize = 28f
                 //     setTextColor(Color.WHITE)
                //      gravity = Gravity.CENTER
                 //     layoutParams = LinearLayout.LayoutParams(
                 //         LinearLayout.LayoutParams.WRAP_CONTENT,
                //          LinearLayout.LayoutParams.WRAP_CONTENT
               //       ).apply {
                  //      bottomMargin = dpToPx(16)
                //      }
             //    }

                // Message
                val messageText = TextView(activity).apply {
                    text = "This app contains sensitive information.\nContent is hidden for your security."
                    textSize = 16f
                    setTextColor(Color.parseColor("#B0B0B0"))
                    gravity = Gravity.CENTER
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        bottomMargin = dpToPx(32)
                    }
                }

                // Warning box
               //  val warningBox = LinearLayout(activity).apply {
                  //   orientation = LinearLayout.VERTICAL
                  //   gravity = Gravity.CENTER
                 //    setBackgroundColor(Color.parseColor("#1A1A1A"))
                //     setPadding(dpToPx(20), dpToPx(20), dpToPx(20), dpToPx(20))
                 //    layoutParams = LinearLayout.LayoutParams(
                 //        LinearLayout.LayoutParams.MATCH_PARENT,
                  //       LinearLayout.LayoutParams.WRAP_CONTENT
                 //    )
              //   }

               // val warningTitle = TextView(activity).apply {
                  //  text = "⚠️ Security Notice"
                  //  textSize = 16f
                  //  setTextColor(Color.parseColor("#FF5252"))
                  //  gravity = Gravity.CENTER
                  //  layoutParams = LinearLayout.LayoutParams(
                  //      LinearLayout.LayoutParams.WRAP_CONTENT,
                  //      LinearLayout.LayoutParams.WRAP_CONTENT
                  //  ).apply {
                  //      bottomMargin = dpToPx(8)
                  //  }
             //   }

             //   val warningMessage = TextView(activity).apply {
                 //   text = "Screenshots and screen recordings are blocked.\nReturn to the app to view content."
             //       textSize = 14f
                //    setTextColor(Color.parseColor("#B0B0B0"))
               //     gravity = Gravity.CENTER
                //    layoutParams = LinearLayout.LayoutParams(
                 //       LinearLayout.LayoutParams.WRAP_CONTENT,
               //         LinearLayout.LayoutParams.WRAP_CONTENT
               //     )
             //   }

               // warningBox.addView(warningTitle)
               // warningBox.addView(warningMessage)

                // Add all views to content layout
              //  contentLayout.addView(lockIcon)
              //  contentLayout.addView(titleText)
                contentLayout.addView(messageText)
               //  contentLayout.addView(warningBox)

                // Add content to overlay container
                overlayContainer.addView(contentLayout)

                // Add overlay to root view
                rootView.addView(overlayContainer)
                secureOverlayView = overlayContainer

                Log.d(TAG, "🔒 Secure overlay shown - content hidden")
            } catch (e: Exception) {
                Log.e(TAG, "Error showing secure overlay: ${e.message}", e)
            }
        }
    }

    /**
     * Hide secure overlay when app returns to foreground
     */
    private fun hideSecureOverlay() {
        activity.runOnUiThread {
            secureOverlayView?.let { overlay ->
                try {
                    val rootView = activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
                    rootView.removeView(overlay)
                    secureOverlayView = null
                    Log.d(TAG, "🔓 Secure overlay hidden - content visible")
                } catch (e: Exception) {
                    Log.e(TAG, "Error hiding secure overlay: ${e.message}", e)
                }
            }
        }
    }

    /**
     * Convert dp to pixels
     */
    private fun dpToPx(dp: Int): Int {
        val density = activity.resources.displayMetrics.density
        return (dp * density).toInt()
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        contentObserver?.let {
            activity.contentResolver.unregisterContentObserver(it)
        }
        hideSecureOverlay()
    }
}
