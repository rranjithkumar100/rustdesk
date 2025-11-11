# RustDesk Android - Flutter Developer Setup Guide

> **Target Audience:** Flutter developers (including juniors) who want to build RustDesk Android APK  
> **Estimated Setup Time:** 30-45 minutes (first time)  
> **Prerequisite Knowledge:** Basic terminal/command-line usage

---

## 📋 Table of Contents
1. [Prerequisites Check](#prerequisites-check)
2. [Java Version Setup (CRITICAL)](#java-version-setup)
3. [Flutter Version Downgrade](#flutter-version-downgrade)
4. [Android SDK/NDK Setup](#android-sdkndk-setup)
5. [Rust Toolchain Setup](#rust-toolchain-setup)
6. [vcpkg Setup](#vcpkg-setup)
7. [Clone and Configure Project](#clone-and-configure-project)
8. [Build Process](#build-process)
9. [Common Issues](#common-issues)

---

## Prerequisites Check

Before starting, make sure you have:

- [ ] macOS (Intel or Apple Silicon) or Linux (Ubuntu/Debian)
- [ ] At least 20GB free disk space
- [ ] Stable internet connection
- [ ] Terminal/command-line access
- [ ] Git installed (`git --version`)

---

## Step 1: Java Version Setup (CRITICAL)

⚠️ **IMPORTANT:** You MUST use Java 17. Newer versions (Java 21+) will cause build failures.

### macOS:
```bash
# Install Java 17 via Homebrew
brew install openjdk@17

# Set Java 17 as default
# For Apple Silicon (M1/M2/M3):
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"' >> ~/.zshrc

# For Intel Mac:
echo 'export JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"' >> ~/.zshrc

# Add to PATH
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.zshrc

# Apply changes
source ~/.zshrc

# Verify Java 17 is active
java --version
# Must show: openjdk 17.0.x
```

### Linux (Ubuntu/Debian):
```bash
# Install Java 17
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk

# Set Java 17 as default
sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java

# Add to environment
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
java --version
# Must show: openjdk 17.0.x
```

---

## Step 2: Flutter Version Downgrade

⚠️ **IMPORTANT:** This project requires Flutter 3.24.5 (stable). Latest Flutter versions are NOT compatible.

### If You Already Have Flutter Installed:

```bash
# Navigate to your Flutter directory
cd $HOME/flutter  # or wherever your Flutter SDK is

# Fetch all versions
git fetch --all --tags

# Switch to Flutter 3.24.5
git checkout 3.24.5

# Verify version
flutter --version
# Must show: Flutter 3.24.5 • Dart 3.5.4

# Clean cache
flutter clean
rm -rf $HOME/.pub-cache
```

### If You Don't Have Flutter:

```bash
# Clone Flutter SDK
cd $HOME
git clone https://github.com/flutter/flutter.git -b stable
cd flutter
git checkout 3.24.5

# Add to PATH
# For macOS (zsh):
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For Linux (bash):
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
flutter --version
```

---

## Step 3: Android SDK/NDK Setup

### macOS:

```bash
# Install Android Studio (easiest way)
# Download from: https://developer.android.com/studio
# Or use Homebrew:
brew install --cask android-studio

# Set environment variables
echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.zshrc
echo 'export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"' >> ~/.zshrc
echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Install required components via Android Studio SDK Manager:
# - Android SDK Platform 34
# - Android SDK Build-Tools 34.0.0
# - NDK (Side by side) version 25.1.8937393

# Configure Flutter
flutter config --android-sdk $ANDROID_HOME
flutter doctor --android-licenses  # Accept all licenses
```

### Linux:

```bash
# Create SDK directory
mkdir -p $HOME/android-sdk
cd $HOME/android-sdk

# Download command-line tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true

# Set environment variables
echo 'export ANDROID_HOME=$HOME/android-sdk' >> ~/.bashrc
echo 'export ANDROID_SDK_ROOT=$ANDROID_HOME' >> ~/.bashrc
echo 'export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc

# Accept licenses
yes | sdkmanager --licenses

# Install required components
sdkmanager "platform-tools" \
           "platforms;android-34" \
           "platforms;android-33" \
           "build-tools;34.0.0" \
           "ndk;25.1.8937393"

# Configure Flutter
flutter config --android-sdk $ANDROID_HOME
flutter doctor --android-licenses
```

---

## Step 4: Rust Toolchain Setup

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

## Step 5: vcpkg Setup

vcpkg is required for C++ dependencies (libvpx, opus, aom, etc.).

### macOS:

```bash
# Clone vcpkg
cd $HOME
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh

# Set environment variable
echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.zshrc
source ~/.zshrc

# Verify
$VCPKG_ROOT/vcpkg version
```

### Linux:

```bash
# Install build dependencies first
sudo apt-get update
sudo apt-get install -y build-essential gcc g++ cmake \
  nasm yasm pkg-config autoconf automake libtool \
  libssl-dev curl wget unzip git

# Clone vcpkg
cd $HOME
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh

# Set environment variable
echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.bashrc
source ~/.bashrc

# Verify
$VCPKG_ROOT/vcpkg version
```

---

## Step 6: Clone and Configure Project

```bash
# Clone RustDesk repository
cd $HOME
git clone https://github.com/YOUR_USERNAME/rustdesk.git
cd rustdesk

# IMPORTANT: Initialize git submodules
git submodule update --init --recursive

# Verify submodule loaded
ls -la libs/hbb_common/
# Should show files, not empty

# Install Flutter-Rust Bridge code generator
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
```

---

## Step 7: Configure Gradle for Java 17 (macOS Only)

This forces Gradle to use Java 17 instead of Android Studio's embedded JDK.

```bash
cd $HOME/rustdesk/flutter/android

# Find your Java 17 path
JAVA17_PATH=$(/usr/libexec/java_home -v 17)

# Add to gradle.properties
echo "org.gradle.java.home=$JAVA17_PATH" >> gradle.properties

# Verify it was added
cat gradle.properties | grep "java.home"
```

---

## Step 8: Build Process

Now you're ready to build! Follow these steps in order:

### 8.1: Generate Flutter-Rust Bridge

```bash
cd $HOME/rustdesk

flutter_rust_bridge_codegen \
  --rust-input src/flutter_ffi.rs \
  --dart-output flutter/lib/generated_bridge.dart \
  --c-output flutter/macos/Runner/bridge_generated.h

# Verify files generated
ls -l src/bridge_generated.rs
ls -l flutter/lib/generated_bridge.dart
```

### 8.2: Build vcpkg Dependencies (One-time, takes 5-10 minutes)

```bash
cd $HOME/rustdesk/flutter

# Build for arm64-v8a (64-bit ARM - most common)
bash build_android_deps.sh arm64-v8a

# Wait for: "*** [arm64-v8a][Finished] Build and install vcpkg dependencies"
```

### 8.3: Build Rust Library

```bash
cd $HOME/rustdesk

# Build library only (not binaries - they have linking issues)
cargo ndk --platform 21 --target aarch64-linux-android build --release --lib --features flutter

# Wait for compilation (takes 2-3 minutes first time)
# Verify library exists
ls -lh target/aarch64-linux-android/release/liblibrustdesk.so
# Should show ~26-27 MB file
```

### 8.4: Copy Native Library to Flutter

```bash
cd $HOME/rustdesk

# Create jniLibs directory
mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a

# Copy Rust library
cp target/aarch64-linux-android/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# Verify
ls -lh flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
```

### 8.5: Fix Flutter Plugins (REQUIRED for macOS)

This script fixes namespace issues with Flutter plugins for Android Gradle Plugin 8+.

```bash
cd $HOME/rustdesk/flutter

# Run the automated fix script
bash fix_android_plugins_macos.sh

# Wait for: "✅ All plugin fixes applied!"
```

### 8.6: Clean and Prepare Flutter

```bash
cd $HOME/rustdesk/flutter

# Clean Gradle cache (important!)
rm -rf ~/.gradle/caches

# Clean Flutter build
flutter clean

# Get dependencies
flutter pub get

# Wait for: "Got dependencies!"
```

### 8.7: Build APK

```bash
cd $HOME/rustdesk/flutter

# Build release APK
flutter build apk --target-platform android-arm64 --release

# Wait for build to complete (1-2 minutes)
```

### 8.8: Locate Your APK

```bash
# APK location:
ls -lh build/app/outputs/flutter-apk/app-release.apk

# Size should be ~50-55 MB
```

---

## Step 9: Quick Rebuild Script

After the initial setup, use this script for faster rebuilds:

### Save as `rebuild_android.sh`:

```bash
#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🔨 Rebuilding RustDesk Android..."

# Rebuild Rust if needed
if [ ! -f "flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so" ]; then
    echo "📦 Building Rust library..."
    cargo ndk --platform 21 --target aarch64-linux-android build --release --lib --features flutter
    mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
    cp target/aarch64-linux-android/release/liblibrustdesk.so \
       flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
fi

# Build Flutter APK
cd flutter
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release

echo ""
echo "✅ Build complete!"
echo "📱 APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
```

Make it executable and run:

```bash
chmod +x rebuild_android.sh
./rebuild_android.sh
```

---

## Common Issues

### Issue 1: "Flutter not found" or wrong version

**Solution:**
```bash
# Verify Flutter path
which flutter

# Check version
flutter --version

# If wrong version:
cd $HOME/flutter
git checkout 3.24.5
flutter clean
```

### Issue 2: "java: error: invalid target release: 17"

**Cause:** Wrong Java version active

**Solution:**
```bash
# Check current Java
java --version

# If not 17, reinstall and set:
# macOS:
brew install openjdk@17
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

# Linux:
sudo apt-get install openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Issue 3: "Namespace not specified" errors

**Solution:**
```bash
cd flutter
bash fix_android_plugins_macos.sh
rm -rf ~/.gradle/caches
flutter clean
```

### Issue 4: "file not found for module `bridge_generated`"

**Solution:**
```bash
flutter_rust_bridge_codegen \
  --rust-input src/flutter_ffi.rs \
  --dart-output flutter/lib/generated_bridge.dart \
  --c-output flutter/macos/Runner/bridge_generated.h
```

### Issue 5: "Could not find directory of OpenSSL"

**Solution (Linux only):**
```bash
sudo apt-get install -y libssl-dev pkg-config
```

### Issue 6: Build takes too long (>15 minutes)

**Solutions:**
- First build always takes longer (10-15 min)
- Use `cargo clean` less frequently
- Don't run `flutter clean` unless necessary
- Use ccache (macOS): `brew install ccache`

---

## 🎯 Quick Reference - Environment Variables

Add these to your shell profile (`~/.zshrc` for macOS, `~/.bashrc` for Linux):

### macOS (Apple Silicon):
```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export VCPKG_ROOT="$HOME/vcpkg"
```

### macOS (Intel):
```bash
export JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
export VCPKG_ROOT="$HOME/vcpkg"
```

### Linux:
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="$JAVA_HOME/bin:$PATH"
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME=$HOME/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
export VCPKG_ROOT=$HOME/vcpkg
```

---

## ✅ Verification Checklist

Before building, verify everything is correct:

```bash
# Java 17
java --version | grep "17.0"

# Flutter 3.24.5
flutter --version | grep "3.24.5"

# Android SDK
ls $ANDROID_HOME/platforms/ | grep android-34

# NDK
ls $ANDROID_HOME/ndk/ | grep "25.1"

# Rust
rustc --version
cargo --version

# Rust Android targets
rustup target list --installed | grep aarch64-linux-android

# vcpkg
$VCPKG_ROOT/vcpkg version

# Submodules
ls libs/hbb_common/Cargo.toml  # Should exist
```

All commands should return results. If any fail, revisit that setup section.

---

## 📊 Build Time Expectations

- **Initial setup:** 30-45 minutes
- **First build:** 15-20 minutes
  - vcpkg dependencies: 5-10 min
  - Rust compilation: 3-5 min
  - Flutter APK build: 2-3 min
- **Incremental builds:** 2-3 minutes
  - Rust changes only: 30-60 sec
  - Flutter changes only: 30-60 sec

---

## 🎓 For Team Leads / Seniors

**Onboarding new developers? Share this checklist:**

1. Clone this repo
2. Read `FLUTTER_DEVELOPER_SETUP_GUIDE.md` (this file)
3. Follow steps 1-8 exactly as written
4. Run verification checklist before first build
5. Common issues? Check section 9 first
6. Still stuck? Check these files:
   - `ANDROID_BUILD_README.md` (Linux detailed guide)
   - `MACOS_ANDROID_BUILD.md` (macOS detailed guide)
   - `ANDROID_BUILD_ENVIRONMENT.md` (Environment reference)

---

## 📞 Getting Help

If you encounter issues not covered here:

1. Check existing documentation:
   - `ANDROID_BUILD_README.md` - Linux build guide
   - `MACOS_ANDROID_BUILD.md` - macOS build guide
   - `ANDROID_BUILD_ENVIRONMENT.md` - Environment details

2. Run Flutter doctor:
   ```bash
   flutter doctor -v
   ```

3. Check Gradle logs:
   ```bash
   cd flutter/android
   ./gradlew assembleRelease --stacktrace
   ```

4. Verify Java version:
   ```bash
   java --version  # Must be 17.0.x
   echo $JAVA_HOME  # Must point to Java 17
   ```

---

**Last Updated:** November 10, 2025  
**Flutter Version:** 3.24.5 (stable)  
**Java Version:** OpenJDK 17 (LTS)  
**Build Status:** ✅ **WORKING**

---

## 🎉 Success!

Once you see:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (XX.XMB).
```

**Congratulations!** You've successfully built the RustDesk Android APK. 🚀

Install on device:
```bash
adb install flutter/build/app/outputs/flutter-apk/app-release.apk
```
