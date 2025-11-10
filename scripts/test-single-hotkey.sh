#!/bin/bash
# Test a single hotkey quickly

if [ -z "$1" ]; then
    echo "Usage: $0 <hotkey>"
    echo "Example: $0 F9"
    echo "Example: $0 Pause"
    exit 1
fi

HOTKEY="$1"
CONFIG_FILE="$HOME/.config/voxtype/config.json"
VOXTYPE_BIN="./src-tauri/target/release/voxtype"

if [ ! -f "$VOXTYPE_BIN" ]; then
    VOXTYPE_BIN="./src-tauri/target/debug/voxtype"
fi

if [ ! -f "$VOXTYPE_BIN" ]; then
    echo "❌ voxtype binary not found. Build first:"
    echo "   npm run build:release"
    exit 1
fi

echo "🧪 Testing hotkey: $HOTKEY"
echo ""

# Kill existing
pkill -9 voxtype 2>/dev/null || true
sleep 1

# Update config
jq --arg key "$HOTKEY" '.shortcut = $key' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
echo "Updated config to: $HOTKEY"
echo ""

# Test
echo "Starting voxtype..."
timeout 5 $VOXTYPE_BIN > /tmp/voxtype-test.log 2>&1 &
TEST_PID=$!

sleep 3

# Check result
if grep -q "Failed to register hotkey" /tmp/voxtype-test.log; then
    echo "❌ FAILED - Hotkey is taken"
    echo ""
    grep "Warning" /tmp/voxtype-test.log || true
    kill $TEST_PID 2>/dev/null || true
    exit 1
else
    if ps -p $TEST_PID > /dev/null 2>&1; then
        echo "✅ SUCCESS - Hotkey works!"
        echo ""
        cat /tmp/voxtype-test.log
        kill $TEST_PID 2>/dev/null || true
        exit 0
    else
        echo "❌ FAILED - App crashed"
        cat /tmp/voxtype-test.log
        exit 1
    fi
fi

