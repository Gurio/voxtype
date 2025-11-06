use anyhow::{Result, Context};
use reqwest::multipart;
use serde::{Deserialize, Serialize};

const OPENAI_API_BASE: &str = "https://api.openai.com/v1";

#[derive(Debug, Deserialize)]
struct TranscriptionResponse {
    text: String,
}

#[derive(Debug, Serialize)]
struct ResponsesRequest {
    model: String,
    input: Vec<Message>,
}

#[derive(Debug, Serialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct ResponsesOutput {
    output_text: Option<String>,
    choices: Option<Vec<Choice>>,
}

#[derive(Debug, Deserialize)]
struct Choice {
    message: Option<MessageContent>,
}

#[derive(Debug, Deserialize)]
struct MessageContent {
    content: Option<String>,
}

pub async fn transcribe_audio(audio_data: &[u8], api_key: &str) -> Result<String> {
    let client = reqwest::Client::new();
    
    // Create multipart form
    let part = multipart::Part::bytes(audio_data.to_vec())
        .file_name("audio.webm")
        .mime_str("audio/webm")?;
    
    let form = multipart::Form::new()
        .part("file", part)
        .text("model", "gpt-4o-mini-transcribe");
    
    let response = client
        .post(format!("{}/audio/transcriptions", OPENAI_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .multipart(form)
        .send()
        .await
        .context("Failed to send transcription request")?;
    
    if !response.status().is_success() {
        let error_text = response.text().await?;
        return Err(anyhow::anyhow!("OpenAI API error: {}", error_text));
    }
    
    let transcription: TranscriptionResponse = response.json().await?;
    Ok(transcription.text)
}

pub async fn postprocess_text(transcript: &str, api_key: &str) -> Result<String> {
    let client = reqwest::Client::new();
    
    let system_prompt = "You normalize raw speech transcripts for typing. \
        Apply natural punctuation and capitalization. \
        Convert spoken punctuation words (comma, period, question mark, exclamation point, new line) into symbols. \
        Keep it concise and well-formatted for messaging, shell commands, or AI prompts. \
        Return ONLY the final text, no quotes or explanations.";
    
    let request = ResponsesRequest {
        model: "gpt-4.1-mini".to_string(),
        input: vec![
            Message {
                role: "system".to_string(),
                content: system_prompt.to_string(),
            },
            Message {
                role: "user".to_string(),
                content: transcript.to_string(),
            },
        ],
    };
    
    let response = client
        .post(format!("{}/responses", OPENAI_API_BASE))
        .header("Authorization", format!("Bearer {}", api_key))
        .json(&request)
        .send()
        .await
        .context("Failed to send responses request")?;
    
    if !response.status().is_success() {
        let error_text = response.text().await?;
        return Err(anyhow::anyhow!("OpenAI Responses API error: {}", error_text));
    }
    
    let output: ResponsesOutput = response.json().await?;
    
    // Try to extract text from response
    if let Some(text) = output.output_text {
        return Ok(text.trim().to_string());
    }
    
    if let Some(choices) = output.choices {
        if let Some(choice) = choices.first() {
            if let Some(message) = &choice.message {
                if let Some(content) = &message.content {
                    return Ok(content.trim().to_string());
                }
            }
        }
    }
    
    // Fallback: return original transcript
    Ok(transcript.to_string())
}

