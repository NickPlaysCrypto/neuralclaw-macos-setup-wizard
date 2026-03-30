#!/bin/bash
set -e

PROJECT_DIR="/Users/nick/Desktop/NeuralClawSetup"
APP_NAME="NeuralClawSetup"
DEST="/Users/nick/Desktop/${APP_NAME}.app"

echo "🔨 Building release binary..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

echo "📦 Creating .app bundle..."
rm -rf "$DEST"
mkdir -p "$DEST/Contents/MacOS"
mkdir -p "$DEST/Contents/Resources"

echo "📋 Copying binary..."
cp "$PROJECT_DIR/.build/release/$APP_NAME" "$DEST/Contents/MacOS/$APP_NAME"

echo "🎨 Copying icon..."
cp "$PROJECT_DIR/Sources/Resources/AppIcon.icns" "$DEST/Contents/Resources/AppIcon.icns"

echo "📋 Copying resource bundle..."
BUNDLE_PATH="$PROJECT_DIR/.build/release/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$BUNDLE_PATH" ]; then
    cp -R "$BUNDLE_PATH" "$DEST/Contents/Resources/"
    echo "   ✅ Resource bundle copied"
else
    echo "   ⚠️  No resource bundle found (icon loaded from Resources/)"
fi

echo "📝 Writing Info.plist..."
cat > "$DEST/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NeuralClawSetup</string>
    <key>CFBundleIdentifier</key>
    <string>com.neuralclaw.setup-wizard</string>
    <key>CFBundleName</key>
    <string>NeuralClaw Setup</string>
    <key>CFBundleDisplayName</key>
    <string>NeuralClaw Setup</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo ""
echo "✅ App bundle created at: $DEST"
echo "🚀 Launching..."
open "$DEST"
