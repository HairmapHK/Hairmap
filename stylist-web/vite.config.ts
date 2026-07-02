import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig(({ command }) => ({
  base: command === 'serve' ? '/' : '/Hairmap/stylist/',
  build: {
    outDir: '../docs/stylist',
    emptyOutDir: true,
  },
  plugins: [react()],
}));
