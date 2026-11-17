import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service for real-time speech-to-text conversion
class SpeechToTextService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  
  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      debugPrint('[SpeechToText] Initializing...');
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('[SpeechToText] ❌ Error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('[SpeechToText] Status: $status');
        },
      );
      
      if (_isInitialized) {
        debugPrint('[SpeechToText] ✅ Initialized successfully');
        
        // Log available locales
        final locales = await _speech.locales();
        debugPrint('[SpeechToText] Available locales: ${locales.length}');
        for (var locale in locales.take(5)) {
          debugPrint('[SpeechToText]   - ${locale.localeId}: ${locale.name}');
        }
      } else {
        debugPrint('[SpeechToText] ⚠️ Initialization failed');
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('[SpeechToText] ❌ Initialization error: $e');
      return false;
    }
  }
  
  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    debugPrint('[SpeechToText] Microphone permission: $status');
    
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      debugPrint('[SpeechToText] Permission request result: $result');
      return result.isGranted;
    }
    
    return true;
  }
  
  /// Start listening for speech
  /// [onResult] callback receives recognized text (partial or final)
  /// [onFinal] callback receives only final recognized text
  /// [continuous] if true, will automatically restart listening after each result
  Future<bool> startListening({
    required Function(String text) onResult,
    Function(String text)? onFinal,
    String localeId = 'en_US',
    bool continuous = true,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('[SpeechToText] ❌ Cannot start listening: not initialized');
        return false;
      }
    }
    
    if (_isListening) {
      debugPrint('[SpeechToText] ⚠️ Already listening');
      return true;
    }
    
    // Check permission
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      debugPrint('[SpeechToText] ❌ No microphone permission');
      return false;
    }
    
    try {
      debugPrint('[SpeechToText] 🎤 Starting to listen (locale: $localeId, continuous: $continuous)...');
      
      await _speech.listen(
        onResult: (result) {
          final recognizedText = result.recognizedWords;
          debugPrint('[SpeechToText] 📝 Recognized: "$recognizedText" (final: ${result.finalResult})');
          
          // Call the result callback
          onResult(recognizedText);
          
          // If this is a final result, call the onFinal callback
          if (result.finalResult && onFinal != null) {
            onFinal(recognizedText);
          }
        },
        localeId: localeId,
        listenMode: stt.ListenMode.confirmation, // Get both partial and final results
        cancelOnError: false,
        partialResults: true, // Enable partial results for real-time feedback
        listenFor: const Duration(hours: 1), // Listen for extended period
        pauseFor: const Duration(seconds: 5), // Wait 5 seconds before considering speech done
      );
      
      _isListening = true;
      debugPrint('[SpeechToText] ✅ Listening started');
      return true;
    } catch (e) {
      debugPrint('[SpeechToText] ❌ Error starting to listen: $e');
      return false;
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) {
      debugPrint('[SpeechToText] ⚠️ Not currently listening');
      return;
    }
    
    try {
      debugPrint('[SpeechToText] 🛑 Stopping listening...');
      await _speech.stop();
      _isListening = false;
      debugPrint('[SpeechToText] ✅ Listening stopped');
    } catch (e) {
      debugPrint('[SpeechToText] ❌ Error stopping listening: $e');
    }
  }
  
  /// Cancel listening (without waiting for final result)
  Future<void> cancelListening() async {
    if (!_isListening) {
      debugPrint('[SpeechToText] ⚠️ Not currently listening');
      return;
    }
    
    try {
      debugPrint('[SpeechToText] ❌ Canceling listening...');
      await _speech.cancel();
      _isListening = false;
      debugPrint('[SpeechToText] ✅ Listening canceled');
    } catch (e) {
      debugPrint('[SpeechToText] ❌ Error canceling listening: $e');
    }
  }
  
  /// Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _speech.locales();
  }
  
  /// Dispose resources
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    debugPrint('[SpeechToText] 🗑️ Service disposed');
  }
}
