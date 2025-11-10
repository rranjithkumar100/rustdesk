#!/bin/bash
# Script to fix Flutter plugin namespace issues for Android builds on macOS
# This is required for AGP 8+ compatibility

set -e

echo "🔧 Fixing Flutter Android plugins for macOS build..."
echo ""

PUB_CACHE="${HOME}/.pub-cache"

if [ ! -d "$PUB_CACHE" ]; then
    echo "❌ Pub cache not found at: $PUB_CACHE"
    echo "   Run 'flutter pub get' first"
    exit 1
fi

fix_plugin() {
    local plugin_name=$1
    local namespace=$2
    local remove_manifest_package=$3
    
    echo "🔍 Looking for plugin: $plugin_name"
    
    # Find plugin in pub.dev
    PLUGIN_DIR=$(find "$PUB_CACHE/hosted/pub.dev" -maxdepth 1 -name "${plugin_name}-*" -type d 2>/dev/null | head -1)
    
    if [ -z "$PLUGIN_DIR" ]; then
        echo "   ⚠️  Plugin not found in pub cache"
        return
    fi
    
    BUILD_GRADLE="${PLUGIN_DIR}/android/build.gradle"
    
    if [ ! -f "$BUILD_GRADLE" ]; then
        echo "   ⚠️  build.gradle not found"
        return
    fi
    
    # Add namespace if not present
    if ! grep -q "namespace" "$BUILD_GRADLE"; then
        echo "   📝 Adding namespace: $namespace"
        sed -i '' "/android {/a\\
    namespace \"${namespace}\"\\
" "$BUILD_GRADLE"
        echo "   ✅ Added namespace"
    else
        # Update namespace if it's wrong
        if grep -q 'namespace "com.github.flutterkeyboardvisibility"' "$BUILD_GRADLE" 2>/dev/null; then
            echo "   📝 Correcting namespace"
            sed -i '' 's/namespace "com.github.flutterkeyboardvisibility"/namespace "com.jrai.flutter_keyboard_visibility"/' "$BUILD_GRADLE"
            echo "   ✅ Corrected namespace"
        else
            echo "   ✓ Namespace already present"
        fi
    fi
    
    # Add kotlinOptions if not present (for Kotlin plugins)
    if grep -q "kotlin" "$BUILD_GRADLE" && ! grep -q "kotlinOptions" "$BUILD_GRADLE"; then
        echo "   📝 Adding kotlinOptions for JVM target compatibility"
        sed -i '' "/android {/a\\
    kotlinOptions {\\
        jvmTarget = \"1.8\"\\
    }\\
" "$BUILD_GRADLE"
        echo "   ✅ Added kotlinOptions"
    fi
    
    # Remove package attribute from AndroidManifest.xml if needed
    if [ "$remove_manifest_package" = "true" ]; then
        MANIFEST="${PLUGIN_DIR}/android/src/main/AndroidManifest.xml"
        if [ -f "$MANIFEST" ] && grep -q "package=" "$MANIFEST"; then
            echo "   📝 Removing deprecated package attribute from AndroidManifest.xml"
            sed -i '' "s/package=\"[^\"]*\"//" "$MANIFEST"
            echo "   ✅ Removed package attribute"
        fi
    fi
    
    echo ""
}

# Fix all problematic plugins
fix_plugin "external_path" "com.pinciat.external_path" "false"
fix_plugin "flutter_keyboard_visibility" "com.jrai.flutter_keyboard_visibility" "true"
fix_plugin "sqflite" "com.github.sqflite" "false"
fix_plugin "qr_code_scanner" "net.touchcapture.qr.flutterqr" "false"
fix_plugin "device_info_plus" "dev.fluttercommunity.plus.device_info" "false"
fix_plugin "url_launcher" "io.flutter.plugins.urllauncher" "false"
fix_plugin "path_provider" "io.flutter.plugins.pathprovider" "false"
fix_plugin "package_info_plus" "dev.fluttercommunity.plus.package_info" "false"
fix_plugin "shared_preferences" "io.flutter.plugins.sharedpreferences" "false"
fix_plugin "image_picker_android" "io.flutter.plugins.imagepicker" "false"

# Fix uni_links (git dependency)
echo "🔍 Looking for plugin: uni_links (git)"
UNI_LINKS=$(find "$PUB_CACHE/git" -name "uni_links" -type d 2>/dev/null | head -1)
if [ -n "$UNI_LINKS" ]; then
    BUILD_GRADLE="${UNI_LINKS}/android/build.gradle"
    if [ -f "$BUILD_GRADLE" ] && ! grep -q "namespace" "$BUILD_GRADLE"; then
        echo "   📝 Adding namespace: name.avioli.unilinks"
        sed -i '' '/android {/a\
    namespace "name.avioli.unilinks"
' "$BUILD_GRADLE"
        echo "   ✅ Added namespace"
    else
        echo "   ✓ Namespace already present"
    fi
else
    echo "   ⚠️  Plugin not found in pub cache"
fi
echo ""

echo "✅ All plugin fixes applied!"
echo ""
echo "📋 Next steps:"
echo "   1. Clean Gradle cache: rm -rf ~/.gradle/caches"
echo "   2. Clean Flutter: flutter clean"
echo "   3. Get dependencies: flutter pub get"
echo "   4. Build APK: flutter build apk --target-platform android-arm64 --release"
echo ""
