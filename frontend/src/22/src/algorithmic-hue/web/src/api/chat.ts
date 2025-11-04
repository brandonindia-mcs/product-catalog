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

export function sendChatPrompt(prompt: string): Promise<ChatResponse> {
  return apiClient.post('/chat', { prompt })
}

export async function getWelcome(): Promise<string> {
  const res = await fetch('/api/welcome');
  if (!res.ok) {
    throw new Error(`HTTP error! status: ${res.status}`);
  }

  const data = await res.json();
  return data.message; // Extract the message field from JSON
}
