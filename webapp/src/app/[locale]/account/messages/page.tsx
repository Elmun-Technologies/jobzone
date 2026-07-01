import type { Metadata } from "next";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { EmptyState } from "@/components/ui/states";
import { getMyConversations } from "@/lib/data/chat";
import { Link } from "@/i18n/navigation";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "chat" });
  return { title: t("title"), robots: { index: false } };
}

// Per-user page (reads the session inside getMyConversations, whose catch
// swallows the cookies() dynamic signal). Without this Next.js statically
// bakes the guest render — a permanently empty list for signed-in users.
export const dynamic = "force-dynamic";

export default async function MessagesPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("chat");
  const conversations = await getMyConversations();

  return (
    <Container className="max-w-2xl py-12">
      <h1 className="text-foreground mb-6 text-2xl font-bold">{t("title")}</h1>

      {conversations.length === 0 ? (
        <EmptyState title={t("empty")} />
      ) : (
        <ul className="divide-border border-border divide-y rounded-xl border">
          {conversations.map((c) => (
            <li key={c.id}>
              <Link
                href={`/account/messages/${c.id}`}
                className="hover:bg-muted/40 flex items-center gap-3 p-4 transition-colors"
              >
                {c.otherAvatar ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={c.otherAvatar}
                    alt={c.otherName}
                    width={44}
                    height={44}
                    className="size-11 shrink-0 rounded-full object-cover"
                  />
                ) : (
                  <div className="bg-primary text-primary-foreground flex size-11 shrink-0 items-center justify-center rounded-full font-bold">
                    {c.otherName.charAt(0).toUpperCase()}
                  </div>
                )}
                <div className="min-w-0">
                  <p className="text-foreground truncate font-semibold">
                    {c.otherName}
                  </p>
                  <p className="text-muted-foreground truncate text-sm">
                    {c.lastMessage}
                  </p>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </Container>
  );
}
