import type { Metadata } from "next";
import { Search } from "lucide-react";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { DeleteSavedSearchButton } from "@/components/account/delete-saved-search-button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getSavedSearches } from "@/lib/data/saved-searches";
import { getCurrentUser } from "@/lib/auth/user";
import { Link } from "@/i18n/navigation";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "savedSearches" });
  return { title: t("title"), robots: { index: false } };
}

/** Builds the /jobs URL that re-runs a saved search's criteria. */
function runHref(keywords: string | null, city: string | null): string {
  const sp = new URLSearchParams();
  if (keywords) sp.set("q", keywords);
  if (city) sp.set("city", city);
  const qs = sp.toString();
  return qs ? `/jobs?${qs}` : "/jobs";
}

export default async function SavedSearchesPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);

  // Proxy gates /account; this is the secure (DAL-style) check.
  const user = await getCurrentUser();
  if (!user)
    redirect(`/${locale}/sign-in?next=/${locale}/account/saved-searches`);

  const t = await getTranslations("savedSearches");
  const items = await getSavedSearches();

  return (
    <Container className="max-w-2xl py-10">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-1 mb-6 text-sm">{t("subtitle")}</p>

      {items.length === 0 ? (
        <EmptyState title={t("emptyTitle")} description={t("emptyBody")} />
      ) : (
        <ul className="border-border divide-border bg-card divide-y rounded-2xl border">
          {items.map((s) => {
            const summary = [s.keywords, s.city].filter(Boolean).join(" · ");
            return (
              <li key={s.id} className="flex items-center gap-3 p-4">
                <span className="bg-muted text-primary flex size-9 shrink-0 items-center justify-center rounded-full">
                  <Search className="size-4" />
                </span>
                <Link
                  href={runHref(s.keywords, s.city)}
                  className="min-w-0 flex-1"
                >
                  <span className="text-foreground block truncate font-medium">
                    {s.name}
                  </span>
                  {summary ? (
                    <span className="text-muted-foreground block truncate text-sm">
                      {summary}
                    </span>
                  ) : null}
                </Link>
                <Link
                  href={runHref(s.keywords, s.city)}
                  className={cn(
                    buttonVariants({ variant: "outline", size: "sm" }),
                    "shrink-0",
                  )}
                >
                  {t("run")}
                </Link>
                <DeleteSavedSearchButton id={s.id} />
              </li>
            );
          })}
        </ul>
      )}
    </Container>
  );
}
