#!/bin/bash
# Comprehensive fix for "App not installed as package appears to be invalid" error
# This script addresses common causes of Android APK installation failures

set -e

echo "🔧 Fixing 'Invalid Package' Installation Error..."
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the flutter directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Must be run from the flutter directory${NC}"
    echo "   Run: cd /workspace/flutter && ./fix_invalid_package.sh"
    exit 1
fi

echo -e "${BLUE}📋 Diagnosing common issues...${NC}"
echo ""

# Issue 1: Check for plugin namespace issues
echo -e "${YELLOW}1. Checking plugin configurations...${NC}"
if [ -f "fix_android_plugins_linux.sh" ]; then
    echo "   ✓ Plugin fix script found"
    echo "   🔄 Running plugin fix script..."
    bash fix_android_plugins_linux.sh
else
    echo -e "   ${RED}⚠️  Plugin fix script not found${NC}"
fi
echo ""

# Issue 2: Clean build artifacts
echo -e "${YELLOW}2. Cleaning build artifacts...${NC}"
if [ -d "build" ]; then
    echo "   🗑️  Removing Flutter build directory..."
    rm -rf build
    echo "   ✅ Removed build/"
fi

if [ -d "android/.gradle" ]; then
    echo "   🗑️  Removing Gradle cache..."
    rm -rf android/.gradle
    echo "   ✅ Removed android/.gradle/"
fi

if [ -d "android/app/build" ]; then
    echo "   🗑️  Removing app build directory..."
    rm -rf android/app/build
    echo "   ✅ Removed android/app/build/"
fi

if [ -d "$HOME/.gradle/caches" ]; then
    echo "   🗑️  Removing user Gradle cache..."
    rm -rf "$HOME/.gradle/caches"
    echo "   ✅ Removed ~/.gradle/caches/"
fi
echo ""

# Issue 3: Verify minSdkVersion is set correctly
echo -e "${YELLOW}3. Verifying minSdkVersion...${NC}"
BUILD_GRADLE="android/app/build.gradle"
if grep -q "minSdkVersion 23" "$BUILD_GRADLE"; then
    echo "   ✅ minSdkVersion is correctly set to 23"
else
    if grep -q "minSdkVersion flutter.minSdkVersion" "$BUILD_GRADLE"; then
        echo -e "   ${YELLOW}⚠️  minSdkVersion uses flutter.minSdkVersion (dynamic)${NC}"
        echo "   📝 Setting minSdkVersion to 23 for rustls compatibility..."
        sed -i 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' "$BUILD_GRADLE"
        echo "   ✅ Updated minSdkVersion to 23"
    else
        echo -e "   ${YELLOW}⚠️  minSdkVersion not found or set incorrectly${NC}"
    fi
fi
echo ""

# Issue 4: Verify namespace is set
echo -e "${YELLOW}4. Verifying app namespace...${NC}"
if grep -q 'namespace "com.carriez.flutter_hbb"' "$BUILD_GRADLE"; then
    echo "   ✅ App namespace is correctly set"
else
    echo -e "   ${RED}⚠️  App namespace not found${NC}"
    echo "   This may cause build issues with AGP 8+"
fi
echo ""

# Issue 5: Check AndroidManifest.xml
echo -e "${YELLOW}5. Verifying AndroidManifest.xml...${NC}"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
    if grep -q 'package="com.carriez.flutter_hbb"' "$MANIFEST"; then
        echo "   ✅ Package name is set correctly"
    else
        echo -e "   ${RED}⚠️  Package name not found in manifest${NC}"
    fi
    
    if grep -q 'android:exported="true"' "$MANIFEST"; then
        echo "   ✅ Exported activities are properly declared"
    else
        echo -e "   ${YELLOW}⚠️  No exported activities found${NC}"
    fi
else
    echo -e "   ${RED}❌ AndroidManifest.xml not found${NC}"
fi
echo ""

# Issue 6: Verify Gradle version compatibility
echo -e "${YELLOW}6. Checking Gradle configuration...${NC}"
GRADLE_WRAPPER="android/gradle/wrapper/gradle-wrapper.properties"
if [ -f "$GRADLE_WRAPPER" ]; then
    GRADLE_VERSION=$(grep "distributionUrl" "$GRADLE_WRAPPER" | grep -oP 'gradle-\K[0-9.]+')
    if [ -n "$GRADLE_VERSION" ]; then
        echo "   ✓ Gradle version: $GRADLE_VERSION"
        # Check if version is 8.0 or higher
        MAJOR_VERSION=$(echo "$GRADLE_VERSION" | cut -d. -f1)
        if [ "$MAJOR_VERSION" -ge 8 ]; then
            echo "   ✅ Gradle 8+ detected (compatible with AGP 8.1.1)"
        else
            echo -e "   ${YELLOW}⚠️  Gradle version < 8.0 may cause issues${NC}"
        fi
    fi
fi
echo ""

# Issue 7: Check for signing configuration
echo -e "${YELLOW}7. Checking signing configuration...${NC}"
if [ -f "android/key.properties" ]; then
    echo "   ✓ Release signing configured (key.properties found)"
    echo "   ⚠️  Note: If installing debug APK on a device with release APK installed,"
    echo "        you must first uninstall the old version"
else
    echo "   ✓ No release signing configured (will use debug signing)"
fi
echo ""

# Final recommendations
echo -e "${GREEN}✅ Diagnostic complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps to build APK:${NC}"
echo ""
echo "1. Get Flutter dependencies:"
echo "   flutter pub get"
echo ""
echo "2. Build APK (choose one):"
echo "   # Debug APK (for testing):"
echo "   flutter build apk --debug --target-platform android-arm64"
echo ""
echo "   # Release APK (for distribution):"
echo "   flutter build apk --release --target-platform android-arm64"
echo ""
echo "3. Install APK on device:"
echo "   adb install -r build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo -e "${BLUE}📱 If installation still fails:${NC}"
echo ""
echo "• Uninstall existing app first:"
echo "  adb uninstall com.carriez.flutter_hbb"
echo ""
echo "• Check device compatibility:"
echo "  - Minimum Android version: 6.0 (API 23)"
echo "  - Architecture: ARM64 (arm64-v8a)"
echo ""
echo "• Verify APK signature:"
echo "  - Debug and release APKs have different signatures"
echo "  - Cannot update release app with debug APK (or vice versa)"
echo ""
echo -e "${GREEN}================================================${NC}"
