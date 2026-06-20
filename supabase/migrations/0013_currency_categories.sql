-- 0013_currency_categories.sql
-- Localize money to the Uzbek market and broaden the category taxonomy for the
-- blue-collar / mass-hiring marketplace.

-- Currency: default to UZS (so'm); allow UZS or USD.
alter table public.jobs alter column currency set default 'UZS';
alter table public.jobs drop constraint if exists jobs_currency_check;
alter table public.jobs
  add constraint jobs_currency_check
  check (currency is null or currency in ('UZS','USD'));

-- Blue-collar + foreign-jobs categories (idempotent; mirrors seed.sql).
insert into public.job_categories (name, slug, icon) values
  ('Restaurants & Hospitality', 'horeca',             'restaurant'),
  ('Retail & Sales',            'retail',             'storefront'),
  ('Logistics & Delivery',      'logistics-delivery', 'local_shipping'),
  ('Construction',              'construction',       'construction'),
  ('Drivers',                   'driver',             'directions_car'),
  ('Warehouse',                 'warehouse',          'warehouse'),
  ('Security',                  'security',           'security'),
  ('Cleaning',                  'cleaning',           'cleaning_services'),
  ('Beauty & Salon',            'beauty',             'content_cut'),
  ('Manufacturing',             'manufacturing',      'precision_manufacturing'),
  ('Agriculture',               'agriculture',        'agriculture'),
  ('Foreign Jobs',              'foreign-jobs',       'flight_takeoff')
on conflict (slug) do nothing;
