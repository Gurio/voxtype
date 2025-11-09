#!/bin/bash
# Ultra-fast dev loop: build binary and run directly (no packaging)
# Best for rapid iteration

set -e

echo "⚡ Quick build (binary only)..."
npm run build:release

echo ""
echo "🚀 Starting voxtype..."
echo "   Press Ctrl+Shift+F12 to activate"
echo "   Press Ctrl+C to stop"
echo ""

./src-tauri/target/release/voxtype

