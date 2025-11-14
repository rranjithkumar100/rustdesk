# macOS Quick Start - RustDesk Android Build

## 🍎 For MacBook Users

**Complete Guide:** [ANDROID_BUILD_MACOS_COMPLETE.md](./ANDROID_BUILD_MACOS_COMPLETE.md)

---

## ⚡ Super Quick Start (If You Have Everything)

If you already have Java, Android SDK/NDK, Rust, and Flutter installed:

```bash
# 1. Set environment
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393
export PATH="$HOME/flutter-sdk/bin:$PATH"

# 2. Build Rust library
cd /workspace
cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter

# 3. Setup jniLibs
cd flutter
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# 4. Copy libraries
cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/

cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/

# 5. Fix plugins
bash fix_android_plugins_macos.sh

# 6. Build APK
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release

# 7. Install
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 First Time Setup

### 1. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Install Java 17
```bash
brew install openjdk@17
sudo ln -sfn $(brew --prefix)/opt/openjdk@17/libexec/openjdk.jdk \
  /Library/Java/JavaVirtualMachines/openjdk-17.jdk
```

### 3. Set JAVA_HOME

**Apple Silicon (M1/M2/M3):**
```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home' >> ~/.zshrc
```

**Intel Mac:**
```bash
export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
echo 'export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home' >> ~/.zshrc
```

### 4. Install Android SDK & NDK
```bash
# Create directory
mkdir -p $HOME/Library/Android/sdk
cd $HOME/Library/Android/sdk

# Download Command Line Tools
curl -O https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip
unzip commandlinetools-mac-11076708_latest.zip

# Setup
mkdir -p cmdline-tools/latest
mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true

# Set environment
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH

# Add to shell
cat >> ~/.zshrc <<'EOF'
export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
EOF

source ~/.zshrc

# Accept licenses
yes | sdkmanager --licenses

# Install components
sdkmanager "platform-tools" \
  "platforms;android-34" \
  "platforms;android-33" \
  "build-tools;34.0.0" \
  "build-tools;33.0.1" \
  "ndk;25.1.8937393"

# Set NDK path
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393
echo 'export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393' >> ~/.zshrc
```

### 5. Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Add Android targets
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi

# Install cargo-ndk
cargo install cargo-ndk
```

### 6. Install Flutter
```bash
cd $HOME
git clone https://github.com/flutter/flutter.git -b stable flutter-sdk

export PATH="$HOME/flutter-sdk/bin:$PATH"
echo 'export PATH="$HOME/flutter-sdk/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

flutter doctor
```

---

## 🔨 Build APK

Now follow the "Super Quick Start" commands at the top of this document.

---

## 🐛 Common Issues

### "xcrun: error: invalid active developer path"
```bash
xcode-select --install
```

### "JAVA_HOME not set"
```bash
# Check Java
/usr/libexec/java_home -V

# Set for Apple Silicon
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# OR for Intel
export JAVA_HOME=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

### "NDK not found"
```bash
# Check installation
ls $HOME/Library/Android/sdk/ndk/

# Reinstall if missing
sdkmanager "ndk;25.1.8937393"
```

### "libc++_shared.so not found when building"
```bash
# Find it
find $ANDROID_NDK_HOME -name "libc++_shared.so"

# Should be at:
# $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
```

---

## ✅ Verify Everything Works

```bash
# Check Java
java -version

# Check Android SDK
sdkmanager --list_installed

# Check Rust
cargo --version
rustup target list | grep android

# Check Flutter
flutter doctor

# Check NDK
ls $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/
```

---

## 📱 Install APK on Device

```bash
# Uninstall old version
adb uninstall com.carriez.flutter_hbb

# Install new APK
adb install /workspace/flutter/build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb logcat | grep -i "rustdesk\|AndroidRuntime"
```

---

## 🎯 Automated Build Script

Save as `build_android_macos.sh`:

```bash
#!/bin/bash
set -e

export ANDROID_HOME=$HOME/Library/Android/sdk
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393
export PATH="$HOME/flutter-sdk/bin:$PATH"

cd /workspace
cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter

cd flutter
mkdir -p android/app/src/main/jniLibs/arm64-v8a

cp ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/

cp $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   android/app/src/main/jniLibs/arm64-v8a/

bash fix_android_plugins_macos.sh
flutter clean
flutter pub get
flutter build apk --target-platform android-arm64 --release

echo "✅ Build complete!"
echo "📱 APK: build/app/outputs/flutter-apk/app-release.apk"
```

Then run:
```bash
chmod +x build_android_macos.sh
./build_android_macos.sh
```

---

## 📚 Full Documentation

For detailed information, see:
- **[ANDROID_BUILD_MACOS_COMPLETE.md](./ANDROID_BUILD_MACOS_COMPLETE.md)** - Complete guide with explanations
- [ANDROID_BUILD_PREREQUISITES.md](./ANDROID_BUILD_PREREQUISITES.md) - Prerequisites explanation
- [ANDROID_CRASH_LIBC_FIX.md](./ANDROID_CRASH_LIBC_FIX.md) - Crash troubleshooting

---

**Platform:** macOS (Intel & Apple Silicon)  
**Time:** ~30-40 min first setup, ~3-5 min rebuilds  
**Status:** ✅ Copy-paste ready commands
