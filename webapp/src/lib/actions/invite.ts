"use server";

import { createClient } from "@/lib/supabase/server";

export interface InviteState {
  ok?: boolean;
  error?: boolean;
}

/**
 * Invite a recommended candidate to a job. The `invite_candidate` RPC (0050) is
 * gated to the job owner and notifies the candidate about the vacancy
 * (idempotent per job + candidate), so this action just forwards the call.
 */
export async function inviteCandidate(
  jobId: string,
  candidateId: string,
): Promise<InviteState> {
  if (!jobId || !candidateId) return { error: true };
  try {
    const supabase = await createClient();
    const { error } = await supabase.rpc("invite_candidate", {
      p_job_id: jobId,
      p_candidate: candidateId,
    });
    if (error) {
      console.error("inviteCandidate failed", error);
      return { error: true };
    }
    return { ok: true };
  } catch (e) {
    console.error("inviteCandidate threw", e);
    return { error: true };
  }
}
