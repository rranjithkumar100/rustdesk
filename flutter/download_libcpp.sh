#!/bin/bash
set -e

echo "📥 Downloading libc++_shared.so for Android..."
echo ""

# Create directory
mkdir -p android/app/src/main/jniLibs/arm64-v8a

# Download from official Android NDK r25c release
echo "Downloading from Android NDK r25c..."
echo "This is the official LLVM C++ STL library from Google"
echo ""

# Temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "⬇️  Downloading NDK r25c (this will take a few minutes, ~1GB)..."
curl -L -o ndk.zip https://dl.google.com/android/repository/android-ndk-r25c-darwin.zip

echo "📦 Extracting only the required library..."
unzip -q ndk.zip "android-ndk-r25c/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"

echo "📋 Copying to jniLibs..."
cp android-ndk-r25c/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so \
   /workspace/flutter/android/app/src/main/jniLibs/arm64-v8a/

# Clean up
cd /workspace/flutter
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Successfully downloaded and copied libc++_shared.so"
echo ""
ls -lh android/app/src/main/jniLibs/arm64-v8a/libc++_shared.so
echo ""
