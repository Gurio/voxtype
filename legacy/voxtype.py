#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse, os, sys, shutil, tempfile, time, subprocess, wave, queue
import numpy as np
import sounddevice as sd
import soundfile as sf
import yaml

# --- Config defaults ---
DEFAULT_CONFIG = {
    "provider": "openai",
    "openai": {
        "transcribe_model": "gpt-4o-mini-transcribe",  # fast, robust
        "post_model": "gpt-4.1-mini"                   # for emoji/command formatting
    },
    "recording": {
        "samplerate": 16000,
        "channels": 1,
        "max_seconds": 60,
        "silence_threshold": 0.008,   # 0..1 (lower = more sensitive)
        "silence_ms_to_stop": 900,    # stop after ~0.9s of silence
        "device": None                # None = default; or set a specific device name/index
    },
    "dictate": {
        "insert_emoji": True,
        "smart_punctuation": True
    },
    "command": {
        "confirm": True,     # require zenity confirmation before running
        "terminal": "gnome-terminal", # or "xterm", "konsole" etc.
        "on_cancel": "type"  # "type" (type the command) or "clipboard"
    }
}

CONFIG_PATH = os.path.expanduser("~/.config/voicectl/config.yaml")

def load_config():
    cfg = DEFAULT_CONFIG.copy()
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            user = yaml.safe_load(f) or {}
        # deep merge:
        def dmerge(a,b):
            for k,v in b.items():
                if isinstance(v, dict) and isinstance(a.get(k), dict):
                    dmerge(a[k], v)
                else:
                    a[k] = v
        dmerge(cfg, user)
    return cfg

def notify(summary, body=None):
    if shutil.which("notify-send"):
        args = ["notify-send", summary]
        if body:
            args += [body]
        subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def is_wayland():
    return os.environ.get("XDG_SESSION_TYPE","").lower()=="wayland"

def type_text(text):
    # Prefer wtype on Wayland, xdotool on X11; fallback to clipboard.
    if is_wayland() and shutil.which("wtype"):
        subprocess.run(["wtype", text])
    elif not is_wayland() and shutil.which("xdotool"):
        subprocess.run(["xdotool","type","--clearmodifiers","--delay","2", text])
    else:
        # Fallback: put into clipboard and tell user to paste
        if shutil.which("wl-copy"):
            subprocess.run(["wl-copy"], input=text.encode("utf-8"))
        elif shutil.which("xclip"):
            subprocess.run(["xclip","-selection","clipboard"], input=text.encode("utf-8"))
        notify("voicectl", "Typed input unavailable. Text copied to clipboard.")

def confirm_dialog(question_text):
    # Returns True if user clicked "OK"
    if shutil.which("zenity"):
        res = subprocess.run(["zenity","--question","--text",question_text])
        return res.returncode == 0
    # No zenity → auto-confirm
    return True

# --- Audio capture with simple VAD ---
def record_once(cfg, out_wav):
    sr = cfg["recording"]["samplerate"]
    channels = cfg["recording"]["channels"]
    max_seconds = cfg["recording"]["max_seconds"]
    silence_threshold = cfg["recording"]["silence_threshold"]
    silence_ms_to_stop = cfg["recording"]["silence_ms_to_stop"]
    device = cfg["recording"]["device"]

    block_ms = 20
    blocksize = int(sr * block_ms / 1000)
    qbuf = []
    silence_ms = 0
    started_talking = False

    notify("🎙️ Listening...", "Speak now")

    def callback(indata, frames, time_info, status):
        nonlocal silence_ms, started_talking
        if status:
            pass
        data = indata.copy()
        # simple energy-based VAD
        level = float(np.mean(np.abs(data)))
        qbuf.append(data)
        if level > silence_threshold:
            started_talking = True
            silence_ms = 0
        else:
            if started_talking:
                silence_ms += block_ms

    with sd.InputStream(samplerate=sr, channels=channels, blocksize=blocksize,
                        callback=callback, dtype='float32', device=device):
        t0 = time.time()
        while True:
            time.sleep(block_ms/1000.0)
            if started_talking and silence_ms >= silence_ms_to_stop:
                break
            if time.time() - t0 > max_seconds:
                break

    # assemble, write wav (16-bit PCM)
    if not qbuf:
        # capture a small silence so Whisper doesn't error
        qbuf = [np.zeros((blocksize, channels), dtype=np.float32)]
    audio = np.concatenate(qbuf, axis=0)
    sf.write(out_wav, audio, sr, subtype="PCM_16")
    notify("✅ Captured", None)

# --- OpenAI helpers ---
def openai_transcribe(cfg, wav_path):
    from openai import OpenAI
    client = OpenAI()
    model = cfg["openai"]["transcribe_model"]
    with open(wav_path, "rb") as f:
        resp = client.audio.transcriptions.create(
            model=model,
            file=f
        )
    # .text for Whisper-compatible responses; fallback to best guess:
    text = getattr(resp, "text", None) or getattr(resp, "text", "") or str(resp)
    return text.strip()

def openai_postprocess(cfg, mode, transcript):
    """
    mode: "dictate" or "command"
    Returns processed text or command string
    """
    from openai import OpenAI
    client = OpenAI()
    model = cfg["openai"]["post_model"]

    if mode == "dictate":
        insert_emoji = cfg["dictate"]["insert_emoji"]
        smart_punct = cfg["dictate"]["smart_punctuation"]
        sys_prompt = (
            "You normalize raw speech transcripts for on-screen typing. "
            "Apply natural punctuation/capitalization. Convert spoken punctuation words (comma, period, question mark, exclamation point, new line) into symbols. "
            f"{'Tasteful emoji substitutions are allowed (e.g., “smile” → 🙂) but keep it minimal.' if insert_emoji else 'Do not insert any emoji.'} "
            f"{'Fix common homophones and casing for names/brands.' if smart_punct else ''} "
            "Return ONLY the final text, no quotes."
        )
    else:
        # command mode
        sys_prompt = (
            "You convert speech to a single shell command (bash). "
            "Interpret natural phrases like 'list files' → 'ls -la', 'search for TODOs recursively' → 'grep -R \"TODO\" .'. "
            "NEVER include explanations or code fences. Output ONE line, safe and portable. "
            "If the user dictated something that is clearly not a command, return a harmless echo, e.g., echo '<text>'."
        )

    resp = client.responses.create(
        model=model,
        input=[
            {"role":"system","content":sys_prompt},
            {"role":"user","content":transcript}
        ]
    )
    # SDK v1: aggregate to plain string
    try:
        return resp.output_text.strip()
    except Exception:
        # fallback: try to read content parts
        if hasattr(resp, "choices") and resp.choices:
            c = resp.choices[0]
            if hasattr(c, "message") and c.message and c.message.content:
                # content could be list of parts
                parts = c.message.content
                if isinstance(parts, list) and parts and hasattr(parts[0], "text"):
                    return parts[0].text.strip()
        return transcript.strip()

# --- Actions ---
def do_dictate(cfg):
    with tempfile.TemporaryDirectory() as td:
        wavp = os.path.join(td, "in.wav")
        record_once(cfg, wavp)
        text = openai_transcribe(cfg, wavp)
        text = openai_postprocess(cfg, "dictate", text)
        if text:
            type_text(text)

def run_in_terminal(terminal, cmd):
    if terminal == "gnome-terminal":
        subprocess.Popen(["gnome-terminal","--", "bash", "-lc", f"{cmd}; echo; read -p 'Press Enter to close' _"])
    elif terminal == "xterm":
        subprocess.Popen(["xterm","-e", f"bash -lc '{cmd}; echo; read -p \"Press Enter to close\" _'"])
    elif terminal == "konsole":
        subprocess.Popen(["konsole","-e", "bash", "-lc", f"{cmd}; echo; read -p 'Press Enter to close' _"])
    else:
        # Fallback: try to run detached
        subprocess.Popen(["bash","-lc", cmd])

def do_command(cfg):
    with tempfile.TemporaryDirectory() as td:
        wavp = os.path.join(td, "in.wav")
        record_once(cfg, wavp)
        text = openai_transcribe(cfg, wavp)
        cmd = openai_postprocess(cfg, "command", text)

        if not cmd:
            notify("voicectl", "No command recognized.")
            return

        if cfg["command"]["confirm"]:
            ok = confirm_dialog(f"Run this command?\n\n{cmd}")
            if ok:
                run_in_terminal(cfg["command"]["terminal"], cmd)
                return
        # on cancel or no confirm
        if cfg["command"]["on_cancel"] == "type":
            type_text(cmd)
        else:
            # clipboard
            if shutil.which("wl-copy"):
                subprocess.run(["wl-copy"], input=cmd.encode("utf-8"))
            elif shutil.which("xclip"):
                subprocess.run(["xclip","-selection","clipboard"], input=cmd.encode("utf-8"))
            notify("voicectl", "Command copied to clipboard.")

def main():
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    if not os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "w") as f:
            yaml.safe_dump(DEFAULT_CONFIG, f)

    cfg = load_config()

    ap = argparse.ArgumentParser(prog="voicectl", description="Hotkey voice dictation & commands for Linux")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("dictate", help="Transcribe and type into active window")
    sub.add_parser("command", help="Transcribe, turn into shell command, confirm, then run")

    args = ap.parse_args()

    if not os.environ.get("OPENAI_API_KEY"):
        print("OPENAI_API_KEY not set", file=sys.stderr)
        notify("voicectl error", "OPENAI_API_KEY not set")
        sys.exit(1)

    if args.cmd == "dictate":
        do_dictate(cfg)
    elif args.cmd == "command":
        do_command(cfg)

if __name__ == "__main__":
    main()