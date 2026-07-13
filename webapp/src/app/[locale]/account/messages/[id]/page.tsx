import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { getTranslations, setRequestLocale } from "next-intl/server";

import { ChatThread } from "@/components/chat/chat-thread";
import { Container } from "@/components/ui/container";
import { getCurrentUser } from "@/lib/auth/user";
import { getConversation } from "@/lib/data/chat";

// Auth/session-dependent, per-request. Without this the page can be
// full-route-cached (getCurrentUser swallows cookies() so Next never sees
// the dynamic signal) and one visitor's render could be served to another.
export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "chat" });
  return { title: t("title"), robots: { index: false } };
}

export default async function ConversationPage({
  params,
}: {
  params: Promise<{ locale: string; id: string }>;
}) {
  const { locale, id } = await params;
  setRequestLocale(locale);

  const user = await getCurrentUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const convo = await getConversation(id);
  if (!convo) notFound();

  return (
    <Container className="max-w-2xl py-6">
      <h1 className="text-foreground mb-4 text-xl font-bold">
        {convo.otherName}
      </h1>
      <ChatThread
        conversationId={id}
        currentUserId={user.id}
        initial={convo.messages}
      />
    </Container>
  );
}
