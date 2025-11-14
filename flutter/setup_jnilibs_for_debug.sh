#!/bin/bash
# Temporary script to download or setup libc++_shared.so for testing
# This is a workaround when NDK is not available in the environment

set -e

echo "🔧 Setting up jniLibs for debug APK..."
echo ""
echo "⚠️  NOTE: This is a temporary solution for testing."
echo "   For production builds, use the full build process with NDK and cargo-ndk."
echo ""

JNILIBS_DIR="android/app/src/main/jniLibs"
mkdir -p "$JNILIBS_DIR/arm64-v8a"
mkdir -p "$JNILIBS_DIR/armeabi-v7a"

echo "✅ Created jniLibs directories"
echo ""

# Check if librustdesk.so exists in target
if [ -f "/workspace/target/aarch64-linux-android/release/liblibrustdesk.so" ]; then
    echo "📦 Found pre-built Rust library, copying..."
    cp /workspace/target/aarch64-linux-android/release/liblibrustdesk.so \
       "$JNILIBS_DIR/arm64-v8a/librustdesk.so"
    echo "✅ Copied librustdesk.so"
else
    echo "⚠️  No pre-built Rust library found at:"
    echo "   /workspace/target/aarch64-linux-android/release/liblibrustdesk.so"
    echo ""
    echo "   You need to build the Rust library first:"
    echo "   cd /workspace"
    echo "   cargo ndk --platform 21 --target aarch64-linux-android build --release --features flutter"
    echo ""
fi

# Download libc++_shared.so from NDK distribution (r25c)
echo "📥 Downloading libc++_shared.so from NDK r25c..."
echo ""

# For arm64-v8a
LIBC_ARM64_URL="https://dl.google.com/android/repository/android-ndk-r25c-linux.zip"
echo "ℹ️  libc++_shared.so needs to be obtained from Android NDK."
echo ""
echo "   Option 1: Install NDK and run copy_ndk_libs.sh"
echo "   Option 2: Extract from NDK zip:"
echo "   - Download: $LIBC_ARM64_URL"
echo "   - Extract: android-ndk-r25c/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"
echo "   - Copy to: $JNILIBS_DIR/arm64-v8a/"
echo ""

# Alternative: Create a placeholder/dummy script that explains the issue
cat > "$JNILIBS_DIR/README.txt" <<'EOF'
Required files for jniLibs:

arm64-v8a/:
  - librustdesk.so    (Built from Rust code via cargo-ndk)
  - libc++_shared.so  (From Android NDK)

armeabi-v7a/:
  - librustdesk.so    (Built from Rust code via cargo-ndk) 
  - libc++_shared.so  (From Android NDK)

To build properly:
1. Install Android NDK (version 25.x recommended)
2. Build Rust library: cargo ndk --target aarch64-linux-android build --release
3. Copy NDK libraries: ./copy_ndk_libs.sh
4. Build APK: flutter build apk --target-platform android-arm64 --release

For manual extraction of libc++_shared.so:
- arm64-v8a: $NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so
- armeabi-v7a: $NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so
EOF

echo "📋 Created README.txt in jniLibs directory"
echo ""
echo "❌ Cannot complete setup without NDK installation"
echo ""
echo "📋 Next steps:"
echo "   1. Install Android NDK (if not already installed)"
echo "   2. Set ANDROID_NDK_HOME environment variable"
echo "   3. Build Rust library (if not already built)"
echo "   4. Run: ./copy_ndk_libs.sh"
echo "   5. Build APK: flutter build apk --target-platform android-arm64 --release"
echo ""
