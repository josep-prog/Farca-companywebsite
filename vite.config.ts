import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: parseInt(process.env.PORT || '10000'),
    allowedHosts: ['farca-companywebsite.onrender.com'],
  },
  preview: {
    host: '0.0.0.0',
    port: parseInt(process.env.PORT || '10000'),
  },
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
});
