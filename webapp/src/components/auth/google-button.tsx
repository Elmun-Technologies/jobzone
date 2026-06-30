"use client";

import { useLocale, useTranslations } from "next-intl";

import { buttonVariants } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

export function GoogleButton({ next }: { next?: string }) {
  const t = useTranslations("auth");
  const locale = useLocale();

  async function onClick() {
    if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return;
    const supabase = createClient();
    const dest = next ?? `/${locale}/account`;
    await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(dest)}`,
      },
    });
  }

  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        buttonVariants({ variant: "outline", size: "lg" }),
        "w-full",
      )}
    >
      {t("continueWithGoogle")}
    </button>
  );
}
