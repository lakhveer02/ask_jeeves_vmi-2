class ApiConstants {
  // Base URLs - Using ngrok for remote access
  // ⚠️ IMPORTANT: Update this with your actual ngrok URL
  // Both HTTP and WebSocket should use the SAME ngrok URL
  static String get baseUrl {
    return 'http://18.220.3.254:8000';
    // return 'https://fafa-2404-7c80-5e-c0c3-6f5f-8c56-227e-d669.ngrok-free.app';
  }
  
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';

  // WebSocket URLs - MUST use the same ngrok URL as baseUrl
  static String get wsBaseUrl {
    // Convert https:// to wss:// for WebSocket
    return '${baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://')}/';
  }

  
  // Device Auth Endpoints
  static const String deviceAuthAuthenticate = '/device-auth/authenticate'; // Unified register/login
  static const String deviceAuthInfo = '/device-auth/info';
  static const String deviceAuthSecurityRecommendations = '/device-auth/security-recommendations';

  // Vault Endpoints
  static const String sessionTerminate = '/sessions/device/';

  // Geofence Endpoints
  static const String geofenceCreate = '/geofences';
  static const String geofenceList = '/geofences/device'; // + /{device_id}
  static const String geofenceGet = '/geofences'; // + /{geofence_id}
  static const String geofenceUpdate = '/geofences'; // + /{geofence_id}
  static const String geofenceDelete = '/geofences'; // + /{geofence_id}
  static const String geofenceCheck = '/geofences/check'; // + /{device_id}

  // Health Check
  static const String health = '/health';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAuthorization = 'Authorization';
  static const String headerDeviceId = 'X-Device-ID';
  static const String headerAppVersion = 'X-App-Version';

  // Storage Keys
  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyDeviceId = 'device_id';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeySessionId = 'session_id';
}
