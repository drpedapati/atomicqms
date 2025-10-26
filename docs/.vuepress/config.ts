import { defineUserConfig } from 'vuepress'
import { defaultTheme } from '@vuepress/theme-default'
import { viteBundler } from '@vuepress/bundler-vite'

export default defineUserConfig({
  lang: 'en-US',
  title: 'AtomicQMS',
  description: 'Containerized Quality Management for Agile Teams',

  bundler: viteBundler(),

  theme: defaultTheme({
    logo: null,
    navbar: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'Architecture', link: '/architecture/' },
      { text: 'Deployment', link: '/deployment/' },
      { text: 'AI Integration', link: '/ai-integration/' },
    ],

    sidebar: {
      '/guide/': [
        {
          text: 'Getting Started',
          children: [
            '/guide/README.md',
            '/guide/quick-start.md',
            '/guide/core-concepts.md',
          ],
        },
        {
          text: 'Usage',
          children: [
            '/guide/sops.md',
            '/guide/capa.md',
            '/guide/change-control.md',
          ],
        },
      ],
      '/architecture/': [
        {
          text: 'Architecture',
          children: [
            '/architecture/README.md',
            '/architecture/modular-design.md',
            '/architecture/git-based-audit.md',
          ],
        },
      ],
      '/deployment/': [
        {
          text: 'Deployment',
          children: [
            '/deployment/README.md',
            '/deployment/docker-compose.md',
            '/deployment/configuration.md',
            '/deployment/scaling.md',
          ],
        },
      ],
      '/ai-integration/': [
        {
          text: 'AI Integration',
          children: [
            '/ai-integration/README.md',
            '/ai-integration/document-drafting.md',
            '/ai-integration/review-automation.md',
          ],
        },
      ],
    },

    repo: 'atomicqms/atomicqms',
    editLink: false,
    lastUpdated: true,
    contributors: false,
  }),
})
