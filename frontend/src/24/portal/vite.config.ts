import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { env } from 'process'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // base: '/portal/',
  server: {
    host: '0.0.0.0',
    port: 5174,
    proxy: {
      '/products': {
        target: env.VITE_API_URL,
        changeOrigin: true,
        secure: false
      },
      '/api': {
        // target: env.VITE_CHAT_URL,
        target: 'http://product-catalog.progress.notls:32001',
        changeOrigin: true,
        secure: false,
      },
      // '/api/welcome': {
      //   target: env.VITE_CHAT_URL,
      //   changeOrigin: true,
      //   secure: false,
      // },
      // '/api/chat': {
      //   target: env.VITE_CHAT_URL,
      //   changeOrigin: true,
      //   secure: false,

        // Your backend expects /portal/api/chat
        // Your frontend sends /portal/api/chat
        // Vite rewrites /portal/api/chat → /api/chat
        // before proxying to http://product-catalog.progress.notls:32001
        // rewrite: path => path.replace(/^\/portal\/api/, '/api')

      // }
    }
  }
})
