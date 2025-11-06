// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod openai;
mod config;

use tauri::{Manager, Emitter};
use tauri_plugin_global_shortcut::{GlobalShortcutExt, Shortcut};
use tauri_plugin_clipboard_manager::ClipboardExt;
use std::sync::Mutex;

struct AppState {
    config: Mutex<config::Config>,
}

#[tauri::command]
async fn transcribe_audio(
    audio_data: String,
    state: tauri::State<'_, AppState>,
    app: tauri::AppHandle,
) -> Result<String, String> {
    let config = state.config.lock().unwrap().clone();
    
    // Decode base64 audio
    use base64::Engine;
    let audio_bytes = base64::engine::general_purpose::STANDARD
        .decode(&audio_data)
        .map_err(|e| format!("Failed to decode audio: {}", e))?;
    
    // Transcribe
    let transcript = openai::transcribe_audio(&audio_bytes, &config.openai_api_key)
        .await
        .map_err(|e| format!("Transcription failed: {}", e))?;
    
    // Post-process
    let processed = openai::postprocess_text(&transcript, &config.openai_api_key)
        .await
        .map_err(|e| format!("Post-processing failed: {}", e))?;
    
    // Copy to clipboard
    app.clipboard()
        .write_text(&processed)
        .map_err(|e| format!("Failed to copy to clipboard: {}", e))?;
    
    Ok(processed)
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            // Load configuration
            let config = config::Config::load()
                .unwrap_or_else(|e| {
                    eprintln!("Failed to load config, using defaults: {}", e);
                    config::Config::default()
                });
            
            app.manage(AppState {
                config: Mutex::new(config.clone()),
            });
            
            // Get overlay window
            let overlay = app.get_webview_window("overlay").unwrap();
            
            // Register global shortcut
            let shortcut_str = &config.shortcut;
            let shortcut = shortcut_str.parse::<Shortcut>()
                .unwrap_or_else(|_| "Ctrl+Shift+Space".parse().unwrap());
            
            let overlay_clone = overlay.clone();
            if let Err(e) = app.global_shortcut().on_shortcut(shortcut, move |_app, _shortcut, _event| {
                overlay_clone.emit("toggle-record", ()).ok();
            }) {
                eprintln!("⚠️  Warning: Failed to set up hotkey handler '{}': {}", shortcut_str, e);
                eprintln!("   The app will continue without global hotkey support.");
            } else if let Err(e) = app.global_shortcut().register(shortcut) {
                eprintln!("⚠️  Warning: Failed to register hotkey '{}': {}", shortcut_str, e);
                eprintln!("   The app will still work, but the global hotkey won't be available.");
                eprintln!("   You may need to restart your system to clear stuck hotkeys.");
                eprintln!("   Alternative: Change shortcut in ~/.config/voxtype/config.json");
            } else {
                println!("✅ voxtype started. Press {} to activate.", shortcut_str);
            }
            
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![transcribe_audio])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

