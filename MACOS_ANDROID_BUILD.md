# Building RustDesk Android on macOS

This guide covers building the RustDesk Android APK on macOS (Apple Silicon and Intel).

---

## ⚠️ Important Prerequisites

### 1. Java Version (CRITICAL)
You **MUST** use **Java 17 (LTS)**. Newer versions (Java 21+) will cause build failures.

```bash
# Check current Java version
java --version

# Install Java 17 via Homebrew
brew install openjdk@17

# Set Java 17 as default (add to ~/.zshrc or ~/.bash_profile)
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"  # Apple Silicon
# OR
export JAVA_HOME="/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"  # Intel Mac

# Add to PATH
export PATH="$JAVA_HOME/bin:$PATH"

# Apply changes
source ~/.zshrc  # or source ~/.bash_profile

# Verify
java --version
# Should show: openjdk 17.0.x
```

### 2. Android SDK/NDK
```bash
# Install via Android Studio or command-line tools
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

### 3. Rust Toolchain
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install cargo-ndk
cargo install cargo-ndk --version 3.5.4

# Add Android targets
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
```

### 4. vcpkg (for C++ dependencies)
```bash
# Clone vcpkg
cd $HOME
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
./bootstrap-vcpkg.sh

# Set environment variable
export VCPKG_ROOT=$HOME/vcpkg
echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.zshrc
```

### 5. Flutter SDK
```bash
# Clone Flutter
cd $HOME
git clone https://github.com/flutter/flutter.git -b stable
cd flutter
git checkout 3.24.5

# Add to PATH
export PATH="$HOME/flutter/bin:$PATH"
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zshrc

# Configure Android SDK
flutter config --android-sdk $ANDROID_HOME
flutter doctor --android-licenses
```

---

## 🏗️ Build Steps

### Step 1: Clone Repository
```bash
cd $HOME/Downloads
git clone https://github.com/YOUR_USERNAME/rustdesk.git
cd rustdesk
git submodule update --init --recursive
```

### Step 2: Install Flutter-Rust Bridge Codegen
```bash
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid
```

### Step 3: Generate Bridge Files
```bash
cd $HOME/Downloads/rustdesk
flutter_rust_bridge_codegen \
  --rust-input src/flutter_ffi.rs \
  --dart-output flutter/lib/generated_bridge.dart \
  --c-output flutter/macos/Runner/bridge_generated.h
```

### Step 4: Build vcpkg Dependencies
```bash
cd flutter
export VCPKG_ROOT=$HOME/vcpkg
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/25.1.8937393
bash build_android_deps.sh arm64-v8a
```

### Step 5: Build Rust Library
```bash
cd ..  # Back to rustdesk root
export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/25.1.8937393

# Build library only (not binaries - they have duplicate symbol issues)
cargo ndk --platform 21 --target aarch64-linux-android build --release --lib --features flutter
```

### Step 6: Copy Native Library
```bash
mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
cp target/aarch64-linux-android/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
```

### Step 7: Fix Flutter Plugins (REQUIRED)
```bash
cd flutter

# Run the plugin fix script
bash fix_android_plugins_macos.sh

# Clean Gradle cache (important!)
rm -rf ~/.gradle/caches

# Clean Flutter build
flutter clean
flutter pub get
```

### Step 8: Build APK
```bash
flutter build apk --target-platform android-arm64 --release
```

**Output APK:**
```
flutter/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "Namespace not specified"
**Solution:** Run the plugin fix script:
```bash
cd flutter
bash fix_android_plugins_macos.sh
flutter clean
flutter pub get
```

### Issue 2: "Could not resolve all files for configuration"
**Cause:** Java version too new (Java 21+)
**Solution:** Downgrade to Java 17:
```bash
brew install openjdk@17
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
java --version  # Verify it shows 17.0.x
rm -rf ~/.gradle/caches
flutter clean
```

### Issue 3: "duplicate symbol: oboe::..."
**Cause:** Both vcpkg and oboe-sys provide liboboe
**Solution:** Build library only (not binaries):
```bash
cargo ndk --platform 21 --target aarch64-linux-android build --release --lib --features flutter
```

### Issue 4: "Incorrect package=... found in AndroidManifest.xml"
**Cause:** Plugin has deprecated package attribute
**Solution:** The fix script handles this, but manually:
```bash
PLUGIN=$(find ~/.pub-cache/hosted/pub.dev -name "PLUGIN_NAME-*" -type d | head -1)
sed -i '' 's/package="[^"]*"//' "${PLUGIN}/android/src/main/AndroidManifest.xml"
```

### Issue 5: Build is very slow
**Solution:** Use ccache for faster C++ compilation:
```bash
brew install ccache
export NDK_CCACHE=$(which ccache)
```

---

## 🚀 Quick Build Script

Save this as `build_android_macos.sh`:

```bash
#!/bin/bash
set -e

# Environment setup
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"
export VCPKG_ROOT="$HOME/vcpkg"
export PATH="$HOME/flutter/bin:$PATH"

cd "$(dirname "$0")"

echo "🏗️  Building RustDesk for Android..."

# Generate bridge if needed
if [ ! -f "src/bridge_generated.rs" ]; then
    echo "📝 Generating Flutter-Rust bridge..."
    flutter_rust_bridge_codegen \
      --rust-input src/flutter_ffi.rs \
      --dart-output flutter/lib/generated_bridge.dart \
      --c-output flutter/macos/Runner/bridge_generated.h
fi

# Build Rust library
echo "🦀 Building Rust library..."
cargo ndk --platform 21 --target aarch64-linux-android build --release --lib --features flutter

# Copy library
echo "📦 Copying native library..."
mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
cp target/aarch64-linux-android/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# Fix plugins
echo "🔧 Fixing Flutter plugins..."
cd flutter
bash fix_android_plugins_macos.sh

# Clean and build
echo "🧹 Cleaning..."
rm -rf ~/.gradle/caches
flutter clean

echo "📥 Getting dependencies..."
flutter pub get

echo "🔨 Building APK..."
flutter build apk --target-platform android-arm64 --release

echo ""
echo "✅ Build complete!"
echo "📱 APK: flutter/build/app/outputs/flutter-apk/app-release.apk"
```

Make it executable:
```bash
chmod +x build_android_macos.sh
./build_android_macos.sh
```

---

## ⏱️ Build Times (Apple Silicon M1/M2)

- First build: ~15-20 minutes
- Incremental Rust rebuild: ~2 minutes
- Incremental Flutter rebuild: ~30 seconds

---

## 📋 Complete Environment Variables

Add to `~/.zshrc` or `~/.bash_profile`:

```bash
# Java 17 (REQUIRED)
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/25.1.8937393"

# Flutter
export PATH="$HOME/flutter/bin:$PATH"

# vcpkg
export VCPKG_ROOT="$HOME/vcpkg"

# PATH additions
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

Apply changes:
```bash
source ~/.zshrc
```

---

## 🎯 Verified Configuration

- **OS:** macOS 14+ (Sonoma) / macOS 13 (Ventura)
- **Java:** OpenJDK 17.0.x
- **Flutter:** 3.24.5 (stable)
- **Gradle:** 8.5
- **Android Gradle Plugin:** 8.1.1
- **Kotlin:** 1.9.22
- **NDK:** 25.1.8937393
- **Min Android:** API 23 (Android 6.0)

---

## 📞 Troubleshooting

If build still fails after following all steps:

1. **Verify Java 17:**
   ```bash
   java --version | grep "17.0"
   ```

2. **Clean everything:**
   ```bash
   rm -rf ~/.gradle/caches
   rm -rf ~/.pub-cache
   cargo clean
   flutter clean
   ```

3. **Reinstall Flutter dependencies:**
   ```bash
   cd flutter
   rm -rf .dart_tool
   flutter pub get
   ```

4. **Check plugin fixes:**
   ```bash
   bash fix_android_plugins_macos.sh
   ```

---

**Last Updated:** November 10, 2025  
**Tested On:** macOS 14 Sonoma (Apple Silicon M2)  
**Build Status:** ✅ WORKING
