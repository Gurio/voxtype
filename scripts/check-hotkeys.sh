#!/bin/bash
# Check what hotkeys are registered on your system

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 System Hotkey Registration Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Detect environment
DE="$XDG_CURRENT_DESKTOP"
SESSION="$XDG_SESSION_TYPE"

echo "Desktop Environment: $DE"
echo "Session Type: $SESSION"
echo ""

# Check for specific hotkey-holding processes
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Application Processes Holding Hotkeys"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for voxtype
VOXTYPE_PIDS=$(pgrep -f "voxtype" || true)
if [ -n "$VOXTYPE_PIDS" ]; then
    echo "⚠️  voxtype is running (PIDs: $VOXTYPE_PIDS)"
    ps aux | grep voxtype | grep -v grep
    echo ""
    echo "   To kill: pkill -9 voxtype"
else
    echo "✅ No voxtype processes"
fi
echo ""

# Check for hotkey managers
echo "Checking for hotkey manager processes..."
for proc in xbindkeys sxhkd xcape xdotool xhotkeys; do
    if pgrep -x "$proc" > /dev/null; then
        echo "⚠️  Found: $proc (PID: $(pgrep -x "$proc"))"
        echo "   To kill: pkill $proc"
    fi
done
echo ""

# GNOME/Unity shortcuts
if [[ "$DE" == *"GNOME"* ]] || [[ "$DE" == *"Unity"* ]] || [[ "$DE" == *"ubuntu"* ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "2️⃣  GNOME/Unity System Shortcuts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "Window Manager Shortcuts:"
    gsettings list-recursively org.gnome.desktop.wm.keybindings | grep -v "@as \[\]" | \
        grep -E "(Alt|Super|Ctrl|Shift|F[0-9])" | head -20
    echo ""
    
    echo "Media Keys:"
    gsettings list-recursively org.gnome.settings-daemon.plugins.media-keys | \
        grep -v "@as \[\]" | grep -E "(F[0-9]|Alt|Super|Ctrl)" | head -10
    echo ""
    
    echo "Custom Shortcuts:"
    CUSTOM=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if [ "$CUSTOM" != "@as []" ]; then
        echo "$CUSTOM" | tr ',' '\n' | while read path; do
            path=$(echo "$path" | tr -d "[] '")
            [ -n "$path" ] && gsettings list-recursively "$path"
        done
    else
        echo "✅ No custom shortcuts defined"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Common Conflicts (What NOT to use)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "These are OFTEN TAKEN:"
echo "  ❌ Alt+Space       - Window menu (GNOME/Unity)"
echo "  ❌ Ctrl+Alt+T      - Terminal"
echo "  ❌ Super+D         - Show desktop"
echo "  ❌ Super+L         - Lock screen"
echo "  ❌ Alt+Tab         - Window switcher"
echo "  ❌ Ctrl+Space      - Input method / Terminal autocomplete"
echo ""

echo "These are USUALLY FREE:"
echo "  ✅ F9             - Function keys rarely used"
echo "  ✅ F10            - Same as F9"
echo "  ✅ F8             - Usually free"
echo "  ✅ Super+V        - Windows/Meta key + V"
echo "  ✅ Pause          - Pause/Break key"
echo "  ✅ ScrollLock     - Rarely used"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  How to Free Up Hotkeys"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -n "$VOXTYPE_PIDS" ]; then
    echo "Kill voxtype processes:"
    echo "  ./scripts/kill-all-voxtype.sh"
    echo ""
fi

echo "Reset all GNOME shortcuts (CAREFUL!):"
echo "  gsettings reset-recursively org.gnome.desktop.wm.keybindings"
echo "  gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys"
echo ""

echo "Disable a specific shortcut:"
echo "  gsettings set org.gnome.desktop.wm.keybindings panel-main-menu \"[]\""
echo ""

echo "Restart GNOME Shell (X11 only):"
echo "  Alt+F2, type 'r', press Enter"
echo ""

echo "Nuclear option (clears everything):"
echo "  sudo reboot"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Test a Hotkey"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To test if a hotkey is available:"
echo "  1. Edit ~/.config/voxtype/config.json"
echo "  2. Change \"shortcut\" to your choice (e.g., \"F9\")"
echo "  3. Run: npm run dev"
echo "  4. Look for:"
echo "     ✅ \"voxtype started. Press F9 to activate.\""
echo "     ❌ \"Failed to register hotkey\""
echo ""

echo "Or use auto-finder:"
echo "  ./scripts/find-working-hotkey.sh"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

