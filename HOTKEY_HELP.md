# Hotkey Troubleshooting Guide

## Quick Fix

```bash
# Stop everything and find a working hotkey
./scripts/kill-all-voxtype.sh
./scripts/find-working-hotkey.sh

# Or manually try simple keys:
# Edit ~/.config/voxtype/config.json
# Try: F9, F10, F11, F8, or Super+V
```

## Understanding the Issue

**Why hotkeys get stuck:**
1. Crashed voxtype instances leave hotkeys registered
2. Linux doesn't always clean up on crash
3. Multiple instances try to register same key

**When it happens:**
- After Ctrl+C during dev
- After system crashes
- When testing different hotkeys

## Current Hotkey

Check your current setting:
```bash
cat ~/.config/voxtype/config.json | grep shortcut
```

## Finding Available Hotkeys

### Method 1: Auto-find (Recommended)
```bash
./scripts/find-working-hotkey.sh
```

This tests hotkeys in order:
1. F9, F10, F11, F8 (function keys - rarely taken)
2. Ctrl+F9, Ctrl+F10 (modified function keys)
3. Alt+F9, Alt+F10
4. Shift+F9, Shift+F10
5. Ctrl+Alt+V, Ctrl+Shift+V
6. Super+V (Windows/Command key)

### Method 2: Manual Test

```bash
# 1. Stop all voxtype
./scripts/kill-all-voxtype.sh

# 2. Edit config
nano ~/.config/voxtype/config.json
# Change "shortcut" to your choice

# 3. Test it
npm run dev
# Watch for "✅ voxtype started" (success)
# or "⚠️ Failed to register" (taken)
```

### Method 3: Check What's Using Hotkeys

```bash
# Check for hotkey managers
ps aux | grep -E "(hotkey|shortcut|xbindkeys|sxhkd)"

# Kill them if found
pkill xbindkeys
pkill sxhkd
```

## Recommended Hotkeys

**Best choices (rarely taken):**
- `F9` - Simple, works most places
- `F10` - Same as F9
- `F8` - Less commonly used
- `Super+V` - Windows/Command key + V

**Avoid these (often taken):**
- `Ctrl+Space` - Often used by terminals
- `Alt+Space` - Window manager
- `Ctrl+Shift+Space` - Various apps
- `Ctrl+Alt+*` - Desktop environment shortcuts

## Testing Your Hotkey

After changing config:

```bash
# 1. Start dev mode
npm run dev

# 2. Look for this message:
# "✅ voxtype started. Press [YOUR_HOTKEY] to activate."

# 3. Test it - press your hotkey
# The overlay should appear!

# 4. If you see warning:
# "⚠️ Failed to register hotkey"
# Try a different key
```

## Why Restart Helps

```bash
# Restarting clears ALL hotkey registrations
sudo reboot

# After restart, any hotkey should work
```

## Solutions Ranked

### 1. Auto-Find (Fastest)
```bash
./scripts/find-working-hotkey.sh
npm run dev
```

### 2. Try F9 (Simple)
```bash
# Edit ~/.config/voxtype/config.json:
{
  "shortcut": "F9"
}
npm run dev
```

### 3. Kill Everything (Clean Slate)
```bash
./scripts/kill-all-voxtype.sh
pkill xbindkeys  # if you use it
# Wait 5 seconds
npm run dev
```

### 4. Restart System (Nuclear Option)
```bash
sudo reboot
# After restart, original hotkey should work
```

## Common Desktop Environments

### GNOME (Ubuntu default)
- Reserved: Super (opens activities)
- Safe: F9, F10, F11, Super+V

### KDE Plasma
- Reserved: Many Meta/Super combos
- Safe: F9, F10, Function keys

### i3/Sway
- Reserved: Mod key combos (usually Super)
- Safe: Function keys, or reconfigure i3

## Checking DE Shortcuts

```bash
# GNOME
gsettings list-recursively | grep keybindings

# KDE
kwriteconfig5 --file kglobalshortcutsrc

# i3
cat ~/.config/i3/config | grep bindsym
```

## Advanced: Release Stuck Hotkeys

**Note: This requires root and can break things!**

```bash
# Don't run this unless you know what you're doing
# It tries to reset X11 input
setxkbmap -option
xmodmap -e "clear Lock"
```

## For Development

While developing, if hotkeys keep getting stuck:

```bash
# Use a simple key that nothing else uses
{
  "shortcut": "F9"
}

# And add this alias to ~/.bashrc:
alias vt-reset='pkill -9 voxtype; sleep 2; npm run dev'

# Then just run: vt-reset
```

## Working Without Hotkey

If you can't find a working hotkey:

```bash
# The app still works!
# Just run it manually:
npm run dev

# Or binary mode:
./src-tauri/target/release/voxtype

# Then use it without hotkey:
# - The overlay won't auto-appear
# - But you can trigger it from the app menu/tray (future feature)
# - Or bind it to a different trigger in your DE
```

## Creating a Custom Trigger

You can use your desktop environment to trigger voxtype:

```bash
# GNOME - Add custom keyboard shortcut:
# Settings → Keyboard → Custom Shortcuts
# Command: killall -USR1 voxtype
# Key: Whatever you want

# i3/Sway - Add to config:
# bindsym $mod+v exec "killall -USR1 voxtype"
```

## Future Improvement

We could add multiple trigger methods:
- DBus signal
- HTTP endpoint
- Unix socket
- FIFO pipe

These don't conflict with system hotkeys!

## Summary

**Quick fix:**
```bash
./scripts/find-working-hotkey.sh
```

**If that doesn't work:**
```bash
sudo reboot
```

**Best permanent solution:**
Use F9, F10, or another function key that nothing else uses.

---

**Need more help?** Check the terminal output when you run `npm run dev` - it tells you exactly what happened with your hotkey!

