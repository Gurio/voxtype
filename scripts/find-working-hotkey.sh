#!/bin/bash
# Find a working hotkey for voxtype
# Tests various hotkeys to find one that isn't taken

set -e

CONFIG_FILE="$HOME/.config/voxtype/config.json"

echo "🔍 Finding available hotkey for voxtype..."
echo ""

# Kill any running voxtype instances first
echo "1️⃣ Stopping all voxtype instances..."
pkill -9 -f voxtype 2>/dev/null || true
pkill -9 -f "tauri dev" 2>/dev/null || true
pkill -9 -f "cargo.*run" 2>/dev/null || true
sleep 2
echo "   ✅ Stopped"
echo ""

# List of hotkeys to try (from least likely to be taken to most common)
HOTKEYS=(
    "F9"
    "F10"
    "F11"
    "F8"
    "Ctrl+F9"
    "Ctrl+F10"
    "Alt+F9"
    "Alt+F10"
    "Shift+F9"
    "Shift+F10"
    "Ctrl+Alt+V"
    "Ctrl+Shift+V"
    "Super+V"
)

echo "2️⃣ Testing hotkeys..."
echo ""

for hotkey in "${HOTKEYS[@]}"; do
    echo -n "   Testing '$hotkey'... "
    
    # Update config
    jq --arg key "$hotkey" '.shortcut = $key' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    
    # Try to start voxtype
    timeout 5 /home/gurio/src/misc/prj/voxtype/src-tauri/target/release/voxtype > /tmp/voxtype-test.log 2>&1 &
    TEST_PID=$!
    
    sleep 2
    
    # Check if it's still running (means hotkey worked)
    if ps -p $TEST_PID > /dev/null 2>&1; then
        # Check if hotkey registered successfully
        if ! grep -q "Failed to register hotkey" /tmp/voxtype-test.log; then
            echo "✅ WORKS!"
            kill $TEST_PID 2>/dev/null || true
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "✨ Found working hotkey: $hotkey"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "Updated config file: $CONFIG_FILE"
            echo ""
            echo "To use voxtype:"
            echo "  1. Run: npm run dev"
            echo "  2. Press: $hotkey"
            echo ""
            exit 0
        fi
    fi
    
    kill $TEST_PID 2>/dev/null || true
    echo "❌ taken"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  All tested hotkeys are taken!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Solutions:"
echo ""
echo "1. Restart your system (clears all hotkeys)"
echo "   sudo reboot"
echo ""
echo "2. Check what's using hotkeys:"
echo "   ps aux | grep -E '(hotkey|shortcut|xbindkeys)'"
echo ""
echo "3. Manually edit config to try other keys:"
echo "   nano $CONFIG_FILE"
echo "   Try: F7, F6, F5, Pause, ScrollLock, etc."
echo ""
echo "4. For now, run without hotkey:"
echo "   ./src-tauri/target/release/voxtype"
echo "   (You can still use the app, just no global hotkey)"
echo ""

