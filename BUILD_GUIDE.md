# 📱 Build & Install Guide

## 🚀 Automated Build (Easiest)

### Windows
```bash
# Double-click or run:
build-apk.bat
```

This will:
1. Generate keystore (if needed)
2. Create key.properties (if needed)
3. Clean project
4. Build signed APK

**APK Location**: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🔧 Manual Build (Step by Step)

### Step 1: Generate Keystore (One-time)
```bash
cd android
keytool -genkey -v -keystore nlaabo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nlaabo -storepass nlaabo2024 -keypass nlaabo2024 -dname "CN=Nlaabo, OU=Nlaabo, O=Nlaabo, L=Casablanca, S=Casablanca, C=MA"
cd ..
```

### Step 2: Create key.properties
Create `android/key.properties`:
```properties
storePassword=nlaabo2024
keyPassword=nlaabo2024
keyAlias=nlaabo
storeFile=nlaabo-release-key.jks
```

### Step 3: Build APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📲 Install on Phone

### Method 1: USB Cable (Recommended)
```bash
# 1. Enable USB debugging on phone:
#    Settings > Developer Options > USB Debugging

# 2. Connect phone via USB

# 3. Install APK
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Method 2: File Transfer
1. Copy `app-release.apk` to phone (via USB, email, cloud)
2. On phone, open the APK file
3. Allow "Install from unknown sources" if prompted
4. Tap "Install"

### Method 3: QR Code
1. Upload APK to cloud storage
2. Generate QR code with link
3. Scan QR code on phone
4. Download and install

---

## 🎯 Build Variants

### Release APK (Smallest, Optimized)
```bash
flutter build apk --release
```
**Size**: ~20-30 MB
**Use**: Production, distribution

### Debug APK (Larger, with debugging)
```bash
flutter build apk --debug
```
**Size**: ~40-50 MB
**Use**: Testing, debugging

### Profile APK (Performance testing)
```bash
flutter build apk --profile
```
**Size**: ~30-40 MB
**Use**: Performance analysis

---

## 📦 Build App Bundle (For Play Store)

```bash
flutter build appbundle --release
```

**Output**: `build\app\outputs\bundle\release\app-release.aab`

---

## 🔐 Security Notes

### ⚠️ IMPORTANT
- **NEVER** commit `key.properties` to git
- **NEVER** commit `*.jks` files to git
- **BACKUP** your keystore file securely
- **REMEMBER** your keystore password

### Keystore Backup
```bash
# Backup keystore to safe location
copy android\nlaabo-release-key.jks D:\Backup\nlaabo-keystore-backup.jks
```

---

## 🐛 Troubleshooting

### Error: "keytool not found"
**Solution**: Add Java to PATH
```bash
# Find Java installation
where java

# Add to PATH (example)
set PATH=%PATH%;C:\Program Files\Java\jdk-11\bin
```

### Error: "Keystore was tampered with"
**Solution**: Wrong password or corrupted keystore
- Verify password in `key.properties`
- Regenerate keystore if corrupted

### Error: "Execution failed for task ':app:lintVitalRelease'"
**Solution**: Disable lint checks
Add to `android/app/build.gradle.kts`:
```kotlin
android {
    lintOptions {
        checkReleaseBuilds = false
    }
}
```

### Error: "Insufficient storage"
**Solution**: Clean build
```bash
flutter clean
cd android
gradlew clean
cd ..
flutter build apk --release
```

---

## 📊 APK Size Optimization

### Current Size: ~25 MB

### Reduce Size:
```bash
# Split APKs by architecture
flutter build apk --split-per-abi --release

# Outputs:
# - app-armeabi-v7a-release.apk (~15 MB)
# - app-arm64-v8a-release.apk (~18 MB)
# - app-x86_64-release.apk (~20 MB)
```

---

## ✅ Verification

### Check APK Info
```bash
# View APK details
aapt dump badging build\app\outputs\flutter-apk\app-release.apk

# Check signature
jarsigner -verify -verbose -certs build\app\outputs\flutter-apk\app-release.apk
```

### Test Installation
```bash
# Install on connected device
adb install -r build\app\outputs\flutter-apk\app-release.apk

# View logs
adb logcat | findstr flutter
```

---

## 🎉 Success!

Your APK is ready to install on any Android device!

**APK Location**: `build\app\outputs\flutter-apk\app-release.apk`

**Next Steps**:
1. Test on multiple devices
2. Gather user feedback
3. Prepare for Play Store submission
