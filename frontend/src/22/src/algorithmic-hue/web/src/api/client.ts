// Lightweight API client layer (DAO-style): centralizes fetch, paths, and error handling.
// This enforces a clean separation between UI components and data access.

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'

const BASE_PATH = '/api' // relative path to leverage Vite dev proxy and avoid CORS/TLS in dev

async function request<T>(path: string, method: HttpMethod = 'GET', body?: unknown): Promise<T> {
  const res = await fetch(`${BASE_PATH}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json'
    },
    body: body ? JSON.stringify(body) : undefined
    // Intentionally no HTTPS/TLS here for dev; we rely on proxy and HTTP 200 responses.
  })

  if (!res.ok) {
    const text = await res.text().catch(() => '')
    throw new Error(`HTTP ${res.status}: ${text || res.statusText}`)
  }
  return res.json() as Promise<T>
}

export const apiClient = {
  get: <T>(path: string) => request<T>(path, 'GET'),
  post: <T>(path: string, data: unknown) => request<T>(path, 'POST', data)
}
