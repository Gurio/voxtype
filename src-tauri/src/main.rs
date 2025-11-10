// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod config;
mod openai;

use std::sync::Mutex;
use tauri::{Emitter, Manager};
use tauri_plugin_clipboard_manager::ClipboardExt;
use tauri_plugin_global_shortcut::{GlobalShortcutExt, Shortcut};

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
        .plugin(tauri_plugin_single_instance::init(|_app, _args, _cwd| {}))
        .plugin(tauri_plugin_clipboard_manager::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            // Load configuration
            let config = config::Config::load().unwrap_or_else(|e| {
                eprintln!("Failed to load config, using defaults: {}", e);
                config::Config::default()
            });

            app.manage(AppState {
                config: Mutex::new(config.clone()),
            });

            // Get overlay window
            let overlay = app.get_webview_window("overlay").unwrap();

            // Try to register global shortcut with intelligent fallback
            let fallback_hotkeys = vec![
                config.shortcut.as_str(), // User's preference first
                "F12",
                "F11", 
                "F10",
                "F9",
                "Pause",
                "ScrollLock",
                "Insert",
                "F8",
                "F7",
            ];

            let mut registered_hotkey: Option<String> = None;

            for hotkey_str in fallback_hotkeys {
                if let Ok(shortcut) = hotkey_str.parse::<Shortcut>() {
                    let overlay_clone = overlay.clone();
                    
                    // Try to set up handler
                    if app.global_shortcut()
                        .on_shortcut(shortcut.clone(), move |_app, _shortcut, _event| {
                            overlay_clone.emit("toggle-record", ()).ok();
                        })
                        .is_err()
                    {
                        continue; // Try next hotkey
                    }
                    
                    // Try to register
                    if app.global_shortcut().register(shortcut).is_ok() {
                        registered_hotkey = Some(hotkey_str.to_string());
                        
                        // If we used a fallback (not user's preference), update config
                        if hotkey_str != config.shortcut {
                            println!("⚠️  Configured hotkey '{}' was taken.", config.shortcut);
                            println!("✅ Auto-selected working hotkey: {}", hotkey_str);
                            
                            let mut new_config = config.clone();
                            new_config.shortcut = hotkey_str.to_string();
                            if let Err(e) = new_config.save() {
                                eprintln!("   Warning: Could not save new hotkey to config: {}", e);
                            } else {
                                println!("   Updated config file with new hotkey.");
                            }
                        } else {
                            println!("✅ voxtype started. Press {} to activate.", hotkey_str);
                        }
                        
                        break;
                    }
                }
            }

            if registered_hotkey.is_none() {
                eprintln!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                eprintln!("⚠️  Could not register ANY hotkey!");
                eprintln!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                eprintln!("");
                eprintln!("This usually means:");
                eprintln!("  1. Another voxtype instance is running");
                eprintln!("  2. Your system has many hotkeys registered");
                eprintln!("  3. A system restart is needed to clear stuck keys");
                eprintln!("");
                eprintln!("Solutions:");
                eprintln!("  • Kill other instances: pkill -9 voxtype");
                eprintln!("  • Restart your computer: sudo reboot");
                eprintln!("");
                eprintln!("The app will continue but WITHOUT hotkey support.");
                eprintln!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![transcribe_audio])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
