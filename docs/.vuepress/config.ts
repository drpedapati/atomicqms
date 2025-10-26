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
      { text: 'Authentication', link: '/authentication/' },
      { text: 'AI Integration', link: '/ai-integration/' },
      { text: 'Architecture', link: '/architecture/' },
      { text: 'Deployment', link: '/deployment/' },
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
      '/authentication/': [
        {
          text: 'Authentication',
          children: [
            '/authentication/README.md',
            '/authentication/github-oauth-setup.md',
          ],
        },
      ],
      '/ai-integration/': [
        {
          text: 'AI Integration',
          children: [
            '/ai-integration/README.md',
            '/ai-integration/gitea-actions-setup.md',
            '/ai-integration/claude-code-oauth-setup.md',
            '/ai-integration/qms-workflows.md',
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
