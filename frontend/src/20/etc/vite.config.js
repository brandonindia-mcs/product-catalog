import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd());

  return {
    publicDir: 'product-catalog-frontend/public',
    build: {
      outDir: 'build',
      emptyOutDir: true
    },
    plugins: [react()],
    server: {
      proxy: {
        '/products': {
          target: env.VITE_API_URL,
          changeOrigin: true,
          secure: false  // allow self-signed certs
        }
      }
    }
  };
});