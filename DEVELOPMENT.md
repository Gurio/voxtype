# Development Guide

## Project Structure

```
voxtype/
├── src/                      # Frontend (TypeScript + Vite)
│   ├── main.ts              # Main app logic
│   └── style.css            # UI styling
├── src-tauri/               # Rust backend
│   ├── src/
│   │   ├── main.rs          # Tauri app entry point
│   │   ├── config.rs        # Configuration management
│   │   └── openai.rs        # OpenAI API integration
│   ├── Cargo.toml           # Rust dependencies
│   └── tauri.conf.json      # Tauri configuration
├── scripts/                 # Helper scripts
│   ├── setup.sh            # First-time setup
│   ├── generate-icons.sh   # Icon generation (requires ImageMagick)
│   └── create-placeholder-icons.py  # Fallback icon creation
└── index.html              # HTML entry point
```

## Architecture

### Frontend (TypeScript)
- **Web Audio API**: Captures microphone input
- **MediaRecorder**: Records audio as webm/opus
- **AnalyserNode**: Provides real-time level metering
- **Tauri IPC**: Calls Rust backend for transcription

### Backend (Rust)
- **Tauri**: App framework & IPC layer
- **Global Shortcut**: System-wide hotkey registration
- **OpenAI Client**: HTTP calls to transcription & responses APIs
- **Clipboard**: Cross-platform clipboard access
- **Config**: JSON-based settings persistence

### Flow
1. User presses global shortcut (`Alt+Space`)
2. Rust emits `toggle-record` event to frontend
3. Frontend starts `MediaRecorder` and shows overlay
4. User speaks → audio visualizer shows levels
5. User presses `Enter` or shortcut again
6. Frontend sends base64 audio to Rust via IPC
7. Rust calls OpenAI transcription API
8. Rust calls Responses API for post-processing
9. Result copied to clipboard
10. Overlay hides after brief success message

## Key Technologies

### Dependencies

**Frontend:**
- `@tauri-apps/api` - Tauri JavaScript bindings
- `@tauri-apps/plugin-*` - Official Tauri plugins
- `vite` - Build tool & dev server
- `typescript` - Type safety

**Backend:**
- `tauri` - Core framework
- `reqwest` - HTTP client for API calls
- `serde` - JSON serialization
- `anyhow` - Error handling
- `base64` - Audio data encoding
- `dirs` - Config directory paths

## Development Workflow

### Running Development Server

```bash
npm run dev
```

This starts:
1. Vite dev server (http://localhost:5173)
2. Rust compilation (first time: ~2-5 min)
3. Tauri app window

**Hot reload**: Frontend changes hot-reload; Rust changes require restart.

### Debugging

**Frontend:**
```bash
# Dev mode includes browser devtools
npm run dev
# Then: Right-click → Inspect Element
```

**Rust:**
```bash
# Enable debug logging
RUST_LOG=debug npm run dev

# Or add to src-tauri/src/main.rs:
env_logger::init();  // In main()
```

**Console Logs:**
- Frontend: Browser console in webview
- Rust: Terminal where `npm run dev` runs

### Testing Changes

**Frontend:**
1. Edit `src/main.ts` or `src/style.css`
2. Save → page auto-reloads
3. Test: Press `Alt+Space`

**Rust:**
1. Edit `src-tauri/src/*.rs`
2. Save → Tauri rebuilds (auto)
3. App restarts automatically

## API Integration

### OpenAI Transcription

File: `src-tauri/src/openai.rs` → `transcribe_audio()`

```rust
POST https://api.openai.com/v1/audio/transcriptions
Content-Type: multipart/form-data

file: <audio.webm>
model: gpt-4o-mini-transcribe
```

### OpenAI Responses API

File: `src-tauri/src/openai.rs` → `postprocess_text()`

```rust
POST https://api.openai.com/v1/responses
Content-Type: application/json

{
  "model": "gpt-4.1-mini",
  "input": [
    {"role": "system", "content": "<prompt>"},
    {"role": "user", "content": "<transcript>"}
  ]
}
```

**Note**: If Responses API returns errors, it falls back to returning the raw transcript.

## Configuration

### User Config Location

- **Linux**: `~/.config/voxtype/config.json`
- **Windows**: `%APPDATA%\voxtype\config.json`
- **macOS**: `~/Library/Application Support/voxtype/config.json`

### Config Schema

```json
{
  "openai_api_key": "sk-...",
  "shortcut": "Alt+Space",
  "transcribe_model": "gpt-4o-mini-transcribe",
  "post_model": "gpt-4.1-mini"
}
```

### Environment Variables (Dev)

`.env` file (not committed):
```
VITE_OPENAI_API_KEY=sk-...
```

**Why VITE_ prefix?** Vite only exposes env vars with this prefix to the frontend.

## Building

### Development Build
```bash
npm run dev
```

### Release Build
```bash
npm run build

# Outputs in:
# src-tauri/target/release/bundle/
```

### Platform-Specific

**Linux:**
```bash
npm run build
# Generates: .appimage, .deb
```

**Windows:**
```bash
npm run build
# Generates: .msi
# Requires: WiX Toolset, VS Build Tools
```

**macOS:**
```bash
npm run build
# Generates: .dmg, .app
# Requires: Xcode Command Line Tools
```

## Common Tasks

### Change Global Shortcut

1. Edit `src-tauri/src/main.rs`
2. Find: `.register("Alt+Space"...`
3. Change to: `.register("Ctrl+Shift+V"...`

Or let users configure via `config.json` (already implemented).

### Modify Post-Processing Prompt

Edit `src-tauri/src/openai.rs`:

```rust
let system_prompt = "Your custom prompt here...";
```

### Add Settings UI

1. Create new window in `src-tauri/tauri.conf.json`
2. Add HTML page: `settings.html`
3. Use Tauri `invoke()` to save/load config
4. Add menu item in system tray (future)

### Customize Overlay Appearance

Edit `src/style.css`:
- `.overlay-container` - Main card styling
- `.status-text` - Status message
- `.level-bar` - Audio meter color/animation

## Troubleshooting Development Issues

### "Error: could not find `Cargo.toml`"
```bash
cd src-tauri
cargo build
cd ..
```

### TypeScript Errors
```bash
npm install
npx tsc --noEmit  # Check types
```

### Rust Compilation Slow
- First compile is slow (~2-5 min)
- Incremental rebuilds are fast (<10s)
- Use `cargo build --release` only for final builds

### Hot Reload Not Working
- Check Vite dev server is running (http://localhost:5173)
- Clear browser cache
- Restart: `npm run dev`

### OpenAI API Errors
```bash
# Test API key manually
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer YOUR_KEY"
```

### Microphone Access
- **Linux**: Check PipeWire/PulseAudio
- **Windows**: Check Privacy Settings → Microphone
- **macOS**: Check System Preferences → Privacy → Microphone

## Code Style

**TypeScript:**
- 2-space indentation
- Use `async/await` over promises
- Type everything (avoid `any`)

**Rust:**
- 4-space indentation (cargo fmt default)
- Use `?` for error propagation
- Prefer `anyhow::Result` for error types

## Performance Notes

- **Audio encoding**: webm/opus is efficient & OpenAI-compatible
- **Transcription latency**: ~1-3s for short clips
- **Post-processing**: ~0.5-1s with gpt-4.1-mini
- **Overlay render**: <16ms (60 FPS)

## Security Considerations

⚠️ **Alpha Warning**: API key stored in plaintext config.

**For production:**
1. Implement backend proxy server
2. Use OAuth for user authentication
3. Keep API keys server-side only
4. Rate-limit API calls per user

## Future Improvements

- [ ] Streaming transcription (Realtime API)
- [ ] Voice Activity Detection (auto-stop)
- [ ] Multiple output modes (type vs clipboard vs command)
- [ ] Local STT option (Whisper.cpp)
- [ ] Settings UI window
- [ ] System tray menu
- [ ] Auto-updater
- [ ] Multi-language support

---

**Questions?** Check the main README.md or file an issue.

