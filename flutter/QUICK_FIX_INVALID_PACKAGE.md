# Quick Fix: "App Not Installed as Package Appears to be Invalid"

## 🚀 One-Command Fix

### For Linux/Ubuntu:
```bash
cd /workspace/flutter && ./fix_invalid_package.sh
```

### For macOS:
```bash
cd /workspace/flutter && ./fix_android_plugins_macos.sh && flutter clean && flutter pub get
```

---

## 🔨 Then Build:

### Debug APK (for testing):
```bash
flutter build apk --debug --target-platform android-arm64
```

### Release APK (for production):
```bash
flutter build apk --release --target-platform android-arm64
```

---

## 📱 Install on Device:

### First-time installation:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Reinstalling (if app already exists):
```bash
adb uninstall com.carriez.flutter_hbb
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📖 Need More Details?

See [ANDROID_INVALID_PACKAGE_FIX.md](../ANDROID_INVALID_PACKAGE_FIX.md) for:
- Detailed explanation of the issue
- Root cause analysis
- Manual fix steps
- Troubleshooting guide
- Technical details

---

## ✅ What Gets Fixed:

1. ✓ Plugin namespace declarations (AGP 8+ requirement)
2. ✓ Deprecated package attributes removed
3. ✓ minSdkVersion set to 23 (rustls compatibility)
4. ✓ Kotlin JVM target compatibility
5. ✓ Build cache cleanup
6. ✓ Gradle configuration validation

---

**Time to fix:** ~2-3 minutes  
**Works on:** Linux, macOS, WSL
