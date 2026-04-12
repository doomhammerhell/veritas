import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Veritas',
  description: 'Commit-reveal blind voting on StarkNet',
  themeConfig: {
    nav: [
      { text: 'Guide', link: '/guide/quick-start' },
      { text: 'API', link: '/api' },
      { text: 'Architecture', link: '/architecture' },
    ],
    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Quick Start', link: '/guide/quick-start' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Architecture', link: '/architecture' },
          { text: 'API', link: '/api' },
        ],
      },
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/doomhammerhell/veritas' },
    ],
    footer: {
      message: 'MIT License',
    },
  },
})
