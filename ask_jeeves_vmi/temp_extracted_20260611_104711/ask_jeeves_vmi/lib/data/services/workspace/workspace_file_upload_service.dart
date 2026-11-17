import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ask_jeeves_vmi/data/services/workspace/workspace_socket_service.dart';
import 'package:ask_jeeves_vmi/shared/handlers/client_error_handler.dart';
import 'package:ask_jeeves_vmi/core/theme/app_theme.dart';

/// Service for handling native file uploads to workspace
/// Supports images, documents, audio, and video
class WorkspaceFileUploadService {
  final WorkspaceSocketService _socketService;
  final ImagePicker _imagePicker = ImagePicker();
  BuildContext? _context; // Store context for permission dialogs

  WorkspaceFileUploadService(this._socketService);

  /// Set context for showing permission dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Request and check permission with user-friendly dialog
  Future<bool> _requestPermission(Permission permission, String permissionName) async {
    var status = await permission.status;
    
    debugPrint('[FileUpload] 🔐 Permission status for $permissionName: $status');
    debugPrint('[FileUpload] 🔐 Context available: ${_context != null}');

    // Already granted
    if (status.isGranted) {
      debugPrint('[FileUpload] ✅ Permission already granted');
      return true;
    }

    // Permanently denied - show settings snackbar
    if (status.isPermanentlyDenied) {
      debugPrint('[FileUpload] ⚠️ Permission permanently denied, showing settings snackbar');
      
      if (_context == null || !_context!.mounted) {
        debugPrint('[FileUpload] ❌ No context available for settings snackbar');
        return false;
      }
      
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('$permissionName permission required. Enable it in Settings.'),
          backgroundColor: AppTheme.warningRed,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () async {
              debugPrint('[FileUpload] 📱 Opening app settings');
              await openAppSettings();
            },
          ),
        ),
      );
      return false;
    }

    // Not granted and not permanently denied - request permission
    debugPrint('[FileUpload] 📋 Showing permission request snackbar');
    
    if (_context == null || !_context!.mounted) {
      debugPrint('[FileUpload] ❌ No context available for permission snackbar');
      // Try direct request without our custom snackbar
      final directStatus = await permission.request();
      final granted = directStatus.isGranted;
      debugPrint('[FileUpload] Direct permission request result: $granted');
      return granted;
    }
    
    // Show snackbar with request
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text('$permissionName access required to upload files'),
        backgroundColor: AppTheme.warningRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );

    // Request the actual permission
    debugPrint('[FileUpload] 🔐 Requesting system permission');
    final requestStatus = await permission.request();
    final granted = requestStatus.isGranted;
    
    debugPrint('[FileUpload] System permission result: $granted ($requestStatus)');

    // Show feedback if permission was denied
    if (!granted && _context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Text('$permissionName permission needed to upload files'),
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

    return granted;
  }

  /// Pick image from gallery and prepare for upload (without uploading)
  Future<Map<String, dynamic>?> pickAndPrepareFile() async {
    try {
      debugPrint('[FileUpload] 📷 Opening file picker...');
      
      // Request permission with user-friendly dialog
      final granted = await _requestPermission(Permission.photos, 'Media');
      if (!granted) {
        debugPrint('[FileUpload] ❌ Media permission denied');
        return null;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[FileUpload] ❌ No image selected');
        return null;
      }

      // Prepare file data without uploading
      final file = File(image.path);
      final fileSize = await file.length();
      
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File too large. Maximum size is 10MB.');
      }

      final bytes = await file.readAsBytes();
      final base64Data = base64Encode(bytes);
      final fileType = _getFileType(image.name);
      
      debugPrint('[FileUpload] ✅ File prepared: ${image.name}');
      debugPrint('[FileUpload]   Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('[FileUpload]   Type: $fileType');
      
      return {
        'fileName': image.name,
        'fileType': fileType,
        'fileSize': fileSize,
        'base64Data': base64Data,
      };
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error preparing file: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
      return null;
    }
  }

  /// Pick image from gallery
  Future<void> pickImageFromGallery({String? elementId}) async {
    try {
      debugPrint('[FileUpload] 📷 Opening gallery...');
      
      // Request permission with user-friendly dialog
      final granted = await _requestPermission(Permission.photos, 'Media');
      if (!granted) {
        debugPrint('[FileUpload] ❌ Media permission denied');
        return; // Don't throw exception, just return
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('[FileUpload] ❌ No image selected');
        return;
      }

      await _uploadFile(
        filePath: image.path,
        fileName: image.name,
        elementId: elementId,
      );
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error picking image: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
    }
  }

  /// Take photo with camera
  Future<void> takePhoto({String? elementId}) async {
    try {
      debugPrint('[FileUpload] 📸 Opening camera...');
      
      // Request permission with user-friendly dialog
      final granted = await _requestPermission(Permission.camera, 'Camera');
      if (!granted) {
        debugPrint('[FileUpload] ❌ Camera permission denied');
        return; // Don't throw exception, just return
      }

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo == null) {
        debugPrint('[FileUpload] ❌ No photo taken');
        return;
      }

      await _uploadFile(
        filePath: photo.path,
        fileName: photo.name,
        elementId: elementId,
      );
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error taking photo: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
    }
  }

  /// Pick video from gallery
  Future<void> pickVideo({String? elementId}) async {
    try {
      debugPrint('[FileUpload] 🎥 Opening video picker...');
      
      // Request permission with user-friendly dialog
      final granted = await _requestPermission(Permission.photos, 'Media');
      if (!granted) {
        debugPrint('[FileUpload] ❌ Media permission denied');
        return; // Don't throw exception, just return
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) {
        debugPrint('[FileUpload] ❌ No video selected');
        return;
      }

      await _uploadFile(
        filePath: video.path,
        fileName: video.name,
        elementId: elementId,
      );
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error picking video: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
    }
  }

  /// Record video with camera
  Future<void> recordVideo({String? elementId}) async {
    try {
      debugPrint('[FileUpload] 🎥 Opening camera for video...');
      
      // Request permission with user-friendly dialog
      final granted = await _requestPermission(Permission.camera, 'Camera');
      if (!granted) {
        debugPrint('[FileUpload] ❌ Camera permission denied');
        return; // Don't throw exception, just return
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) {
        debugPrint('[FileUpload] ❌ No video recorded');
        return;
      }

      await _uploadFile(
        filePath: video.path,
        fileName: video.name,
        elementId: elementId,
      );
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error recording video: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
    }
  }

  /// Pick document file
  Future<void> pickDocument({String? elementId}) async {
    try {
      debugPrint('[FileUpload] 📄 Opening document picker...');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FileUpload] ❌ No document selected');
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        debugPrint('[FileUpload] ❌ File path is null');
        return;
      }

      await _uploadFile(
        filePath: file.path!,
        fileName: file.name,
        elementId: elementId,
      );
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error picking document: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
    }
  }

  /// Pick any file
  Future<void> pickAnyFile({String? elementId}) async {
    try {
      debugPrint('[FileUpload] 📁 Opening file picker...');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[FileUpload] ❌ No file selected');
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        debugPrint('[FileUpload] ❌ File path is null');
        return;
      }

      await _uploadFile(
        filePath: file.path!,
        fileName: file.name,
        elementId: elementId,
      );
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error picking file: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
    }
  }

  /// Upload file to workspace
  Future<void> _uploadFile({
    required String filePath,
    required String fileName,
    String? elementId,
  }) async {
    try {
      debugPrint('[FileUpload] 📤 Uploading file: $fileName');
      
      final file = File(filePath);
      
      // Check file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('File too large. Maximum size is 10MB.');
      }

      debugPrint('[FileUpload] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Read file as bytes
      final bytes = await file.readAsBytes();
      
      // Convert to base64
      final base64Data = base64Encode(bytes);
      
      // Get file type
      final fileType = _getFileType(fileName);
      
      debugPrint('[FileUpload] File type: $fileType');
      debugPrint('[FileUpload] Base64 length: ${base64Data.length}');

      // Send to workspace via socket
      await _socketService.sendFileUpload(
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        base64Data: base64Data,
        elementId: elementId,
      );

      debugPrint('[FileUpload] ✅ File uploaded successfully');
    } catch (e, stackTrace) {
      debugPrint('[FileUpload] ❌ Error uploading file: $e');
      debugPrint('[FileUpload] Stack trace: $stackTrace');
      
      // Show user-friendly error
      if (_context != null && _context!.mounted) {
        ClientErrorHandler.showAutoErrorSnackbar(_context!, error: e);
      }
      rethrow;
    }
  }

  /// Get file MIME type from extension
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      
      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'm4a':
        return 'audio/mp4';
      
      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      
      default:
        return 'application/octet-stream';
    }
  }

  /// Show file picker options dialog
  Future<void> showFilePickerOptions({
    required BuildContext context,
    String? elementId,
  }) async {
    // Set context immediately when this method is called
    setContext(context);
    
    // Store the root navigator context before showing bottom sheet
    final rootContext = context;
    
    await showModalBottomSheet(
      context: context,
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Media'),
              onTap: () {
                Navigator.pop(modalContext);
                // Use root context for permission dialogs
                setContext(rootContext);
                pickImageFromGallery(elementId: elementId);
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.camera_alt),
            //   title: const Text('Take Photo'),
            //   onTap: () {
            //     Navigator.pop(modalContext);
            //     setContext(rootContext);
            //     takePhoto(elementId: elementId);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.videocam),
            //   title: const Text('Record Video'),
            //   onTap: () {
            //     Navigator.pop(modalContext);
            //     setContext(rootContext);
            //     recordVideo(elementId: elementId);
            //   },
            // ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Video'),
              onTap: () {
                Navigator.pop(modalContext);
                // Use root context for permission dialogs
                setContext(rootContext);
                pickVideo(elementId: elementId);
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.insert_drive_file),
            //   title: const Text('Choose Document'),
            //   onTap: () {
            //     Navigator.pop(modalContext);
            //     setContext(rootContext);
            //     pickDocument(elementId: elementId);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.attach_file),
            //   title: const Text('Choose Any File'),
            //   onTap: () {
            //     Navigator.pop(modalContext);
            //     setContext(rootContext);
            //     pickAnyFile(elementId: elementId);
            //   },
            // ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Provider for Workspace File Upload Service
final workspaceFileUploadServiceProvider = Provider<WorkspaceFileUploadService>((ref) {
  final socketService = ref.watch(workspaceSocketServiceProvider);
  return WorkspaceFileUploadService(socketService);
});
