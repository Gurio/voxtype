#!/bin/bash
# Kill all voxtype processes and free up hotkeys

echo "🔪 Killing all voxtype processes..."
echo ""

# Kill voxtype binaries
pkill -9 -f "target.*voxtype" 2>/dev/null && echo "✅ Killed voxtype binaries" || echo "ℹ️  No voxtype binaries running"

# Kill tauri dev
pkill -9 -f "tauri dev" 2>/dev/null && echo "✅ Killed tauri dev" || echo "ℹ️  No tauri dev running"

# Kill cargo run
pkill -9 -f "cargo.*run" 2>/dev/null && echo "✅ Killed cargo run" || echo "ℹ️  No cargo run processes"

# Kill node/vite
pkill -9 -f "vite.*voxtype" 2>/dev/null && echo "✅ Killed vite server" || echo "ℹ️  No vite server running"

# Kill npm processes
pkill -9 -f "npm.*voxtype" 2>/dev/null && echo "✅ Killed npm processes" || echo "ℹ️  No npm processes running"

echo ""
echo "✨ Done! All voxtype processes stopped."
echo ""
echo "Note: Hotkeys may still be stuck until you:"
echo "  1. Restart your system, or"
echo "  2. Use a different hotkey"
echo ""
echo "To find a working hotkey:"
echo "  ./scripts/find-working-hotkey.sh"
echo ""

