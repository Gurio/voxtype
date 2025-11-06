# Hotkey Registration Issue - Troubleshooting

## Problem

You're seeing this error:
```
⚠️ Warning: Failed to set up hotkey handler 'Ctrl+Shift+F12': 
HotKey already registered
```

## Why This Happens

During development, crashed instances of the app can leave hotkeys "registered" at the system level. Linux doesn't always clean these up automatically.

## Solutions

### Solution 1: Restart Your Computer (Easiest)

```bash
sudo reboot
```

After restart, the hotkeys will be cleared and the app will work normally.

### Solution 2: Test Without Hotkey (For Now)

The app is fully functional even without the global hotkey! You just can't trigger it from outside the app.

**To test the recording feature:**

1. Open your browser DevTools on the overlay window
2. In the console, type:
   ```javascript
   // Manually trigger the recording
   await window.__TAURI__.event.emit('toggle-record', {});
   ```

### Solution 3: Try a Different Shortcut

Edit `~/.config/voxtype/config.json`:

```json
{
  "shortcut": "F9",
  "...": "..."
}
```

Simple keys like F9, F10, F11 might work if they're not taken by your desktop environment.

### Solution 4: Check What's Using the Hotkey

```bash
# List running processes that might have hotkeys
ps aux | grep -E "(hotkey|shortcut|xbindkeys)"

# Kill any suspicious processes
pkill xbindkeys  # if you use xbindkeys
```

### Solution 5: Disable Conflicting Desktop Environment Hotkeys

**GNOME:**
```bash
gsettings list-recursively | grep -i "ctrl.*shift.*f12"
# Or open Settings → Keyboard → View and Customize Shortcuts
```

**KDE:**
```bash
# System Settings → Shortcuts
```

## For Production

In production, the app will:
1. Try to register the configured hotkey
2. If it fails, show a notification to the user
3. Continue working (user can configure a different hotkey)

## Current Workaround

The app is running successfully! The hotkey just won't work until you restart or clear the stuck registration. All other functionality works fine.

