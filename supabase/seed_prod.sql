-- seed_prod.sql — production-safe demo content so the LIVE backend shows a full,
-- realistic Uzbek blue-collar feed on both mobile clients (iOS + Android) and the
-- web app. This makes the real apps look like the offline mock ("iOS demo"), but
-- backed by real rows in `job_feed`.
--
-- SAFE TO RUN ON PRODUCTION and idempotent: companies key on `slug`, jobs key on
-- deterministic ids, both with `on conflict … do nothing`. No auth users are
-- required (companies.owner_id / jobs.posted_by are nullable), and no reviews or
-- applications are created (those need real accounts — make them from the app).
--
-- Apply:  psql "$DATABASE_URL" -f supabase/seed_prod.sql
-- Remove: delete from public.jobs      where id::text like 'a0000000-0000-4000-8000-%';
--         delete from public.companies where slug in (select slug from … );  -- see tags below

-- Companies ------------------------------------------------------------------
-- Plausible, non-trademark local names (one per hiring vertical). Logos use a
-- stable placeholder service so cards render an avatar offline-style.
insert into public.companies (slug, name, about, industry, size, founded_year,
                              headquarters, lat, lng, logo_url, is_verified)
values
  ('chinor-restoran',  'Chinor Restoran',      'Milliy va yevropa taomlari restorani. Toshkent markazida, kunlik 500+ mehmon.',                 'Restoran',      '51–200',  2016, 'Toshkent',  41.3110, 69.2797, 'https://picsum.photos/seed/chinor/200/200',   true),
  ('bahor-savdo',      'Bahor Savdo',          'Oziq-ovqat va maishiy tovarlar do‘konlari tarmog‘i. Toshkent va viloyatlarda 40+ filial.',       'Chakana savdo', '201–500', 2014, 'Toshkent',  41.2995, 69.2401, 'https://picsum.photos/seed/bahor/200/200',    true),
  ('zamon-logistika',  'Zamon Logistika',      'Shahar ichi va viloyatlararo yetkazib berish xizmati. O‘z avtoparki bilan.',                     'Logistika',     '51–200',  2019, 'Toshkent',  41.3300, 69.2900, 'https://picsum.photos/seed/zamon/200/200',    false),
  ('milliy-qurilish',  'Milliy Qurilish',      'Turar-joy va tijorat ob‘ektlari qurilishi. Vahta usulida ishchi jamoalari.',                     'Qurilish',      '201–500', 2012, 'Toshkent',  41.3450, 69.2870, 'https://picsum.photos/seed/milliy/200/200',   true),
  ('oq-yol-trans',     'Oq Yo‘l Trans',        'Yuk tashish va yo‘lovchi tashish kompaniyasi. Litsenziyalangan avtopark.',                       'Transport',     '51–200',  2015, 'Toshkent',  41.2856, 69.2034, 'https://picsum.photos/seed/oqyol/200/200',    false),
  ('baraka-ombor',     'Baraka Ombor',         'Zamonaviy logistika markazi va saralash omborlari. Toshkent yaqinida.',                          'Ombor',         '201–500', 2017, 'Toshkent',  41.2700, 69.3300, 'https://picsum.photos/seed/baraka/200/200',   false),
  ('qalqon-security',  'Qalqon Security',      'Ob‘ektlarni qo‘riqlash va video-nazorat xizmati. 24/7 monitoring markazi.',                      'Xavfsizlik',    '51–200',  2018, 'Toshkent',  41.3160, 69.2490, 'https://picsum.photos/seed/qalqon/200/200',   true),
  ('toza-hayot',       'Toza Hayot',           'Ofis, savdo markazlari va turar-joylarni professional tozalash xizmati.',                        'Klining',       '11–50',   2020, 'Toshkent',  41.3050, 69.2600, 'https://picsum.photos/seed/tozahayot/200/200',false),
  ('gulbahor-salon',   'Gulbahor Beauty',      'Go‘zallik salonlari tarmog‘i. Sartaroshlik, manikur, kosmetologiya.',                            'Go‘zallik',     '11–50',   2019, 'Samarqand', 39.6540, 66.9597, 'https://picsum.photos/seed/gulbahor/200/200', true),
  ('sharq-tikuv',      'Sharq Tikuvchilik',    'Trikotaj va tayyor kiyim ishlab chiqarish fabrikasi. Eksportga yo‘naltirilgan.',                 'Ishlab chiqarish','201–500',2013, 'Namangan',  40.9983, 71.6726, 'https://picsum.photos/seed/sharq/200/200',    true),
  ('yashil-dala-agro', 'Yashil Dala Agro',     'Issiqxona xo‘jaligi va qishloq xo‘jaligi mahsulotlari yetishtirish.',                            'Qishloq xo‘jaligi','51–200',2016,'Farg‘ona',  40.3864, 71.7864, 'https://picsum.photos/seed/yashil/200/200',   false),
  ('global-mehnat',    'Global Mehnat',        'Chet elga qonuniy ishga yuborish agentligi. Rossiya, Koreya, Qozog‘iston yo‘nalishlari.',        'Bandlik agentligi','11–50',2018,'Toshkent',  41.3111, 69.2797, 'https://picsum.photos/seed/global/200/200',   true)
on conflict (slug) do nothing;

-- Open jobs ------------------------------------------------------------------
-- One VALUES table (with an ordinal for a stable id + a recency offset). Salaries
-- are UZS/month; coordinates scatter around each city so the map view is full.
insert into public.jobs (
  id, company_id, category_id, title, description, job_type, experience_level,
  working_model, city, region, country, lat, lng, salary_min, salary_max,
  currency, salary_period, schedule_pattern, night_shift, women_friendly,
  disability_friendly, formalization, driver_licenses, skills_required,
  applicants_count, status, posted_at, expires_at)
select
  ('a0000000-0000-4000-8000-0000000000' || lpad(j.ord::text, 2, '0'))::uuid,
  c.id, cat.id, j.title, j.description, j.job_type, j.exp, 'onsite',
  j.city, j.region, coalesce(j.country, 'UZ'), j.lat, j.lng,
  j.smin, j.smax, coalesce(j.currency, 'UZS'), 'month',
  nullif(j.sched, ''), j.night, j.women, j.disab, nullif(j.formal, ''),
  case when j.lic = '' then '{}'::text[] else string_to_array(j.lic, '|') end,
  string_to_array(j.skills, '|'),
  j.applicants, 'open',
  now() - (j.days_ago * interval '1 day') - (j.ord * interval '37 minutes'),
  now() + interval '45 days'
from (values
  -- ord, company_slug, category_slug, title, job_type, exp, city, region, lat, lng, smin, smax, sched, night, women, disab, formal, lic, applicants, days_ago, skills, description, currency, country
  ( 1,'chinor-restoran','horeca','Ofitsiant','full_time','entry','Toshkent','Toshkent',41.3115,69.2790,3500000,5000000,'5_2',false,true,false,'',           '', 14, 0,'Mehmonlarni kutib olish|Jamoada ishlash','Restoran zalida mehmonlarga xizmat ko‘rsatish. Insho va choychaqa qo‘shimcha.',null,null),
  ( 2,'chinor-restoran','horeca','Oshpaz (Povar)','full_time','mid','Toshkent','Toshkent',41.3108,69.2802,6000000,9000000,'6_1',false,false,false,'employment_contract','', 8, 1,'Milliy taomlar|Issiq sex|Sanitariya','Issiq sexda milliy va yevropa taomlarini tayyorlash. Tajriba talab qilinadi.',null,null),
  ( 3,'chinor-restoran','horeca','Barista','part_time','entry','Toshkent','Toshkent',41.3121,69.2775,2500000,4000000,'2_2',false,true,false,'',           '', 21, 2,'Kofe tayyorlash|Kassa','Qahvaxonada kofe va ichimliklar tayyorlash. O‘qishga qulay grafik.',null,null),
  ( 4,'bahor-savdo','retail','Kassir-sotuvchi','full_time','entry','Toshkent','Toshkent',41.2990,69.2410,3000000,4500000,'2_2',false,true,true,'',           '', 33, 0,'Kassa apparati|Mijozlar bilan muloqot','Do‘konda xaridorlarga xizmat va kassada hisob-kitob. Nogironligi borlar ham qabul qilinadi.',null,null),
  ( 5,'bahor-savdo','retail','Sotuvchi-konsultant','full_time','entry','Samarqand','Samarqand',39.6542,66.9605,3500000,5000000,'5_2',false,true,false,'',           '', 12, 1,'Savdo|Tovar joylashtirish','Savdo zalida xaridorlarga maslahat va tovarlarni joylashtirish.',null,null),
  ( 6,'bahor-savdo','retail','Do‘kon mudiri','full_time','senior','Toshkent','Toshkent',41.3015,69.2450,7000000,10000000,'5_2',false,false,false,'employment_contract','B', 6, 3,'Rahbarlik|Hisobot|Inventarizatsiya','Filialni boshqarish, jamoani muvofiqlashtirish va savdo rejasini bajarish.',null,null),
  ( 7,'zamon-logistika','logistics-delivery','Kuryer (velosiped/moped)','part_time','entry','Toshkent','Toshkent',41.3290,69.2880,3000000,6000000,'',false,false,false,'',           'A', 48, 0,'Shahar yo‘llarini bilish|Vaqtida yetkazish','Buyurtmalarni mijozlarga yetkazib berish. Moslashuvchan grafik, kunlik to‘lov.',null,null),
  ( 8,'zamon-logistika','logistics-delivery','Ekspeditor','full_time','mid','Toshkent','Toshkent',41.3310,69.2905,5000000,7000000,'6_1',false,false,false,'employment_contract','B', 17, 2,'Hujjatlar bilan ishlash|Marshrut','Yuklarni kuzatib borish va hujjatlarni rasmiylashtirish.',null,null),
  ( 9,'zamon-logistika','logistics-delivery','Yetkazib beruvchi (avto)','full_time','entry','Toshkent','Toshkent',41.3275,69.2860,5000000,8000000,'6_1',false,false,false,'',           'B', 24, 1,'Haydash|Mijozlar bilan muloqot','Yengil avtomobilda buyurtmalarni yetkazish. Yoqilg‘i kompaniya hisobidan.',null,null),
  (10,'milliy-qurilish','construction','Qurilish ustasi (Vahta)','rotational','mid','Andijon','Andijon',40.7830,72.3440,8000000,12000000,'custom',false,false,false,'employment_contract','C|E', 33, 1,'G‘isht terish|Suvoq|Beton','Vahta usulida qurilish ob‘ektlarida ishlash. Yotoqxona va ovqat bilan ta’minlanadi.',null,null),
  (11,'milliy-qurilish','construction','Suvoqchi','full_time','mid','Toshkent','Toshkent',41.3460,69.2880,7000000,10000000,'6_1',false,false,false,'gph',        '', 15, 2,'Suvoq|Shpaklovka|Bo‘yoq','Yangi binolarda ichki pardozlash ishlari. Ish qurollari beriladi.',null,null),
  (12,'milliy-qurilish','construction','Elektromontajchi','full_time','mid','Toshkent','Toshkent',41.3440,69.2855,8000000,11000000,'5_2',false,false,false,'employment_contract','', 9, 3,'Elektr montaj|Sxema o‘qish','Turar-joy binolarida elektr tarmoqlarini o‘rnatish.',null,null),
  (13,'oq-yol-trans','driver','Yuk mashina haydovchisi','full_time','mid','Toshkent','Toshkent',41.2860,69.2040,7000000,10000000,'6_1',false,false,false,'employment_contract','C|E', 19, 0,'Yuk tashish|Texnika holati','Viloyatlararo yuk tashish. Tajribali haydovchilar taklif etiladi.',null,null),
  (14,'oq-yol-trans','driver','Taksi haydovchi','full_time','entry','Toshkent','Toshkent',41.2875,69.2065,5000000,9000000,'custom',false,false,false,'',           'B', 41, 1,'Shahar navigatsiyasi|Xushmuomalalik','Shahar bo‘ylab yo‘lovchi tashish. O‘z avtomobili yoki kompaniya avtosi.',null,null),
  (15,'oq-yol-trans','driver','Avtobus haydovchisi','full_time','mid','Toshkent','Toshkent',41.2845,69.2020,6000000,8000000,'5_2',false,false,false,'employment_contract','D', 11, 2,'Yo‘lovchi tashish|Xavfsizlik','Shahar marshrutlarida avtobus boshqarish. Sog‘liq ko‘rigi majburiy.',null,null),
  (16,'baraka-ombor','warehouse','Omborchi','full_time','entry','Toshkent','Toshkent',41.2705,69.3310,4000000,5500000,'6_1',false,false,false,'',           '', 22, 0,'Hisob-kitob|1C dastur','Omborda tovarlarni qabul qilish, saqlash va hisobini yuritish.',null,null),
  (17,'baraka-ombor','warehouse','Yuk tashuvchi (gruzchik)','full_time','entry','Toshkent','Toshkent',41.2690,69.3325,4500000,6000000,'6_1',false,false,false,'',           '', 28, 1,'Jismoniy chidamlilik|Yuk ortish','Ombor va mashinaga tovar ortish-tushirish. Sog‘lom erkaklar taklif etiladi.',null,null),
  (18,'baraka-ombor','warehouse','Saralovchi (komplektovshik)','full_time','entry','Toshkent','Toshkent',41.2715,69.3290,4000000,5000000,'2_2',true,true,false,'',           '', 16, 2,'Diqqat|Tezkorlik','Buyurtmalarni terib, saralab tayyorlash. Tungi smena qo‘shimcha to‘lovli.',null,null),
  (19,'qalqon-security','security','Qo‘riqlash xodimi (tungi smena)','full_time','mid','Toshkent','Toshkent',41.3165,69.2495,4000000,4500000,'2_2',true,false,false,'employment_contract','', 7, 0,'Hushyorlik|Video kuzatuv','Ob‘ektni tungi vaqtda qo‘riqlash va nazorat qilish.',null,null),
  (20,'qalqon-security','security','Nazoratchi (video-monitoring)','full_time','mid','Toshkent','Toshkent',41.3150,69.2480,4500000,5500000,'5_2',false,false,true,'employment_contract','', 13, 2,'Monitoring|Hisobot','Monitoring markazida kameralarni kuzatish. Nogironligi borlar uchun qulay.',null,null),
  (21,'toza-hayot','cleaning','Farrosh (ofis)','part_time','entry','Toshkent','Toshkent',41.3055,69.2610,2500000,3500000,'5_2',false,true,true,'',           '', 26, 1,'Tozalash|Vaqtni boshqarish','Ofis xonalarini ertalabki tozalash. Yarim kunlik ish.',null,null),
  (22,'toza-hayot','cleaning','Tozalash xodimi (savdo markazi)','full_time','entry','Toshkent','Toshkent',41.3040,69.2585,3500000,4500000,'6_1',false,true,false,'',           '', 18, 2,'Tozalash|Kimyoviy vositalar','Savdo markazi hududini smena davomida toza saqlash.',null,null),
  (23,'gulbahor-salon','beauty','Sartarosh (erkaklar zali)','full_time','mid','Samarqand','Samarqand',39.6545,66.9600,6000000,12000000,'6_1',false,false,false,'self_employed','', 14, 0,'Soch olish|Soqol|Mijozlar bazasi','Erkaklar go‘zallik salonida ishlash. Foizli to‘lov + mijozlar bazasi.',null,null),
  (24,'gulbahor-salon','beauty','Manikur ustasi','full_time','mid','Samarqand','Samarqand',39.6535,66.9590,5000000,10000000,'6_1',false,true,false,'self_employed','', 22, 1,'Manikur|Pedikyur|Dizayn','Manikur va pedikyur xizmatlari. Qurollari salon tomonidan beriladi.',null,null),
  (25,'gulbahor-salon','beauty','Salon administratori','full_time','entry','Samarqand','Samarqand',39.6550,66.9610,4000000,6000000,'5_2',false,true,false,'',           '', 26, 3,'Mijozlarni qabul qilish|Jadval yuritish','Go‘zallik salonida qabul, yozuv va mijozlar bilan ishlash.',null,null),
  (26,'sharq-tikuv','manufacturing','Tikuvchi (shveya)','full_time','mid','Namangan','Namangan',40.9990,71.6730,4000000,7000000,'6_1',false,true,false,'employment_contract','', 31, 0,'Tikuv mashinasi|Trikotaj|Sifat nazorati','Fabrikada tayyor kiyim tikish. Norma bo‘yicha qo‘shimcha to‘lov.',null,null),
  (27,'sharq-tikuv','manufacturing','Ishlab chiqarish operatori','full_time','entry','Namangan','Namangan',40.9975,71.6715,4500000,6000000,'2_2',true,false,false,'employment_contract','', 20, 1,'Stanok|Diqqat|Smenali ish','Ishlab chiqarish liniyasida uskunani boshqarish. Tungi smena to‘lovli.',null,null),
  (28,'yashil-dala-agro','agriculture','Issiqxona ishchisi','full_time','entry','Farg‘ona','Farg‘ona',40.3870,71.7870,3500000,5000000,'6_1',false,true,false,'',           '', 15, 1,'Parvarish|Hosil yig‘ish','Issiqxonada pomidor va bodring parvarishi hamda hosil yig‘ish.',null,null),
  (29,'global-mehnat','foreign-jobs','Rossiya — Qurilishchi (Vahta)','rotational','mid','Moskva','',55.7558,37.6173,25000000,35000000,'custom',false,false,false,'employment_contract','', 52, 0,'Qurilish|Vahta|Chidamlilik','Moskvada qurilish ob‘ektlarida vahta usulida ishlash. Yo‘l, yashash, patent hujjatlari rasmiylashtiriladi.',null,'RU'),
  (30,'global-mehnat','foreign-jobs','Koreya — Zavod ishchisi (EPS-TOPIK)','full_time','entry','Seul','',37.5665,126.9780,30000000,45000000,'5_2',false,false,false,'employment_contract','', 61, 2,'EPS-TOPIK|Zavod|Intizom','Janubiy Koreyada ishlab chiqarish zavodida ishlash. EPS-TOPIK imtihoniga tayyorlov bilan.',null,'KR')
) as j(ord, company_slug, category_slug, title, job_type, exp, city, region, lat, lng,
       smin, smax, sched, night, women, disab, formal, lic, applicants, days_ago,
       skills, description, currency, country)
join public.companies c    on c.slug   = j.company_slug
join public.job_categories cat on cat.slug = j.category_slug
on conflict (id) do nothing;
