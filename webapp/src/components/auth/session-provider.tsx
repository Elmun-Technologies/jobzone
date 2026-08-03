"use client";

import { usePathname } from "next/navigation";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import { hasAuthCookie, isAuthRoute } from "@/lib/auth/browser-session";

export interface SessionState {
  /** `null` while the browser is still asking — render neutral, not "guest". */
  signedIn: boolean | null;
  userId: string | null;
  isEmployer: boolean;
  unread: number;
}

export interface SessionValue extends SessionState {
  /** Re-read the session (used when a live notification lands). */
  refresh: () => void;
}

const EMPTY: SessionState = {
  signedIn: null,
  userId: null,
  isEmployer: false,
  unread: 0,
};
const GUEST: SessionState = {
  signedIn: false,
  userId: null,
  isEmployer: false,
  unread: 0,
};

/**
 * Last known shape of the session, kept so a returning visitor's header
 * renders the right way round on the first frame after hydration instead of
 * flashing "Sign in" at someone who is signed in. It holds no credentials —
 * only "there was a session, and it was an employer's" — and everything it
 * unlocks is still gated server-side. The real answer overwrites it a moment
 * later either way.
 */
const HINT_KEY = "yolla:session-hint";

function readHint(): SessionState | null {
  try {
    const raw = window.localStorage.getItem(HINT_KEY);
    if (!raw) return null;
    const v = JSON.parse(raw) as { signedIn?: unknown; isEmployer?: unknown };
    if (typeof v.signedIn !== "boolean") return null;
    return {
      signedIn: v.signedIn,
      userId: null,
      isEmployer: v.isEmployer === true,
      unread: 0,
    };
  } catch {
    return null;
  }
}

function writeHint(state: SessionState): void {
  try {
    window.localStorage.setItem(
      HINT_KEY,
      JSON.stringify({
        signedIn: state.signedIn,
        isEmployer: state.isEmployer,
      }),
    );
  } catch {
    // Private mode / disabled storage — the hint is an optimization only.
  }
}

const SessionContext = createContext<SessionValue>({
  ...EMPTY,
  refresh: () => {},
});

/**
 * Who is looking, resolved in the browser instead of on the server.
 *
 * The header, the phone tab bar and the drawer all need this, and asking for
 * it on the server is what kept every page in the app off the CDN: one session
 * read anywhere in the tree makes the whole route render per request. Moving
 * it here lets the shell be prerendered once and the personal parts fill in on
 * hydration.
 *
 * The cost is honest: for the first frame a signed-in visitor's header does
 * not yet know them. Consumers render a neutral placeholder while `signedIn`
 * is `null` rather than a "Sign in" button, so nobody is told they are logged
 * out when they are not — and the localStorage hint above usually skips even
 * that for anyone who has been here before.
 */
export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<SessionState>(EMPTY);
  // Bumping this re-runs the effect below. The unread badge has to move when a
  // notification arrives live, and it used to be a server component that
  // `router.refresh()` could repaint.
  const [nonce, setNonce] = useState(0);
  const refresh = useCallback(() => setNonce((n) => n + 1), []);
  const pathname = usePathname();
  // A cookieless visitor on an ordinary page is a guest, and we can say so
  // without downloading anything. On the auth routes we load regardless, so
  // that a sign-in completed without a document load is still noticed.
  const needsClient = isAuthRoute(pathname) || hasAuthCookie();

  useEffect(() => {
    let cancelled = false;

    // Applied in the effect, not in the initial state: the prerendered HTML
    // was built without any of this, so reading storage during the first
    // render would be a hydration mismatch.
    const hint = readHint();
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (hint) setState(hint);

    // Imported here rather than at the top of the file, because this provider
    // wraps every page: a static import puts 244 KB of Supabase in the bundle
    // that has to parse before anything else runs, on a page whose whole point
    // is that it came off the CDN ready to paint. As a dynamic import it is a
    // separate chunk the browser fetches while the page is already on screen —
    // which is exactly the shape of the work (the header fills in a beat
    // later either way).
    let supabase: Awaited<
      ReturnType<typeof import("@/lib/supabase/client").createClient>
    >;

    async function load() {
      try {
        const {
          data: { user },
        } = await supabase.auth.getUser();
        if (cancelled) return;
        if (!user) {
          setState(GUEST);
          writeHint(GUEST);
          return;
        }
        // Both reads are RLS-scoped to the caller, so the anon key is enough.
        const [{ data: profile }, { count }] = await Promise.all([
          supabase
            .from("profiles")
            .select("role")
            .eq("id", user.id)
            .maybeSingle(),
          supabase
            .from("notifications")
            .select("id", { count: "exact", head: true })
            .eq("is_read", false),
        ]);
        if (cancelled) return;
        const next: SessionState = {
          signedIn: true,
          userId: user.id,
          isEmployer:
            String((profile as { role?: unknown } | null)?.role ?? "") ===
            "employer",
          unread: count ?? 0,
        };
        setState(next);
        writeHint(next);
      } catch {
        // Never break the header over this — fall back to the guest shape,
        // but leave the hint alone: a failed network call is not a sign-out.
        if (!cancelled) setState(GUEST);
      }
    }

    if (!needsClient) {
      setState(GUEST);
      writeHint(GUEST);
      return () => {
        cancelled = true;
      };
    }

    let unsubscribe: (() => void) | undefined;
    void (async () => {
      try {
        const { createClient } = await import("@/lib/supabase/client");
        supabase = createClient();
      } catch {
        // No backend configured (a preview build without the envs). Settle on
        // the guest shape rather than leaving the header in limbo forever.
        if (!cancelled) setState(GUEST);
        return;
      }
      if (cancelled) return;
      await load();
      // Sign-in and sign-out happen without a reload (OTP, Google, the
      // sign-out action), so follow the auth state rather than only reading
      // it once.
      const { data: sub } = supabase.auth.onAuthStateChange(() => void load());
      unsubscribe = () => sub.subscription.unsubscribe();
      // The effect may have been torn down while the chunk was in flight.
      if (cancelled) unsubscribe();
    })();

    return () => {
      cancelled = true;
      unsubscribe?.();
    };
  }, [nonce, needsClient]);

  const value = useMemo<SessionValue>(
    () => ({ ...state, refresh }),
    [state, refresh],
  );

  return (
    <SessionContext.Provider value={value}>{children}</SessionContext.Provider>
  );
}

export function useSession(): SessionValue {
  return useContext(SessionContext);
}
