import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface ConversationSummary {
  id: string;
  otherName: string;
  otherAvatar: string | null;
  lastMessage: string;
  lastAt: string | null;
}

export interface ChatMessage {
  id: string;
  senderId: string;
  content: string;
  createdAt: string | null;
}

function pickOne(v: unknown): Record<string, unknown> | null {
  if (Array.isArray(v)) return (v[0] as Record<string, unknown>) ?? null;
  if (v && typeof v === "object") return v as Record<string, unknown>;
  return null;
}

/** The signed-in user's conversations, most-recent first. */
export async function getMyConversations(): Promise<ConversationSummary[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const { data: parts } = await supabase
      .from("conversation_participants")
      .select("conversation_id")
      .eq("profile_id", user.id);
    const ids = (parts ?? []).map((p) =>
      String((p as { conversation_id: unknown }).conversation_id),
    );
    if (!ids.length) return [];

    const { data: convos } = await supabase
      .from("conversations")
      .select(
        "id, last_message_at, last_message:messages!conversations_last_message_fkey(content)",
      )
      .in("id", ids)
      .order("last_message_at", { ascending: false, nullsFirst: false });

    const { data: others } = await supabase
      .from("conversation_participants")
      .select("conversation_id, profile_id")
      .in("conversation_id", ids)
      .neq("profile_id", user.id);
    const otherByConvo = new Map<string, string>();
    for (const o of others ?? []) {
      const r = o as Record<string, unknown>;
      const cid = String(r.conversation_id);
      if (!otherByConvo.has(cid)) otherByConvo.set(cid, String(r.profile_id));
    }

    const otherIds = [...new Set(otherByConvo.values())];
    const profiles = new Map<string, Record<string, unknown>>();
    if (otherIds.length) {
      const { data: profs } = await supabase
        .from("profiles_public")
        .select("id, full_name, avatar_url")
        .in("id", otherIds);
      for (const p of profs ?? []) {
        const pr = p as Record<string, unknown>;
        profiles.set(String(pr.id), pr);
      }
    }

    return (convos ?? []).map((row) => {
      const c = row as Record<string, unknown>;
      const otherId = otherByConvo.get(String(c.id));
      const prof = otherId ? profiles.get(otherId) : null;
      const last = pickOne(c.last_message);
      return {
        id: String(c.id),
        otherName: prof?.full_name ? String(prof.full_name) : "—",
        otherAvatar: prof?.avatar_url ? String(prof.avatar_url) : null,
        lastMessage: last?.content ? String(last.content) : "",
        lastAt:
          typeof c.last_message_at === "string" ? c.last_message_at : null,
      };
    });
  } catch (e) {
    console.error("getMyConversations failed", e);
    return [];
  }
}

/** A conversation's messages + the other participant's name. RLS-gated. */
export async function getConversation(
  id: string,
): Promise<{ messages: ChatMessage[]; otherName: string } | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;

    // RLS: only a participant can read the conversation row.
    const { data: convo } = await supabase
      .from("conversations")
      .select("id")
      .eq("id", id)
      .maybeSingle();
    if (!convo) return null;

    const { data: msgs } = await supabase
      .from("messages")
      .select("id, sender_id, content, created_at")
      .eq("conversation_id", id)
      .is("deleted_at", null)
      .order("created_at", { ascending: true });

    const { data: others } = await supabase
      .from("conversation_participants")
      .select("profile_id")
      .eq("conversation_id", id)
      .neq("profile_id", user.id)
      .limit(1);
    let otherName = "—";
    const otherId = others?.[0]
      ? String((others[0] as { profile_id: unknown }).profile_id)
      : null;
    if (otherId) {
      const { data: p } = await supabase
        .from("profiles_public")
        .select("full_name")
        .eq("id", otherId)
        .maybeSingle();
      if (p) otherName = String((p as { full_name: unknown }).full_name ?? "—");
    }

    return {
      otherName,
      messages: (msgs ?? []).map((m) => {
        const r = m as Record<string, unknown>;
        return {
          id: String(r.id),
          senderId: String(r.sender_id),
          content: typeof r.content === "string" ? r.content : "",
          createdAt: typeof r.created_at === "string" ? r.created_at : null,
        };
      }),
    };
  } catch (e) {
    console.error("getConversation failed", e);
    return null;
  }
}
