# Android Installation & APK Signing Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Generate Signing Key](#generate-signing-key)
3. [Configure App Signing](#configure-app-signing)
4. [Build APK](#build-apk)
5. [Build App Bundle (AAB)](#build-app-bundle-aab)
6. [Install APK on Device](#install-apk-on-device)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have:

- **Flutter SDK** installed and configured
- **Android Studio** or **Android SDK** installed
- **Java JDK** (version 11 or higher)
- **USB debugging** enabled on your Android device (for direct installation)

### Verify Flutter Installation
```bash
flutter doctor
```

---

## Generate Signing Key

### Step 1: Create a Keystore File

On macOS/Linux:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

On Windows:
```bash
keytool -genkey -v -keystore %userprofile%\upload-keystore.jks ^
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias upload
```

### Step 2: Fill in the Required Information

You'll be prompted to enter:
- **Keystore password**: Choose a strong password
- **Key password**: Can be the same as keystore password
- **First and Last Name**: Your name or organization name
- **Organizational Unit**: Your team/department
- **Organization**: Your company name
- **City/Locality**: Your city
- **State/Province**: Your state
- **Country Code**: Two-letter country code (e.g., US)

**Important**: Store these credentials securely! You'll need them for all future app updates.

### Step 3: Move Keystore to Project

```bash
# Move keystore to android/app directory (recommended location)
mv ~/upload-keystore.jks /Users/squad-mac/Desktop/Flutter/ask_jeeves_vmi/android/app/
```

---

## Configure App Signing

### Step 1: Create key.properties File

Create a file at `android/key.properties`:

```bash
touch android/key.properties
```

### Step 2: Add Signing Configuration

Edit `android/key.properties` and add:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

**Security Note**: Add `key.properties` to `.gitignore` to prevent committing credentials:

```bash
echo "android/key.properties" >> .gitignore
```

### Step 3: Configure build.gradle

The `android/app/build.gradle.kts` file should already contain signing configuration. Verify it includes:

```kotlin
// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... other configuration

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ... other configuration
        }
    }
}
```

---

## Build APK

### Build Release APK

```bash
cd /Users/squad-mac/Desktop/Flutter/ask_jeeves_vmi
flutter build apk --release
```

### Build Split APKs (Smaller file sizes)

```bash
flutter build apk --split-per-abi --release
```

This creates separate APKs for different CPU architectures:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

**Output Location**: `build/app/outputs/flutter-apk/`

### Verify Signing

```bash
# Navigate to APK directory
cd build/app/outputs/flutter-apk/

# Verify APK signature
keytool -printcert -jarfile app-release.apk
```

You should see certificate details including your organization name.

---

## Build App Bundle (AAB)

For **Google Play Store** deployment, use Android App Bundle format:

```bash
flutter build appbundle --release
```

**Output Location**: `build/app/outputs/bundle/release/app-release.aab`

### Why Use AAB?

- **Smaller downloads**: Google Play generates optimized APKs for each device
- **Required for Play Store**: New apps must use AAB format
- **Dynamic delivery**: Support for on-demand features

---

## Install APK on Device

### Method 1: USB Connection (ADB)

1. **Enable USB Debugging** on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times to enable Developer Options
   - Go to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect device** via USB cable

3. **Verify device connection**:
```bash
flutter devices
```

4. **Install APK**:
```bash
flutter install
```

Or using ADB directly:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Manual Installation

1. **Transfer APK** to device:
   - Email the APK to yourself
   - Use cloud storage (Google Drive, Dropbox)
   - Transfer via USB and copy to Downloads folder

2. **Enable Unknown Sources**:
   - Go to Settings → Security
   - Enable "Install from Unknown Sources" or "Allow from this source"

3. **Install APK**:
   - Open file manager on device
   - Navigate to APK location
   - Tap on APK file
   - Follow installation prompts

### Method 3: Email Distribution to Clients

**For small-scale distribution**, you can email APKs directly to clients:

#### Email Size Limitations

Most email providers have attachment size limits:
- **Gmail**: 25 MB
- **Outlook**: 20 MB
- **Yahoo**: 25 MB

If your APK is larger:
1. Use split APKs (usually 15-30 MB each)
2. Use cloud storage links (see Method 4)

#### Steps to Email APK

1. **Build the APK**:
```bash
flutter build apk --release
```

2. **Locate the APK**:
```bash
open build/app/outputs/flutter-apk/
```

3. **Attach to email** and send to client with installation instructions

#### Sample Email Template for Clients

```
Subject: Ask Jeeves VMI - App Installation

Hi [Client Name],

Please find attached the Ask Jeeves VMI application for Android.

Installation Instructions:

1. Download the APK file (app-release.apk) from this email
2. On your Android device, go to Settings → Security
3. Enable "Install from Unknown Sources" or "Allow from this source"
4. Open your Downloads folder and tap on app-release.apk
5. Tap "Install" and follow the prompts
6. Once installed, you can disable "Unknown Sources" for security

App Requirements:
- Android 5.0 (Lollipop) or higher
- Camera access (for face recognition)
- Microphone access (for voice input)
- Location access (for geofence validation)

If you encounter any installation issues, please reply to this email.

Best regards,
[Your Name]
```

### Method 4: Cloud Storage Distribution

**For larger APKs or multiple clients**, use cloud storage:

#### Google Drive

1. **Upload APK** to Google Drive
2. **Right-click** on the file → Share → Get link
3. **Set permissions** to "Anyone with the link"
4. **Send link** to clients via email

#### Dropbox

1. **Upload APK** to Dropbox
2. **Click Share** → Create link
3. **Copy link** and send to clients

#### WeTransfer

1. Go to [wetransfer.com](https://wetransfer.com)
2. **Upload APK** (up to 2 GB free)
3. **Enter client email**
4. Add message with installation instructions
5. **Send** - client receives download link

#### Client Instructions for Cloud Storage

```
Subject: Ask Jeeves VMI - Installation Link

Hi [Client Name],

Please download the Ask Jeeves VMI application from the link below:

[Cloud Storage Link]

Installation Instructions:

1. Click the link above on your Android device
2. Download the APK file
3. Once downloaded, tap "Open" or find the file in your Downloads folder
4. Enable "Install from Unknown Sources" if prompted
5. Tap "Install" and follow the prompts

App Requirements:
- Android 5.0 or higher
- 100 MB free storage
- Active internet connection

For detailed instructions, see the attached installation guide.

Support: [your-email@example.com]

Best regards,
[Your Name]
```

---

## Troubleshooting

### Issue: "Failed to load keystore"

**Solution**: Verify that:
- `key.properties` exists in `android/` directory
- Keystore file path in `key.properties` is correct
- Passwords are correct (no extra spaces)

### Issue: "Gradle build failed"

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: "App not compatible with device"

**Solution**: Build split APKs or ensure you're installing the correct architecture:
- ARM devices need `arm64-v8a` or `armeabi-v7a`
- Most modern devices use `arm64-v8a`

### Issue: "Installation blocked"

**Solution**:
- Enable "Install from Unknown Sources" in device settings
- Check device storage space
- Uninstall previous version if signature mismatch occurs

### Issue: Signature mismatch during update

**Solution**: This happens when the signing key changed. Users must:
1. Uninstall the old app
2. Install the new APK

**Prevention**: Always use the same keystore for updates!

---

## Security Best Practices

### Protect Your Keystore

1. **Backup keystore file** to multiple secure locations
2. **Never commit** `key.properties` or keystore to version control
3. **Use strong passwords** (minimum 12 characters)
4. **Document credentials** securely (password manager)

### Lost Keystore Recovery

⚠️ **If you lose your keystore, you cannot update your app on the Play Store!**

Users would need to uninstall and reinstall as a new app, losing all data.

### For Team Development

Use **Android Studio's Play App Signing**:
- Google manages your signing key
- You upload AAB files (not APK)
- Reduces risk of key loss

---

## Quick Reference Commands

```bash
# Generate keystore
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build release APK
flutter build apk --release

# Build split APKs
flutter build apk --split-per-abi --release

# Build App Bundle
flutter build appbundle --release

# Install on connected device
flutter install

# Install specific APK with ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# List connected devices
flutter devices
adb devices

# Verify APK signature
keytool -printcert -jarfile app-release.apk

# Clean build
flutter clean && flutter pub get
```

---

## Additional Resources

- [Flutter Android Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Google Play Console](https://play.google.com/console)

---

## Notes for This Project (Ask Jeeves VMI)

### Current Configuration

- **Package Name**: `com.example.ask_jeeves_vmi`
- **Min SDK**: API 21 (Android 5.0)
- **Target SDK**: API 34 (Android 14)
- **Compile SDK**: API 34

### Required Permissions

The app requires these permissions (already configured in `AndroidManifest.xml`):
- Camera (face recognition)
- Microphone (voice input)
- Location (geofence validation)
- Internet (API communication)
- WebRTC (video streaming)

### Before Distribution

1. **Update package name** in `build.gradle.kts` if needed
2. **Review permissions** in `AndroidManifest.xml`
3. **Test on physical device** (not just emulator)
4. **Verify security features** work correctly
5. **Test in release mode** (performance differs from debug)

---

**Created**: June 3, 2026  
**Last Updated**: June 3, 2026  
**Version**: 1.0
