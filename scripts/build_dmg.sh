#!/bin/bash

# Configuration
APP_NAME="MacStats"
# Universal build location
BUILD_DIR=".build/apple/Products/Release"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

echo "🚀 Building release..."
swift build -c release --arch arm64 --arch x86_64

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "📦 Creating App Bundle..."
if [ -d "$APP_BUNDLE" ]; then
    rm -rf "$APP_BUNDLE"
fi

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
if [ -f "$BUILD_DIR/$APP_NAME" ]; then
    cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
else
    echo "❌ Binary not found at $BUILD_DIR/$APP_NAME"
    exit 1
fi

# Copy Info.plist
cp "Info.plist" "$APP_BUNDLE/Contents/"

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Set permissions
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Strip quarantine (Fix "App Damaged" on Apple Silicon)
echo "🧹 Stripping quarantine attributes..."
xattr -rc "$APP_BUNDLE"

echo "🔏 Signing app (Ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "💿 Creating DMG..."
if [ -f "$DMG_NAME" ]; then
    rm "$DMG_NAME"
fi

hdiutil create -volname "$APP_NAME" -srcfolder "$APP_BUNDLE" -ov -format UDZO "$DMG_NAME"

echo "✅ Done! Created $DMG_NAME"
