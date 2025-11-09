#!/bin/bash
# Quick reinstall script for development
# Builds and installs the .deb package locally for testing

set -e

echo "🔨 Building voxtype .deb package..."
npm run build:deb

echo ""
echo "📦 Installing voxtype..."
PACKAGE=$(ls -t src-tauri/target/release/bundle/deb/voxtype_*.deb | head -1)
sudo dpkg -i "$PACKAGE"

echo ""
echo "✅ voxtype installed!"
echo ""
echo "To test:"
echo "  1. Press Ctrl+Shift+F12 (or your configured hotkey)"
echo "  2. Or run: voxtype"
echo ""
echo "To uninstall:"
echo "  sudo apt remove voxtype"

