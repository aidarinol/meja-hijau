import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

// GANTI 'https://thatsoundradio.com' dengan domain final saat sudah ada.
export default defineConfig({
  site: 'https://thatsoundradio.com',
  integrations: [mdx(), sitemap()],
});
