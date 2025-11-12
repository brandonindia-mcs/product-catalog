import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  // Load all env vars (both .env and process env), no prefix filter
  const env = loadEnv(mode, process.cwd(), '')

  const apiUrl = env.VITE_API_URL
  const chatUrl = env.VITE_CHAT_URL

  return {
    plugins: [react()],
    // base: '/portal/',
    server: {
      host: '0.0.0.0',
      port: 5174,
      proxy: {
        '/products': {
          target: apiUrl,
          changeOrigin: true,
          secure: false,
        },
        '/api': {
          target: chatUrl,
          changeOrigin: true,
          secure: false,
          // If your frontend sends /portal/api/*, rewrite it to /api/*
          rewrite: path => path.replace(/^\/portal\/api/, '/api'),
        },
      },
    },
  }
})
