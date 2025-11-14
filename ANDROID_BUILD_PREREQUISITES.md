# Android Build Prerequisites - Critical Information

## 🚨 **IMPORTANT: You Cannot Build Android APK Without These**

The crash you're experiencing (`libc++_shared.so not found`) is because **the APK was built without the required native libraries**. This happened because the build environment is incomplete.

---

## ❌ Current Problem

Your APK crashes because it's **missing critical files**:

```
android/app/src/main/jniLibs/arm64-v8a/
├── librustdesk.so       ❌ MISSING (Rust native library)
└── libc++_shared.so     ❌ MISSING (C++ STL library)
```

When Flutter builds the APK, it packages whatever is in the `jniLibs` directory. If these files are missing, the APK won't have them, and the app will crash.

---

## ✅ Required Prerequisites

To build a working RustDesk Android APK, you **MUST** have:

### 1. **Android NDK** (Native Development Kit)
**Status on your system:** ❌ **NOT INSTALLED**

**Why you need it:**
- Provides `libc++_shared.so` (C++ Standard Library)
- Required for cross-compiling Rust to Android
- Used by cargo-ndk toolchain

**How to install:**
```bash
# Option A: Using sdkmanager (if Android SDK is installed)
sdkmanager "ndk;25.1.8937393"

# Option B: Manual download
# Download from: https://developer.android.com/ndk/downloads
# Extract to: $HOME/android-sdk/ndk/25.1.8937393
# Set: export ANDROID_NDK_HOME=$HOME/android-sdk/ndk/25.1.8937393
```

### 2. **Rust Toolchain with Android Target**
**Status on your system:** ✅ Cargo installed, but **Android target not configured**

**Why you need it:**
- Builds `librustdesk.so` from Rust source code
- Cross-compiles Rust to ARM64 Android

**How to setup:**
```bash
# Add Android target
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi

# Install cargo-ndk (for Android cross-compilation)
cargo install cargo-ndk
```

### 3. **Build Rust Library BEFORE Flutter Build**
**Status:** ❌ **NOT DONE** - No `librustdesk.so` found

**Why you need it:**
- The Flutter app loads Rust code via JNI
- Must be built and placed in `jniLibs/` before Flutter build

**How to build:**
```bash
cd /workspace

# Build for ARM64 (64-bit Android)
cargo ndk --platform 21 --target aarch64-linux-android \
  build --release --features flutter

# The output will be at:
# target/aarch64-linux-android/release/liblibrustdesk.so
```

### 4. **Copy Libraries to jniLibs Directory**
**Status:** ❌ **NOT DONE** - `jniLibs/` directory doesn't exist

**Why you need it:**
- Flutter packages whatever is in `android/app/src/main/jniLibs/`
- Both `librustdesk.so` and `libc++_shared.so` must be there

**How to do it:**
```bash
cd /workspace/flutter

# Create directories
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Copy Rust library
cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# Copy C++ STL (requires NDK)
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/
```

---

## 📋 Complete Build Process (Step-by-Step)

### Prerequisites Check

```bash
# 1. Check Rust
rustup --version
rustup target list | grep android

# 2. Check NDK
echo $ANDROID_NDK_HOME
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so

# 3. Check cargo-ndk
cargo ndk --version
```

### Full Build Sequence

```bash
# Step 1: Install prerequisites (if missing)
rustup target add aarch64-linux-android
cargo install cargo-ndk

# Step 2: Set environment variables
export ANDROID_NDK_HOME=$HOME/android-sdk/ndk/25.1.8937393
export ANDROID_SDK_ROOT=$HOME/android-sdk

# Step 3: Build Rust library
cd /workspace
cargo ndk --platform 21 --target aarch64-linux-android \
  build --release --features flutter

# Step 4: Create jniLibs structure
cd /workspace/flutter
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Step 5: Copy native libraries
cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/

# Step 6: Verify files are in place
ls -lh android/app/src/main/jniLibs/arm64-v8a/
# Should show: librustdesk.so (~26MB), libc++_shared.so (~1.5MB)

# Step 7: Build Flutter APK
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release

# Step 8: Verify APK contains libraries
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "lib/arm64-v8a"
# Should show: librustdesk.so, libc++_shared.so, libflutter.so

# Step 9: Install and test
adb uninstall com.carriez.flutter_hbb
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔍 Why Your Current Build Fails

Looking at your error:
```
dlopen failed: library "libc++_shared.so" not found: 
needed by /data/app/.../lib/arm64/librustdesk.so
```

This tells us:
1. ✅ `librustdesk.so` IS in the APK (otherwise it wouldn't try to load it)
2. ❌ `libc++_shared.so` is NOT in the APK
3. ❌ The `jniLibs/` directory was empty when you built the APK

**Root Cause:** You built the Flutter APK without first:
- Building the Rust library
- Copying the NDK C++ library
- Setting up the `jniLibs/` directory

---

## 🛠️ Quick Diagnostic

Run this to check your current state:

```bash
cd /workspace

echo "=== Rust Library Status ==="
ls -lh target/aarch64-linux-android/release/liblibrustdesk.so 2>/dev/null || echo "❌ NOT BUILT"

echo ""
echo "=== jniLibs Status ==="
ls -lh flutter/android/app/src/main/jniLibs/arm64-v8a/ 2>/dev/null || echo "❌ DIRECTORY EMPTY OR MISSING"

echo ""
echo "=== NDK Status ==="
echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"
ls -l $ANDROID_NDK_HOME/toolchains/llvm 2>/dev/null || echo "❌ NDK NOT FOUND"

echo ""
echo "=== APK Status ==="
ls -lh flutter/build/app/outputs/flutter-apk/*.apk 2>/dev/null || echo "No APK built yet"
```

---

## 📱 Alternative: Use Pre-Built Libraries (If Available)

If someone else has already built the Rust library and you just want to test:

1. **Get the pre-built libraries:**
   - `librustdesk.so` (from team member or CI build)
   - `libc++_shared.so` (from NDK)

2. **Place them manually:**
   ```bash
   mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
   cp /path/to/librustdesk.so flutter/android/app/src/main/jniLibs/arm64-v8a/
   cp /path/to/libc++_shared.so flutter/android/app/src/main/jniLibs/arm64-v8a/
   ```

3. **Build APK:**
   ```bash
   cd flutter
   flutter build apk --target-platform android-arm64 --release
   ```

---

## 🚀 Automated Build Scripts

For reference, the project includes these automated build scripts:

- **`flutter/build_fdroid.sh`** - Complete F-Droid build (includes Rust compilation)
- **`flutter/build_android_deps.sh`** - Build C++ dependencies (vcpkg)
- **`flutter/copy_ndk_libs.sh`** - Copy NDK libraries (requires NDK installed)

These scripts expect a **fully configured build environment** as described in:
- [ANDROID_BUILD_README.md](./ANDROID_BUILD_README.md)
- [ANDROID_BUILD_ENVIRONMENT.md](./ANDROID_BUILD_ENVIRONMENT.md)

---

## ✅ Success Criteria

Your build is ready when:

- [ ] NDK is installed and `$ANDROID_NDK_HOME` is set
- [ ] Rust Android targets are installed
- [ ] `cargo-ndk` is installed
- [ ] Rust library is built: `target/aarch64-linux-android/release/liblibrustdesk.so` exists
- [ ] jniLibs directory contains both libraries:
  - `flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so`
  - `flutter/android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so`
- [ ] APK build completes successfully
- [ ] APK contains libraries (verify with `unzip -l`)
- [ ] App installs and launches without crashes

---

## 🔗 Related Documentation

- [ANDROID_BUILD_README.md](./ANDROID_BUILD_README.md) - Complete build guide
- [ANDROID_CRASH_LIBC_FIX.md](./ANDROID_CRASH_LIBC_FIX.md) - Details on the crash issue
- [ANDROID_BUILD_ENVIRONMENT.md](./ANDROID_BUILD_ENVIRONMENT.md) - Working environment reference

---

**Last Updated:** 2025-11-14  
**Status:** 📋 **Build Prerequisites Not Met**

**Action Required:** Install NDK, build Rust library, then rebuild APK.
