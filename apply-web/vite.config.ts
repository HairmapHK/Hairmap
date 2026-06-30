import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';

export default defineConfig(({ command }) => ({
  base: command === 'serve' ? '/' : '/Hairmap/apply/',
  build: {
    outDir: '../docs/apply',
    emptyOutDir: true,
  },
  plugins: [react()],
}));
