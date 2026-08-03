/**
 * Parks what the visitor has typed before a navigation that rebuilds the tree.
 *
 * The forms here already survive the auth-last detour: on a signed-out submit
 * they write their draft to sessionStorage, and they restore it on mount. That
 * covers the one navigation the product designed for, and nothing else.
 *
 * Changing language is the other one. It re-renders the root layout — the same
 * thing that used to drop the `dark` class — so the page component under
 * `[locale]` is rebuilt and every field goes back to empty. A seeker four
 * fields into an application who switches to Russian lost all four, silently,
 * which is exactly what "nothing typed is ever lost" is meant to rule out.
 *
 * A form registers *how* to park itself; the locale switcher calls them all
 * before it navigates. Restoring needs no new code — each form already reads
 * its stash on mount, so the rebuilt form picks the draft straight back up.
 */

type Capture = () => void;

const captures = new Set<Capture>();

/**
 * Registers a form's "park what is typed" callback for the lifetime of the
 * component. Returns the cleanup, so the usual shape is:
 *
 *     useEffect(() => registerDraftCapture(() => stashDraft(read())), []);
 */
export function registerDraftCapture(capture: Capture): () => void {
  captures.add(capture);
  return () => {
    captures.delete(capture);
  };
}

/**
 * Parks every registered draft. Called immediately before a locale change.
 *
 * One form throwing must not cost the others their draft, so each is isolated:
 * a full sessionStorage quota error while parking a long vacancy description
 * should not also wipe the application someone is halfway through.
 */
export function captureDrafts(): void {
  for (const capture of captures) {
    try {
      capture();
    } catch {
      // Storage unavailable (private mode, quota) — nothing to do but let the
      // remaining forms try.
    }
  }
}
