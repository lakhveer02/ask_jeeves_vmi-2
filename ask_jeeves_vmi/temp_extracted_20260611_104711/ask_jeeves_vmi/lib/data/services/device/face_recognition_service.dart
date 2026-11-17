import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:ask_jeeves_vmi/data/services/storage/secure_storage_service.dart';
import 'dart:convert';

/// Service for face recognition and enrollment
class FaceRecognitionService {
  final SecureStorageService _storage;
  late FaceDetector _faceDetector;
  
  FaceRecognitionService(this._storage) {
    _initializeFaceDetector();
  }

  void _initializeFaceDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  /// Check if face is enrolled
  Future<bool> isFaceEnrolled() async {
    final faceData = await _storage.read('face_enrollment_data');
    return faceData != null;
  }

  /// Detect faces in an image
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      debugPrint('[FaceRecognition] Detected ${faces.length} face(s)');
      return faces;
    } catch (e) {
      debugPrint('[FaceRecognition] Face detection error: $e');
      return [];
    }
  }

  /// Extract face features for enrollment
  Future<Map<String, dynamic>?> extractFaceFeatures(Face face) async {
    try {
      // Extract key facial landmarks and measurements
      final features = <String, dynamic>{};

      // Bounding box
      features['boundingBox'] = {
        'left': face.boundingBox.left,
        'top': face.boundingBox.top,
        'width': face.boundingBox.width,
        'height': face.boundingBox.height,
      };

      // Head pose
      features['headEulerAngleX'] = face.headEulerAngleX;
      features['headEulerAngleY'] = face.headEulerAngleY;
      features['headEulerAngleZ'] = face.headEulerAngleZ;

      // Facial landmarks
      if (face.landmarks.isNotEmpty) {
        final landmarks = <String, dynamic>{};
        
        for (final landmark in face.landmarks.entries) {
          final type = landmark.key;
          final position = landmark.value?.position;
          if (position != null) {
            landmarks[type.toString()] = {
              'x': position.x,
              'y': position.y,
            };
          }
        }
        features['landmarks'] = landmarks;
      }

      // Face contours
      if (face.contours.isNotEmpty) {
        final contours = <String, dynamic>{};
        
        for (final contour in face.contours.entries) {
          final type = contour.key;
          final points = contour.value?.points;
          if (points != null && points.isNotEmpty) {
            contours[type.toString()] = points.map((p) => {
              'x': p.x,
              'y': p.y,
            }).toList();
          }
        }
        features['contours'] = contours;
      }

      // Classification (smiling, eyes open)
      if (face.smilingProbability != null) {
        features['smilingProbability'] = face.smilingProbability;
      }
      if (face.leftEyeOpenProbability != null) {
        features['leftEyeOpenProbability'] = face.leftEyeOpenProbability;
      }
      if (face.rightEyeOpenProbability != null) {
        features['rightEyeOpenProbability'] = face.rightEyeOpenProbability;
      }

      // Tracking ID
      if (face.trackingId != null) {
        features['trackingId'] = face.trackingId;
      }

      debugPrint('[FaceRecognition] Extracted features: ${features.keys.length} properties');
      return features;
    } catch (e) {
      debugPrint('[FaceRecognition] Feature extraction error: $e');
      return null;
    }
  }

  /// Enroll a face for authentication
  Future<bool> enrollFace(Face face, Uint8List imageBytes) async {
    try {
      debugPrint('[FaceRecognition] Starting face enrollment...');

      // Extract facial features
      final features = await extractFaceFeatures(face);
      if (features == null) {
        debugPrint('[FaceRecognition] Failed to extract features');
        return false;
      }

      // Store face data
      final enrollmentData = {
        'features': features,
        'enrolledAt': DateTime.now().toIso8601String(),
        'imageHash': _hashImage(imageBytes),
      };

      await _storage.write('face_enrollment_data', jsonEncode(enrollmentData));
      await _storage.write('face_enrolled', 'true');

      debugPrint('[FaceRecognition] Face enrolled successfully');
      return true;
    } catch (e) {
      debugPrint('[FaceRecognition] Enrollment error: $e');
      return false;
    }
  }

  /// Verify a face against enrolled data
  Future<FaceMatchResult> verifyFace(Face face) async {
    try {
      debugPrint('[FaceRecognition] Starting face verification...');

      // Get enrolled face data
      final enrolledDataStr = await _storage.read('face_enrollment_data');
      if (enrolledDataStr == null) {
        return FaceMatchResult(
          isMatch: false,
          confidence: 0.0,
          message: 'No enrolled face found',
        );
      }

      final enrolledData = jsonDecode(enrolledDataStr);
      final enrolledFeatures = enrolledData['features'] as Map<String, dynamic>;

      // Extract features from current face
      final currentFeatures = await extractFaceFeatures(face);
      if (currentFeatures == null) {
        return FaceMatchResult(
          isMatch: false,
          confidence: 0.0,
          message: 'Failed to extract face features',
        );
      }

      // Calculate similarity score
      final similarity = _calculateSimilarity(enrolledFeatures, currentFeatures);
      
      debugPrint('[FaceRecognition] Similarity score: ${(similarity * 100).toStringAsFixed(1)}%');

      // Threshold for face match (70% similarity)
      const threshold = 0.70;
      final isMatch = similarity >= threshold;

      return FaceMatchResult(
        isMatch: isMatch,
        confidence: similarity,
        message: isMatch 
            ? 'Face matched successfully' 
            : 'Face does not match enrolled face',
      );
    } catch (e) {
      debugPrint('[FaceRecognition] Verification error: $e');
      return FaceMatchResult(
        isMatch: false,
        confidence: 0.0,
        message: 'Verification error: $e',
      );
    }
  }

  /// Calculate similarity between two sets of facial features
  double _calculateSimilarity(
    Map<String, dynamic> features1,
    Map<String, dynamic> features2,
  ) {
    double totalScore = 0.0;
    int comparisons = 0;

    // Compare head pose angles (weight: 0.2)
    if (features1['headEulerAngleX'] != null && features2['headEulerAngleX'] != null) {
      final angleDiff = (features1['headEulerAngleX'] - features2['headEulerAngleX']).abs();
      totalScore += (1.0 - (angleDiff / 180.0).clamp(0.0, 1.0)) * 0.2;
      comparisons++;
    }

    // Compare landmarks (weight: 0.5)
    if (features1['landmarks'] != null && features2['landmarks'] != null) {
      final landmarks1 = features1['landmarks'] as Map<String, dynamic>;
      final landmarks2 = features2['landmarks'] as Map<String, dynamic>;
      
      double landmarkScore = 0.0;
      int landmarkCount = 0;

      for (final key in landmarks1.keys) {
        if (landmarks2.containsKey(key)) {
          final point1 = landmarks1[key] as Map<String, dynamic>;
          final point2 = landmarks2[key] as Map<String, dynamic>;
          
          final distance = _euclideanDistance(
            point1['x'] as double,
            point1['y'] as double,
            point2['x'] as double,
            point2['y'] as double,
          );
          
          // Normalize distance (assuming max distance of 500 pixels)
          final normalizedDistance = (distance / 500.0).clamp(0.0, 1.0);
          landmarkScore += (1.0 - normalizedDistance);
          landmarkCount++;
        }
      }

      if (landmarkCount > 0) {
        totalScore += (landmarkScore / landmarkCount) * 0.5;
        comparisons++;
      }
    }

    // Compare bounding box dimensions (weight: 0.3)
    if (features1['boundingBox'] != null && features2['boundingBox'] != null) {
      final box1 = features1['boundingBox'] as Map<String, dynamic>;
      final box2 = features2['boundingBox'] as Map<String, dynamic>;
      
      final widthDiff = ((box1['width'] - box2['width']).abs() / box1['width']).clamp(0.0, 1.0);
      final heightDiff = ((box1['height'] - box2['height']).abs() / box1['height']).clamp(0.0, 1.0);
      
      final boxScore = 1.0 - ((widthDiff + heightDiff) / 2.0);
      totalScore += boxScore * 0.3;
      comparisons++;
    }

    return comparisons > 0 ? totalScore / comparisons : 0.0;
  }

  /// Calculate Euclidean distance between two points
  double _euclideanDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return (dx * dx + dy * dy);
  }

  /// Hash image bytes for verification
  String _hashImage(Uint8List bytes) {
    // Simple hash for demo - in production, use proper cryptographic hash
    return bytes.length.toString() + bytes.first.toString() + bytes.last.toString();
  }

  /// Clear enrolled face data
  Future<void> clearEnrollment() async {
    await _storage.delete('face_enrollment_data');
    await _storage.delete('face_enrolled');
    debugPrint('[FaceRecognition] Enrollment cleared');
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
  }
}

/// Result of face matching
class FaceMatchResult {
  final bool isMatch;
  final double confidence;
  final String message;

  FaceMatchResult({
    required this.isMatch,
    required this.confidence,
    required this.message,
  });

  @override
  String toString() {
    return 'FaceMatchResult(isMatch: $isMatch, confidence: ${(confidence * 100).toStringAsFixed(1)}%, message: $message)';
  }
}

/// Provider for face recognition service
final faceRecognitionServiceProvider = Provider<FaceRecognitionService>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return FaceRecognitionService(storage);
});
