# Windows Support

Windows builds are currently **disabled** in CI due to icon format issues.

## Issue

The placeholder `icon.ico` file doesn't meet Windows ICO format requirements:

```
Error: failed to parse icon icon.ico: failed to fill whole buffer
```

Windows ICO files need:
- Proper ICO header structure
- Multiple icon sizes (16x16, 32x32, 48x48, 256x256)
- Proper color depth and compression

## Current Status

- ✅ Linux: Fully supported (.deb packages)
- ✅ macOS: Fully supported (.dmg packages)
- ⚠️ Windows: Disabled in CI (can be built locally if you have proper icons)

## To Re-enable Windows Support

### Option 1: Generate Proper Icons (Recommended)

**Using ImageMagick (if available):**
```bash
# On a system with ImageMagick
cd src-tauri/icons

# Create a base PNG (256x256)
convert -size 256x256 xc:"#6366f1" \
  -fill white -font "DejaVu-Sans-Bold" \
  -pointsize 128 -gravity center \
  -annotate +0+0 "V" \
  base-icon.png

# Generate multi-size ICO
convert base-icon.png \
  \( -clone 0 -resize 256x256 \) \
  \( -clone 0 -resize 128x128 \) \
  \( -clone 0 -resize 64x64 \) \
  \( -clone 0 -resize 48x48 \) \
  \( -clone 0 -resize 32x32 \) \
  \( -clone 0 -resize 16x16 \) \
  -delete 0 -colors 256 icon.ico
```

**Using online tool:**
1. Create a 256x256 PNG icon
2. Go to https://converticon.com/
3. Upload PNG and download ICO
4. Replace `src-tauri/icons/icon.ico`

### Option 2: Use Tauri's Default Icon

```bash
# Remove custom icon reference from tauri.conf.json
# Or use Tauri's built-in icon generator
npx @tauri-apps/cli icon path/to/icon.png
```

### Option 3: Skip Icon Temporarily

```json
// In src-tauri/tauri.conf.json
{
  "bundle": {
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.icns"
      // Remove icon.ico temporarily
    ]
  }
}
```

## Re-enabling CI

Once you have a proper icon:

**1. Update `.github/workflows/ci.yml`:**
```yaml
matrix:
  platform: [ubuntu-22.04, windows-latest, macos-latest]
```

**2. Update `.github/workflows/release.yml`:**
```yaml
- name: Windows
  os: windows-latest
  target: x86_64-pc-windows-msvc
  artifacts: |
    src-tauri/target/release/bundle/msi/*.msi
```

**3. Test locally first:**
```bash
# If you have Windows or Wine
npm run build  # Try building MSI
```

## Building for Windows Manually

If you need a Windows build before fixing CI:

**On Windows:**
1. Install prerequisites (Visual Studio Build Tools)
2. Clone repo
3. Replace `icon.ico` with proper icon
4. Run `npm run build`
5. MSI will be in `src-tauri/target/release/bundle/msi/`

**Cross-compile (Linux → Windows, not recommended):**
- Very difficult due to WebView2 dependencies
- Better to use GitHub Actions once icon is fixed

## Why This Happened

The Python placeholder script created a minimal ICO file that works for some tools but doesn't meet Windows' strict requirements for:
- Multiple embedded sizes
- Proper bit depth
- AND mask (transparency)
- Proper directory structure

## Alternative: Professional Icons

For production releases, consider:
- Hiring a designer
- Using icon generators (e.g., https://icon.kitchen/)
- Using Tauri's built-in icon generator
- Free icon resources (with proper licensing)

## Testing

Once you fix the icon:

```bash
# Test ICO is valid
file src-tauri/icons/icon.ico
# Should show: MS Windows icon resource - 6 icons, 256x256, 32 bits/pixel

# Test build locally (if on Windows)
npm run build

# Or test in CI
git commit -am "fix: Add proper Windows icon"
git push
# Watch CI builds
```

## Priority

Since this is a **Linux-first** project, Windows support is:
- ✅ Nice to have
- ❌ Not blocking release
- 📅 Can be added later

Focus on Linux/macOS for now, add Windows when needed.

## Resources

- [Tauri Icon Guide](https://tauri.app/v1/guides/features/icons)
- [ICO Format Specification](https://en.wikipedia.org/wiki/ICO_(file_format))
- [Online ICO Converter](https://converticon.com/)
- [ImageMagick ICO Documentation](https://imagemagick.org/script/formats.php#ico)

