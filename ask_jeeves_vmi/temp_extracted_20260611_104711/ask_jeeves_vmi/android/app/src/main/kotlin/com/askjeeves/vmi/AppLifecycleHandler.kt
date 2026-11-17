package com.askjeeves.vmi

import android.app.Activity
import android.content.Context
import android.os.Process
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.util.Log

/**
 * Handles app lifecycle events including force-close cleanup
 */
class AppLifecycleHandler(private val activity: Activity) {
    companion object {
        private const val CHANNEL_NAME = "com.askjeeves.vmi/app_lifecycle"
        private const val TAG = "AppLifecycleHandler"
    }

    private var methodChannel: MethodChannel? = null

    fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        
        methodChannel?.setMethodCallHandler { call, result: MethodChannel.Result ->
            when (call.method) {
                else -> result.notImplemented()
            }
        }

        // Register shutdown hook to handle force-close
        Runtime.getRuntime().addShutdownHook(Thread {
            Log.d(TAG, "App is terminating - performing cleanup")
            invokeCleanup()
        })
    }

    private fun invokeCleanup() {
        try {
            methodChannel?.invokeMethod("onAppTerminating", null)
            
            // Give the cleanup a moment to complete
            Thread.sleep(2000)
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup: ${e.message}")
        }
    }
}
