"use client";

import { Camera, Loader2 } from "lucide-react";
import { useTranslations } from "next-intl";
import { useRef, useState } from "react";

import { toast } from "@/components/ui/toast";
import { saveAvatarUrl } from "@/lib/actions/profile";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

const MAX_BYTES = 5 * 1024 * 1024;
const TYPES = ["image/jpeg", "image/png", "image/webp"];

/**
 * Résumé photo, asked for here rather than in the wizard.
 *
 * The local apps put this on step 1, but the wizard is the guest-first half of
 * an auth-last flow — a visitor fills it in with no session, and the avatars
 * bucket authorizes writes by `auth.uid()` path prefix. So the picture is asked
 * for at the first moment it can actually be stored: on the account page, right
 * after the résumé has been saved.
 *
 * Uploads straight from the browser to Storage (the file never travels through
 * a server action, which has a body limit and would double the transfer), then
 * a tiny server action writes the public URL onto the profile.
 */
export function AvatarUpload({ current }: { current: string | null }) {
  const t = useTranslations("account.resumeCard");
  const [url, setUrl] = useState(current);
  const [busy, setBusy] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  async function upload(file: File) {
    if (!TYPES.includes(file.type) || file.size > MAX_BYTES) {
      toast({ title: t("photoInvalid"), variant: "error" });
      return;
    }
    setBusy(true);
    try {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        toast({ title: t("photoFailed"), variant: "error" });
        return;
      }
      // `<uid>/…` is what the bucket policy authorizes on. The timestamped name
      // (rather than a fixed `avatar.jpg`) sidesteps the CDN cache serving the
      // previous picture after a change.
      const ext =
        file.type === "image/png"
          ? "png"
          : file.type === "image/webp"
            ? "webp"
            : "jpg";
      const path = `${user.id}/resume-${Date.now()}.${ext}`;
      const up = await supabase.storage
        .from("avatars")
        .upload(path, file, { upsert: true, contentType: file.type });
      if (up.error) {
        toast({ title: t("photoFailed"), variant: "error" });
        return;
      }
      const {
        data: { publicUrl },
      } = supabase.storage.from("avatars").getPublicUrl(path);
      const res = await saveAvatarUrl(publicUrl);
      if (!res.ok) {
        toast({ title: t("photoFailed"), variant: "error" });
        return;
      }
      setUrl(publicUrl);
      toast({ title: t("photoSaved"), variant: "success" });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mt-4 flex items-center gap-3">
      <span className="bg-muted size-14 shrink-0 overflow-hidden rounded-full">
        {url ? (
          // A plain <img>, not next/image: the Storage host isn't in the
          // images config, and optimizing a 56px avatar through the loader
          // would cost a round-trip to save nothing.
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={url}
            alt=""
            className="size-full object-cover"
            width={56}
            height={56}
          />
        ) : (
          <span className="text-muted-foreground flex size-full items-center justify-center">
            <Camera className="size-5" />
          </span>
        )}
      </span>
      <div className="min-w-0">
        <p className="text-foreground text-sm font-medium">
          {url ? t("photoChange") : t("photoAdd")}
        </p>
        <p className="text-muted-foreground text-xs">{t("photoHint")}</p>
      </div>
      <input
        ref={fileRef}
        type="file"
        accept={TYPES.join(",")}
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0];
          // Clear the input so picking the same file twice still fires.
          e.target.value = "";
          if (file) void upload(file);
        }}
      />
      <button
        type="button"
        disabled={busy}
        onClick={() => fileRef.current?.click()}
        className={cn(
          "border-border text-foreground hover:border-primary/40 ml-auto inline-flex shrink-0 items-center gap-2 rounded-full border px-4 py-2 text-sm font-semibold transition-colors disabled:opacity-60",
        )}
      >
        {busy ? <Loader2 className="size-4 animate-spin" /> : null}
        {t("photoCta")}
      </button>
    </div>
  );
}
