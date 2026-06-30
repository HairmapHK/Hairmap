import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig(({ command }) => ({
  base: command === 'serve' ? '/' : '/Hairmap/admin/',
  build: {
    outDir: '../docs/admin',
    emptyOutDir: false,
  },
  plugins: [react()],
}));
