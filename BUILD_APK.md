# Build Signed APK

## 🚀 Quick Build (3 Steps)

### Step 1: Generate Keystore (One-time setup)
```bash
cd d:\Projets\Dev\footconnect\footconnect\nlaabo\android
keytool -genkey -v -keystore nlaabo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nlaabo
```

**Enter when prompted:**
- Password: `nlaabo2024` (remember this!)
- First and Last Name: `Nlaabo`
- Organization: `Nlaabo`
- City: `Casablanca`
- State: `Casablanca`
- Country: `MA`

### Step 2: Create key.properties
Create file: `android/key.properties`
```properties
storePassword=nlaabo2024
keyPassword=nlaabo2024
keyAlias=nlaabo
storeFile=nlaabo-release-key.jks
```

### Step 3: Build APK
```bash
cd d:\Projets\Dev\footconnect\footconnect\nlaabo
flutter build apk --release
```

**APK Location:**
`build\app\outputs\flutter-apk\app-release.apk`

---

## 📱 Install on Phone

### Method 1: USB Cable
```bash
# Connect phone via USB
# Enable USB debugging on phone
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Method 2: File Transfer
1. Copy `app-release.apk` to phone
2. Open file on phone
3. Allow "Install from unknown sources"
4. Install

---

## ⚡ One-Line Build

```bash
cd d:\Projets\Dev\footconnect\footconnect\nlaabo && flutter build apk --release
```

APK will be at: `build\app\outputs\flutter-apk\app-release.apk`
