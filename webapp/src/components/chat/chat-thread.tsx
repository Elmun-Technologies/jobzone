"use client";

import { useTranslations } from "next-intl";
import { useEffect, useMemo, useRef, useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import type { ChatMessage } from "@/lib/data/chat";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";

export function ChatThread({
  conversationId,
  currentUserId,
  initial,
}: {
  conversationId: string;
  currentUserId: string;
  initial: ChatMessage[];
}) {
  const t = useTranslations("chat");
  const supabase = useMemo(() => createClient(), []);
  const [messages, setMessages] = useState<ChatMessage[]>(initial);
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  // Subscribe to new messages in this conversation (RLS still applies).
  useEffect(() => {
    const channel = supabase
      .channel(`messages:${conversationId}`)
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "messages",
          filter: `conversation_id=eq.${conversationId}`,
        },
        (payload) => {
          const m = payload.new as Record<string, unknown>;
          const msg: ChatMessage = {
            id: String(m.id),
            senderId: String(m.sender_id),
            content: typeof m.content === "string" ? m.content : "",
            createdAt: typeof m.created_at === "string" ? m.created_at : null,
          };
          setMessages((prev) =>
            prev.some((x) => x.id === msg.id) ? prev : [...prev, msg],
          );
        },
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [conversationId, supabase]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const content = text.trim();
    if (!content || sending) return;
    setSending(true);
    setText("");
    const { error } = await supabase.from("messages").insert({
      conversation_id: conversationId,
      sender_id: currentUserId,
      content,
    });
    if (error) setText(content); // restore on failure; realtime echoes success
    setSending(false);
  }

  return (
    <div className="flex h-[70vh] flex-col">
      <div className="flex-1 space-y-2 overflow-y-auto p-1">
        {messages.map((m) => (
          <div
            key={m.id}
            className={cn(
              "max-w-[75%] rounded-2xl px-3 py-2 text-sm",
              m.senderId === currentUserId
                ? "bg-primary text-primary-foreground ml-auto"
                : "bg-muted text-foreground",
            )}
          >
            {m.content}
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      <form onSubmit={send} className="mt-3 flex gap-2">
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={t("messagePlaceholder")}
          className="border-border bg-background text-foreground focus-visible:ring-ring h-11 flex-1 rounded-full border px-4 outline-none focus-visible:ring-2"
        />
        <button
          type="submit"
          disabled={sending}
          className={cn(buttonVariants({ variant: "primary", size: "md" }))}
        >
          {t("send")}
        </button>
      </form>
    </div>
  );
}
