import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Vite config for both dev and production
export default defineConfig({
  plugins: [react()],
  base: '/', // app is served at domain root
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
})
