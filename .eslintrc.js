'use strict';

module.exports = {
  env: {
    node: true,
    es6: true,
    mocha: true
  },
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'script',
  },
  extends: 'eslint:recommended',
  rules: {
    indent: ['error', 4],
    'linebreak-style': ['error', 'unix'],
    quotes: ['error', 'single'],
    semi: ['error', 'always'],
    'no-unused-vars': ['error', {args: 'none'}],
    'no-console': 'off',
    curly: 'error',
    eqeqeq: 'warn',
    'no-throw-literal': 'error',
    'no-useless-escape': 'warn',
    'no-var': 'warn',
    'dot-notation': 'error',
    'no-tabs': 'error',
    'no-trailing-spaces': 'error',
    'no-use-before-define': 'error',
    'no-useless-call': 'error',
    'no-with': 'error',
    'operator-linebreak': 'error',
    'no-async-promise-executor': 'off',
    yoda: 'error',
    'quote-props': ['error', 'as-needed'],
    'no-constant-condition': ['error', {checkLoops: false}]
  }
};
