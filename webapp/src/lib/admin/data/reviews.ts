import "server-only";

import type { AdminList, AdminReviewRow } from "../types";
import { adminReadClient, pageRange, toPage } from "./shared";

export type ReviewKind = "company" | "worker";

/**
 * Both review tables through one reader. company_reviews: subject = the
 * reviewed company; worker_reviews: subject = the reviewed worker (FK-hinted
 * embeds — worker_id and author_id both reference profiles).
 */
export async function getAdminReviews(
  kind: ReviewKind,
  page: number,
): Promise<AdminList<AdminReviewRow>> {
  const client = await adminReadClient();
  if (!client) return null;
  try {
    const { from, to } = pageRange(page);
    const select =
      kind === "company"
        ? "id, rating, body, hidden_at, created_at, companies(name), author:profiles(full_name)"
        : "id, rating, body, hidden_at, created_at, worker:profiles!worker_reviews_worker_id_fkey(full_name), author:profiles!worker_reviews_author_id_fkey(full_name)";
    const { data, error } = await client
      .from(kind === "company" ? "company_reviews" : "worker_reviews")
      .select(select)
      .order("created_at", { ascending: false })
      .range(from, to);
    if (error) throw error;
    return toPage(
      (data ?? []).map((row) => {
        const r = row as Record<string, unknown>;
        const subject =
          kind === "company"
            ? (r.companies as { name?: unknown } | null)?.name
            : (r.worker as { full_name?: unknown } | null)?.full_name;
        const author = (r.author as { full_name?: unknown } | null)?.full_name;
        return {
          id: String(r.id),
          subject: String(subject ?? "—"),
          authorName: String(author ?? "—"),
          rating: Number(r.rating ?? 0),
          body: r.body ? String(r.body) : null,
          hiddenAt: r.hidden_at ? String(r.hidden_at) : null,
          createdAt: String(r.created_at ?? ""),
        };
      }),
    );
  } catch (e) {
    console.error("getAdminReviews failed", e);
    return { rows: [], hasNext: false };
  }
}
