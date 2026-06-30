"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

/**
 * Opens (or creates) a direct conversation with another user and navigates to
 * it. Participant rows are inserted self-first so the RLS with-check on the
 * second row passes (the inserter is then already a participant).
 */
export async function startConversationWith(
  otherProfileId: string,
  locale: string,
): Promise<void> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);
  if (!otherProfileId || otherProfileId === user.id) {
    redirect(`/${locale}/account/messages`);
  }

  // Look for an existing shared conversation.
  const { data: mine } = await supabase
    .from("conversation_participants")
    .select("conversation_id")
    .eq("profile_id", user.id);
  const myIds = (mine ?? []).map((m) =>
    String((m as { conversation_id: unknown }).conversation_id),
  );

  if (myIds.length) {
    const { data: shared } = await supabase
      .from("conversation_participants")
      .select("conversation_id")
      .eq("profile_id", otherProfileId)
      .in("conversation_id", myIds);
    const existing = shared?.[0]
      ? String((shared[0] as { conversation_id: unknown }).conversation_id)
      : null;
    if (existing) redirect(`/${locale}/account/messages/${existing}`);
  }

  const { data: convo, error } = await supabase
    .from("conversations")
    .insert({ type: "direct" })
    .select("id")
    .single();
  if (error || !convo) redirect(`/${locale}/account/messages`);

  const conversationId = String((convo as { id: unknown }).id);
  // Insert self first (with-check: profile_id = auth.uid()), then the other
  // (with-check: is_conversation_participant — now true).
  await supabase
    .from("conversation_participants")
    .insert({ conversation_id: conversationId, profile_id: user.id });
  await supabase
    .from("conversation_participants")
    .insert({ conversation_id: conversationId, profile_id: otherProfileId });

  redirect(`/${locale}/account/messages/${conversationId}`);
}
