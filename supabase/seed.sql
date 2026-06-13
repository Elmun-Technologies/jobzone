-- seed.sql — reference data applied on `supabase db reset`.
-- Demo companies/jobs are intentionally omitted here (they require auth users);
-- create those from the app or a separate dev-seed script.

insert into public.job_categories (name, slug, icon) values
  ('Engineering',      'engineering', 'code'),
  ('Design',           'design',      'palette'),
  ('Product',          'product',     'widgets'),
  ('Marketing',        'marketing',   'campaign'),
  ('Sales',            'sales',       'trending_up'),
  ('Finance',          'finance',     'payments'),
  ('Human Resources',  'hr',          'groups'),
  ('Customer Support', 'support',     'headset_mic'),
  ('Data & AI',        'data-ai',     'analytics'),
  ('Operations',       'operations',  'settings')
on conflict (slug) do nothing;
