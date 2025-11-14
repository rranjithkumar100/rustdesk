#!/bin/bash
set -e

echo "🔧 Fixing jniLibs and building debug APK..."
echo ""

# Verify we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in Flutter directory"
    echo "   Run: cd /workspace/flutter"
    exit 1
fi

# Step 1: Check for Rust library
echo "1️⃣ Checking for Rust library..."
if [ ! -f "../target/aarch64-linux-android/release/liblibrustdesk.so" ]; then
    echo "❌ Rust library not found!"
    echo "   Building it now..."
    cd /workspace
    cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter
    cd flutter
    echo "✅ Rust library built"
else
    echo "✅ Rust library found"
fi

# Step 2: Check for NDK
echo ""
echo "2️⃣ Checking for NDK..."
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "❌ ANDROID_NDK_HOME not set!"
    echo "   Set it with: export ANDROID_NDK_HOME=/path/to/ndk"
    exit 1
fi

# Detect OS for NDK path
if [[ "$OSTYPE" == "darwin"* ]]; then
    NDK_PREBUILT="darwin-x86_64"
    echo "✅ macOS detected"
else
    NDK_PREBUILT="linux-x86_64"
    echo "✅ Linux detected"
fi

LIBC_PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/${NDK_PREBUILT}/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"

if [ ! -f "$LIBC_PATH" ]; then
    echo "❌ libc++_shared.so not found at: $LIBC_PATH"
    echo "   Check your ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
    exit 1
fi
echo "✅ NDK libraries found"

# Step 3: Create jniLibs directory
echo ""
echo "3️⃣ Creating jniLibs directory..."
mkdir -p android/app/src/main/jniLibs/arm64-v8a
echo "✅ Directory created"

# Step 4: Copy librustdesk.so
echo ""
echo "4️⃣ Copying librustdesk.so..."
cp -v ../target/aarch64-linux-android/release/liblibrustdesk.so \
   android/app/src/main/jniLibs/arm64-v8a/librustdesk.so
echo "✅ Copied librustdesk.so"

# Step 5: Copy libc++_shared.so
echo ""
echo "5️⃣ Copying libc++_shared.so..."
cp -v "$LIBC_PATH" \
   android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
echo "✅ Copied libc++_shared.so"

# Step 6: Verify files
echo ""
echo "6️⃣ Verifying files in jniLibs..."
ls -lh android/app/src/main/jniLibs/arm64-v8a/

RUSTDESK_SIZE=$(stat -f%z android/app/src/main/jniLibs/arm64-v8a/librustdesk.so 2>/dev/null || stat -c%s android/app/src/main/jniLibs/arm64-v8a/librustdesk.so 2>/dev/null)
LIBC_SIZE=$(stat -f%z android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so 2>/dev/null || stat -c%s android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so 2>/dev/null)

echo ""
echo "File sizes:"
echo "  librustdesk.so: $(($RUSTDESK_SIZE / 1024 / 1024)) MB"
echo "  libc++_shared.so: $(($LIBC_SIZE / 1024 / 1024)) MB"

if [ $RUSTDESK_SIZE -lt 10000000 ]; then
    echo "⚠️  Warning: librustdesk.so seems small (< 10 MB)"
fi

if [ $LIBC_SIZE -lt 500000 ]; then
    echo "⚠️  Warning: libc++_shared.so seems small (< 500 KB)"
fi

# Step 7: Clean build
echo ""
echo "7️⃣ Cleaning previous build..."
flutter clean
echo "✅ Cleaned"

# Step 8: Get dependencies
echo ""
echo "8️⃣ Getting dependencies..."
flutter pub get
echo "✅ Dependencies ready"

# Step 9: Build debug APK
echo ""
echo "9️⃣ Building debug APK..."
flutter build apk --target-platform android-arm64 --debug
echo "✅ APK built"

# Step 10: Verify APK contents
echo ""
echo "🔟 Verifying APK contents..."
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK not found at: $APK_PATH"
    exit 1
fi

echo "Checking APK for native libraries..."
unzip -l "$APK_PATH" | grep "lib/arm64-v8a"

echo ""
echo "Checking for libc++_shared.so..."
if unzip -l "$APK_PATH" | grep -q "libc++_shared.so"; then
    echo "✅ libc++_shared.so IS in APK"
else
    echo "❌ libc++_shared.so NOT in APK - BUILD FAILED!"
    exit 1
fi

echo ""
echo "Checking for librustdesk.so..."
if unzip -l "$APK_PATH" | grep -q "librustdesk.so"; then
    echo "✅ librustdesk.so IS in APK"
else
    echo "❌ librustdesk.so NOT in APK - BUILD FAILED!"
    exit 1
fi

# Success
echo ""
echo "═══════════════════════════════════════════"
echo "✅ BUILD SUCCESSFUL!"
echo "═══════════════════════════════════════════"
echo ""
echo "📱 APK Location: $APK_PATH"
echo "📦 APK Size: $(du -h "$APK_PATH" | cut -f1)"
echo ""
echo "To install:"
echo "  adb uninstall com.carriez.flutter_hbb"
echo "  adb install $APK_PATH"
echo ""
echo "To check logs:"
echo "  adb logcat | grep -i 'rustdesk\\|UnsatisfiedLink'"
echo ""
