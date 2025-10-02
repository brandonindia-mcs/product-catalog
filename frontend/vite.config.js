import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  root: 'product-catalog-frontend',
  publicDir: 'product-catalog-frontend/public',
  build: {
    outDir: 'build',
    emptyOutDir: true
  },
  plugins: [react()],
  server: {
    proxy: {
      '/products': 'http://localhost:3000'
    }
  }
})
