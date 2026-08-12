// High-scale caching and ISR (Incremental Static Regeneration) helpers for Next.js.
// Ensures static/frequent data (categories, public listings) are heavily cached
// at the Vercel Edge / CDN level to protect the database under heavy load.

export const CACHE_TAGS = {
  jobs: 'jobs',
  categories: 'categories',
  companies: 'companies',
};

export const REVALIDATE_SECONDS = {
  short: 60,       // 1 minute for live feeds
  medium: 300,     // 5 minutes for category lists
  long: 3600,      // 1 hour for static CMS pages
};
