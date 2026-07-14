import { Search } from "lucide-react";
import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { CompanyCard } from "@/components/companies/company-card";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getCompanies } from "@/lib/data/companies";
import { localeAlternates } from "@/lib/seo";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "company" });
  return {
    title: t("directoryTitle"),
    alternates: localeAlternates(locale, "companies"),
  };
}

export default async function CompaniesPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const sp = await searchParams;
  const t = await getTranslations("company");
  const tj = await getTranslations("jobs");
  const q = Array.isArray(sp.q) ? sp.q[0] : sp.q;

  const companies = await getCompanies({ q });

  return (
    <Container className="py-8">
      <h1 className="text-foreground text-2xl font-bold sm:text-3xl">
        {t("directoryTitle")}
      </h1>

      <form
        action={`/${locale}/companies`}
        className="border-border bg-card mt-4 flex max-w-xl items-center gap-2 rounded-full border p-1.5"
      >
        <Search className="text-muted-foreground ml-2 size-5 shrink-0" />
        <input
          name="q"
          defaultValue={q ?? ""}
          placeholder={t("searchPlaceholder")}
          aria-label={t("searchPlaceholder")}
          className="text-foreground placeholder:text-muted-foreground h-9 w-full flex-1 bg-transparent px-1 outline-none"
        />
        <button
          type="submit"
          className={cn(buttonVariants({ variant: "primary", size: "sm" }))}
        >
          <Search className="size-4 sm:hidden" />
          <span className="hidden sm:inline">{tj("search")}</span>
        </button>
      </form>

      <div className="mt-6">
        {companies.length === 0 ? (
          <EmptyState title={t("none")} />
        ) : (
          <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {companies.map((c) => (
              <li key={c.id}>
                <CompanyCard company={c} />
              </li>
            ))}
          </ul>
        )}
      </div>
    </Container>
  );
}
