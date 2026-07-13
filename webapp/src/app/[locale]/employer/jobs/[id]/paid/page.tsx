import Link from "next/link";
import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PaidStatusPoller } from "@/components/employer/paid-status";
import { buttonVariants } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { createClient } from "@/lib/supabase/server";
import { cn } from "@/lib/utils";

// Auth-dependent + reflects live payment state — never prerender.
export const dynamic = "force-dynamic";

/**
 * Payment-return page (the gateway `return_url`). The provider callback flips
 * the order to paid out of band, which publishes the draft — so on arrival the
 * job may still be a draft for a moment. While it is, we poll; once it's open,
 * we show success + a link to the live listing.
 */
export default async function PaidPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("employer.paid");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const { data: job } = await supabase
    .from("jobs")
    .select("id, status")
    .eq("id", id)
    .maybeSingle();
  if (!job) redirect(`/${locale}/employer/jobs`);

  const published = (job as { status: string }).status === "open";

  return (
    <Container className="max-w-lg py-16 text-center">
      {published ? (
        <>
          <div className="text-5xl">🎉</div>
          <h1 className="text-foreground mt-4 text-2xl font-bold">
            {t("publishedTitle")}
          </h1>
          <p className="text-muted-foreground mt-2 text-sm">
            {t("publishedSub")}
          </p>
          <div className="mt-6 flex flex-wrap justify-center gap-3">
            <Link
              href={`/${locale}/jobs/${id}`}
              className={cn(buttonVariants({ variant: "primary", size: "lg" }))}
            >
              {t("viewListing")}
            </Link>
            <Link
              href={`/${locale}/employer/jobs`}
              className={cn(buttonVariants({ variant: "outline", size: "lg" }))}
            >
              {t("myJobs")}
            </Link>
          </div>
        </>
      ) : (
        <>
          <div
            className="border-primary/30 border-t-primary mx-auto size-10 animate-spin rounded-full border-4"
            aria-hidden
          />
          <h1 className="text-foreground mt-6 text-xl font-bold">
            {t("confirmingTitle")}
          </h1>
          <p className="text-muted-foreground mt-2 text-sm">
            {t("confirmingSub")}
          </p>
          <PaidStatusPoller />
          <div className="mt-6">
            <Link
              href={`/${locale}/employer/jobs`}
              className="text-muted-foreground hover:text-foreground text-sm underline"
            >
              {t("myJobs")}
            </Link>
          </div>
        </>
      )}
    </Container>
  );
}
