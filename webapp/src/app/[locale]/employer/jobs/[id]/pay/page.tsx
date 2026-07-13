import { redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { PayForm } from "@/components/employer/pay-form";
import { Container } from "@/components/ui/container";
import { createClient } from "@/lib/supabase/server";

// Auth-dependent + shows a draft only its owner can see.
export const dynamic = "force-dynamic";

/** Pick a tier + pay (Payme/Click) to publish a draft vacancy. Reached after
 * posting a 2nd+ vacancy (createJob) or publishing a draft from My jobs. */
export default async function PayPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("employer.pay");

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  // RLS lets an owner read their own draft; anyone else's draft returns null.
  const { data: job } = await supabase
    .from("jobs")
    .select("id, title, status")
    .eq("id", id)
    .maybeSingle();
  if (!job || job.status !== "draft") {
    redirect(`/${locale}/employer/jobs`);
  }

  return (
    <Container className="max-w-2xl py-10">
      <h1 className="text-foreground text-2xl font-bold">{t("title")}</h1>
      <p className="text-muted-foreground mt-1 text-sm">
        {t("subtitle", { title: (job as { title: string }).title })}
      </p>
      <div className="mt-6">
        <PayForm jobId={id} />
      </div>
    </Container>
  );
}
