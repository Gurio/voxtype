# Build Guide

Complete guide for building voxtype locally and for distribution.

## Quick Start

```bash
# Development (with hot reload)
npm run dev

# Local testing (binary only, fast)
npm run build:release
./src-tauri/target/release/voxtype

# Full package (.deb only, reliable)
npm run build:deb
```

## Build Commands

### Development Builds

| Command | Description | Output | Time |
|---------|-------------|--------|------|
| `npm run dev` | Development mode with hot reload | Running app | Instant (after first build) |
| `npm run build:debug` | Debug binary (no packaging) | `src-tauri/target/debug/voxtype` | ~30s |
| `npm run build:release` | Release binary (no packaging) | `src-tauri/target/release/voxtype` | ~30s |

**Use these for:**
- Local testing
- Development
- Quick iterations
- When you don't need installers

### Distribution Builds

| Command | Description | Output | Time |
|---------|-------------|--------|------|
| `npm run build:deb` | Debian package | `*.deb` | ~1-2min |
| `npm run build:appimage` | AppImage (portable) | `*.AppImage` | ~2-3min |
| `npm run build:linux` | Both .deb and AppImage | Both | ~3-4min |
| `npm run build` | All configured targets | All | ~5-10min |

**Use these for:**
- Release builds
- Distribution
- Testing installers
- CI/CD

## Platform-Specific Builds

### Linux

**Prerequisites:**
```bash
# Ubuntu/Debian
sudo apt install -y \
  libwebkit2gtk-4.1-dev \
  build-essential \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev

# For .deb packaging
sudo apt install -y dpkg

# For AppImage packaging (optional, sometimes problematic)
sudo apt install -y fuse libfuse2
```

**Build .deb (Recommended for Linux):**
```bash
npm run build:deb

# Install locally
sudo dpkg -i src-tauri/target/release/bundle/deb/voxtype_*.deb
```

**Build AppImage (Optional):**
```bash
npm run build:appimage

# If it fails (common on some systems), use .deb instead
# AppImage requires FUSE and can be finicky in containers/VMs
```

**Binary Only (Fastest):**
```bash
npm run build:release

# Run directly
./src-tauri/target/release/voxtype
```

### Windows

**Prerequisites:**
- Visual Studio Build Tools
- WebView2 (usually pre-installed)

**Build:**
```bash
npm run build

# Output: src-tauri/target/release/bundle/msi/voxtype_*.msi
```

### macOS

**Prerequisites:**
```bash
xcode-select --install
```

**Build:**
```bash
npm run build

# Output: src-tauri/target/release/bundle/dmg/voxtype_*.dmg
```

## Troubleshooting

### AppImage Build Fails

**Error:** `failed to run linuxdeploy`

**Cause:** AppImage requires FUSE, which may not be available in:
- Docker containers
- Some VMs
- WSL2 (Windows Subsystem for Linux)
- Servers without FUSE support

**Solutions:**

1. **Use .deb instead (recommended):**
   ```bash
   npm run build:deb
   ```

2. **Install FUSE:**
   ```bash
   sudo apt install fuse libfuse2
   sudo modprobe fuse
   ```

3. **Skip AppImage in CI:**
   ```yaml
   # In .github/workflows/release.yml
   - run: npm run build:deb  # Instead of npm run build
   ```

### Frontend Build Errors

**Error:** `Top-level await not available`

**Solution:** Already fixed in vite.config.ts (ES2022 target)

**Error:** `Port 5173 already in use`

**Solution:**
```bash
killall -9 node
npm run dev
```

### Rust Compilation Errors

**Error:** `could not find Cargo.toml`

**Solution:**
```bash
cd src-tauri
cargo build
cd ..
```

**Error:** Formatting issues

**Solution:**
```bash
cd src-tauri
cargo fmt --all
cd ..
```

### Build is Slow

**First build:** ~5-10 minutes (downloads all dependencies)

**Subsequent builds:** ~30 seconds (uses cache)

**Speed tips:**
```bash
# Use debug builds during development
npm run build:debug  # Much faster than release

# Clean when things get weird
npm run clean
npm install
```

## Build Outputs

### Binary Location

```bash
# Debug
src-tauri/target/debug/voxtype

# Release
src-tauri/target/release/voxtype
```

### Package Locations

```bash
# Linux .deb
src-tauri/target/release/bundle/deb/voxtype_0.1.0_amd64.deb

# Linux AppImage
src-tauri/target/release/bundle/appimage/voxtype_0.1.0_amd64.AppImage

# Windows MSI
src-tauri/target/release/bundle/msi/voxtype_0.1.0_x64_en-US.msi

# macOS DMG
src-tauri/target/release/bundle/dmg/voxtype_0.1.0_x64.dmg
```

## Size Comparison

| Build Type | Size | Compressed |
|------------|------|------------|
| Debug binary | ~50 MB | - |
| Release binary | ~18 MB | - |
| .deb package | ~7 MB | ~6 MB |
| AppImage | ~25 MB | ~20 MB |
| Windows MSI | ~12 MB | ~10 MB |

## CI/CD Builds

GitHub Actions automatically builds for all platforms when you push a tag:

```bash
# Create release
git tag v0.1.1
git push origin v0.1.1

# Wait ~20-30 minutes
# Check: https://github.com/Gurio/voxtype/releases
```

**Note:** CI uses `.deb` and `.appimage` on Linux. If AppImage fails in CI, we can disable it.

## Development Workflow

**Recommended workflow:**

```bash
# 1. Start dev server
npm run dev

# 2. Make changes (hot reload works)
# Edit src/ or src-tauri/src/

# 3. Test changes
# App recompiles automatically

# 4. Before committing, run CI checks
./scripts/ci-check-local.sh

# 5. If checks pass, commit and push
git add .
git commit -m "your changes"
git push origin main
```

## Local Testing Without Dev Mode

Sometimes you want to test the production build:

```bash
# Build release binary
npm run build:release

# Test it
./src-tauri/target/release/voxtype

# Or test the .deb package
npm run build:deb
sudo dpkg -i src-tauri/target/release/bundle/deb/voxtype_*.deb
voxtype  # Run installed version
```

## Cross-Platform Building

**You can only build for your current platform locally.**

- Linux → Build Linux packages
- Windows → Build Windows MSI
- macOS → Build macOS DMG

**For multi-platform releases, use GitHub Actions** (already configured).

## Environment Variables

```bash
# Use debug build (faster, larger)
TAURI_DEBUG=1 npm run dev

# Custom build directory
CARGO_TARGET_DIR=/tmp/voxtype-build npm run build

# Verbose output
RUST_LOG=debug npm run dev
```

## Cleaning Up

```bash
# Clean all build artifacts
npm run clean

# Clean + reinstall dependencies
npm run clean
rm -rf node_modules
npm install

# Nuclear option (fresh start)
git clean -fdx  # BE CAREFUL - removes all untracked files!
npm install
```

## Build Performance

**First build:**
- Downloads 400+ Rust crates
- Compiles all dependencies
- Total: 5-10 minutes

**Incremental builds:**
- Only recompiles changed code
- Uses Cargo cache
- Total: 10-30 seconds

**CI builds:**
- Use cached dependencies
- Parallel builds for each platform
- Total: ~20-30 minutes (all platforms)

## Recommended Build Strategy

**For local development:**
```bash
npm run dev  # Use hot reload
```

**For local testing:**
```bash
npm run build:release  # Quick binary build
```

**For releases:**
```bash
# Let GitHub Actions handle it
git tag v0.1.x
git push origin v0.1.x
```

**For testing packages locally:**
```bash
npm run build:deb  # Most reliable
```

## Known Issues

### AppImage

- May fail in Docker/containers
- Requires FUSE kernel module
- Not essential (use .deb instead)

### Windows

- First build downloads large WiX toolset
- Requires Visual Studio Build Tools
- MSI requires administrator for installation

### macOS

- Requires code signing for distribution
- DMG needs to be notarized for Gatekeeper
- Can build unsigned for local testing

## Getting Help

**Build fails?**

1. Run `./scripts/ci-check-local.sh` to see what's wrong
2. Check `BUILD.md` (this file) for your specific error
3. Try `npm run clean` and rebuild
4. Check GitHub Actions logs for CI failures

**Still stuck?**

- Check DEVELOPMENT.md for detailed tech info
- Look at closed issues on GitHub
- File a new issue with your error message

---

**Quick Reference:**

```bash
# Development
npm run dev                    # Hot reload development

# Local Testing
npm run build:release          # Fast binary build
./src-tauri/target/release/voxtype

# Packaging
npm run build:deb             # Debian package (reliable)
npm run build:appimage        # AppImage (may fail)
npm run build                 # All configured targets

# Quality Checks
./scripts/ci-check-local.sh   # Run all CI checks

# Cleanup
npm run clean                 # Remove build artifacts
```

