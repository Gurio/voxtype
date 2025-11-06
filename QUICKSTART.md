# 🚀 Quick Start Guide

Get voxtype running in 5 minutes!

## 1️⃣ Prerequisites Check

```bash
# Check if you have everything
node --version   # Should be v18 or higher
rustc --version  # Should be 1.70 or higher
npm --version    # Any recent version
```

If anything is missing:
- **Node.js**: https://nodejs.org/
- **Rust**: https://rustup.rs/

## 2️⃣ Linux Dependencies (Linux only)

```bash
# Ubuntu/Debian
sudo apt install -y \
  libwebkit2gtk-4.1-dev \
  build-essential \
  curl \
  wget \
  file \
  libxdo-dev \
  libssl-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev

# Or use the setup script
./scripts/setup.sh
```

## 3️⃣ Install Dependencies

```bash
npm install
```

## 4️⃣ Configure OpenAI API Key

Create a `.env` file:

```bash
echo "VITE_OPENAI_API_KEY=sk-your-actual-key-here" > .env
```

> 🔑 Get your API key from: https://platform.openai.com/api-keys

## 5️⃣ Run It!

```bash
npm run dev
```

Wait for compilation (first time takes ~2-5 minutes), then:

1. **Press `Alt+Space`** anywhere
2. **Speak** into your microphone
3. **Press `Enter`** or `Alt+Space` again to stop
4. **Paste** the text with `Ctrl+V`

## 🎯 What to Try

Say these phrases and watch them get perfectly formatted:

- "Hello world comma this is a test period"
- "List all files in the current directory" (becomes: `ls -la`)
- "Send email to John asking about the meeting tomorrow"
- "TODO colon implement user authentication"

## ⚙️ Change the Shortcut

Edit `~/.config/voxtype/config.json` after first run:

```json
{
  "shortcut": "Ctrl+Shift+V"
}
```

Restart the app.

## 🐛 Common Issues

### "OPENAI_API_KEY not set"
- Make sure `.env` exists and has your key
- No spaces around the `=` sign
- Key should start with `sk-`

### Microphone Permission Denied
```bash
# Check audio system (Linux)
systemctl --user status pipewire
```

### Shortcut Not Working
- Try a different shortcut (some are taken by system)
- Check console output for errors: `npm run dev`

### Build Errors
```bash
# Update everything
rustup update
npm install
npm run clean

# Try again
npm run dev
```

## 📦 Build for Production

```bash
npm run build

# Linux outputs:
# - src-tauri/target/release/bundle/appimage/voxtype_*.AppImage
# - src-tauri/target/release/bundle/deb/voxtype_*.deb
```

## 🎨 Customize

Edit these files:
- **UI styling**: `src/style.css`
- **Shortcut**: `~/.config/voxtype/config.json`
- **Post-processing prompt**: `src-tauri/src/openai.rs` (line ~52)

## 🆘 Still Stuck?

1. Check `README.md` for detailed docs
2. Look at console output for error messages
3. File an issue with the error log

## 💡 Pro Tips

- The overlay focuses automatically, so you can just start typing if you want to edit
- Use "new line" in speech to add line breaks
- Say "comma", "period", "question mark" for punctuation
- Works great for coding: "function hello world open paren close paren"

---

**Happy dictating! 🎤**

