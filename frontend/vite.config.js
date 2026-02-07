import { fileURLToPath, URL } from 'node:url'

import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
import { defineConfig, loadEnv } from 'vite'

// ============================================================================
// Vite 7.3.1 Configuration - Optimized for 2026
// ============================================================================
// This configuration leverages Vite 7's new features:
// - New browser target: 'baseline-widely-available'
// - Improved build performance
// - Better tree-shaking
// - Enhanced HMR
// ============================================================================

export default defineConfig(({ mode }) => {
  // Load environment variables
  const env = loadEnv(mode, process.cwd(), '')

  return {
    // ========================================================================
    // Plugins
    // ========================================================================
    plugins: [
      tailwindcss(),
      vue({
        script: {
          defineModel: true,
          propsDestructure: true,
        },
      }),
    ],

    // ========================================================================
    // Path Resolution
    // ========================================================================
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
        '@components': fileURLToPath(new URL('./src/components', import.meta.url)),
        '@views': fileURLToPath(new URL('./src/views', import.meta.url)),
        '@stores': fileURLToPath(new URL('./src/stores', import.meta.url)),
        '@services': fileURLToPath(new URL('./src/services', import.meta.url)),
        '@composables': fileURLToPath(new URL('./src/composables', import.meta.url)),
        '@utils': fileURLToPath(new URL('./src/utils', import.meta.url)),
        '@config': fileURLToPath(new URL('./src/config', import.meta.url)),
        '@assets': fileURLToPath(new URL('./src/assets', import.meta.url)),
      },
    },

    // ========================================================================
    // Development Server
    // ========================================================================
    server: {
      port: 5173,
      strictPort: false,
      host: true,
      open: false,
      cors: true,
      
      // Proxy API requests to Rails backend
      proxy: {
        '/api': {
          target: env.VITE_API_BASE_URL || 'http://localhost:3000',
          changeOrigin: true,
          secure: false,
        },
      },
      
      // Vite 7: Improved HMR
      hmr: {
        overlay: true,
      },
    },

    // ========================================================================
    // Preview Server (for production builds)
    // ========================================================================
    preview: {
      port: 4173,
      strictPort: false,
      host: true,
      open: false,
    },

    // ========================================================================
    // Build Configuration
    // ========================================================================
    build: {
      // Output directory
      outDir: 'dist',

      // Generate source maps for production (optional)
      sourcemap: mode === 'production' ? false : true,

      // Minification
      minify: 'esbuild',

      // Vite 7: New default target (baseline-widely-available)
      // Targets browsers released at least 2.5 years ago
      target: 'baseline-widely-available',

      // Chunk size warning limit (500kb)
      chunkSizeWarningLimit: 500,

      // Rollup options
      rollupOptions: {
        output: {
          // Manual chunks for better caching
          manualChunks: {
            // Vue core
            'vue-core': ['vue', 'vue-router', 'pinia'],

            // Third-party libraries
            'vendor-utils': ['axios', '@vueuse/core'],

            // Form validation
            'vendor-forms': ['vee-validate', 'yup'],
          },

          // Asset file naming
          assetFileNames: (assetInfo) => {
            const info = assetInfo.name.split('.')
            let extType = info[info.length - 1]

            // Group assets by type
            if (/\.(png|jpe?g|svg|gif|tiff|bmp|ico|webp)$/i.test(assetInfo.name)) {
              extType = 'images'
            } else if (/\.(woff2?|eot|ttf|otf)$/i.test(assetInfo.name)) {
              extType = 'fonts'
            } else if (/\.css$/i.test(assetInfo.name)) {
              extType = 'css'
            }

            return `assets/${extType}/[name]-[hash][extname]`
          },

          // Chunk file naming
          chunkFileNames: 'assets/js/[name]-[hash].js',

          // Entry file naming
          entryFileNames: 'assets/js/[name]-[hash].js',
        },
      },

      // CSS code splitting
      cssCodeSplit: true,

      // Report compressed size
      reportCompressedSize: true,

      // Vite 7: Improved CSS minification
      cssMinify: true,
    },

    // ========================================================================
    // CSS Configuration
    // ========================================================================
    css: {
      devSourcemap: true,
    },

    // ========================================================================
    // Dependency Optimization
    // ========================================================================
    optimizeDeps: {
      include: [
        'vue',
        'vue-router',
        'pinia',
        'axios',
        '@vueuse/core',
        'vee-validate',
        'yup',
      ],
      exclude: [],
    },

    // ========================================================================
    // Esbuild Configuration (Vite 7 uses latest esbuild)
    // ========================================================================
    esbuild: {
      // Drop console and debugger in production
      drop: mode === 'production' ? ['console', 'debugger'] : [],
    },
  }
})