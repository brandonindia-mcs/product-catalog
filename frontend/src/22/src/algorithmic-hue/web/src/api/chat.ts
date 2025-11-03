// Domain-specific API calls for the Chat feature.
// This creates a simple paradigm: feature modules call the shared apiClient.

import { apiClient } from './client'

export type ChatResponse = { reply: string }

export function getHealth(): Promise<{ status: string }> {
  return apiClient.get('/health')
}

export function sendChatMessage(message: string): Promise<ChatResponse> {
  return apiClient.post('/chat', { message })
}

export async function getWelcome(): Promise<string> {
  const res = await fetch('/api/welcome')
  const text = await res.text() // ← parse as plain text
  return text
}
