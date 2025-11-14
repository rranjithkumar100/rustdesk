#!/bin/bash
# Script to copy required NDK shared libraries to jniLibs folder
# This ensures libc++_shared.so is included in the APK

set -e

echo "🔧 Copying NDK shared libraries to jniLibs..."
echo ""

# Check for NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    if [ -d "$HOME/android-sdk/ndk" ]; then
        # Find the first NDK version
        NDK_VERSION=$(ls -1 "$HOME/android-sdk/ndk" | head -1)
        export ANDROID_NDK_HOME="$HOME/android-sdk/ndk/$NDK_VERSION"
        echo "📍 Using NDK: $ANDROID_NDK_HOME"
    else
        echo "❌ Error: ANDROID_NDK_HOME not set and NDK not found"
        echo "   Set ANDROID_NDK_HOME or install Android NDK"
        exit 1
    fi
else
    echo "📍 Using NDK: $ANDROID_NDK_HOME"
fi

# Define architectures
ARCHS=("arm64-v8a" "armeabi-v7a")
NDK_TRIPLE_arm64="aarch64-linux-android"
NDK_TRIPLE_arm="arm-linux-androideabi"

JNILIBS_DIR="android/app/src/main/jniLibs"

# Create jniLibs directories
for ARCH in "${ARCHS[@]}"; do
    mkdir -p "$JNILIBS_DIR/$ARCH"
    echo "✓ Created $JNILIBS_DIR/$ARCH"
done

# Copy libc++_shared.so for each architecture
echo ""
echo "📦 Copying libc++_shared.so..."

# arm64-v8a
if [ -f "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" ]; then
    cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
       "$JNILIBS_DIR/arm64-v8a/"
    echo "✅ Copied libc++_shared.so for arm64-v8a"
else
    echo "⚠️  libc++_shared.so not found for arm64-v8a"
fi

# armeabi-v7a
if [ -f "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so" ]; then
    cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so" \
       "$JNILIBS_DIR/armeabi-v7a/"
    echo "✅ Copied libc++_shared.so for armeabi-v7a"
else
    echo "⚠️  libc++_shared.so not found for armeabi-v7a"
fi

echo ""
echo "📋 Verifying jniLibs directory structure:"
ls -lh "$JNILIBS_DIR/arm64-v8a/" 2>/dev/null || echo "   arm64-v8a: empty or not found"
ls -lh "$JNILIBS_DIR/armeabi-v7a/" 2>/dev/null || echo "   armeabi-v7a: empty or not found"

echo ""
echo "✅ NDK library copy complete!"
echo ""
echo "📋 Next step: Build your APK"
echo "   flutter build apk --target-platform android-arm64 --release"
echo ""
