# Dev Quick Start

**Ultra-fast reference for daily development**

## 🚀 Start Developing

```bash
# 1. Hot reload (use 99% of the time)
npm run dev

# 2. Make changes - they appear instantly!
# Edit src/main.ts, src/style.css → instant reload
# Edit src-tauri/src/*.rs → auto-recompile (~10-15s)
```

## ⚡ Quick Commands

```bash
# Fast binary build + run (30s)
./scripts/dev-quick.sh

# Auto-rebuild on every change
./scripts/dev-reload.sh

# Build + install .deb package (2min)
./scripts/dev-install.sh

# Check before pushing
./scripts/ci-check-local.sh
```

## 🎯 When To Use What

| Task | Command | Speed |
|------|---------|-------|
| Change UI color | `npm run dev` | < 1s |
| Change TypeScript | `npm run dev` | < 1s |
| Change Rust code | `npm run dev` | ~10s |
| Test release build | `./scripts/dev-quick.sh` | ~30s |
| Test installation | `./scripts/dev-install.sh` | ~2min |

## 🐛 Testing Your Changes

```bash
# Start dev mode
npm run dev

# Press your hotkey (default: Ctrl+Shift+F12)
# Or if hotkey stuck, run manually:
./src-tauri/target/debug/voxtype

# Test the feature
# - Press hotkey to activate
# - Speak into microphone  
# - See transcription in clipboard
```

## 🔧 Quick Fixes

```bash
# Port in use
killall -9 node
npm run dev

# Hotkey stuck
# Edit ~/.config/voxtype/config.json
# Try: F9, F10, or other simple keys

# Build errors
npm run clean
npm install
npm run dev
```

## 📊 Current App Status

✅ **Works:**
- Audio recording with level meter
- OpenAI transcription  
- Text post-processing
- Clipboard copy
- Configuration management
- Cross-platform (Linux, macOS)

⚠️ **Known Issues:**
- Global hotkey can get stuck (restart to fix)
- Wayland: clipboard only (no direct typing)

## 🎨 Common Changes

**Change UI color:**
```css
/* src/style.css */
.overlay-container {
  background: rgba(20, 20, 30, 0.85); /* Edit this! */
}
```

**Change status text:**
```typescript
// src/main.ts
statusEl.textContent = 'Your text here';
```

**Change API prompt:**
```rust
// src-tauri/src/openai.rs
let system_prompt = "Your prompt here...";
```

**Change hotkey:**
```json
// ~/.config/voxtype/config.json
{
  "shortcut": "F9"
}
```

## 📝 Git Workflow

```bash
# 1. Make changes
# 2. Test
npm run dev

# 3. Check everything works
./scripts/ci-check-local.sh

# 4. Commit
git add .
git commit -m "your change"

# 5. Push
git push origin main

# CI will test on Linux + macOS
```

## 🚀 Create Release

```bash
# 1. Update version
npm version patch  # or minor, or major

# 2. Push tag
git push origin v0.1.1

# 3. GitHub Actions builds packages automatically
# Check: https://github.com/Gurio/voxtype/releases
```

## 💡 Pro Tips

**Alias for speed:**
```bash
# Add to ~/.bashrc
alias vt='cd ~/src/misc/prj/voxtype && npm run dev'
alias vtq='cd ~/src/misc/prj/voxtype && ./scripts/dev-quick.sh'
alias vtc='cd ~/src/misc/prj/voxtype && ./scripts/ci-check-local.sh'
```

**Watch logs:**
```bash
# Terminal 1: Dev server
npm run dev

# Terminal 2: Watch changes
tail -f /tmp/voxtype-build.log
```

**Quick test cycle:**
```bash
# Edit code → Save → App reloads → Test immediately!
# That's it! Hot reload is magic ✨
```

## 📚 Full Docs

- **DEVELOPMENT_WORKFLOW.md** - Complete guide
- **BUILD.md** - Building & packaging
- **README.md** - Full documentation

## 🆘 Need Help?

1. Check error message in terminal
2. Try `npm run clean && npm run dev`
3. Check docs above
4. File GitHub issue

---

**Happy coding! 🎉**

