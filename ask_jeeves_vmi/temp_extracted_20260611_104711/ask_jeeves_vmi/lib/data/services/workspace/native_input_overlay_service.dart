import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/workspace_socket_service.dart';

/// Service for managing native input overlay
/// Provides native keyboard experience while maintaining remote UI
class NativeInputOverlayService {
  // Current input state
  bool _isInputActive = false;
  String _currentText = '';
  String? _currentElementId;
  String? _currentElementType;
  TextInputType _currentInputType = TextInputType.text;
  
  // Text editing controller
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  
  // Callbacks
  VoidCallback? onKeyboardOpen;
  VoidCallback? onKeyboardClose;
  Function(String)? onTextChanged;
  
  // Debounce timer for text sync
  Timer? _syncTimer;
  static const Duration _syncDelay = Duration(milliseconds: 300);

  NativeInputOverlayService(WorkspaceSocketService socketService) {
    _setupListeners();
  }

  /// Setup text controller listeners
  void _setupListeners() {
    textController.addListener(_onTextChanged);
    focusNode.addListener(_onFocusChanged);
  }

  /// Handle text changes
  void _onTextChanged() {
    final newText = textController.text;
    
    if (newText == _currentText) return;
    
    _currentText = newText;
    onTextChanged?.call(newText);
    
    // Debounce socket sync to avoid flooding
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDelay, () {
      _syncTextToRemote(newText);
    });
  }

  /// Handle focus changes
  void _onFocusChanged() {
    debugPrint('[NativeInput] 🔧 Focus changed - hasFocus: ${focusNode.hasFocus}, isInputActive: $_isInputActive');
    
    if (focusNode.hasFocus && !_isInputActive) {
      debugPrint('[NativeInput] 📍 Focus gained - activating input');
      _isInputActive = true;
      onKeyboardOpen?.call();
    } else if (!focusNode.hasFocus && _isInputActive) {
      debugPrint('[NativeInput] 📍 Focus lost - deactivating input');
      _isInputActive = false;
      onKeyboardClose?.call();
      
      // WorkspaceSocket disabled - blur not available
      // IMPORTANT: Don't send blur immediately - it might cancel keyboard opening
      // Only send blur after a delay to ensure keyboard had time to open
      // Future.delayed(const Duration(milliseconds: 500), () {
      //   if (!focusNode.hasFocus) {
      //     _socketService.requestBlur();
      //   }
      // });
    }
  }

  /// Sync text to remote browser
  void _syncTextToRemote(String text) {
    debugPrint('[NativeInput] 📤 Syncing text to remote: ${text.length} chars');
    
    // WorkspaceSocket disabled - text sync not available
    // _socketService.sendTyping(
    //   text: text,
    //   elementId: _currentElementId,
    //   elementType: _currentElementType,
    // );
  }

  /// Activate input for a remote element
  void activateInput({
    required String elementId,
    required String elementType,
    String? initialText,
    TextInputType? inputType,
  }) {
    debugPrint('[NativeInput] ✅ Activating input for: $elementId ($elementType)');
    
    _currentElementId = elementId;
    _currentElementType = elementType;
    _currentInputType = inputType ?? _getInputTypeForElement(elementType);
    
    // Set initial text if provided
    if (initialText != null && initialText != _currentText) {
      textController.text = initialText;
      _currentText = initialText;
    }
    
    // Request focus to open keyboard
    focusNode.requestFocus();
    _isInputActive = true;
    onKeyboardOpen?.call();
  }

  /// Deactivate input
  void deactivateInput({bool silent = false}) {
    debugPrint('[NativeInput] ❌ Deactivating input (silent: $silent)');
    
    _currentElementId = null;
    _currentElementType = null;
    
    // Only trigger callbacks if input was actually active
    final wasActive = _isInputActive;
    _isInputActive = false;
    
    // Unfocus to close keyboard
    focusNode.unfocus();
    
    // Only call callback if input was active and not silent mode
    if (wasActive && !silent) {
      onKeyboardClose?.call();
    }
    
    // WorkspaceSocket disabled - blur not available
    // Send blur to remote (only if socket is connected)
    // try {
    //   _socketService.requestBlur();
    // } catch (e) {
    //   debugPrint('[NativeInput] ⚠️ Error sending blur: $e');
    // }
  }

  /// Update text from remote (for synchronization)
  void updateTextFromRemote(String text) {
    if (text == _currentText) return;
    
    debugPrint('[NativeInput] 📥 Updating text from remote: ${text.length} chars');
    
    // Update without triggering listener
    _currentText = text;
    textController.removeListener(_onTextChanged);
    textController.text = text;
    textController.addListener(_onTextChanged);
  }

  /// Get appropriate input type for element
  TextInputType _getInputTypeForElement(String elementType) {
    switch (elementType.toLowerCase()) {
      case 'email':
        return TextInputType.emailAddress;
      case 'number':
        return TextInputType.number;
      case 'phone':
      case 'tel':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'textarea':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  /// Check if input is currently active
  bool get isInputActive => _isInputActive;

  /// Get current input type
  TextInputType get currentInputType => _currentInputType;

  /// Get current element info
  Map<String, String?> get currentElement => {
    'id': _currentElementId,
    'type': _currentElementType,
  };

  /// Clear current text
  void clearText() {
    textController.clear();
    _currentText = '';
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    textController.removeListener(_onTextChanged);
    focusNode.removeListener(_onFocusChanged);
    textController.dispose();
    focusNode.dispose();
  }
}

/// Provider for Native Input Overlay Service
final nativeInputOverlayServiceProvider = Provider<NativeInputOverlayService>((ref) {
  final socketService = ref.watch(workspaceSocketServiceProvider);
  final service = NativeInputOverlayService(socketService);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
