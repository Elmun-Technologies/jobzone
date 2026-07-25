import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobCard } from "@/components/jobs/job-card";
import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getArchivedJobs } from "@/lib/data/bookmarks";
import { getBookmarkedJobIds } from "@/lib/data/bookmarks";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "archived" });
  return { title: t("title"), robots: { index: false } };
}

// Per-user page (reads the session inside getArchivedJobs, whose catch
// swallows the cookies() dynamic signal). Without this Next.js statically
// bakes the guest render — a permanently empty list for signed-in users.
export const dynamic = "force-dynamic";

/**
 * The jobs a seeker archived.
 *
 * Archiving hid a job from every feed, and the only way to un-archive it was
 * the button on the card that had just been hidden — so it was a one-way door
 * with no undo. This is where those jobs live; the archive button on each card
 * renders pressed, so tapping it puts the job back in the feed.
 */
export default async function ArchivedJobsPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("archived");
  const [jobs, savedIds] = await Promise.all([
    getArchivedJobs(),
    getBookmarkedJobIds(),
  ]);

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-1 mb-6 text-sm">{t("subtitle")}</p>
      {jobs.length === 0 ? (
        <EmptyState title={t("empty")} description={t("emptyHint")} />
      ) : (
        <ul className="space-y-3">
          {jobs.map((job) => (
            <li key={job.id}>
              <JobCard job={job} saved={savedIds.has(job.id)} archived />
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
