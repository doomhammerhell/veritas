import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Veritas',
  description: 'Enterprise-grade blind voting system on Starknet',
  lang: 'en-US',
  
  // Theme configuration
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'API', link: '/api/' },
      { text: 'Examples', link: '/examples/' },
      { text: 'Security', link: '/security/' }
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Introduction', link: '/' },
          { text: 'Quick Start', link: '/guide/quick-start' },
          { text: 'Installation', link: '/guide/installation' },
          { text: 'Configuration', link: '/guide/configuration' }
        ]
      },
      {
        text: 'Core Concepts',
        items: [
          { text: 'Architecture', link: '/guide/architecture' },
          { text: 'Voting Mechanisms', link: '/guide/voting-mechanisms' },
          { text: 'Zero Knowledge', link: '/guide/zero-knowledge' },
          { text: 'Security', link: '/guide/security' }
        ]
      },
      {
        text: 'Contracts',
        items: [
          { text: 'Overview', link: '/contracts/' },
          { text: 'Basic Contract', link: '/contracts/basic' },
          { text: 'Advanced Contract', link: '/contracts/advanced' },
          { text: 'Ultimate Contract', link: '/contracts/ultimate' },
          { text: 'Ultimate++ Contract', link: '/contracts/ultimate-plus' }
        ]
      },
      {
        text: 'Development',
        items: [
          { text: 'Setup', link: '/development/setup' },
          { text: 'Testing', link: '/development/testing' },
          { text: 'Deployment', link: '/development/deployment' },
          { text: 'Monitoring', link: '/development/monitoring' }
        ]
      },
      {
        text: 'API Reference',
        items: [
          { text: 'Core API', link: '/api/core' },
          { text: 'Voting API', link: '/api/voting' },
          { text: 'Governance API', link: '/api/governance' },
          { text: 'Security API', link: '/api/security' }
        ]
      },
      {
        text: 'Examples',
        items: [
          { text: 'Basic Voting', link: '/examples/basic-voting' },
          { text: 'DAO Governance', link: '/examples/dao-governance' },
          { text: 'Multi-chain Voting', link: '/examples/multichain-voting' },
          { text: 'Advanced Features', link: '/examples/advanced-features' }
        ]
      },
      {
        text: 'Security',
        items: [
          { text: 'Security Overview', link: '/security/' },
          { text: 'Audit Reports', link: '/security/audits' },
          { text: 'Vulnerability Disclosure', link: '/security/disclosure' },
          { text: 'Best Practices', link: '/security/best-practices' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/veritas-org/veritas' },
      { icon: 'discord', link: 'https://discord.gg/veritas' },
      { icon: 'twitter', link: 'https://twitter.com/VeritasProtocol' }
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2024 Veritas Organization'
    },

    search: {
      provider: 'local'
    },

    editLink: {
      pattern: 'https://github.com/veritas-org/veritas/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    carbonAds: {
      code: 'your-carbon-code',
      placement: 'your-carbon-placement'
    }
  },

  // Markdown configuration
  markdown: {
    theme: {
      light: 'github-light',
      dark: 'github-dark'
    },
    lineNumbers: true
  },

  // Vite configuration
  vite: {
    define: {
      __VUE_OPTIONS_API__: false
    },
    server: {
      host: true,
      port: 5173
    },
    build: {
      minify: 'terser',
      chunkSizeWarningLimit: 1000
    }
  },

  // Head configuration
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#3c82f6' }],
    ['meta', { name: 'og:type', content: 'website' }],
    ['meta', { name: 'og:locale', content: 'en' }],
    ['meta', { name: 'og:site_name', content: 'Veritas' }],
    ['meta', { name: 'og:image', content: '/og-image.png' }]
  ]
})
