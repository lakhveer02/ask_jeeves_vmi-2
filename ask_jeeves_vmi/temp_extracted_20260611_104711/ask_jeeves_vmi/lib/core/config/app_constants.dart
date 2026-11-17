/// Application-wide constants for Ask-Jeeves Vault
class AppConstants {
  // App Info
  static const String appName = 'VMI Demo';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Zero-Trust Secure AI Workspace';
  
  // Security Constants
  static const int sessionTimeoutMinutes = 15;
  static const int maxLoginAttempts = 3;
  static const int tokenRotationMinutes = 5;
  static const int biometricTimeoutSeconds = 30;
  
  // Geofencing
  static const double defaultGeofenceRadiusMeters = 500.0;
  static const int locationUpdateIntervalSeconds = 30;
  
  // Streaming
  static const int defaultBitrate = 2500000; // 2.5 Mbps
  static const int maxBitrate = 5000000; // 5 Mbps
  static const int minBitrate = 500000; // 500 Kbps
  static const int targetFrameRate = 60;
  
  // WebSocket
  static const int websocketReconnectDelaySeconds = 5;
  static const int websocketPingIntervalSeconds = 30;
  static const int websocketTimeoutSeconds = 60;
  
  // AI Configuration
  static const int maxAIContextTokens = 8000;
  static const int streamingChunkSize = 256;
  static const double aiTemperature = 0.7;
  
  // Watermark
  static const double watermarkOpacity = 0.15;
  static const int watermarkRotationDegrees = -45;
  static const int watermarkUpdateIntervalSeconds = 10;
  
  // Cache & Storage
  static const int maxCacheSizeMB = 50;
  static const int sessionDataRetentionHours = 0; // Ephemeral - no retention
  
  // API Endpoints (Configure based on your backend)
  static const String baseApiUrl = 'https://api.askjeevesvault.com';
  static const String websocketUrl = 'wss://stream.askjeevesvault.com';
  static const String authEndpoint = '/api/v1/auth';
  static const String vaultEndpoint = '/api/v1/vault';
  static const String streamEndpoint = '/api/v1/stream';
  
  // Feature Flags
  static const bool enableBiometrics = true;
  static const bool enableGeofencing = true;
  static const bool enableVoiceAI = true;
  static const bool enableScreenshotDetection = true;
  static const bool enableRootDetection = true;
  static const bool enableDynamicWatermark = true;
  
  // UI Constants
  static const double maxContentWidth = 1200.0;
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  // Animation Constants
  static const int particleCount = 100;
  static const double glowIntensity = 0.8;
  static const double blurSigma = 10.0;
  
  // Compliance
  static const List<String> supportedRegions = ['US', 'EU', 'UK', 'CA'];
  static const bool gdprCompliant = true;
  static const bool hipaaCompliant = true;
  static const bool soc2Compliant = true;
}
