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

export function getWelcome(): Promise<{ message: string }> {
  return apiClient.get('/welcome')
}

export function sendChatPrompt(prompt: string): Promise<ChatResponse> {
  return apiClient.post('/chat', { prompt })
}
