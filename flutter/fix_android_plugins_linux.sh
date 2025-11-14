#!/bin/bash
# Script to fix Flutter plugin namespace issues for Android builds on Linux
# This is required for AGP 8+ compatibility

set -e

echo "🔧 Fixing Flutter Android plugins for Linux build..."
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
    
    echo "🔍 Looking for plugin: $plugin_name"
    
    # Find plugin in pub.dev
    PLUGIN_DIR=$(find "$PUB_CACHE/hosted/pub.dev" -maxdepth 1 -name "${plugin_name}-*" -type d 2>/dev/null | head -1)
    
    if [ -z "$PLUGIN_DIR" ]; then
        echo "   ⚠️  Plugin not found in pub cache"
        return
    fi
    
    BUILD_GRADLE="${PLUGIN_DIR}/android/build.gradle"
    MANIFEST="${PLUGIN_DIR}/android/src/main/AndroidManifest.xml"
    
    if [ ! -f "$BUILD_GRADLE" ]; then
        echo "   ⚠️  build.gradle not found"
        return
    fi
    
    # ALWAYS remove package attribute from AndroidManifest.xml first
    if [ -f "$MANIFEST" ] && grep -q "package=" "$MANIFEST"; then
        echo "   📝 Removing deprecated package attribute from AndroidManifest.xml"
        sed -i 's/ package="[^"]*"//g' "$MANIFEST"
        sed -i 's/package="[^"]*" //g' "$MANIFEST"
        echo "   ✅ Removed package attribute"
    fi
    
    # Add namespace if not present
    if ! grep -q "namespace" "$BUILD_GRADLE"; then
        echo "   📝 Adding namespace: $namespace"
        sed -i "/android {/a\\    namespace \"${namespace}\"" "$BUILD_GRADLE"
        echo "   ✅ Added namespace"
    else
        # Update namespace if it's wrong
        CURRENT_NAMESPACE=$(grep "namespace" "$BUILD_GRADLE" | sed 's/.*namespace "\([^"]*\)".*/\1/')
        if [ "$CURRENT_NAMESPACE" != "$namespace" ]; then
            echo "   📝 Correcting namespace from $CURRENT_NAMESPACE to $namespace"
            sed -i "s|namespace \"$CURRENT_NAMESPACE\"|namespace \"$namespace\"|" "$BUILD_GRADLE"
            echo "   ✅ Corrected namespace"
        else
            echo "   ✓ Namespace already correct"
        fi
    fi
    
    # Add kotlinOptions if not present (for Kotlin plugins)
    if grep -q "kotlin" "$BUILD_GRADLE" && ! grep -q "kotlinOptions" "$BUILD_GRADLE"; then
        echo "   📝 Adding kotlinOptions for JVM target compatibility"
        sed -i "/android {/a\\    kotlinOptions {\\n        jvmTarget = \"1.8\"\\n    }" "$BUILD_GRADLE"
        echo "   ✅ Added kotlinOptions"
    fi
    
    echo ""
}

# Fix all problematic plugins
fix_plugin "external_path" "com.pinciat.external_path"
fix_plugin "flutter_keyboard_visibility" "com.jrai.flutter_keyboard_visibility"
fix_plugin "sqflite" "com.tekartik.sqflite"
fix_plugin "qr_code_scanner" "net.touchcapture.qr.flutterqr"
fix_plugin "device_info_plus" "dev.fluttercommunity.plus.device_info"
fix_plugin "url_launcher" "io.flutter.plugins.urllauncher"
fix_plugin "path_provider" "io.flutter.plugins.pathprovider"
fix_plugin "package_info_plus" "dev.fluttercommunity.plus.package_info"
fix_plugin "shared_preferences" "io.flutter.plugins.sharedpreferences"
fix_plugin "image_picker_android" "io.flutter.plugins.imagepicker"
fix_plugin "permission_handler_android" "com.baseflow.permissionhandler"
fix_plugin "wakelock_plus" "creativemaybeno.wakelock_plus"
fix_plugin "desktop_multi_window" "com.leanflutter.desktop_multi_window"

# Fix uni_links (git dependency)
echo "🔍 Looking for plugin: uni_links (git)"
UNI_LINKS=$(find "$PUB_CACHE/git" -name "uni_links" -type d 2>/dev/null | head -1)
if [ -n "$UNI_LINKS" ]; then
    BUILD_GRADLE="${UNI_LINKS}/android/build.gradle"
    MANIFEST="${UNI_LINKS}/android/src/main/AndroidManifest.xml"
    
    # Remove package attribute from manifest
    if [ -f "$MANIFEST" ] && grep -q "package=" "$MANIFEST"; then
        echo "   📝 Removing package attribute from AndroidManifest.xml"
        sed -i 's/ package="[^"]*"//g' "$MANIFEST"
        sed -i 's/package="[^"]*" //g' "$MANIFEST"
        echo "   ✅ Removed package attribute"
    fi
    
    # Add namespace if not present
    if [ -f "$BUILD_GRADLE" ] && ! grep -q "namespace" "$BUILD_GRADLE"; then
        echo "   📝 Adding namespace: name.avioli.unilinks"
        sed -i '/android {/a\    namespace "name.avioli.unilinks"' "$BUILD_GRADLE"
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
echo "   2. Clean Flutter: cd /workspace/flutter && flutter clean"
echo "   3. Get dependencies: flutter pub get"
echo "   4. Build APK: flutter build apk --target-platform android-arm64 --release"
echo ""
