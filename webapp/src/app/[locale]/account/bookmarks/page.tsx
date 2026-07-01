import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getBookmarkedJobs } from "@/lib/data/bookmarks";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "bookmarks" });
  return { title: t("title"), robots: { index: false } };
}

// Per-user page (reads the session inside getBookmarkedJobs, whose catch
// swallows the cookies() dynamic signal). Without this Next.js statically
// bakes the guest render — a permanently empty list for signed-in users.
export const dynamic = "force-dynamic";

export default async function BookmarksPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("bookmarks");
  const jobs = await getBookmarkedJobs();

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground mb-6 text-2xl font-bold">{t("title")}</h1>
      {jobs.length === 0 ? (
        <EmptyState title={t("empty")} />
      ) : (
        <ul className="space-y-3">
          {jobs.map((job) => (
            <li key={job.id}>
              <JobCard job={job} saved />
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
