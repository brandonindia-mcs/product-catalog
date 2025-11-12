type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE'

const BASE_PATH = '/api'
const DEBUG = import.meta.env.VITE_DEBUG === 'true'

async function request<T>(
  path: string,
  method: HttpMethod = 'GET',
  body?: unknown,
  timeoutMs = 30_000
): Promise<T> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), timeoutMs)

  const url = `${BASE_PATH}${path}`
  const options: RequestInit = {
    method,
    headers: { 'Content-Type': 'application/json' },
    signal: controller.signal,
    body: body ? JSON.stringify(body) : undefined,
  }

  if (DEBUG) console.log(`[client] ${method} ${url}`, body)

  try {
    const res = await fetch(url, options)
    clearTimeout(timeout)

    if (!res.ok) {
      const text = await res.text()
      throw new Error(`HTTP ${res.status}: ${text || res.statusText}`)
    }

    // Safer JSON parsing
    return (await res.json()) as T
  } catch (err: unknown) {
    if (err instanceof DOMException && err.name === 'AbortError') {
      throw new Error('Request timed out')
    }
    throw err
  }
}

export const apiClient = {
  get: <T>(path: string, timeoutMs?: number) =>
    request<T>(path, 'GET', undefined, timeoutMs),
  post: <T>(path: string, data: unknown, timeoutMs?: number) =>
    request<T>(path, 'POST', data, timeoutMs),
}
