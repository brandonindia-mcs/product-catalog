// Domain-specific API calls for the Chat feature.
// This creates a simple paradigm: feature modules call the shared apiClient.

import { apiClient } from './client'

export type ChatResponse = {
  message: string
  status: string
  env: string
  tlsEnabled: boolean
}

export function getHealth(): Promise<{ status: string }> {
  return apiClient.get('/health')
}

// export function sendChatPrompt(prompt: string): Promise<ChatResponse> {
//   return apiClient.post('/chat', { prompt })
// }

export async function sendChatPrompt(prompt: string): Promise<ChatResponse> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000); // 30s timeout

  try {
    const res = await fetch('/api/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt }),
      signal: controller.signal
    });

    clearTimeout(timeout);

    if (!res.ok) {
      const text = await res.text(); // capture raw response
      throw new Error(`HTTP ${res.status}: ${text}`);
    }

    const data = await res.json();
    return data;
  } catch (err: any) {
    if (err.name === 'AbortError') {
      throw new Error('Request timed out');
    }
    throw err;
  }
}


export async function getWelcome(): Promise<string> {
  const res = await fetch('/api/welcome');
  if (!res.ok) {
    throw new Error(`HTTP error! status: ${res.status}`);
  }

  const data = await res.json();
  return data.message; // Extract the message field from JSON
}
