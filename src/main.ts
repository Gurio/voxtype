import './style.css';
import { getCurrentWindow } from '@tauri-apps/api/window';
import { listen } from '@tauri-apps/api/event';
import { invoke } from '@tauri-apps/api/core';

const appEl = document.getElementById('app')!;

// Overlay state
let isRecording = false;
let mediaStream: MediaStream | null = null;
let mediaRecorder: MediaRecorder | null = null;
let audioChunks: Blob[] = [];
let animationFrame: number | null = null;
let audioContext: AudioContext | null = null;
let analyser: AnalyserNode | null = null;

// UI Elements
appEl.innerHTML = `
  <div class="overlay-container">
    <div class="status-text" id="status">Ready</div>
    <div class="level-meter">
      <div class="level-bar" id="levelBar"></div>
    </div>
    <div class="controls">
      <button id="stopBtn" class="stop-btn" style="display: none;">Stop (Enter)</button>
    </div>
  </div>
`;

const statusEl = document.getElementById('status')!;
const levelBar = document.getElementById('levelBar')!;
const stopBtn = document.getElementById('stopBtn')!;

// Audio level visualization
function updateLevelMeter() {
  if (!analyser || !isRecording) {
    levelBar.style.width = '0%';
    return;
  }

  const dataArray = new Uint8Array(analyser.frequencyBinCount);
  analyser.getByteFrequencyData(dataArray);
  
  const average = dataArray.reduce((a, b) => a + b) / dataArray.length;
  const level = Math.min(100, (average / 255) * 100 * 2); // Amplify for visibility
  
  levelBar.style.width = `${level}%`;
  
  animationFrame = requestAnimationFrame(updateLevelMeter);
}

async function startRecording() {
  try {
    statusEl.textContent = 'Listening...';
    isRecording = true;
    audioChunks = [];
    
    // Show stop button
    stopBtn.style.display = 'block';
    
    // Get audio stream
    mediaStream = await navigator.mediaDevices.getUserMedia({ 
      audio: {
        channelCount: 1,
        sampleRate: 16000,
        echoCancellation: true,
        noiseSuppression: true,
      } 
    });
    
    // Set up audio level monitoring
    audioContext = new AudioContext();
    const source = audioContext.createMediaStreamSource(mediaStream);
    analyser = audioContext.createAnalyser();
    analyser.fftSize = 256;
    source.connect(analyser);
    
    updateLevelMeter();
    
    // Start recording
    const options = { mimeType: 'audio/webm;codecs=opus' };
    mediaRecorder = new MediaRecorder(mediaStream, options);
    
    mediaRecorder.ondataavailable = (event) => {
      if (event.data.size > 0) {
        audioChunks.push(event.data);
      }
    };
    
    mediaRecorder.onstop = async () => {
      await processAudio();
    };
    
    mediaRecorder.start();
    
  } catch (error) {
    console.error('Failed to start recording:', error);
    statusEl.textContent = 'Microphone access denied';
    cleanup();
  }
}

async function stopRecording() {
  if (!isRecording || !mediaRecorder) return;
  
  isRecording = false;
  statusEl.textContent = 'Processing...';
  stopBtn.style.display = 'none';
  
  if (animationFrame) {
    cancelAnimationFrame(animationFrame);
    animationFrame = null;
  }
  
  mediaRecorder.stop();
}

async function processAudio() {
  try {
    const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
    
    // Convert blob to base64 for sending to Rust backend
    const reader = new FileReader();
    reader.onloadend = async () => {
      const base64Audio = (reader.result as string).split(',')[1];
      
      try {
        // Call Rust backend to transcribe
        statusEl.textContent = 'Transcribing...';
        const result = await invoke<string>('transcribe_audio', { audioData: base64Audio });
        
        statusEl.textContent = 'Copied to clipboard!';
        
        // Hide overlay after brief delay
        setTimeout(async () => {
          await getCurrentWindow().hide();
          statusEl.textContent = 'Ready';
        }, 1500);
        
      } catch (error) {
        console.error('Transcription failed:', error);
        statusEl.textContent = `Error: ${error}`;
        setTimeout(() => statusEl.textContent = 'Ready', 3000);
      }
    };
    
    reader.readAsDataURL(audioBlob);
    
  } finally {
    cleanup();
  }
}

function cleanup() {
  if (mediaStream) {
    mediaStream.getTracks().forEach(track => track.stop());
    mediaStream = null;
  }
  
  if (audioContext) {
    audioContext.close();
    audioContext = null;
  }
  
  analyser = null;
  mediaRecorder = null;
  audioChunks = [];
  isRecording = false;
  levelBar.style.width = '0%';
  stopBtn.style.display = 'none';
}

// Listen for toggle event from Rust
await listen('toggle-record', async () => {
  const window = getCurrentWindow();
  const isVisible = await window.isVisible();
  
  if (!isVisible) {
    // Show and start recording
    await window.show();
    await window.setFocus();
    await startRecording();
  } else if (isRecording) {
    // Stop recording
    await stopRecording();
  } else {
    // Hide if visible but not recording
    await window.hide();
    statusEl.textContent = 'Ready';
  }
});

// Stop button handler
stopBtn.addEventListener('click', () => {
  stopRecording();
});

// Enter key handler
document.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && isRecording) {
    e.preventDefault();
    stopRecording();
  }
});

console.log('voxtype overlay ready');

