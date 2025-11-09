# Development Workflow Guide

The best ways to iterate quickly on voxtype development.

## 🚀 Quick Reference

| Workflow | Speed | Use Case | Command |
|----------|-------|----------|---------|
| **Hot Reload** | ⚡⚡⚡ Instant | UI changes, quick iteration | `npm run dev` |
| **Quick Binary** | ⚡⚡ 30s | Backend changes, testing | `./scripts/dev-quick.sh` |
| **Auto-Reload** | ⚡ Auto | Full stack changes | `./scripts/dev-reload.sh` |
| **Package Install** | 🐢 2min | Test full installation | `./scripts/dev-install.sh` |

## Development Modes

### 1. Hot Reload Development (Recommended)

**Best for:** UI changes, TypeScript, CSS

```bash
npm run dev
```

**Features:**
- ✅ Instant hot reload for frontend changes
- ✅ Auto-recompiles Rust on save
- ✅ Automatic window reload
- ✅ Console logging available

**How it works:**
- Vite dev server runs on http://localhost:5173
- Tauri watches for Rust changes
- Changes appear immediately without restart

**Limitations:**
- Requires both frontend and backend to be running
- Port 5173 must be available
- Some Rust changes need full restart

---

### 2. Quick Binary Build

**Best for:** Testing full releases, Rust changes

```bash
./scripts/dev-quick.sh
```

**What it does:**
1. Builds frontend (production mode)
2. Compiles Rust (release mode, ~30s)
3. Runs the binary directly
4. Shows console output

**When to use:**
- Testing Rust changes that need release mode
- Verifying production behavior
- Quick full-stack testing
- Before creating a package

---

### 3. Auto-Reload on Changes

**Best for:** Full-stack development with auto-restart

```bash
./scripts/dev-reload.sh
```

**Features:**
- ✅ Watches `src/` and `src-tauri/src/`
- ✅ Auto-rebuilds on file changes
- ✅ Restarts app automatically
- ✅ Shows build errors immediately

**Requires:**
```bash
sudo apt install inotify-tools
```

**How it works:**
1. Initial build
2. Starts app
3. Watches for `.ts`, `.rs`, `.css` changes
4. Rebuilds and restarts on change

---

### 4. Full Package Install

**Best for:** Testing installation, final verification

```bash
./scripts/dev-install.sh
```

**What it does:**
1. Builds .deb package (~1-2min)
2. Installs system-wide with `sudo dpkg -i`
3. App available in application menu
4. Tests full installation flow

**When to use:**
- Before releases
- Testing system integration
- Verifying installation scripts
- Testing desktop file / icons

---

## Iteration Speed Comparison

```
Change UI color:
  Hot reload:    < 1 second  ✅ Use this!
  Quick binary:  30 seconds
  Package:       2 minutes

Change Rust logic:
  Hot reload:    10-15 seconds (dev build)
  Quick binary:  30 seconds (release build) ✅ Use this!
  Package:       2 minutes

Full release test:
  Package:       2 minutes ✅ Use this!
```

## Recommended Workflows

### Frontend Work (UI, styling, TypeScript)

```bash
# Terminal 1: Start dev server
npm run dev

# Make changes in your editor
# Changes appear instantly in app

# To test a specific feature:
# Press Ctrl+Shift+F12 (or configured hotkey)
```

### Backend Work (Rust, API integration)

```bash
# For quick iteration:
npm run dev
# Edit src-tauri/src/*.rs
# Tauri auto-recompiles (10-15s)

# For release-mode testing:
./scripts/dev-quick.sh
# Test the feature
# Ctrl+C to stop
# Edit code
# ./scripts/dev-quick.sh again
```

### Full-Stack Work

```bash
# Option A: Manual control
npm run dev
# Edit frontend or backend as needed

# Option B: Auto-reload everything
./scripts/dev-reload.sh
# Edit any file
# Watch it rebuild and restart
```

### Testing Installation

```bash
# Build and install
./scripts/dev-install.sh

# Test the installed app
voxtype  # or press your hotkey

# Uninstall when done
sudo apt remove voxtype
```

## Debugging Tips

### Check Console Output

**Development mode:**
```bash
npm run dev
# Watch terminal for console.log() and println!() output
```

**Binary mode:**
```bash
./src-tauri/target/release/voxtype
# All stdout/stderr printed to terminal
```

**Installed package:**
```bash
# Check logs
journalctl --user -f | grep voxtype
```

### Debug Rust Code

```bash
# Build with debug symbols
npm run build:debug

# Run with GDB
gdb ./src-tauri/target/debug/voxtype
```

### Debug TypeScript

```bash
npm run dev
# Right-click in app → Inspect Element
# Use browser DevTools
```

## Common Development Tasks

### Add a New Dependency

**TypeScript:**
```bash
npm install <package>
npm run dev  # Test it works
```

**Rust:**
```bash
# Edit src-tauri/Cargo.toml
cd src-tauri
cargo add <crate>
cd ..
npm run dev  # Test it works
```

### Test API Changes

```bash
# Edit src-tauri/src/openai.rs
npm run build:release
./src-tauri/target/release/voxtype
# Test the API call
# Check output in terminal
```

### Test Different Hotkeys

```bash
# Edit ~/.config/voxtype/config.json
{
  "shortcut": "F9"  # Try a simple key
}

# Restart app
pkill voxtype
npm run dev
```

### Profile Performance

```bash
# Build with optimizations
npm run build:release

# Run with time measurement
time ./src-tauri/target/release/voxtype

# Or use perf
perf record ./src-tauri/target/release/voxtype
perf report
```

## Troubleshooting

### Port 5173 in use

```bash
killall -9 node
npm run dev
```

### Build stuck

```bash
pkill -9 cargo
npm run clean
npm run dev
```

### App doesn't start

```bash
# Check if already running
ps aux | grep voxtype

# Kill old instances
pkill voxtype

# Try again
npm run dev
```

### Hotkey doesn't work

```bash
# Known issue - restart system to clear stuck hotkeys
# Or use a different hotkey in config.json
```

### Changes don't appear

```bash
# Frontend changes:
# Hard refresh in browser: Ctrl+Shift+R

# Rust changes:
# Restart the app: Ctrl+C then npm run dev

# Full reset:
npm run clean
npm install
npm run dev
```

## Performance Tips

### Speed Up Builds

```bash
# Use more CPU cores
export CARGO_BUILD_JOBS=8

# Use mold linker (much faster)
cargo install mold
export RUSTFLAGS="-C link-arg=-fuse-ld=mold"

# Disable debug info in dev builds
# Edit src-tauri/Cargo.toml:
[profile.dev]
debug = false
```

### Reduce Recompile Time

```bash
# Use cargo-watch for smarter rebuilds
cargo install cargo-watch

cd src-tauri
cargo watch -x 'build'
```

### Cache Dependencies

```bash
# Use sccache for Rust
cargo install sccache
export RUSTC_WRAPPER=sccache

# Cache npm packages
npm ci --prefer-offline
```

## Git Workflow

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Develop with hot reload
npm run dev

# 3. Test before committing
./scripts/ci-check-local.sh

# 4. Commit if checks pass
git add .
git commit -m "feat: my feature"

# 5. Test full build
./scripts/dev-quick.sh

# 6. Push
git push origin feature/my-feature

# 7. Create PR on GitHub
```

## CI/CD Integration

Your changes will be tested in CI automatically:

```bash
# On push to main:
- TypeScript check
- Rust fmt check
- Rust clippy check
- Full build on Linux/Windows/macOS

# On version tag (v*):
- Full release build
- Package creation
- GitHub release
```

To test locally before CI:
```bash
./scripts/ci-check-local.sh
```

## Pro Tips

**1. Use tmux/screen for multiple terminals:**
```bash
# Terminal 1: Dev server
npm run dev

# Terminal 2: Git operations
git status

# Terminal 3: Testing
./src-tauri/target/release/voxtype
```

**2. Create shell aliases:**
```bash
# Add to ~/.bashrc or ~/.zshrc
alias vt-dev='cd ~/src/misc/prj/voxtype && npm run dev'
alias vt-quick='cd ~/src/misc/prj/voxtype && ./scripts/dev-quick.sh'
alias vt-ci='cd ~/src/misc/prj/voxtype && ./scripts/ci-check-local.sh'
```

**3. Use VS Code tasks:**
Create `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Dev Server",
      "type": "shell",
      "command": "npm run dev",
      "problemMatcher": []
    },
    {
      "label": "Quick Build",
      "type": "shell",
      "command": "./scripts/dev-quick.sh",
      "problemMatcher": []
    }
  ]
}
```

**4. Set up file watchers in your editor:**
- Save triggers auto-format (rustfmt, prettier)
- Save runs type check
- Save shows linter warnings

---

## Summary

**Daily Development:**
```bash
npm run dev  # 99% of the time
```

**Testing Changes:**
```bash
./scripts/dev-quick.sh  # Quick full test
```

**Before Pushing:**
```bash
./scripts/ci-check-local.sh  # Ensure CI will pass
```

**Before Release:**
```bash
./scripts/dev-install.sh  # Test full installation
```

---

**Happy coding! 🚀**

