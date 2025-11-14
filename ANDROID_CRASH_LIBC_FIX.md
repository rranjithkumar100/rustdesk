# Fix: App Crashes with "libc++_shared.so not found"

## 🚨 Problem Description

After successfully installing the RustDesk Android APK, the app crashes immediately on launch with:

```
FATAL EXCEPTION: main
java.lang.UnsatisfiedLinkError: dlopen failed: library "libc++_shared.so" not found: 
needed by /data/app/.../librustdesk.so in namespace clns-7
```

---

## 🔍 Root Cause

The native Rust library `librustdesk.so` was compiled with dependencies on the **C++ Standard Template Library (STL)** `libc++_shared.so`, but this shared library is **not being packaged** in the APK.

When the app tries to load `librustdesk.so` at runtime, it cannot find the required `libc++_shared.so` dependency, causing the crash.

### Why This Happens:

1. **Rust + C++ Dependencies**: The Rust code uses FFI (Foreign Function Interface) to interact with C++ libraries
2. **Dynamic Linking**: The Rust library is dynamically linked against the C++ STL
3. **Missing in APK**: The Android build process doesn't automatically include NDK shared libraries
4. **Runtime Failure**: Android's dynamic linker (`dlopen`) fails to load the library

---

## ✅ Solution

### Quick Fix (Automated)

We've created a script to automatically copy the required NDK libraries:

```bash
cd /workspace/flutter
./copy_ndk_libs.sh
```

This script will:
1. Detect your NDK installation
2. Copy `libc++_shared.so` to `android/app/src/main/jniLibs/` for all architectures
3. Verify the files are in place

### Then rebuild the APK:

```bash
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release
```

---

## 🛠️ Manual Fix Steps

### Step 1: Locate NDK Libraries

Find the `libc++_shared.so` in your NDK installation:

```bash
# Set NDK path (if not already set)
export ANDROID_NDK_HOME="$HOME/android-sdk/ndk/25.1.8937393"

# Find libc++_shared.so
find $ANDROID_NDK_HOME -name "libc++_shared.so"
```

Expected locations:
- **arm64-v8a**: `$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so`
- **armeabi-v7a**: `$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so`

### Step 2: Create jniLibs Directory Structure

```bash
cd /workspace/flutter
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
```

### Step 3: Copy NDK Libraries

```bash
# Copy for arm64-v8a
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/

# Copy for armeabi-v7a
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so \
   android/app/src/main/jniLibs/armeabi-v7a/
```

### Step 4: Update build.gradle (Already Done)

The `flutter/android/app/build.gradle` has been updated with:

```gradle
android {
    defaultConfig {
        // ... other config ...
        
        ndk {
            // Specify ABIs to include in the APK
            abiFilters 'arm64-v8a', 'armeabi-v7a'
        }
    }
    
    // Package NDK shared libraries (including libc++_shared.so)
    packagingOptions {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}
```

### Step 5: Verify Files Are in Place

```bash
ls -lh android/app/src/main/jniLibs/arm64-v8a/
# Should show: libc++_shared.so and librustdesk.so

ls -lh android/app/src/main/jniLibs/armeabi-v7a/
# Should show: libc++_shared.so (and librustdesk.so if building for armv7)
```

### Step 6: Clean and Rebuild

```bash
cd /workspace/flutter
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release
```

---

## 📋 Directory Structure

After applying the fix, your jniLibs directory should look like:

```
flutter/android/app/src/main/jniLibs/
├── arm64-v8a/
│   ├── libc++_shared.so    (from NDK)
│   └── librustdesk.so       (from cargo build)
└── armeabi-v7a/
    ├── libc++_shared.so    (from NDK)
    └── librustdesk.so       (from cargo build, if applicable)
```

---

## 🔧 Technical Details

### What is libc++_shared.so?

`libc++_shared.so` is the **LLVM C++ Standard Library** used by the Android NDK. It provides:
- C++ standard library functions (std::string, std::vector, etc.)
- Exception handling
- RTTI (Run-Time Type Information)
- Memory management

### Why Shared vs Static Linking?

| Type | Pros | Cons |
|------|------|------|
| **Shared** (`.so`) | Smaller APK size, shared across apps | Requires runtime library |
| **Static** (linked in) | Self-contained, no dependencies | Larger binary size |

RustDesk uses **shared linking** to keep the APK size reasonable while using C++ dependencies.

### NDK Configuration Options

The `ndk { }` block in build.gradle controls:
- **abiFilters**: Which CPU architectures to support
- Common values: `'arm64-v8a'` (64-bit), `'armeabi-v7a'` (32-bit), `'x86_64'`, `'x86'`

The `packagingOptions` block controls:
- **useLegacyPackaging**: How native libraries are stored in APK
- **true**: Uncompressed (faster loading, larger APK)
- **false**: Compressed (smaller APK, slower loading)

---

## 🐛 Troubleshooting

### Error: "libc++_shared.so not found in NDK"

**Solution:** Ensure NDK is installed:
```bash
# Check NDK installation
ls $HOME/android-sdk/ndk

# Install NDK if missing (using sdkmanager)
sdkmanager "ndk;25.1.8937393"
```

### Error: "No such file or directory" when copying

**Solution:** Use the correct NDK path:
```bash
# Find your NDK version
ls $HOME/android-sdk/ndk

# Update ANDROID_NDK_HOME
export ANDROID_NDK_HOME="$HOME/android-sdk/ndk/[YOUR_VERSION]"
```

### APK Still Crashes After Fix

**Checklist:**
1. Verify `libc++_shared.so` is in the APK:
   ```bash
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep libc++
   # Should show: lib/arm64-v8a/libc++_shared.so
   ```

2. Verify file was copied correctly:
   ```bash
   ls -lh android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
   # Should show file size ~1-2 MB
   ```

3. Clean rebuild:
   ```bash
   flutter clean
   rm -rf android/.gradle
   rm -rf ~/.gradle/caches
   flutter build apk --target-platform android-arm64 --release
   ```

4. Uninstall old APK first:
   ```bash
   adb uninstall com.carriez.flutter_hbb
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Different Error: "dlopen failed: cannot locate symbol"

This indicates a **symbol mismatch** between the Rust library and C++ STL version.

**Solution:**
1. Ensure Rust library was built with the same NDK version
2. Rebuild the Rust library:
   ```bash
   cd /workspace
   cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter
   ```

---

## 📊 File Sizes (Reference)

Expected file sizes:
- `libc++_shared.so` (arm64-v8a): ~1.5 MB
- `libc++_shared.so` (armeabi-v7a): ~1.2 MB
- `librustdesk.so` (arm64-v8a): ~25-30 MB

Total APK size increase: ~1.5-2 MB

---

## 🔗 Related Documentation

- [ANDROID_INVALID_PACKAGE_FIX.md](./ANDROID_INVALID_PACKAGE_FIX.md) - Fix installation issues
- [ANDROID_BUILD_README.md](./ANDROID_BUILD_README.md) - Complete build guide
- [NDK Documentation](https://developer.android.com/ndk/guides) - Official Android NDK docs

---

## 📝 Build Configuration Changes

### Modified Files:

1. **`flutter/android/app/build.gradle`**
   - Added `ndk { abiFilters }` configuration
   - Added `packagingOptions { jniLibs }` configuration

2. **`flutter/copy_ndk_libs.sh`** (NEW)
   - Automated script to copy NDK libraries

3. **`flutter/android/app/src/main/jniLibs/`** (Directory structure)
   - Contains native libraries for each architecture

---

## ✅ Verification Steps

After applying the fix, verify:

1. **Libraries copied:**
   ```bash
   ls -la flutter/android/app/src/main/jniLibs/arm64-v8a/
   # Should show: libc++_shared.so, librustdesk.so
   ```

2. **Build succeeds:**
   ```bash
   flutter build apk --target-platform android-arm64 --release
   # Should complete without errors
   ```

3. **Libraries in APK:**
   ```bash
   unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "lib/arm64-v8a"
   # Should show: libc++_shared.so, librustdesk.so, libflutter.so
   ```

4. **App launches successfully:**
   ```bash
   adb uninstall com.carriez.flutter_hbb
   adb install build/app/outputs/flutter-apk/app-release.apk
   adb logcat | grep rustdesk
   # Should show app starting without UnsatisfiedLinkError
   ```

---

## 🎉 Expected Result

After applying this fix:
- ✅ APK includes `libc++_shared.so` for target architectures
- ✅ `librustdesk.so` can load successfully at runtime
- ✅ App launches without crashing
- ✅ All native functionality works correctly

---

**Last Updated:** 2025-11-14  
**Status:** ✅ Fixed and Documented  
**Branch:** `cursor/check-for-invalid-app-package-installation-57d7`
