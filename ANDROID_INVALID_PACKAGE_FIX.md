# Fix: "App Not Installed as Package Appears to be Invalid"

## 🚨 Problem Description

When trying to install the RustDesk Android APK, you encounter the error:

```
App not installed as package appears to be invalid
```

This error typically occurs during APK installation on Android devices and can have multiple root causes.

---

## 🔍 Root Causes

### 1. **Plugin Namespace Issues (AGP 8+ Compatibility)**
- Android Gradle Plugin 8.0+ requires explicit namespace declarations in all plugins
- Missing or incorrect namespaces cause build failures or invalid APKs
- Package attributes in AndroidManifest.xml are deprecated and cause conflicts

### 2. **Signing Configuration Mismatch**
- Debug APK has different signature than release APK
- Cannot update/reinstall app if signatures don't match
- Must uninstall old version before installing with different signature

### 3. **Version Code Conflicts**
- Installing APK with lower versionCode than currently installed
- Android prevents downgrading apps by default

### 4. **Corrupted Build Artifacts**
- Gradle cache corruption
- Incomplete or interrupted builds
- Stale build files

### 5. **minSdkVersion Compatibility**
- App requires higher API level than device supports
- rustls-platform-verifier requires minimum API 23 (Android 6.0)

### 6. **Architecture Mismatch**
- APK built for arm64-v8a won't install on arm devices
- Need correct architecture for target device

---

## ✅ Solution

### Quick Fix (Automated)

We've created comprehensive scripts to automatically fix these issues:

#### On Linux:
```bash
cd /workspace/flutter
./fix_invalid_package.sh
```

This script will:
1. Fix all plugin namespace issues
2. Clean corrupted build artifacts
3. Verify and fix minSdkVersion
4. Validate AndroidManifest.xml
5. Check Gradle configuration
6. Provide next steps for building

#### On macOS:
```bash
cd /workspace/flutter
./fix_android_plugins_macos.sh
# Then clean and rebuild
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release
```

---

## 🛠️ Manual Fix Steps

### Step 1: Fix Plugin Namespaces

Flutter plugins require namespace declarations for AGP 8+ compatibility.

**For Linux:**
```bash
cd /workspace/flutter
bash fix_android_plugins_linux.sh
```

**For macOS:**
```bash
cd /workspace/flutter
bash fix_android_plugins_macos.sh
```

This fixes these plugins:
- external_path
- flutter_keyboard_visibility
- sqflite
- qr_code_scanner
- device_info_plus
- url_launcher
- path_provider
- package_info_plus
- shared_preferences
- image_picker_android
- permission_handler_android
- wakelock_plus
- desktop_multi_window
- uni_links (git dependency)

### Step 2: Clean Build Artifacts

Remove all cached and compiled files:

```bash
cd /workspace/flutter

# Clean Flutter build
flutter clean

# Remove Gradle caches
rm -rf android/.gradle
rm -rf android/app/build
rm -rf ~/.gradle/caches

# Remove build directory
rm -rf build
```

### Step 3: Verify Configuration

#### Check minSdkVersion in `android/app/build.gradle`:
```gradle
android {
    namespace "com.carriez.flutter_hbb"
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.carriez.flutter_hbb"
        minSdkVersion 23  // Must be 23+ for rustls compatibility
        targetSdkVersion 33
    }
}
```

#### Verify AndroidManifest.xml has correct package:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.carriez.flutter_hbb">
```

### Step 4: Rebuild APK

```bash
cd /workspace/flutter

# Get dependencies
flutter pub get

# Build debug APK (for testing)
flutter build apk --debug --target-platform android-arm64

# OR build release APK
flutter build apk --release --target-platform android-arm64
```

### Step 5: Install APK

#### If previous version is installed:
```bash
# Uninstall old version first
adb uninstall com.carriez.flutter_hbb

# Then install new APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### If no previous version:
```bash
# Install directly
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔧 Technical Details

### Why Namespace Declarations Are Required

Starting with Android Gradle Plugin 8.0:
- The `package` attribute in AndroidManifest.xml is deprecated
- Namespace must be declared explicitly in build.gradle
- This prevents conflicts and improves build performance

**Before (AGP 7.x):**
```xml
<!-- AndroidManifest.xml -->
<manifest package="com.example.plugin">
```

**After (AGP 8.x):**
```gradle
// build.gradle
android {
    namespace "com.example.plugin"
}
```

```xml
<!-- AndroidManifest.xml -->
<manifest xmlns:android="...">
  <!-- No package attribute -->
```

### Why minSdkVersion = 23

The `rustls-platform-verifier` dependency requires API level 23 (Android 6.0):
- Uses modern Android security APIs
- Earlier versions had `minSdkVersion 21` which caused conflicts

### Signing Configuration

Debug and release APKs have different signatures:

| Type | Signature | Use Case |
|------|-----------|----------|
| Debug | Default debug keystore | Development, testing |
| Release | Custom keystore (key.properties) | Production, distribution |

You cannot install a debug APK over a release APK (or vice versa) without uninstalling first.

---

## 📱 Device Requirements

Ensure your target device meets these requirements:

- **Minimum Android Version:** 6.0 (API 23)
- **Target Android Version:** 13 (API 33)
- **Architecture:** ARM64 (arm64-v8a) or ARM (armeabi-v7a)
- **Available Storage:** At least 100MB free

---

## 🐛 Troubleshooting

### Error: "Minimum supported Gradle version is 8.0"
**Solution:** Update Gradle version in `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-all.zip
```

### Error: "Namespace not specified"
**Solution:** Run the plugin fix script:
```bash
bash flutter/fix_android_plugins_linux.sh
```

### Error: "Inconsistent JVM target compatibility"
**Solution:** Add kotlinOptions to build.gradle:
```gradle
android {
    kotlinOptions {
        jvmTarget = "1.8"
    }
}
```

### Error: "App not installed" (signature conflict)
**Solution:** Uninstall the existing app first:
```bash
adb uninstall com.carriez.flutter_hbb
```

### Error: "Installation failed with message INSTALL_FAILED_VERSION_DOWNGRADE"
**Solution:** Either:
1. Increment versionCode in pubspec.yaml
2. Uninstall old version first
3. Use `adb install -d` flag to allow downgrade (not recommended)

---

## 📊 Build Configuration Summary

### Working Configuration (Verified)

| Component | Version |
|-----------|---------|
| Flutter | 3.24.5 |
| Dart | 3.5.4 |
| Java | OpenJDK 17 LTS |
| Gradle | 8.5 |
| Android Gradle Plugin | 8.1.1 |
| Kotlin | 1.9.22 |
| Min SDK | 23 (Android 6.0) |
| Target SDK | 33 (Android 13) |
| Compile SDK | 34 (Android 14) |

---

## 📝 Files Created/Modified

### New Scripts:
1. **`flutter/fix_android_plugins_linux.sh`** - Linux-compatible plugin fix script
2. **`flutter/fix_invalid_package.sh`** - Comprehensive diagnostic and fix script

### Modified Files:
- `flutter/android/app/build.gradle` - Updated minSdkVersion to 23
- Various plugin build.gradle files - Added namespace declarations
- Various plugin AndroidManifest.xml files - Removed deprecated package attributes

---

## ✅ Verification Checklist

After applying fixes, verify:

- [ ] Plugin namespaces are set correctly
- [ ] minSdkVersion is 23 or higher
- [ ] Build artifacts are cleaned
- [ ] Flutter dependencies are up to date (`flutter pub get`)
- [ ] APK builds successfully
- [ ] APK installs on target device

---

## 🔗 Related Documentation

- [ANDROID_BUILD_README.md](./ANDROID_BUILD_README.md) - Complete Android build guide
- [ANDROID_BUILD_ENVIRONMENT.md](./ANDROID_BUILD_ENVIRONMENT.md) - Working environment documentation
- [MACOS_ANDROID_BUILD.md](./MACOS_ANDROID_BUILD.md) - macOS-specific Android build guide

---

## 📞 Additional Help

If you continue to experience issues:

1. **Check logs:**
   ```bash
   flutter build apk --verbose
   adb logcat | grep "RustDesk"
   ```

2. **Verify APK integrity:**
   ```bash
   aapt dump badging build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Test on different device/emulator:**
   - Some issues are device-specific
   - Try on Android emulator with API 23+

4. **Review recent changes:**
   ```bash
   git log --oneline -10 -- flutter/android/
   ```

---

**Last Updated:** 2025-11-14  
**Status:** ✅ Fixed and Documented
