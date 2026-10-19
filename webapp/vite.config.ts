/// <reference types="vitest/config" />
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

// https://vite.dev/config/
export default defineConfig({
  // GitHub Pages 같은 하위 경로에 배포할 때는 BASE_PATH=/meditation_app/ 처럼 지정한다.
  base: process.env.BASE_PATH ?? '/',
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'apple-touch-icon.png'],
      manifest: {
        name: '명상',
        short_name: '명상',
        description: '종소리, 배경 소리, 가이드 음성, 호흡 안내가 있는 명상 타이머',
        lang: 'ko',
        theme_color: '#3f6f75',
        background_color: '#f4f8f8',
        display: 'standalone',
        icons: [
          { src: 'icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: 'icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        // 소리 파일까지 미리 받아 두어 오프라인에서도 명상할 수 있게 한다.
        globPatterns: ['**/*.{js,css,html,svg,png,wav}'],
      },
    }),
  ],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
