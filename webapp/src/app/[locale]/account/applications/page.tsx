import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getMyApplications } from "@/lib/data/applications";
import { formatDate } from "@/lib/format";
import { Link } from "@/i18n/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "applications" });
  return { title: t("title"), robots: { index: false } };
}

// Tailwind classes per status (amber/green/red/etc.).
const STATUS_CLASS: Record<string, string> = {
  submitted: "bg-muted text-muted-foreground",
  viewed: "bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300",
  shortlisted: "bg-accent text-accent-foreground",
  interview:
    "bg-amber-100 text-amber-700 dark:bg-amber-950 dark:text-amber-300",
  offer:
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
  rejected: "bg-red-100 text-red-700 dark:bg-red-950 dark:text-red-300",
  hired:
    "bg-emerald-100 text-emerald-700 dark:bg-emerald-950 dark:text-emerald-300",
};

export default async function MyApplicationsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("applications");
  const apps = await getMyApplications();

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground mb-6 text-2xl font-bold">{t("title")}</h1>

      {apps.length === 0 ? (
        <EmptyState title={t("empty")} />
      ) : (
        <ul className="space-y-3">
          {apps.map((a) => (
            <li key={a.id}>
              <Link
                href={`/jobs/${a.jobId}`}
                className="border-border bg-card hover:border-primary/40 flex items-center justify-between gap-3 rounded-xl border p-4 transition-colors"
              >
                <div className="min-w-0">
                  <p className="text-foreground truncate font-semibold">
                    {a.jobTitle}
                  </p>
                  <p className="text-muted-foreground truncate text-sm">
                    {a.companyName}
                    {a.appliedAt ? ` · ${formatDate(a.appliedAt)}` : ""}
                  </p>
                </div>
                <span
                  className={`shrink-0 rounded-full px-2.5 py-1 text-xs font-semibold ${
                    STATUS_CLASS[a.status] ?? STATUS_CLASS.submitted
                  }`}
                >
                  {t.has(`status.${a.status}`)
                    ? t(`status.${a.status}`)
                    : a.status}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
