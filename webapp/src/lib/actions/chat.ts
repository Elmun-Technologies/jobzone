"use server";

import { createClient } from "@/lib/supabase/server";

export interface StartConversationState {
  ok?: boolean;
  conversationId?: string;
  signedOut?: boolean;
  error?: boolean;
}

/**
 * Opens (or creates) the direct conversation with another user.
 *
 * Goes through `get_or_create_direct_conversation` (0067) — the ONLY way a
 * client can create a conversation. `conversations` has had no client INSERT
 * policy since 0010, and `conversation_participants` none since 0027
 * ("Membership is created solely by start_direct_conversation() (SECURITY
 * DEFINER)"). This used to insert into both tables directly: every write hit
 * RLS, the caught error just redirected to `/account/messages`, and the
 * seeker landed on an empty inbox with no indication anything failed. No
 * conversation could ever be created from the web — mobile already calls this
 * same RPC (`ChatRepository.getOrCreateDirectConversation`).
 *
 * Returns a result instead of redirecting itself, so the caller can navigate
 * on success and show an error otherwise — the "Message" button silently
 * doing nothing was as much the bug as the RLS failure underneath it.
 */
export async function startConversationWith(
  otherProfileId: string,
): Promise<StartConversationState> {
  if (!otherProfileId) return { error: true };
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };
  if (otherProfileId === user.id) return { error: true };

  const { data, error } = await supabase.rpc(
    "get_or_create_direct_conversation",
    { p_other: otherProfileId },
  );
  if (error || !data) {
    console.error("startConversationWith failed", error);
    return { error: true };
  }
  return { ok: true, conversationId: String(data) };
}
