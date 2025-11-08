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
    // https: false, // <-- this disables HTTPS
    server: {
      proxy: {
        // proxy product lookups to the API backend
        '/products': {
          target: env.VITE_API_URL,
          changeOrigin: true,
          secure: false
        },
        // optional: proxy health or other internal paths used by frontend dev tooling
        '/health': {
          target: env.VITE_API_URL,
          changeOrigin: true,
          secure: false
        }
      }
    }
  };
});

