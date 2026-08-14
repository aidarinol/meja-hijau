import { defineCollection, reference, z } from 'astro:content';

const articles = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    author: reference('authors'),
    kicker: z.string().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
    sources: z.array(z.object({ label: z.string(), url: z.string().url() })).default([]),
  }),
});

const authors = defineCollection({
  type: 'data',
  schema: z.object({
    name: z.string(),
    role: z.string().optional(),
    bio: z.string(),
    credentials: z.string().optional(),
    links: z.array(z.object({ label: z.string(), url: z.string().url() })).default([]),
  }),
});

export const collections = { articles, authors };
