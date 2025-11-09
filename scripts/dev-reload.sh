#!/bin/bash
# Auto-rebuild and restart on file changes
# Uses inotifywait to watch for changes

set -e

# Check if inotifywait is available
if ! command -v inotifywait &> /dev/null; then
    echo "❌ inotifywait not found"
    echo ""
    echo "Install it with:"
    echo "  sudo apt install inotify-tools"
    exit 1
fi

WATCH_DIRS="src src-tauri/src"
WATCH_PATTERN=".*\.(ts|tsx|css|html|rs|toml)$"

build_and_run() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔨 Building at $(date +%H:%M:%S)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Kill previous instance if running
    pkill -f "target/release/voxtype" 2>/dev/null || true
    
    # Build
    if npm run build:release > /tmp/voxtype-build.log 2>&1; then
        echo "✅ Build successful"
        echo ""
        echo "🚀 Starting voxtype..."
        ./src-tauri/target/release/voxtype &
        APP_PID=$!
        echo "   PID: $APP_PID"
        echo "   Press Ctrl+Shift+F12 to test"
    else
        echo "❌ Build failed"
        tail -20 /tmp/voxtype-build.log
    fi
}

# Initial build
build_and_run

echo ""
echo "👀 Watching for changes..."
echo "   Directories: $WATCH_DIRS"
echo "   Press Ctrl+C to stop"
echo ""

# Watch for changes
while inotifywait -r -e modify,create,delete \
    --exclude '(target|node_modules|dist|\.git)' \
    $WATCH_DIRS 2>/dev/null; do
    
    # Debounce: wait a bit for multiple rapid changes
    sleep 0.5
    
    build_and_run
done

