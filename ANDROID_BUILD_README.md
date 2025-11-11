# RustDesk Android Build Guide - Complete Setup Instructions

## 📱 Android Build - Quick Start Guide

This guide provides **step-by-step commands** to build RustDesk for Android from a clean Ubuntu environment.

---

## 🎯 Verified Working Configuration

- **Flutter:** 3.24.5 (stable)
- **Java:** OpenJDK 17 LTS
- **Gradle:** 8.5
- **Android Gradle Plugin:** 8.1.1
- **Kotlin:** 1.9.22
- **Min Android Version:** 6.0 (API 23)
- **Target Architecture:** arm64-v8a

---

## 📋 Prerequisites

- Ubuntu 22.04 LTS or 24.04 LTS (or compatible Linux)
- At least 20GB free disk space
- Internet connection for downloading dependencies
- `git` installed

---

## 🚀 Complete Build Instructions

### Step 1: Install System Dependencies

```bash
# Update system
sudo apt-get update

# Install build essentials
sudo apt-get install -y \
  build-essential \
  gcc \
  g++ \
  libstdc++-12-dev \
  pkg-config \
  libssl-dev \
  cmake \
  nasm \
  yasm \
  autoconf \
  automake \
  libtool \
  curl \
  wget \
  unzip \
  git

# Install Java 17 LTS (Required for Gradle)
sudo apt-get install -y openjdk-17-jdk

# Set Java 17 as default
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java

# Verify Java version
java --version
# Should show: openjdk 17.0.x
```

---

### Step 2: Install Flutter 3.24.5 (Stable)

```bash
# Clone Flutter SDK
cd $HOME
git clone https://github.com/flutter/flutter.git -b stable flutter-sdk

# Checkout specific stable version
cd $HOME/flutter-sdk
git checkout 3.24.5

# Add Flutter to PATH (temporary for current session)
export PATH="$HOME/flutter-sdk/bin:$PATH"

# Add to shell profile for permanent use
echo 'export PATH="$HOME/flutter-sdk/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify Flutter installation
flutter --version
# Should show: Flutter 3.24.5 • Dart 3.5.4
```

---

### Step 3: Install Android SDK

```bash
# Create Android SDK directory
mkdir -p $HOME/android-sdk
cd $HOME/android-sdk

# Download Android Command Line Tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

# Extract and organize
unzip commandlinetools-linux-11076708_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
rm commandlinetools-linux-11076708_latest.zip

# Set environment variables (temporary)
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

# Add to shell profile (permanent)
cat >> ~/.bashrc << 'EOF'
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
EOF
source ~/.bashrc

# Accept Android licenses
yes | sdkmanager --licenses

# Install required Android SDK components
sdkmanager "platform-tools" \
           "platforms;android-34" \
           "platforms;android-33" \
           "platforms;android-32" \
           "platforms;android-31" \
           "build-tools;34.0.0" \
           "build-tools;33.0.1" \
           "ndk;25.1.8937393"

# Configure Flutter to use Android SDK
flutter config --android-sdk $ANDROID_HOME
flutter doctor --android-licenses

# Verify setup
flutter doctor -v
# Android toolchain should show ✓
```

---

### Step 4: Install Rust Toolchain

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Verify Rust installation
rustc --version
cargo --version

# Install cargo-ndk (for Android builds)
cargo install cargo-ndk --version 3.5.4

# Add Android targets
rustup target add aarch64-linux-android \
                  armv7-linux-androideabi \
                  x86_64-linux-android \
                  i686-linux-android

# Verify targets installed
rustup target list --installed | grep android
```

---

### Step 5: Install vcpkg (for C++ dependencies)

```bash
# Clone vcpkg
cd $HOME
git clone https://github.com/Microsoft/vcpkg.git

# Bootstrap vcpkg
cd $HOME/vcpkg
./bootstrap-vcpkg.sh

# Set environment variable (temporary)
export VCPKG_ROOT=$HOME/vcpkg

# Add to shell profile (permanent)
echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.bashrc
source ~/.bashrc

# Verify vcpkg
$VCPKG_ROOT/vcpkg version
```

---

### Step 6: Install Flutter-Rust Bridge Codegen

```bash
# Install Flutter Rust Bridge code generator
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid

# Verify installation
flutter_rust_bridge_codegen --version
```

---

### Step 7: Clone RustDesk Repository

```bash
# Clone your RustDesk fork
cd $HOME
git clone https://github.com/YOUR_USERNAME/rustdesk.git
cd rustdesk

# Initialize git submodules (IMPORTANT!)
git submodule update --init --recursive

# Verify hbb_common submodule exists
ls -la libs/hbb_common/
# Should show files, not empty
```

---

### Step 8: Build vcpkg Dependencies (One-time setup)

```bash
# Navigate to flutter directory
cd $HOME/rustdesk/flutter

# Set required environment variables
export VCPKG_ROOT=$HOME/vcpkg
export ANDROID_NDK_HOME=$HOME/android-sdk/ndk/25.1.8937393
export ANDROID_NDK=$ANDROID_NDK_HOME

# Build vcpkg dependencies for arm64-v8a (takes 5-10 minutes)
bash build_android_deps.sh arm64-v8a

# Expected output: "*** [arm64-v8a][Finished] Build and install vcpkg dependencies"
```

**Note:** If you need to build for other architectures:
```bash
# For armeabi-v7a (32-bit ARM)
bash build_android_deps.sh armeabi-v7a

# For x86_64 (64-bit emulator)
bash build_android_deps.sh x86_64
```

---

### Step 9: Generate Flutter-Rust Bridge

```bash
# Navigate to workspace root
cd $HOME/rustdesk

# Generate bridge files
flutter_rust_bridge_codegen \
  --rust-input src/flutter_ffi.rs \
  --dart-output flutter/lib/generated_bridge.dart \
  --c-output flutter/macos/Runner/bridge_generated.h

# Verify files generated
ls -l flutter/lib/generated_bridge.dart
ls -l src/bridge_generated.rs
```

---

### Step 10: Build Rust Native Library

```bash
# Navigate to workspace root
cd $HOME/rustdesk

# Set environment variables
export VCPKG_ROOT=$HOME/vcpkg
export ANDROID_NDK_HOME=$HOME/android-sdk/ndk/25.1.8937393
export ANDROID_NDK=$ANDROID_NDK_HOME
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot"

# Build Rust library for arm64-v8a (takes 2-3 minutes)
cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter

# Verify library built successfully
ls -lh target/aarch64-linux-android/release/liblibrustdesk.so
# Should show ~26-27 MB file
```

**For other architectures:**
```bash
# For armeabi-v7a (32-bit ARM)
cargo ndk --platform 21 --target armv7-linux-androideabi build --release --features flutter

# For x86_64 (emulator)
cargo ndk --platform 21 --target x86_64-linux-android build --release --features flutter
```

---

### Step 11: Copy Native Library to Flutter Project

```bash
# Create jniLibs directory structure
mkdir -p $HOME/rustdesk/flutter/android/app/src/main/jniLibs/arm64-v8a

# Copy Rust library
cp $HOME/rustdesk/target/aarch64-linux-android/release/liblibrustdesk.so \
   $HOME/rustdesk/flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# Verify copy
ls -lh $HOME/rustdesk/flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
```

**For other architectures:**
```bash
# For armeabi-v7a
mkdir -p flutter/android/app/src/main/jniLibs/armeabi-v7a
cp target/armv7-linux-androideabi/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/armeabi-v7a/librustdesk.so

# For x86_64
mkdir -p flutter/android/app/src/main/jniLibs/x86_64
cp target/x86_64-linux-android/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/x86_64/librustdesk.so
```

---

### Step 12: Build Flutter APK

```bash
# Navigate to Flutter directory
cd $HOME/rustdesk/flutter

# Set environment variables
export PATH="$HOME/flutter-sdk/bin:$PATH"
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Get Flutter dependencies
flutter pub get

# Build APK for arm64-v8a (takes 1-2 minutes)
flutter build apk \
  --target-platform android-arm64 \
  --release \
  --android-skip-build-dependency-validation

# Build successful! APK location:
# $HOME/rustdesk/flutter/build/app/outputs/flutter-apk/app-release.apk
```

**Build options:**
```bash
# Build for all architectures (separate APKs)
flutter build apk --split-per-abi --release

# Build App Bundle for Google Play Store
flutter build appbundle --release

# Build debug version for testing
flutter build apk --debug
```

---

### Step 13: Locate and Test APK

```bash
# Find your APK
ls -lh $HOME/rustdesk/flutter/build/app/outputs/flutter-apk/

# Expected files:
# app-release.apk          (~51 MB for arm64-v8a)
# or
# app-arm64-v8a-release.apk
# app-armeabi-v7a-release.apk
# app-x86_64-release.apk   (if built with --split-per-abi)

# Copy APK to easily accessible location
cp $HOME/rustdesk/flutter/build/app/outputs/flutter-apk/app-release.apk \
   $HOME/rustdesk-android.apk

echo "✅ APK ready: $HOME/rustdesk-android.apk"
```

---

## 🔄 How to Downgrade/Change Flutter Version

### Switching to a Specific Flutter Version

```bash
# Navigate to Flutter SDK directory
cd $HOME/flutter-sdk

# Fetch all available versions
git fetch --all --tags

# List all stable versions
git tag | grep -E "^[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -20

# Checkout specific version (e.g., 3.24.5)
git checkout 3.24.5

# Verify version
flutter --version

# Clean Flutter cache
flutter clean
rm -rf $HOME/.pub-cache

# Re-run Flutter doctor
flutter doctor -v
```

### Common Stable Versions for Enterprise:
```bash
# Flutter 3.24.5 (Recommended - Used in this build)
git checkout 3.24.5

# Flutter 3.22.3 (Previous stable)
git checkout 3.22.3

# Flutter 3.19.6 (Older stable)
git checkout 3.19.6

# Flutter 3.16.9 (LTS-like)
git checkout 3.16.9

# Flutter 3.13.9 (Older LTS-like)
git checkout 3.13.9
```

---

## 🧹 Clean Installation / Reset Build Environment

### Complete Clean Build (Start Fresh)

```bash
# 1. Clean Flutter build artifacts
cd $HOME/rustdesk/flutter
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf android/.gradle
rm -rf android/app/build
rm -rf android/build

# 2. Clean Rust build artifacts
cd $HOME/rustdesk
cargo clean

# 3. Clean vcpkg packages (if you want to rebuild from scratch)
rm -rf $HOME/vcpkg/installed/arm64-android
rm -rf $HOME/vcpkg/installed/x64-linux
rm -rf $HOME/vcpkg/buildtrees

# 4. Clean Flutter pub cache
flutter pub cache clean
rm -rf $HOME/.pub-cache

# 5. Clean Gradle cache (if issues persist)
rm -rf $HOME/.gradle/caches

# 6. Now rebuild from Step 8 onwards
cd $HOME/rustdesk/flutter
bash build_android_deps.sh arm64-v8a
# Continue with steps 9-12
```

### Quick Clean (Between Builds)

```bash
# Clean Flutter only
cd $HOME/rustdesk/flutter
flutter clean
rm -rf android/.gradle

# Get dependencies fresh
flutter pub get

# Rebuild APK
flutter build apk --target-platform android-arm64 --release
```

### Clean and Rebuild Native Library Only

```bash
# Clean Rust build
cd $HOME/rustdesk
cargo clean

# Rebuild Rust library
export ANDROID_NDK_HOME=$HOME/android-sdk/ndk/25.1.8937393
export BINDGEN_EXTRA_CLANG_ARGS="--sysroot=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot"
cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter

# Copy to Flutter
cp target/aarch64-linux-android/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# Rebuild Flutter APK
cd flutter
flutter build apk --target-platform android-arm64 --release
```

---

## 🐛 Troubleshooting

### Issue: "Unsupported class file major version 65"
**Solution:** You're using Java 21, need Java 17:
```bash
sudo apt-get install openjdk-17-jdk
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java
java --version  # Should show 17.x
```

### Issue: "Could not find directory of OpenSSL"
**Solution:** Install OpenSSL development libraries:
```bash
sudo apt-get install -y libssl-dev pkg-config
```

### Issue: "cannot find -lstdc++"
**Solution:** Install C++ standard library:
```bash
sudo apt-get install -y libstdc++-12-dev g++ gcc build-essential
```

### Issue: "namespace not specified"
**Solution:** This is expected with AGP 8.x. Add to plugin build.gradle:
```gradle
android {
    namespace "your.package.name"
    // ... rest of config
}
```

### Issue: "Inconsistent JVM Target Compatibility"
**Solution:** Add kotlinOptions to build.gradle:
```gradle
android {
    // ... other config
    kotlinOptions {
        jvmTarget = "1.8"
    }
}
```

### Issue: Flutter doctor shows Android toolchain issues
**Solution:** Run these commands:
```bash
flutter config --android-sdk $HOME/android-sdk
flutter doctor --android-licenses
flutter doctor -v
```

### Issue: "No connected devices"
**For physical device:**
```bash
# Enable USB debugging on Android device
# Connect via USB
adb devices  # Should show your device
flutter devices
```

**For emulator:**
```bash
# Create and start emulator via Android Studio
# Or use command line:
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  -n test -k "system-images;android-33;google_apis;x86_64"
$ANDROID_HOME/emulator/emulator -avd test &
```

---

## 📊 Build Time Expectations

- **Initial vcpkg build:** 5-10 minutes (one-time)
- **Rust compilation:** 2-3 minutes (first time), 30-60s (incremental)
- **Flutter APK build:** 60-90 seconds
- **Total first build:** ~15-20 minutes
- **Subsequent builds:** ~2-3 minutes

---

## 📦 Output Files

After successful build:

```
$HOME/rustdesk/flutter/build/app/outputs/flutter-apk/
├── app-release.apk                    (51 MB - all included architectures)
└── app-arm64-v8a-release.apk         (if using --split-per-abi)
```

**APK Contents:**
- `libapp.so` - Flutter engine (~12 MB)
- `libflutter.so` - Flutter framework (~11 MB)  
- `librustdesk.so` - RustDesk native library (~27 MB)
- Dart code and assets (~1 MB)

---

## ✅ Verification Checklist

Before building, verify:

```bash
# Java version
java --version | grep "17.0"

# Flutter version  
flutter --version | grep "3.24.5"

# Android SDK
ls $ANDROID_HOME/platforms/ | grep android-34

# NDK
ls $ANDROID_HOME/ndk/ | grep "25.1"

# Rust targets
rustup target list --installed | grep aarch64-linux-android

# vcpkg
ls $HOME/vcpkg/vcpkg

# Submodules
ls $HOME/rustdesk/libs/hbb_common/Cargo.toml
```

All commands should return results. If any fail, revisit that installation step.

---

## 🎯 Quick Reference Commands

```bash
# Environment setup (run before each build session)
export PATH="$HOME/flutter-sdk/bin:$PATH"
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export VCPKG_ROOT=$HOME/vcpkg
export ANDROID_NDK_HOME=$HOME/android-sdk/ndk/25.1.8937393

# Quick rebuild command
cd $HOME/rustdesk/flutter && \
flutter clean && \
flutter pub get && \
flutter build apk --target-platform android-arm64 --release --android-skip-build-dependency-validation
```

---

## 📞 Support

For issues specific to this build configuration, check:
1. `/workspace/ANDROID_BUILD_ENVIRONMENT.md` - Full environment details
2. Build logs in `/tmp/build_*.log`
3. RustDesk GitHub Issues: https://github.com/rustdesk/rustdesk/issues

---

**Last Updated:** November 9, 2025  
**Tested On:** Ubuntu 24.04 LTS  
**Build Status:** ✅ **WORKING**
