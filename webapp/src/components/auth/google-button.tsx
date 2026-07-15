"use client";

import { useLocale, useTranslations } from "next-intl";
import { useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

import { FormError } from "./auth-fields";

export function GoogleButton({ next }: { next?: string }) {
  const t = useTranslations("auth");
  const locale = useLocale();
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | undefined>();

  async function onClick() {
    if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return;
    setPending(true);
    setError(undefined);
    const supabase = createClient();
    const dest = next ?? `/${locale}/account`;
    const { error: oauthError } = await supabase.auth.signInWithOAuth({
      provider: "google",
      options: {
        redirectTo: `${window.location.origin}/auth/callback?next=${encodeURIComponent(dest)}`,
      },
    });
    // On success the browser is already navigating to Google — only a failure
    // to even start the flow (provider disabled, network) lands here. Show the
    // real reason; a silent dead button made misconfiguration undiagnosable.
    if (oauthError) {
      console.error("Google OAuth start failed", oauthError);
      setPending(false);
      setError(oauthError.message || t("errUnknown"));
    }
  }

  return (
    <div className="flex flex-col gap-2">
      <button
        type="button"
        onClick={onClick}
        disabled={pending}
        className={cn(
          buttonVariants({ variant: "outline", size: "lg" }),
          "w-full",
        )}
      >
        {t("continueWithGoogle")}
      </button>
      <FormError message={error} />
    </div>
  );
}
