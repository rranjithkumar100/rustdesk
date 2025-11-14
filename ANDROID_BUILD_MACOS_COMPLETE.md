# Complete Android Build Guide for macOS

## 🍎 macOS-Specific Build Instructions

This guide provides **copy-paste ready commands** for building RustDesk Android APK on macOS (Intel or Apple Silicon).

---

## 📋 Prerequisites Check

Run this to check what's already installed:

```bash
# Check Homebrew
which brew

# Check Java
java -version

# Check Flutter
flutter --version

# Check Rust
rustup --version
cargo --version

# Check Android SDK/NDK
echo $ANDROID_HOME
echo $ANDROID_NDK_HOME
ls $HOME/Library/Android/sdk/ndk 2>/dev/null || echo "NDK not found"
```

---

## 🚀 Complete Setup (Step-by-Step)

### Step 1: Install Homebrew (if not installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Java 17 LTS

```bash
# Install OpenJDK 17
brew install openjdk@17

# Link it
sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# Verify
java -version
# Should show: openjdk version "17.x.x"
```

### Step 3: Set JAVA_HOME (Apple Silicon)

```bash
# For Apple Silicon (M1/M2/M3)
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# Add to shell profile
echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home' >> ~/.zshrc
source ~/.zshrc
```

**OR for Intel Mac:**

```bash
# For Intel Mac
export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# Add to shell profile
echo 'export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home' >> ~/.zshrc
source ~/.zshrc
```

### Step 4: Install Android Command Line Tools

```bash
# Create Android SDK directory
mkdir -p $HOME/Library/Android/sdk
cd $HOME/Library/Android/sdk

# Download Command Line Tools (macOS)
curl -O https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip

# Extract
unzip commandlinetools-mac-11076708_latest.zip

# Move to correct location
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
mv cmdline-tools/latest/cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true

# Set environment variables
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# Add to shell profile
cat >> ~/.zshrc <<'EOF'
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
EOF

source ~/.zshrc
```

### Step 5: Accept Android SDK Licenses

```bash
yes | sdkmanager --licenses
```

### Step 6: Install Android SDK Components

```bash
# Install required SDK components
sdkmanager "platform-tools" \
  "platforms;android-34" \
  "platforms;android-33" \
  "build-tools;34.0.0" \
  "build-tools;33.0.1" \
  "ndk;25.1.8937393"

# Verify installation
sdkmanager --list_installed
```

### Step 7: Set NDK Environment Variable

```bash
# Set NDK path
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393

# Add to shell profile
echo 'export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393' >> ~/.zshrc
source ~/.zshrc

# Verify
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-*/
```

### Step 8: Install Rust and Android Targets

```bash
# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Add Android targets
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android

# Install cargo-ndk
cargo install cargo-ndk

# Verify
rustup target list | grep android
cargo ndk --version
```

### Step 9: Install Flutter (if not already installed)

```bash
# Download Flutter
cd $HOME
git clone https://github.com/flutter/flutter.git -b stable flutter-sdk

# Add to PATH
export PATH="$HOME/flutter-sdk/bin:$PATH"
echo 'export PATH="$HOME/flutter-sdk/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
flutter --version
flutter doctor
```

---

## 🔨 Build RustDesk APK

### Step 1: Navigate to Project

```bash
cd /workspace
```

### Step 2: Build Rust Library for Android

```bash
# Build for ARM64 (64-bit)
cargo ndk --platform 21 --target aarch64-linux-android \
  build --release --features flutter

# Verify the library was built
ls -lh target/aarch64-linux-android/release/liblibrustdesk.so
# Should show ~25-30 MB file
```

### Step 3: Setup jniLibs Directory

```bash
cd /workspace/flutter

# Create jniLibs directory structure
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/armeabi-v7a

echo "✅ Created jniLibs directories"
```

### Step 4: Copy Native Libraries

```bash
# Copy Rust library (ARM64)
cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# Detect macOS architecture for NDK path
if [[ $(uname -m) == "arm64" ]]; then
  NDK_HOST="darwin-x86_64"  # Even on Apple Silicon, NDK uses x86_64 tools
else
  NDK_HOST="darwin-x86_64"
fi

# Copy libc++_shared.so (ARM64)
cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/${NDK_HOST}/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/

echo "✅ Copied ARM64 libraries"
```

### Step 5: Verify Files

```bash
# Check files are in place
ls -lh android/app/src/main/jniLibs/arm64-v8a/

# Should show:
# librustdesk.so    (~26 MB)
# libc++_shared.so  (~1.5 MB)
```

### Step 6: Fix Flutter Plugins (macOS-specific)

```bash
cd /workspace/flutter

# Run the macOS plugin fix script
bash fix_android_plugins_macos.sh

echo "✅ Fixed Flutter plugins"
```

### Step 7: Clean and Get Dependencies

```bash
# Clean previous builds
flutter clean
rm -rf android/.gradle
rm -rf android/app/build
rm -rf ~/.gradle/caches

# Get Flutter dependencies
flutter pub get

echo "✅ Ready to build"
```

### Step 8: Build APK

```bash
# Build release APK for ARM64
flutter build apk \
  --target-platform android-arm64 \
  --release

# Wait for build to complete (2-3 minutes)
```

### Step 9: Verify APK Contents

```bash
# Check if libraries are in the APK
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "lib/arm64-v8a"

# Should show:
# lib/arm64-v8a/libflutter.so
# lib/arm64-v8a/librustdesk.so
# lib/arm64-v8a/libc++_shared.so
```

### Step 10: Install on Device

```bash
# Uninstall old version (if exists)
adb uninstall com.carriez.flutter_hbb

# Install new APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Launch app
adb shell am start -n com.carriez.flutter_hbb/.MainActivity

# Check for crashes
adb logcat | grep -i "rustdesk\|AndroidRuntime"
```

---

## 🍎 macOS-Specific Notes

### Apple Silicon (M1/M2/M3) Considerations

1. **Rosetta 2**: Not required for Android development
2. **NDK Tools**: Use x86_64 tools (they work on ARM via Rosetta transparently)
3. **Flutter**: Native ARM version works fine
4. **Homebrew**: Install ARM version (automatic on Apple Silicon)

### File Paths on macOS

```bash
# Android SDK
$HOME/Library/Android/sdk/

# NDK
$HOME/Library/Android/sdk/ndk/25.1.8937393/

# NDK Libraries (ARM64)
$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/

# Rust targets
$HOME/.rustup/toolchains/stable-*/lib/rustlib/aarch64-linux-android/

# Flutter SDK
$HOME/flutter-sdk/
```

---

## 🔧 Troubleshooting

### Error: "xcrun: error: invalid active developer path"

```bash
# Install Xcode Command Line Tools
xcode-select --install
```

### Error: "JAVA_HOME not set"

```bash
# Check Java installation
/usr/libexec/java_home -V

# Set JAVA_HOME (Apple Silicon)
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# OR for Intel
export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

### Error: "NDK not found"

```bash
# Verify NDK installation
ls $HOME/Library/Android/sdk/ndk/

# If empty, reinstall
sdkmanager "ndk;25.1.8937393"
```

### Error: "libc++_shared.so not found" when copying

```bash
# Check NDK host architecture
if [[ $(uname -m) == "arm64" ]]; then
  echo "Apple Silicon detected"
else
  echo "Intel Mac detected"
fi

# Check NDK prebuilt directory
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/
# Should show: darwin-x86_64

# Find libc++_shared.so
find $ANDROID_NDK_HOME -name "libc++_shared.so"
```

### APK Still Crashes

```bash
# 1. Verify libraries in jniLibs
ls -lh /workspace/flutter/android/app/src/main/jniLibs/arm64-v8a/

# 2. Verify libraries in built APK
unzip -l /workspace/flutter/build/app/outputs/flutter-apk/app-release.apk | grep libc++

# 3. Clean and rebuild
cd /workspace/flutter
rm -rf android/app/src/main/jniLibs
rm -rf build
flutter clean

# Then repeat steps 3-8 above
```

---

## ⚡ Quick Rebuild (After First Setup)

Once everything is installed, rebuilds are fast:

```bash
cd /workspace

# 1. Rebuild Rust library (if code changed)
cargo ndk --platform 21 --target aarch64-linux-android \
  build --release --features flutter

# 2. Copy libraries
cd flutter
cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# 3. Build APK
flutter build apk --target-platform android-arm64 --release

# 4. Install
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

**Time:** ~3-5 minutes

---

## 📦 Build for Multiple Architectures

To build for both ARM64 and ARM32:

```bash
# Build Rust for ARM32
cargo ndk --platform 21 --target armv7-linux-androideabi \
  build --release --features flutter

# Copy ARM32 libraries
cp ../target/armv7-linux-androideabi/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/armeabi-v7a/librustdesk.so

cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so \
   android/app/src/main/jniLibs/armeabi-v7a/

# Build multi-architecture APK
flutter build apk \
  --target-platform android-arm64,android-arm \
  --release
```

---

## 🎯 Complete Build Script (Copy-Paste)

Save this as `build_macos.sh`:

```bash
#!/bin/bash
set -e

echo "🍎 Building RustDesk for Android on macOS..."

# Set environment
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393
export PATH="$HOME/flutter-sdk/bin:$PATH"

# Detect NDK host
NDK_HOST="darwin-x86_64"

# Build Rust library
cd /workspace
echo "🦀 Building Rust library..."
cargo ndk --platform 21 --target aarch64-linux-android \
  build --release --features flutter

# Setup jniLibs
cd /workspace/flutter
echo "📦 Setting up jniLibs..."
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Copy libraries
echo "📋 Copying native libraries..."
cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/${NDK_HOST}/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/

# Verify
echo "✅ Verifying files..."
ls -lh android/app/src/main/jniLibs/arm64-v8a/

# Build APK
echo "🔨 Building Flutter APK..."
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release

# Verify APK
echo "✅ Verifying APK contents..."
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "lib/arm64-v8a"

echo ""
echo "🎉 Build complete!"
echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To install:"
echo "  adb install -r build/app/outputs/flutter-apk/app-release.apk"
```

Make it executable and run:

```bash
chmod +x build_macos.sh
./build_macos.sh
```

---

## ✅ Success Checklist

- [ ] Java 17 installed and JAVA_HOME set
- [ ] Android SDK installed at `$HOME/Library/Android/sdk`
- [ ] Android NDK 25.1.8937393 installed
- [ ] Rust with Android targets installed
- [ ] cargo-ndk installed
- [ ] Flutter SDK installed
- [ ] Rust library built: `target/aarch64-linux-android/release/liblibrustdesk.so` exists
- [ ] Libraries copied to `flutter/android/app/src/main/jniLibs/arm64-v8a/`
- [ ] APK built successfully
- [ ] APK contains both librustdesk.so and libc++_shared.so
- [ ] App installs and launches without crashes

---

**Last Updated:** 2025-11-14  
**Platform:** macOS (Intel & Apple Silicon)  
**Status:** ✅ Complete macOS Build Guide
