import js from '@eslint/js';
import typescript from '@typescript-eslint/eslint-plugin';
import typescriptParser from '@typescript-eslint/parser';

export default [
  js.configs.recommended,
  {
    files: ['src/**/*.ts'],
    languageOptions: {
      parser: typescriptParser,
      ecmaVersion: 2020,
      sourceType: 'module',
      globals: {
        console: 'readonly',
        process: 'readonly',
        Buffer: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        exports: 'readonly',
        module: 'readonly',
        require: 'readonly',
        global: 'readonly',
        Response: 'readonly',
        Request: 'readonly',
        Headers: 'readonly',
        fetch: 'readonly',
        addEventListener: 'readonly',
        URL: 'readonly',
        FetchEvent: 'readonly',
        KVNamespace: 'readonly',
        MAINTENANCE_CONFIG: 'readonly',
        MAINTENANCE_ANALYTICS: 'readonly',
      }
    },
    plugins: {
      '@typescript-eslint': typescript,
    },
    rules: {
      ...typescript.configs.recommended.rules,
      // Performance optimizations
      'prefer-const': 'error',
      'no-var': 'error',
      'no-unused-vars': 'off', // TypeScript handles this better
      '@typescript-eslint/no-unused-vars': ['error', { 
        'argsIgnorePattern': '^_',
        'varsIgnorePattern': '^_'
      }],
      
      // Prevent security issues
      'no-eval': 'error',
      'no-implied-eval': 'error',
      
      // Maintainability
      'max-lines-per-function': ['warn', { 
        max: 50,
        skipBlankLines: true,
        skipComments: true
      }],
      'complexity': ['warn', 15],
      
      // Performance issues
      'no-console': ['warn', { allow: ['warn', 'error'] }]
    },
  },
  {
    ignores: ['dist/**/*', 'node_modules/**/*'],
  }
];