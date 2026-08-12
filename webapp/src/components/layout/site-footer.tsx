import { getTranslations } from "next-intl/server";

import { CookieSettingsButton } from "@/components/consent/cookie-settings-button";
import { Container } from "@/components/ui/container";
import { getCategoriesWithCounts } from "@/lib/data/categories";
import { regionNames } from "@/lib/data/regions";
import { Link } from "@/i18n/navigation";
import { slugify } from "@/lib/slug";

import { YollaLogo } from "./yolla-logo";

/** How many trades to link. Enough to cover the market, short of a link farm. */
const FOOTER_CATEGORIES = 12;

/**
 * The footer is the site's internal link graph.
 *
 * Every landing page we generate — fourteen regions, ~20 trades, and the
 * region × trade pages under them — used to be reachable only from the home
 * page's category grid or a search. Linking the regions and the busiest trades
 * from *every* page puts the whole long tail one hop from wherever a crawler
 * lands, which is the cheapest organic reach a job site can buy, and it is
 * exactly what the local competitors do.
 *
 * Categories come from the cached counts reader (5-minute window, shared with
 * the home grid), so this costs no extra database work per page.
 */
export async function SiteFooter() {
  const t = await getTranslations("footer");
  const tn = await getTranslations("nav");
  const year = new Date().getFullYear();
  const categories = (await getCategoriesWithCounts())
    .filter((c) => c.count > 0)
    .slice(0, FOOTER_CATEGORIES);
  const regions = regionNames();

  const linkClass = "hover:text-primary block py-1 transition-colors";

  return (
    <footer className="border-border text-muted-foreground border-t text-sm">
      <Container className="py-10">
        <div className="grid grid-cols-2 gap-8 md:grid-cols-4">
          <nav aria-labelledby="footer-regions" className="col-span-2">
            <h2
              id="footer-regions"
              className="text-foreground mb-2 font-semibold"
            >
              {t("byRegion")}
            </h2>
            <ul className="grid grid-cols-2 gap-x-4">
              {regions.map((r) => (
                <li key={r}>
                  <Link href={`/hudud/${slugify(r)}`} className={linkClass}>
                    {r}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>

          {categories.length > 0 ? (
            <nav aria-labelledby="footer-categories">
              <h2
                id="footer-categories"
                className="text-foreground mb-2 font-semibold"
              >
                {t("byCategory")}
              </h2>
              <ul>
                {categories.map((c) => (
                  <li key={c.id}>
                    <Link href={`/ish/${c.slug}`} className={linkClass}>
                      {c.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </nav>
          ) : null}

          <nav aria-labelledby="footer-about">
            <h2
              id="footer-about"
              className="text-foreground mb-2 font-semibold"
            >
              {t("aboutHeading")}
            </h2>
            <ul>
              <li>
                <Link href="/jobs" className={linkClass}>
                  {tn("jobs")}
                </Link>
              </li>
              <li>
                <Link href="/companies" className={linkClass}>
                  {tn("companies")}
                </Link>
              </li>
              <li>
                <Link href="/explore" className={linkClass}>
                  {tn("map")}
                </Link>
              </li>
              <li>
                <Link href="/employer/jobs/new" className={linkClass}>
                  {tn("postVacancy")}
                </Link>
              </li>
              <li>
                <Link href="/pricing" className={linkClass}>
                  {tn("pricing")}
                </Link>
              </li>
              <li>
                <Link href="/privacy" className={linkClass}>
                  {t("privacy")}
                </Link>
              </li>
              <li>
                <Link href="/terms" className={linkClass}>
                  {t("terms")}
                </Link>
              </li>
              <li>
                <CookieSettingsButton className="hover:text-primary block cursor-pointer py-1 transition-colors" />
              </li>
            </ul>
          </nav>
        </div>

        <div className="border-border mt-8 flex flex-col items-center justify-between gap-3 border-t pt-6 sm:flex-row">
          <div className="flex items-center gap-2">
            <YollaLogo />
            <span>— {t("tagline")}</span>
          </div>
          <p>
            © {year} Yollla. {t("rights")}
          </p>
        </div>
      </Container>
    </footer>
  );
}
