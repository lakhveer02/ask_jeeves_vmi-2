import 'package:flutter/material.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/native_input_overlay_service.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/workspace_file_upload_service.dart';
import 'package:ask_jeeves_vmi/data/services/webrtc/webrtc_control_service.dart';
import 'package:ask_jeeves_vmi/data/services/speech/speech_to_text_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Modal overlay for text input - appears as a bottom sheet
class InputModalOverlay extends StatefulWidget {
  final NativeInputOverlayService? inputOverlayService;
  final WorkspaceFileUploadService? fileUploadService;
  final WebRTCControlService controlService;
  final VoidCallback onClose;
  final Function(bool) onTypingChanged;

  const InputModalOverlay({
    super.key,
    required this.inputOverlayService,
    required this.fileUploadService,
    required this.controlService,
    required this.onClose,
    required this.onTypingChanged,
  });

  @override
  State<InputModalOverlay> createState() => _InputModalOverlayState();
}

class _InputModalOverlayState extends State<InputModalOverlay> with WidgetsBindingObserver {
  bool _isRecording = false;
  bool _isExpanded = false; // Track if input field is expanded
  
  // Speech to text
  final _speechService = SpeechToTextService();
  String _accumulatedText = ''; // Store all accumulated text
  String _lastRecognizedText = ''; // Track last partial result
  
  // Attached file data
  String? _attachedFileName;
  String? _attachedFileType;
  int? _attachedFileSize;
  String? _attachedFileBase64;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }
  
  /// Initialize speech recognition
  Future<void> _initializeSpeech() async {
    final initialized = await _speechService.initialize();
    if (initialized) {
      debugPrint('[InputModal] ✅ Speech recognition initialized');
    } else {
      debugPrint('[InputModal] ⚠️ Speech recognition initialization failed');
    }
  }
  
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _speechService.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Clear input when app is paused (closed/backgrounded) or detached
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _clearInput();
      debugPrint('[InputModal] 🧹 App paused/closed - input cleared');
    }
    
    // Also clear when app is resumed (reopened) for a fresh start
    if (state == AppLifecycleState.resumed) {
      _clearInput();
      debugPrint('[InputModal] 🧹 App resumed - input cleared');
    }
  }
  
  /// Clear all input field text and attachments
  void _clearInput() {
    if (mounted) {
      widget.inputOverlayService?.textController.clear();
      setState(() {
        _attachedFileName = null;
        _attachedFileType = null;
        _attachedFileSize = null;
        _attachedFileBase64 = null;
        _isExpanded = false;
        _accumulatedText = '';
        _lastRecognizedText = '';
      });
      widget.onTypingChanged(false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set context for file upload service to show permission dialogs
    widget.fileUploadService?.setContext(context);
  }


  void _handleSend() async {
    // Stop speech recognition if recording
    if (_isRecording) {
      await _stopListening();
    }
    
    final hasText = widget.inputOverlayService?.textController.text.isNotEmpty ?? false;
    final hasFile = _attachedFileBase64 != null;
    
    if (!hasText && !hasFile) {
      debugPrint('[InputModal] ⚠️ Nothing to send');
      return;
    }
    
    final text = widget.inputOverlayService?.textController.text ?? '';
    
    // Send file with text
    if (hasFile) {
      debugPrint('[InputModal] 📤 Sending file with text');
      debugPrint('[InputModal]   File: $_attachedFileName');
      debugPrint('[InputModal]   Text: ${text.isNotEmpty ? text : "(none)"}');
      
      widget.controlService.sendFileWithText(
        fileName: _attachedFileName!,
        fileType: _attachedFileType!,
        fileSize: _attachedFileSize!,
        base64Data: _attachedFileBase64!,
        text: text.isNotEmpty ? text : null,
      );
      
      // Clear file attachment
      setState(() {
        _attachedFileName = null;
        _attachedFileType = null;
        _attachedFileSize = null;
        _attachedFileBase64 = null;
      });
    } else {
      // Send text only
      debugPrint('[InputModal] 📤 Sending text: $text');
      widget.controlService.sendSubmitText(text);
    }
    
    // Clear text
    widget.inputOverlayService!.textController.clear();
    widget.onTypingChanged(false);
    
    // Close keyboard after sending
    widget.inputOverlayService!.focusNode.unfocus();
    debugPrint('[InputModal] ⌨️ Keyboard closed after sending');
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Stop recording/listening
      await _stopListening();
    } else {
      // Start recording/listening
      await _startListening();
    }
  }
  
  /// Start speech-to-text listening
  Future<void> _startListening() async {
    try {
      debugPrint('[InputModal] 🎤 Starting speech recognition...');
      
      // Get existing text from input field to continue from where user left off
      _accumulatedText = widget.inputOverlayService?.textController.text ?? '';
      _lastRecognizedText = '';
      if (_accumulatedText.isNotEmpty && !_accumulatedText.endsWith(' ')) {
        _accumulatedText += ' '; // Add space before new speech
      }
      
      final success = await _speechService.startListening(
        onResult: (text) {
          // Update the input field with accumulated + new text in real-time
          // IGNORE EMPTY TEXT - don't clear when pausing!
          if (mounted && _isRecording && text.isNotEmpty) {
            // DETECT NEW SEGMENT: If text suddenly becomes much shorter, previous segment ended
            if (_lastRecognizedText.length > 10 && text.length < (_lastRecognizedText.length ~/ 2)) {
              // New segment detected! Accumulate the previous one
              debugPrint('[InputModal] 🔄 New segment detected, accumulating: "$_lastRecognizedText"');
              _accumulatedText += _lastRecognizedText;
              if (!_accumulatedText.endsWith(' ')) {
                _accumulatedText += ' ';
              }
              debugPrint('[InputModal] 📝 Accumulated so far: "$_accumulatedText"');
            }
            
            // Show accumulated + current text
            final combinedText = _accumulatedText + text;
            widget.inputOverlayService?.textController.text = combinedText;
            widget.onTypingChanged(combinedText.isNotEmpty);
            
            setState(() {
              _lastRecognizedText = text;
            });
          }
        },
        onFinal: (text) {
          // Final result - add to accumulated text and prepare for next segment
          debugPrint('[InputModal] ✅ Final result: "$text"');
          if (mounted && _isRecording && text.trim().isNotEmpty) {
            _accumulatedText += text;
            if (!_accumulatedText.endsWith(' ')) {
              _accumulatedText += ' '; // Add space after finalized segment
            }
            debugPrint('[InputModal] 📝 Accumulated text: "$_accumulatedText"');
            
            // Update input field with accumulated text
            widget.inputOverlayService?.textController.text = _accumulatedText;
            widget.onTypingChanged(_accumulatedText.isNotEmpty);
            _lastRecognizedText = '';
          }
        },
        continuous: true, // Enable continuous listening
      );
      
      if (success) {
        setState(() {
          _isRecording = true;
        });
        debugPrint('[InputModal] ✅ Speech recognition started (continuous mode)');
        debugPrint('[InputModal] 📝 Starting with existing text: "$_accumulatedText"');
        
        // Monitor speech recognition status
        _monitorSpeechStatus();
      } else {
        debugPrint('[InputModal] ❌ Failed to start speech recognition');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to start speech recognition. Please check microphone permissions.'),
              backgroundColor: AppTheme.warningRed,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[InputModal] ❌ Error starting speech recognition: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start speech recognition: $e'),
            backgroundColor: AppTheme.warningRed,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }
  }
  
  /// Monitor speech recognition status and restart if needed
  void _monitorSpeechStatus() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if speech service is still listening
      if (_isRecording && !_speechService.isListening) {
        debugPrint('[InputModal] ⚠️ Speech recognition stopped unexpectedly, restarting...');
        debugPrint('[InputModal] 📝 Preserving accumulated text: "$_accumulatedText"');
        
        // Restart listening with accumulated text preserved
        await _speechService.startListening(
          onResult: (text) {
            // IGNORE EMPTY TEXT - don't clear when pausing!
            if (mounted && _isRecording && text.isNotEmpty) {
              final combinedText = _accumulatedText + text;
              widget.inputOverlayService?.textController.text = combinedText;
              widget.onTypingChanged(combinedText.isNotEmpty);
              setState(() {
              });
            }
          },
          onFinal: (text) {
            debugPrint('[InputModal] ✅ Final result: "$text"');
            if (mounted && _isRecording && text.trim().isNotEmpty) {
              _accumulatedText += text;
              if (!_accumulatedText.endsWith(' ')) {
                _accumulatedText += ' ';
              }
              widget.inputOverlayService?.textController.text = _accumulatedText;
              widget.onTypingChanged(_accumulatedText.isNotEmpty);
            }
          },
          continuous: true,
        );
      }
      
      return _isRecording;
    });
  }
  
  /// Stop speech-to-text listening
  Future<void> _stopListening() async {
    try {
      debugPrint('[InputModal] 🛑 Stopping speech recognition...');
      
      await _speechService.stopListening();
      
      setState(() {
        _isRecording = false;
      });
      
      debugPrint('[InputModal] ✅ Speech recognition stopped');
      debugPrint('[InputModal] Final accumulated text: "$_accumulatedText"');
      
      // Reset accumulated text for next recording session
      _accumulatedText = '';
    } catch (e) {
      debugPrint('[InputModal] ❌ Error stopping speech recognition: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Handle file attachment (without immediate upload)
  Future<void> _handleFileAttachment() async {
    try {
      debugPrint('[InputModal] 📎 Opening file picker...');
      
      final result = await widget.fileUploadService?.pickAndPrepareFile();
      
      if (result != null) {
        setState(() {
          _attachedFileName = result['fileName'];
          _attachedFileType = result['fileType'];
          _attachedFileSize = result['fileSize'];
          _attachedFileBase64 = result['base64Data'];
        });
        
        debugPrint('[InputModal] ✅ File attached: $_attachedFileName');
        debugPrint('[InputModal]   Size: ${(_attachedFileSize! / 1024 / 1024).toStringAsFixed(2)} MB');
      }
    } catch (e) {
      debugPrint('[InputModal] ❌ Error attaching file: $e');
    }
  }
  
  /// Remove attached file
  void _removeAttachment() {
    setState(() {
      _attachedFileName = null;
      _attachedFileType = null;
      _attachedFileSize = null;
      _attachedFileBase64 = null;
    });
    debugPrint('[InputModal] 🗑️ File attachment removed');
  }
  
  /// Toggle expanded view
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    debugPrint('[InputModal] ${_isExpanded ? '📖 Expanded' : '📕 Collapsed'} input field');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final hasAttachment = _attachedFileName != null;
    final hasText = widget.inputOverlayService?.textController.text.isNotEmpty ?? false;
    final canSend = hasText || hasAttachment;
    
    // Show expand button when text is long (more than 100 characters or has multiple lines)
    final textLength = widget.inputOverlayService?.textController.text.length ?? 0;
    final hasNewlines = widget.inputOverlayService?.textController.text.contains('\n') ?? false;
    final shouldShowExpandButton = textLength > 100 || hasNewlines;

    // If expanded, show full-screen modal
    if (_isExpanded) {
      return Positioned.fill(
        child: Container(
          color: AppTheme.deepBlack.withOpacity(0.98),
          child: Column(
            children: [
              // Add top spacing in expanded mode
              const SizedBox(height: 60),
              
              // Expanded text area at the top
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: widget.inputOverlayService?.textController,
                    focusNode: widget.inputOverlayService?.focusNode,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    autofocus: true,
                    style: const TextStyle(
                      color: AppTheme.ghostWhite,
                      fontSize: 16,
                      fontFamily: 'SpaceGrotesk',
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: hasAttachment
                          ? 'Add a caption...'
                          : 'Type your message here...',
                      hintStyle: TextStyle(
                        color: AppTheme.ghostWhite.withOpacity(0.4),
                        fontSize: 16,
                        fontFamily: 'SpaceGrotesk',
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (text) {
                      setState(() {});
                      widget.onTypingChanged(text.isNotEmpty);
                    },
                  ),
                ),
              ),
              
              // Bottom bar with file attachment and action buttons
              // Positioned above keyboard using Positioned + bottom
              Padding(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.deepBlack.withOpacity(0.98),
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.electricCyan.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Collapse button (left)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleExpanded,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.close_fullscreen_rounded,
                                color: AppTheme.ghostWhite.withOpacity(0.7),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // File attachment indicator (if exists)
                        if (hasAttachment)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.electricCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _attachedFileType?.startsWith('image/') == true
                                      ? Icons.image_rounded
                                      : _attachedFileType?.startsWith('video/') == true
                                          ? Icons.videocam_rounded
                                          : Icons.insert_drive_file_rounded,
                                  color: AppTheme.electricCyan,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _attachedFileName!.length > 20 
                                      ? '${_attachedFileName!.substring(0, 20)}...'
                                      : _attachedFileName!,
                                  style: const TextStyle(
                                    color: AppTheme.ghostWhite,
                                    fontSize: 12,
                                    fontFamily: 'SpaceGrotesk',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _removeAttachment,
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: AppTheme.ghostWhite.withOpacity(0.6),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Send button (bottom-right)
                        Container(
                          decoration: BoxDecoration(
                            color: canSend 
                                ? AppTheme.electricCyan 
                                : AppTheme.darkMatterViolet.withOpacity(0.4),
                            shape: BoxShape.circle,
                            boxShadow: canSend
                                ? [
                                    BoxShadow(
                                      color: AppTheme.electricCyan.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: canSend ? _handleSend : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: canSend 
                                      ? AppTheme.deepBlack 
                                      : AppTheme.ghostWhite.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal compact mode
    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.deepBlack.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: _isRecording 
                  ? AppTheme.warningRed.withOpacity(0.3)
                  : AppTheme.electricCyan.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File attachment preview (if file is attached)
              if (hasAttachment)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkMatterViolet.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.electricCyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // File icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.electricCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _attachedFileType?.startsWith('image/') == true
                              ? Icons.image_rounded
                              : _attachedFileType?.startsWith('video/') == true
                                  ? Icons.videocam_rounded
                                  : Icons.insert_drive_file_rounded,
                          color: AppTheme.electricCyan,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // File info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _attachedFileName!,
                              style: const TextStyle(
                                color: AppTheme.ghostWhite,
                                fontSize: 13,
                                fontFamily: 'SpaceGrotesk',
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(_attachedFileSize! / 1024 / 1024).toStringAsFixed(2)} MB',
                              style: TextStyle(
                                color: AppTheme.ghostWhite.withOpacity(0.5),
                                fontSize: 11,
                                fontFamily: 'SpaceGrotesk',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Remove button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _removeAttachment,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              color: AppTheme.ghostWhite.withOpacity(0.6),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
            
              
              // Main input container - ChatGPT style
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left action button - Attach file (hide when recording)
                    if (!_isRecording)
                      Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.darkMatterViolet.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.electricCyan.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleFileAttachment,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Icon(
                                hasAttachment ? Icons.image_rounded : Icons.add_rounded,
                                color: hasAttachment 
                                    ? AppTheme.electricCyan
                                    : AppTheme.ghostWhite.withOpacity(0.7),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Center input field - ChatGPT style rounded container
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 48,
                          maxHeight: 120,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkMatterViolet.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isRecording
                                ? AppTheme.electricCyan.withOpacity(0.5)
                                : hasAttachment
                                    ? AppTheme.electricCyan.withOpacity(0.4)
                                    : AppTheme.electricCyan.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Input field
                                Expanded(
                                  child: TextField(
                                    controller: widget.inputOverlayService?.textController,
                                    focusNode: widget.inputOverlayService?.focusNode,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    maxLines: null,
                                    minLines: 1,
                                    enabled: !_isRecording,
                                    style: const TextStyle(
                                      color: AppTheme.ghostWhite,
                                      fontSize: 15,
                                      fontFamily: 'SpaceGrotesk',
                                      height: 1.4,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: _isRecording
                                          ? 'Listening... speak now'
                                          : hasAttachment
                                              ? 'Add a caption...'
                                              : 'Message',
                                      hintStyle: TextStyle(
                                        color: _isRecording
                                            ? AppTheme.electricCyan.withOpacity(0.7)
                                            : AppTheme.ghostWhite.withOpacity(0.4),
                                        fontSize: 15,
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.fromLTRB(16, 13, 8, 13),
                                    ),
                                    onChanged: (text) {
                                      setState(() {});
                                      widget.onTypingChanged(text.isNotEmpty);
                                    },
                                    onSubmitted: canSend ? (_) => _handleSend() : null,
                                  ),
                                ),
                                
                                // Microphone button (inside input field)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleRecording,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                                        color: _isRecording 
                                            ? AppTheme.warningRed 
                                            : AppTheme.ghostWhite.withOpacity(0.6),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Expand button - positioned at top-right corner (like ChatGPT)
                            // Only show when text is long
                            if (!_isRecording && shouldShowExpandButton)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _toggleExpanded,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.deepBlack.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.electricCyan.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.open_in_full_rounded,
                                        color: AppTheme.ghostWhite.withOpacity(0.8),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                          ),
                        ),
                        
                        // Right send button - ChatGPT style
                        Container(
                          margin: const EdgeInsets.only(left: 8, bottom: 4),
                          decoration: BoxDecoration(
                            color: canSend 
                                ? AppTheme.electricCyan 
                                : AppTheme.darkMatterViolet.withOpacity(0.4),
                            shape: BoxShape.circle,
                            boxShadow: canSend
                                ? [
                                    BoxShadow(
                                      color: AppTheme.electricCyan.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: canSend ? _handleSend : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.arrow_upward_rounded,
                                  color: canSend 
                                      ? AppTheme.deepBlack 
                                      : AppTheme.ghostWhite.withOpacity(0.3),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        
              ),
      
          ),
    
        );
    
  }
}
