#!/bin/bash
set -e

# ─────────────────────────────────────────────────────────────────────
# NeuralClaw Setup Wizard — Install Script
#
# Run this after cloning the repo to build the app and place it
# on your Desktop as a launchable .app icon.
#
# Usage:
#   git clone https://github.com/NickPlaysCrypto/neuralclaw-macos-setup-wizard.git
#   cd neuralclaw-macos-setup-wizard
#   bash install.sh
#
# What it does:
#   1. Checks for Swift toolchain
#   2. Builds the release binary via SPM
#   3. Creates NeuralClawSetup.app on the Desktop
#   4. Launches the wizard
# ─────────────────────────────────────────────────────────────────────

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="NeuralClawSetup"
DEST="$HOME/Desktop/${APP_NAME}.app"

echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   🧠 NeuralClaw Setup Wizard        ║"
echo "  ║   Installing...                      ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

# ── Prerequisites ──────────────────────────────────────────────────
echo "🔍 Checking prerequisites..."

if ! command -v swift &> /dev/null; then
    echo "❌ Swift is not installed."
    echo "   Install Xcode from the App Store or run:"
    echo "   xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "   ✅ $SWIFT_VERSION"

# ── Build ──────────────────────────────────────────────────────────
echo ""
echo "🔨 Building release binary (this may take a minute on first run)..."
cd "$PROJECT_DIR"
swift build -c release 2>&1

# ── Create .app bundle ────────────────────────────────────────────
echo ""
echo "📦 Creating .app bundle..."

# Kill any running instance
pkill -f "$APP_NAME" 2>/dev/null || true
sleep 0.3

rm -rf "$DEST"
mkdir -p "$DEST/Contents/MacOS"
mkdir -p "$DEST/Contents/Resources"

# Binary
cp "$PROJECT_DIR/.build/release/$APP_NAME" "$DEST/Contents/MacOS/$APP_NAME"
echo "   ✅ Binary copied"

# Icon
cp "$PROJECT_DIR/Sources/Resources/AppIcon.icns" "$DEST/Contents/Resources/AppIcon.icns"
echo "   ✅ Icon copied"

# SPM resource bundle (for volatile_defaults.json etc.)
BUNDLE_PATH="$PROJECT_DIR/.build/release/${APP_NAME}_${APP_NAME}.bundle"
if [ -d "$BUNDLE_PATH" ]; then
    cp -R "$BUNDLE_PATH" "$DEST/Contents/Resources/"
    echo "   ✅ Resource bundle copied"
fi

# Info.plist
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
echo "   ✅ Info.plist written"

# ── Done ───────────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║   ✅ Installation complete!          ║"
echo "  ║                                      ║"
echo "  ║   App: ~/Desktop/NeuralClawSetup.app ║"
echo "  ║                                      ║"
echo "  ║   To rebuild later:                  ║"
echo "  ║     bash build_app.sh                ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

echo "🚀 Launching NeuralClaw Setup Wizard..."
open "$DEST"
