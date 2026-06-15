-- seed_dev.sql — DEV-ONLY demo content (companies + open jobs) so a fresh
-- backend shows real data immediately and mirrors the app's offline mock.
-- Apply manually in development:  psql "$DATABASE_URL" -f supabase/seed_dev.sql
-- Do NOT run against production. Reviews/applications are omitted (they need
-- real auth users); create those from the app.

-- Companies ------------------------------------------------------------------
insert into public.companies (id, name, slug, about, industry, size,
                              founded_year, website, headquarters, is_verified)
values
  ('00000000-0000-0000-0000-0000000ac3e0', 'Acme', 'acme',
   'Acme builds cross-platform mobile products used by millions across Central Asia. Remote-first and obsessed with craft.',
   'Software', '201–500', 2015, 'https://acme.example.com', 'Tashkent, UZ', true),
  ('00000000-0000-0000-0000-00000001b005', 'Nimbus', 'nimbus',
   'Nimbus is a design-led studio crafting delightful digital products for fast-growing startups.',
   'Design', '51–200', 2018, 'https://nimbus.example.com', 'Remote', false)
on conflict (slug) do nothing;

-- Open jobs ------------------------------------------------------------------
insert into public.jobs (company_id, title, description, responsibilities,
                         requirements, benefits, category_id, job_type,
                         experience_level, working_model, city, country,
                         salary_min, salary_max, currency, skills_required, status)
select c.id, j.title, j.description, j.responsibilities, j.requirements,
       j.benefits, cat.id, j.job_type, j.experience_level, j.working_model,
       j.city, j.country, j.salary_min, j.salary_max, 'USD', j.skills, 'open'
from (values
  ('acme',   'Senior Flutter Engineer',
   'Build and scale our cross-platform mobile apps used by millions.',
   'Own features end-to-end. Mentor engineers. Improve app performance.',
   '5+ years mobile. Strong Flutter. Experience with CI/CD.',
   'Remote-first. Equity. Learning budget.',
   'engineering', 'full_time', 'senior', 'remote', 'Tashkent', 'UZ',
   2500, 4000, array['Dart','Flutter','Riverpod','Supabase']),
  ('nimbus', 'Product Designer',
   'Design delightful end-to-end product experiences.',
   null, null, null,
   'design', 'full_time', 'mid', 'remote', 'Remote', null,
   1800, 2800, array['Figma','Prototyping','Design Systems']),
  ('acme',   'Backend Developer (Node.js)',
   'Develop reliable APIs powering our platform.',
   null, null, null,
   'engineering', 'full_time', 'mid', 'hybrid', 'Samarkand', 'UZ',
   2000, 3200, array['Node.js','PostgreSQL','REST']),
  ('nimbus', 'Marketing Manager',
   'Lead growth and brand marketing initiatives.',
   null, null, null,
   'marketing', 'full_time', 'senior', 'onsite', 'Tashkent', 'UZ',
   1500, 2500, array['SEO','Content','Analytics']),
  ('acme',   'Flutter Intern',
   'Kickstart your mobile career with hands-on projects.',
   null, null, null,
   'engineering', 'internship', 'entry', 'onsite', 'Tashkent', 'UZ',
   500, 800, array['Dart','Flutter'])
) as j(company_slug, title, description, responsibilities, requirements,
       benefits, category_slug, job_type, experience_level, working_model,
       city, country, salary_min, salary_max, skills)
join public.companies c on c.slug = j.company_slug
left join public.job_categories cat on cat.slug = j.category_slug
on conflict do nothing;
