# Ask Jeeves VMI - Complete Application Documentation
**Version**: 1.0.0+1  
**Date**: June 3, 2026  
**Platform**: Flutter (iOS & Android)

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [App Architecture](#app-architecture)
3. [Security Features](#security-features)
4. [User Flow & Timeline](#user-flow--timeline)
5. [Package Dependencies](#package-dependencies)
6. [Core Services](#core-services)
7. [API Integration](#api-integration)
8. [State Management](#state-management)
9. [Screen Flow Diagram](#screen-flow-diagram)
10. [Technical Specifications](#technical-specifications)

---

## 🎯 Executive Summary

**Ask Jeeves VMI** is an enterprise-grade Virtual Mobile Infrastructure (VMI) AI platform that provides secure, 
remote access to workspace environments through WebRTC pixel streaming. The app implements zero-trust security 
principles with multi-layered authentication, biometric verification, location-based access control, and 
real-time security monitoring.

### Key Features
- 🔐 **Zero-Trust Security**: Multi-factor authentication with biometric verification
- 📍 **Geofence Protection**: Location-based access control with real-time monitoring
- 🎥 **WebRTC Streaming**: Pixel-perfect workspace streaming via WebRTC
- 🛡️ **Device Attestation**: Root/jailbreak detection and device integrity checks
- 🗣️ **Speech Recognition**: Voice input for AI interactions
- 🔄 **Session Management**: Auto-logout on inactivity, location violations, or security threats
- 📱 **Native Integration**: Platform channels for screenshot protection and lifecycle management
- 🌐 **Network Monitoring**: Real-time connectivity tracking with auto-reconnection

### Security Highlights
- ✅ AES-256 encryption for local storage
- ✅ SSL certificate pinning for API communication
- ✅ Biometric authentication (Face ID, Touch ID, Fingerprint)
- ✅ Face detection using Google ML Kit
- ✅ Screenshot and screen recording protection
- ✅ Continuous location validation
- ✅ Real-time threat detection
- ✅ Automatic session termination on security violations

---

### Architecture Pattern

**Clean Architecture with Riverpod State Management**

```
┌─────────────────────────────────────────────────────┐
│              Presentation Layer                      │
│  (Screens, Widgets, UI Components)                  │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│              Application Layer                       │
│  (Providers, State Management, Business Logic)      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│                Data Layer                            │
│  (Services, Repositories, API Clients)              │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│            External Services                         │
│  (Backend API, WebRTC, Native Platform)             │
└─────────────────────────────────────────────────────┘
```

### Technology Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | Flutter 3.38.9 |
| **Language** | Dart 3.10.8 |
| **State Management** | Riverpod 2.6.1 |
| **Navigation** | GoRouter 14.8.1 |
| **HTTP Client** | Dio 5.7.0 |
| **WebRTC** | flutter_webrtc 1.4.1 |
| **Real-time Communication** | Socket.IO Client 2.0.3 |
| **Security** | AES-256, RSA-2048, Device Attestation |
| **Storage** | flutter_secure_storage 9.2.4 |
| **Biometrics** | local_auth 2.3.0 |
| **Face Detection** | google_mlkit_face_detection 0.10.1 |
| **Location** | geolocator 13.0.4, geocoding 3.0.0 |
| **Permissions** | permission_handler 11.4.0 |

---

## 🔐 Security Features

### 1. **Multi-Layer Authentication**

#### Layer 1: Vault Initialization
- **Purpose**: One-time device setup
- **Process**:
  - Create unique device vault with secure passkey
  - Generate device UUID and cryptographic keys
  - Store encrypted credentials in secure storage
  - **Storage**: AES-256 encryption via flutter_secure_storage
  - **Keys Stored**: device_uuid, device_name, vault_passkey, device_public_key, device_private_key

#### Layer 2: Biometric Verification
- **Purpose**: Quick, secure device unlock
- **Supported Methods**:
  - iOS: Face ID, Touch ID
  - Android: Fingerprint, Face Unlock, Iris Scanner
- **Implementation**: local_auth package with platform-specific biometric APIs
- **Security**: Biometric data never leaves device; only authentication result is used
- **Fallback**: Vault passkey if biometrics fail

#### Layer 3: Face Recognition (Optional Enhancement)
- **Purpose**: Additional identity verification layer
- **Technology**: Google ML Kit Face Detection
- **Process**:
  - Capture live face image during registration
  - Extract face features and landmarks
  - Compare against stored face template during login
- **Anti-Spoofing**: Liveness detection to prevent photo attacks
- **Privacy**: Face data encrypted and stored locally only

#### Layer 4: Device Attestation
- **Purpose**: Verify device integrity before allowing access
- **Checks**:
  - ✅ Root/Jailbreak detection
  - ✅ Developer mode detection
  - ✅ Emulator detection
  - ✅ Mock location detection
  - ✅ Device ID tampering detection
- **Action**: Immediate logout if device compromised

#### Layer 5: Location-Based Access Control
- **Purpose**: Ensure user is in authorized location
- **Technology**: GPS + Geofencing
- **Process**:
  1. Admin creates geofence (center point + radius) during user creation
  2. App validates user location against geofence before login
  3. Continuous monitoring during workspace session (every 10 seconds)
  4. Warning shown 15 seconds before logout if user leaves area
  5. Automatic logout if user doesn't return to authorized zone
- **Services**: GeofenceService, WorkspaceLocationMonitorService, LocationValidationService

### 2. **Real-Time Security Monitoring**

**RealtimeSecurityMonitor** continuously monitors for threats:

| Threat Type | Detection Method | Action |
|-------------|------------------|--------|
| **Root/Jailbreak** | System file checks, system properties | Immediate logout |
| **Developer Mode** | ADB enabled, USB debugging | Warning + monitoring |
| **Emulator** | Build properties, hardware checks | Block access |
| **Mock Location** | Location provider analysis | Immediate logout |
| **Trust Score Drop** | Composite security score < 30 | Immediate logout |
| **Device Tampering** | Integrity checksum validation | Immediate logout |

**Trust Score Calculation** (0-100):
- Base Score: 100
- Root/Jailbreak: -50
- Developer Mode: -20
- Emulator: -30
- Mock Location: -40
- Age Penalty: -0.1 per day since last security check

### 3. **Screenshot & Screen Recording Protection**

**iOS Implementation**:
- Native Swift code detects screenshots via `userDidTakeScreenshotNotification`
- Screen recording detected via `UIScreen.isCaptured`
- Secure overlay shown in app switcher
- Real-time alerts sent to Flutter via method channels

**Android Implementation**:
- `FLAG_SECURE` prevents screenshots in secure screens
- Activity lifecycle monitoring
- Blur overlay in recent apps view

### 4. **Session Security**

**Inactivity Timeout**: 60 seconds of no interaction → Auto logout
**Session Monitoring**: Every 10 seconds check with backend
**Automatic Termination Triggers**:
- App backgrounded for > 2 minutes (except Settings navigation)
- Network disconnection
- Location violation
- Security threat detected
- Trust score below threshold
- Manual logout

**Session Cleanup**:
- Backend WebRTC session terminated
- Local secure storage cleared
- Navigation to login screen
- All sensitive data wiped

---

## 📱 User Flow & Timeline

### Complete User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                    FIRST TIME USER SETUP                         │
└─────────────────────────────────────────────────────────────────┘

1. [App Launch] → Onboarding Screen
   ↓
2. [Tap "Get Started"] → Vault Initialization Screen
   ↓
3. [Enter Passkey] → Create Device Vault
   ↓ (Background: Generate device UUID, crypto keys, store securely)
   ↓
4. [Success] → Biometric Requirement Screen
   ↓
5. [Enable Biometrics] → System Biometric Setup
   ↓
6. [Biometric Enabled] → Device Verification Screen
   ↓ (Background: Perform device attestation checks)
   ↓
7. [Device Verified] → Login Screen

┌─────────────────────────────────────────────────────────────────┐
│                    RETURNING USER LOGIN                          │
└─────────────────────────────────────────────────────────────────┘

1. [App Launch] → Auto-navigate to Login Screen
   ↓
2. [Tap "Sign In"] → Biometric Authentication Prompt
   ↓
3. [Biometric Success] → Check Location Permissions
   ↓
4. [Permissions Granted] → Geofence Validation Screen
   ↓ (Background: Get GPS location, validate against geofence)
   ↓
5. [Location Valid] → Login API Call
   ↓ (Send: email, password, device_uuid, location)
   ↓ (Receive: session_token, user_data, geofence_data)
   ↓
6. [Login Success] → AI Chat Screen (Workspace)

┌─────────────────────────────────────────────────────────────────┐
│                    WORKSPACE SESSION                             │
└─────────────────────────────────────────────────────────────────┘

1. [AI Chat Screen Loads] → Initialize WebRTC Session
   ↓
2. [Request Workspace] → Backend Creates Docker Container
   ↓ (Backend: Pulls browser image, starts container, configures VNC)
   ↓
3. [WebRTC Session Created] → Stream Workspace Display
   ↓
4. [User Interacts] → Input Methods Available:
   │
   ├─ Touch/Tap → WebRTC Control Service (mouse events)
   ├─ Text Input → Native Input Overlay (keyboard)
   ├─ Voice Input → Speech-to-Text Service → AI Processing
   └─ File Upload → File Picker → Workspace File Upload Service
   ↓
5. [Continuous Monitoring] → Background Services:
   │
   ├─ Session Monitor (every 10s) → Check session validity
   ├─ Location Monitor (every 10s) → Validate geofence
   ├─ Security Monitor (continuous) → Check device integrity
   ├─ Inactivity Monitor → Track user interaction
   └─ Network Monitor → Check connectivity
   ↓
6. [Session Continues] → User works in streamed workspace
   ↓
7. [Logout Triggered] → Automatic/Manual Termination:
   │
   ├─ Manual: User taps logout button
   ├─ Auto: Inactivity timeout (60 seconds)
   ├─ Auto: Location violation (out of geofence)
   ├─ Auto: Security threat detected
   ├─ Auto: Network disconnection
   └─ Auto: Session expired (8 hours max)
   ↓
8. [Cleanup] → Terminate WebRTC, Clear Session, Navigate to Login
```

### Detailed Timeline with Timestamps

**Example: Complete Session Flow (30-minute session)**

```
T+0s    │ App Launch
T+1s    │ ├─ Load secure storage
T+1s    │ ├─ Check vault exists → Yes
T+1s    │ ├─ Navigate to Login Screen
T+2s    │ └─ Login screen rendered

T+2s    │ User taps "Sign In"
T+3s    │ ├─ Show biometric prompt
T+5s    │ ├─ User authenticates (Face ID)
T+5s    │ └─ Biometric success

T+5s    │ Request Permissions
T+6s    │ ├─ Location permission → Granted
T+7s    │ ├─ Camera permission → Granted
T+8s    │ └─ Microphone permission → Granted

T+8s    │ Geofence Validation
T+9s    │ ├─ Get GPS location (lat, lng)
T+10s   │ ├─ Calculate distance to geofence center
T+10s   │ └─ Location valid (within radius)

T+10s   │ Login API Request
T+11s   │ ├─ POST /api/users/login
T+12s   │ ├─ Backend validates credentials
T+13s   │ ├─ Backend creates session token
T+14s   │ ├─ Response: session_token, user_data
T+14s   │ └─ Store session_token securely

T+14s   │ Navigate to AI Chat Screen
T+15s   │ ├─ Screen rendered (loading state)
T+15s   │ └─ Initialize services

T+15s   │ Start Security Monitoring
T+15s   │ ├─ Device attestation check → PASSED
T+16s   │ ├─ Root detection → NOT ROOTED
T+16s   │ ├─ Mock location check → REAL GPS
T+16s   │ ├─ Trust score calculated → 100
T+16s   │ └─ Security status: SECURE

T+16s   │ Start Location Monitoring
T+16s   │ ├─ Subscribe to location updates
T+16s   │ └─ Monitor every 10 seconds

T+16s   │ Start Inactivity Monitoring
T+16s   │ └─ Timeout: 60 seconds

T+16s   │ Initialize WebRTC Session
T+17s   │ ├─ POST /api/webrtc/create-session
T+18s   │ ├─ Device info: width=390, height=844, dpr=3.0
T+19s   │ ├─ Backend checks for existing session → None
T+20s   │ ├─ Backend pulls Docker image (cached)
T+22s   │ ├─ Backend starts container with VNC
T+25s   │ ├─ Backend configures WebRTC peer connection
T+27s   │ ├─ Response: session_id, container_id, target_url
T+27s   │ └─ WebRTC session created

T+27s   │ Establish WebRTC Connection
T+28s   │ ├─ Create RTCPeerConnection
T+29s   │ ├─ Exchange ICE candidates
T+30s   │ ├─ Set remote SDP
T+31s   │ ├─ WebRTC connected
T+32s   │ ├─ Video stream starts
T+32s   │ └─ Display workspace in UI

T+32s   │ Workspace Ready - User can interact
T+32s   │ └─ Status: STREAMING

[User works for 30 minutes...]

T+26s   │ [Every 10s] Session status check
T+36s   │ [Every 10s] Location validation
T+46s   │ [Every 10s] Security monitoring
T+1800s │ User taps logout button
T+1801s │ ├─ POST /api/webrtc/destroy-session
T+1802s │ ├─ Backend stops Docker container
T+1803s │ ├─ Backend removes container
T+1804s │ ├─ Clear WebRTC connection
T+1805s │ ├─ Clear secure storage (session_token)
T+1806s │ ├─ Navigate to Login Screen
T+1806s │ └─ Logout complete
```

---

## 📦 Package Dependencies

### Production Dependencies (22 packages)

#### **State Management & Architecture**
```yaml
flutter_riverpod: ^2.5.1
  Purpose: Reactive state management with provider pattern
  Usage: Global app state, service instances, reactive UI updates
  Key Features: Type-safe, compile-time safety, automatic disposal
```

#### **Navigation**
```yaml
go_router: ^14.2.7
  Purpose: Declarative routing with deep linking
  Usage: Screen navigation, route guards, URL-based navigation
  Screens: /onboarding, /login, /workspace, /device-verification
```

#### **UI & Animations**
```yaml
flutter_animate: ^4.5.0
  Purpose: Declarative animations with effects
  Usage: Screen transitions, loading animations, UI micro-interactions
  Effects: Fade, slide, blur, shimmer, scale
```

#### **Networking & Real-time Communication**
```yaml
dio: ^5.7.0
  Purpose: HTTP client with interceptors
  Usage: REST API calls to backend
  Features: 
    - Request/response interceptors
    - Error handling
    - Timeout configuration
    - SSL certificate pinning
  
socket_io_client: ^2.0.3+1
  Purpose: Real-time bidirectional communication
  Usage: Workspace text synchronization, file upload notifications
  Status: Currently disabled to avoid 403 errors
  
web_socket_channel: ^3.0.1
  Purpose: WebSocket communication
  Usage: WebSocket connections for workspace service
  
flutter_webrtc: ^1.4.1
  Purpose: WebRTC peer-to-peer connection
  Usage: Pixel streaming from backend workspace container
  Features:
    - Video stream rendering
    - Audio support
    - Data channels for control
    - ICE candidate exchange
```

#### **Security & Authentication**
```yaml
local_auth: ^2.3.0
  Purpose: Biometric authentication
  Usage: Face ID, Touch ID, Fingerprint authentication
  Platforms: iOS (Face ID, Touch ID), Android (Fingerprint, Face Unlock)
  
flutter_secure_storage: ^9.2.2
  Purpose: Encrypted key-value storage
  Usage: Store session tokens, device UUID, user credentials
  Encryption: 
    - iOS: Keychain with AES-256
    - Android: KeyStore with AES-256
  Keys Stored:
    - device_uuid
    - device_name
    - vault_passkey
    - backend_session_token
    - backend_session_id
    - user_email
    - user_password
    - biometric_user_email
    - login_geofence_id
  
crypto: ^3.0.5
  Purpose: Cryptographic functions
  Usage: SHA-256 hashing, HMAC, key derivation
  
pointycastle: ^3.9.1
  Purpose: Cryptographic library for Dart
  Usage: RSA encryption, AES encryption, digital signatures
```

#### **Face Recognition & Media**
```yaml
google_mlkit_face_detection: ^0.10.0
  Purpose: On-device face detection using Google ML Kit
  Usage: Face verification, liveness detection
  Features:
    - Face landmark detection
    - Face tracking
    - Contour detection
    - Face classification (eyes open, smiling)
  
image_picker: ^1.0.7
  Purpose: Pick images from gallery or camera
  Usage: Face photo capture, file attachments
  
file_picker: ^8.0.0+1
  Purpose: Pick files from device storage
  Usage: File uploads to workspace
```

#### **Location & Geofencing**
```yaml
geolocator: ^13.0.1
  Purpose: Location services with geofencing
  Usage: Get GPS coordinates, calculate distances, geofence validation
  Features:
    - High-accuracy location
    - Background location updates
    - Distance calculation (Haversine formula)
    - Permission handling
  
geocoding: ^3.0.0
  Purpose: Convert coordinates to addresses
  Usage: Display location names, reverse geocoding
```

#### **Network & Connectivity**
```yaml
connectivity_plus: ^6.0.5
  Purpose: Network connectivity monitoring
  Usage: Detect WiFi/cellular connection, monitor connection changes
  Features:
    - Real-time connectivity status
    - Connection type detection (WiFi, cellular, none)
    - Stream-based updates
```

#### **Device Information**
```yaml
device_info_plus: ^10.1.2
  Purpose: Get device information
  Usage: Device attestation, analytics, security checks
  Data Retrieved:
    - Device model, brand, manufacturer
    - OS version, SDK version
    - Unique device identifiers
    - Hardware capabilities
  
package_info_plus: ^8.0.2
  Purpose: App package information
  Usage: App version, build number, package name
```

#### **Permissions**
```yaml
permission_handler: ^11.3.1
  Purpose: Request and check permissions
  Usage: Location, camera, microphone permissions
  Permissions Managed:
    - location (always/when in use)
    - camera
    - microphone
    - storage
```

#### **Speech Recognition**
```yaml
speech_to_text: ^7.0.0
  Purpose: Convert speech to text
  Usage: Voice input for AI interactions
  Features:
    - Real-time transcription
    - Multiple language support
    - Continuous listening mode
    - On-device processing (iOS)
    - Cloud-based processing (Android)
```

#### **Utilities**
```yaml
uuid: ^4.5.1
  Purpose: Generate unique identifiers
  Usage: Device UUID generation, session IDs
  
logger: ^2.4.0
  Purpose: Structured logging
  Usage: Debug logs, error tracking, analytics
  
freezed_annotation: ^2.4.4
  Purpose: Code generation for immutable classes
  Usage: Data models, state classes
  Features: Immutability, equality, copyWith
```

### Development Dependencies (4 packages)

```yaml
flutter_test:
  Purpose: Widget and unit testing framework
  
flutter_lints: ^6.0.0
  Purpose: Official Flutter linting rules
  
build_runner: ^2.4.13
  Purpose: Code generation runner
  Usage: Generate code for Riverpod, Freezed
  
freezed: ^2.5.7
  Purpose: Generate immutable data classes
  
mockito: ^5.4.4
  Purpose: Mocking framework for testing
  
flutter_launcher_icons: ^0.14.1
  Purpose: Generate app icons for all platforms
```

### Removed Unused Packages (9 packages)

The following packages were removed during code audit as they were not used:

✅ **riverpod_annotation** - Not using annotation-based providers  
✅ **cupertino_icons** - Using custom icons only  
✅ **camera** - Using image_picker instead  
✅ **intl** - No internationalization implemented  
✅ **shared_preferences** - Using flutter_secure_storage for all storage  
✅ **json_annotation** - Not using JSON serialization  
✅ **record** - Audio recording not implemented  
✅ **path_provider** - Not accessing file paths directly  
✅ **riverpod_generator** - Not using code generation for Riverpod  
✅ **json_serializable** - Not using JSON serialization

**Impact**: Reduced app size, faster builds, fewer dependencies to manage

---

## 🔧 Core Services
