import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import jsconfigPaths from 'vite-jsconfig-paths';
import path from 'path';

const withoutTrailingSlash = (value) => String(value || '').replace(/\/+$/, '');

const getApiUrl = (env) => {
  if (env.VITE_APP_API_URL) return env.VITE_APP_API_URL;

  const publicBaseUrl = env.PUBLIC_BASE_URL || env.APP_URL || env.BASE_URL || env.SERVER_URL;
  if (publicBaseUrl) return `${withoutTrailingSlash(publicBaseUrl)}/api`;

  return '/api';
};

export default defineConfig(({ mode }) => {
  const rootEnv = loadEnv(mode, path.resolve(process.cwd(), '..'), '');
  const localEnv = loadEnv(mode, process.cwd(), '');
  const env = { ...rootEnv, ...localEnv };
  const API_URL = env.VITE_APP_BASE_NAME || '/';
  const PORT = env.VITE_APP_PORT || '5173';
  const backendApiUrl = getApiUrl(env);

  return {
    server: {
      open: true,
      port: parseInt(PORT, 10),
    },
    define: {
      global: 'window',
      'import.meta.env.VITE_APP_API_URL': JSON.stringify(backendApiUrl)
    },
    resolve: {
      alias: [
        // { find: '', replacement: path.resolve(__dirname, 'src') },
        // {
        //   find: /^~(.+)/,
        //   replacement: path.join(process.cwd(), 'node_modules/$1')
        // },
        // {
        //   find: /^src(.+)/,
        //   replacement: path.join(process.cwd(), 'src/$1')
        // }
        // {
        //   find: 'assets',
        //   replacement: path.join(process.cwd(), 'src/assets')
        // },
      ]
    },
    css: {
      preprocessorOptions: {
        scss: {
          charset: false
        },
        less: {
          charset: false
        }
      },
      charset: false,
      postcss: {
        plugins: [
          {
            postcssPlugin: 'internal:charset-removal',
            AtRule: {
              charset: (atRule) => {
                if (atRule.name === 'charset') {
                  atRule.remove();
                }
              }
            }
          }
        ]
      }
    },
    base: API_URL,
    plugins: [react(), jsconfigPaths()]
  };
});
