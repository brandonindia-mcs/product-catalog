import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { env } from 'process'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5174,
    proxy: {
      '/products': {
        target: env.VITE_API_URL,
        // rewrite: path => path.replace(/^\/catalog/, ''),
        changeOrigin: true,
        secure: false
      },
      '/api/chat': {
        target: env.VITE_CHAT_URL,
        // rewrite: path => path.replace(/^\/catalog/, ''),
        changeOrigin: true,
        secure: false
      }
    }
  }
})
