import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { JobsMap } from "@/components/map/jobs-map";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { getOpenJobs } from "@/lib/data/jobs";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "explore" });
  return { title: t("title"), description: t("subtitle") };
}

export default async function ExplorePage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("explore");
  const jobs = await getOpenJobs({ limit: 100 });

  return (
    <Container className="py-8">
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h1 className="text-foreground text-2xl font-bold sm:text-3xl">
            {t("title")}
          </h1>
          <p className="text-muted-foreground text-sm">{t("subtitle")}</p>
        </div>
        <Link
          href="/jobs"
          className={cn(buttonVariants({ variant: "outline", size: "sm" }))}
        >
          {t("listView")}
        </Link>
      </div>
      <JobsMap jobs={jobs} />
    </Container>
  );
}
