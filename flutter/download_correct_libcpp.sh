#!/bin/bash
set -e

echo "📥 Downloading CORRECT libc++_shared.so..."
echo ""

cd /workspace/flutter
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Method 1: Download from Android NDK official GitHub releases
echo "Attempting Method 1: GitHub Release..."
curl -L -o /tmp/libc++_shared.so \
  "https://github.com/android/ndk/raw/main/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
  2>/dev/null || echo "Method 1 failed, trying next..."

if [ -f "/tmp/libc++_shared.so" ] && [ $(stat -f%z /tmp/libc++_shared.so 2>/dev/null || stat -c%s /tmp/libc++_shared.so) -gt 500000 ]; then
    echo "✅ Method 1 succeeded"
    cp /tmp/libc++_shared.so android/app/src/main/jniLibs/arm64-v8a/
    rm /tmp/libc++_shared.so
else
    # Method 2: Extract from minimal NDK archive
    echo "Trying Method 2: Minimal NDK archive..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download a small prebuilt package
    curl -L -o ndk-minimal.tar.xz \
      "https://dl.google.com/android/repository/android-ndk-r21e-darwin-x86_64.zip"
    
    if [ -f "ndk-minimal.tar.xz" ]; then
        # Extract only the specific file we need
        unzip -p ndk-minimal.tar.xz \
          "android-ndk-r21e/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
          > libc++_shared.so 2>/dev/null || echo "Extraction method 2 failed"
    fi
    
    if [ -f "libc++_shared.so" ] && [ $(stat -f%z libc++_shared.so 2>/dev/null || stat -c%s libc++_shared.so) -gt 500000 ]; then
        echo "✅ Method 2 succeeded"
        cp libc++_shared.so /workspace/flutter/android/app/src/main/jniLibs/arm64-v8a/
        cd /workspace/flutter
        rm -rf "$TEMP_DIR"
    else
        cd /workspace/flutter
        rm -rf "$TEMP_DIR"
        echo "❌ All automatic methods failed"
        echo ""
        echo "You need to install Android NDK manually:"
        echo "1. Download from: https://developer.android.com/ndk/downloads"
        echo "2. Or use: brew install android-ndk"
        echo "3. Then run: cp \$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so android/app/src/main/jniLibs/arm64-v8a/"
        exit 1
    fi
fi

echo ""
echo "✅ Downloaded libc++_shared.so"
ls -lh android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
FILE_SIZE=$(stat -f%z android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so 2>/dev/null || stat -c%s android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so)
echo "File size: $(($FILE_SIZE / 1024)) KB"
echo ""

if [ $FILE_SIZE -lt 500000 ]; then
    echo "⚠️  Warning: File seems too small!"
    exit 1
fi
