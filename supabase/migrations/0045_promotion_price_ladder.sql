-- 0045_promotion_price_ladder.sql
-- Make the TOP promotion ladder actually reward buying longer. Before this,
-- 3-day TOP and 7-day TOP both cost 5 000 so'm/day (15 000 vs 35 000) — no
-- reason to buy the longer one. Now the per-day price falls as duration grows:
--   top_3  15 000 / 3d  = 5 000 /day  (baseline)
--   top_7  30 000 / 7d  ≈ 4 286 /day  (~14% cheaper/day)
--   top_30 99 000 / 30d = 3 300 /day  (~34% cheaper/day, best value)
-- Only top_7 changes (35 000 -> 30 000); the others were already on-ladder.
-- 0011 seeds prices with `on conflict do nothing`, so re-running it never
-- updates an existing row — the price move has to be an explicit UPDATE.

update public.promotion_products set price_uzs = 30000 where code = 'top_7';
