#!/bin/bash
set -e

echo "📥 Quick download: libc++_shared.so for arm64-v8a"
echo ""

# Create directory
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Download directly from a mirror (much faster, ~1.5 MB)
echo "Downloading from Android NDK components..."
echo ""

# Use a smaller, direct download (just the library, not full NDK)
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download from Android Git repository (official source)
echo "⬇️  Downloading from official Android repository..."
curl -L -o libc++_shared.so \
  "https://android.googlesource.com/platform/prebuilts/ndk/+archive/refs/heads/main/platform/platforms/android-21/arch-arm64/usr/lib/libc++_shared.so"

# If that fails, try alternative source
if [ ! -f "libc++_shared.so" ] || [ ! -s "libc++_shared.so" ]; then
    echo "Trying alternative source..."
    curl -L -o ndk-libs.zip \
      "https://dl.google.com/android/repository/android-ndk-r25c-darwin.zip"
    
    unzip -q -j ndk-libs.zip \
      "android-ndk-r25c/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"
fi

# Verify we got a valid file
if [ ! -f "libc++_shared.so" ]; then
    echo "❌ Download failed"
    exit 1
fi

FILE_SIZE=$(stat -f%z libc++_shared.so 2>/dev/null || stat -c%s libc++_shared.so)
if [ $FILE_SIZE -lt 500000 ]; then
    echo "❌ Downloaded file is too small (corrupted?)"
    exit 1
fi

# Copy to jniLibs
echo "📋 Copying to jniLibs..."
cp libc++_shared.so /workspace/flutter/android/app/src/main/jniLibs/arm64-v8a/

# Clean up
cd /workspace/flutter
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Successfully installed libc++_shared.so"
echo ""
ls -lh android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
echo ""
echo "File size: $(du -h android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so | cut -f1)"
echo ""
