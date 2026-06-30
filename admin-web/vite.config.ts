import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig({
  base: process.env.VITE_GITHUB_PAGES === 'true' ? '/Hairmap/admin/' : '/',
  build: {
    outDir: '../docs/admin',
    emptyOutDir: false,
  },
  plugins: [react()],
});
