# voxtype

[![CI](https://github.com/Gurio/voxtype/actions/workflows/ci.yml/badge.svg)](https://github.com/Gurio/voxtype/actions/workflows/ci.yml)
[![Release](https://github.com/Gurio/voxtype/actions/workflows/release.yml/badge.svg)](https://github.com/Gurio/voxtype/actions/workflows/release.yml)

**Speech to text under a cursor (keyless text typing)**

A cross-platform voice dictation tool built with Tauri. Press a global hotkey, speak, and get perfectly formatted text copied to your clipboard.

## ✨ Features

- 🎯 **Intelligent Hotkey System** - Auto-finds a working hotkey (F12, F11, Pause, etc.) - zero configuration!
- 🎤 **Smart Recording** - Visual level meter, auto-stop on silence
- 🧠 **AI-Powered** - OpenAI transcription + intelligent post-processing
- 📋 **Clipboard Integration** - Transcribed text automatically copied
- 🌊 **Beautiful UI** - Liquid glass overlay effect
- 🔒 **Privacy-First** - Runs locally, you control your API keys
- 🚀 **Cross-Platform** - Linux-first, Windows & macOS supported
- ⚡ **Just Works** - Automatic hotkey fallback, no JSON editing needed

## 🏗️ Tech Stack

- **Frontend**: Vite + TypeScript
- **Backend**: Rust + Tauri 2.x
- **AI**: OpenAI Transcription API + Responses API
- **Packaging**: AppImage, .deb, MSI, DMG

## 📋 Prerequisites

### All Platforms
- [Node.js](https://nodejs.org/) (v18+)
- [Rust](https://rustup.rs/) (latest stable)
- [npm](https://www.npmjs.com/) or [pnpm](https://pnpm.io/)
- OpenAI API key

### Linux
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

# Fedora
sudo dnf install \
  webkit2gtk4.1-devel \
  openssl-devel \
  curl \
  wget \
  file \
  libappindicator-gtk3-devel \
  librsvg2-devel

# Arch
sudo pacman -S \
  webkit2gtk-4.1 \
  base-devel \
  curl \
  wget \
  file \
  openssl \
  appmenu-gtk-module \
  libappindicator-gtk3 \
  librsvg
```

### Windows
- [Microsoft Visual Studio C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
- [WebView2](https://developer.microsoft.com/en-us/microsoft-edge/webview2/) (usually pre-installed on Windows 10/11)

### macOS
```bash
# Xcode Command Line Tools
xcode-select --install
```

## 🚀 Quick Start

### 1. Clone and Install

```bash
cd voxtype
npm install
```

### 2. Configure API Key

Create a `.env` file:

```bash
cp .env.example .env
```

Edit `.env` and add your OpenAI API key:

```
VITE_OPENAI_API_KEY=sk-your-api-key-here
```

Or set it in the config file after first run:

```bash
# Linux/macOS
~/.config/voxtype/config.json

# Windows
%APPDATA%\voxtype\config.json
```

### 3. Development Mode

```bash
npm run dev
```

Press `Alt+Space` to activate the overlay!

## 📦 Building for Production

```bash
# Build for your current platform
npm run build

# Outputs will be in src-tauri/target/release/bundle/
```

### Linux Packages
- **AppImage**: `src-tauri/target/release/bundle/appimage/voxtype_*.AppImage`
- **Debian**: `src-tauri/target/release/bundle/deb/voxtype_*.deb`

### Windows
- **MSI Installer**: `src-tauri/target/release/bundle/msi/voxtype_*.msi`

### macOS
- **DMG**: `src-tauri/target/release/bundle/dmg/voxtype_*.dmg`

## ⚙️ Configuration

Edit `~/.config/voxtype/config.json`:

```json
{
  "openai_api_key": "sk-...",
  "shortcut": "Alt+Space",
  "transcribe_model": "gpt-4o-mini-transcribe",
  "post_model": "gpt-4.1-mini"
}
```

### Shortcut Format

Examples:
- `Alt+Space`
- `Ctrl+Shift+V`
- `Super+D` (Linux/Windows: Win key, macOS: Cmd)
- `CmdOrCtrl+Shift+Space` (Cmd on macOS, Ctrl elsewhere)

## 🎨 How It Works

1. **Press** your configured hotkey (default: `Alt+Space`)
2. **Speak** into your microphone (visual level meter shows input)
3. **Stop** by pressing `Enter` or the hotkey again
4. **Get** perfectly formatted text copied to your clipboard
5. **Paste** anywhere with `Ctrl+V`

The AI automatically:
- Adds proper punctuation and capitalization
- Converts spoken punctuation ("comma", "period") to symbols
- Formats text appropriately for messaging, code, or commands

## 🐧 Linux-Specific Notes

### Wayland
On Wayland, the app uses clipboard output exclusively (simulated typing is unreliable). This is the default and recommended approach.

### Permissions
If you encounter microphone access issues:

```bash
# Check PipeWire/PulseAudio status
systemctl --user status pipewire pipewire-pulse

# Grant microphone access (Flatpak/Snap)
flatpak permission-set microphone voxtype yes
```

### Autostart
To run at login:

```bash
# Copy desktop file
cp src-tauri/target/release/bundle/deb/voxtype.desktop ~/.config/autostart/
```

## 🔧 Troubleshooting

### "OPENAI_API_KEY not found"
- Set your key in `.env` or `config.json`
- Restart the app after adding the key

### Microphone not working
- Grant microphone permissions in system settings
- Check browser microphone access (for dev mode)
- Linux: Ensure PipeWire or PulseAudio is running

### Shortcut not registering
- Check if another app is using the same shortcut
- Try a different shortcut in `config.json`
- Restart the app after changing shortcuts

### Overlay not appearing
- Check if the window is hidden by compositor settings
- Try disabling "always on top" restrictions in system settings

### Build failures
- Update Rust: `rustup update`
- Clean build: `npm run clean && npm run build`
- Check prerequisites are installed

## 🗺️ Roadmap

### v1.1 (Coming Soon)
- [ ] Auto-update support
- [ ] Realtime API with auto-stop detection
- [ ] Mode selector (dictation / command / code)
- [ ] Command execution with confirmation
- [ ] Settings UI window
- [ ] System tray menu

### Future
- [ ] Local STT option (Whisper.cpp)
- [ ] Custom vocabulary/corrections
- [ ] Multi-language support
- [ ] Voice commands for editing
- [ ] Integration with text editors

## 🤝 Contributing

Contributions welcome! This is an early alpha, so expect rough edges.

## 📄 License

MIT

## ⚠️ Security Note

**Alpha Version**: This build includes your OpenAI API key in the app configuration. For personal use only. 

For production/multi-user deployments, implement a backend proxy to keep API keys secure.

## 🙏 Credits

Built with:
- [Tauri](https://tauri.app/) - Rust-powered desktop framework
- [OpenAI](https://openai.com/) - Transcription & text processing
- [Vite](https://vitejs.dev/) - Lightning-fast frontend tooling
