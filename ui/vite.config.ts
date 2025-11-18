import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [
      react(),
      tailwindcss()
    ],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
        crypto: 'crypto-browserify',
      },
    },
    css: {preprocessorOptions: {less: {javascriptEnabled: true},},},
    server: {
      // 修改为监听所有接口，而不是特定主机名
      host: '0.0.0.0',
      port: 3000,
      allowedHosts: true,
      proxy: {
        '/web': {
          target: env.SERVICE_BASE_URL,
          changeOrigin: true,
        },
      },
    },
    define: {
      // 一定要序列化，否则打包时会报错
      SERVICE_BASE_URL: JSON.stringify(env.SERVICE_BASE_URL),
    },
    build: {
      outDir: 'dist',
      sourcemap: false,
      minify: 'esbuild', // 使用 esbuild 而不是 terser，更省内存
      rollupOptions: {
        output: {
          inlineDynamicImports: true,
          manualChunks: undefined, // 禁用代码分割以减少内存使用
        },
      },
      cssCodeSplit: false,
      cssMinify: 'lightningcss', // 使用 lightningcss 而不是 esbuild 处理 CSS
      chunkSizeWarningLimit: 1000, // 增加 chunk 大小警告限制
    },
  }
});
