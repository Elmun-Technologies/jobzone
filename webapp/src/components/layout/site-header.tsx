import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";

import { HeaderAuth } from "./header-auth";
import { HeaderNav } from "./header-nav";
import { LocaleSwitcher } from "./locale-switcher";
import { MobileMenu } from "./mobile-menu";
import { RoleToggle } from "./role-toggle";
import { ThemeToggle } from "./theme-toggle";
import { YollaLogo } from "./yolla-logo";

// One destination for both audiences: /employer renders the dashboard for a
// signed-in employer and the landing for everyone else. It used to send guests
// straight to the empty post form, which asked for work before saying what
// hiring here gets you.
const EMPLOYER_HREF = "/employer";

/**
 * Top navigation: brand + audience toggle, mode-aware links + CTA, auth.
 *
 * Nothing here touches the request. Who is signed in is resolved in the
 * browser (SessionProvider) and consumed by the three parts that care —
 * HeaderNav, HeaderAuth and MobileMenu. That is what lets a vacancy page or a
 * category landing be prerendered and served from the CDN: a single session
 * read in this component made every route in the app render per request.
 */
export function SiteHeader() {
  return (
    <header className="border-border bg-background/80 sticky top-0 z-50 border-b backdrop-blur">
      <Container className="flex h-16 items-center justify-between gap-4">
        {/* `shrink-0`: this is the flex item Container's row actually
            squeezes once space runs short — right around the 1024px `lg:`
            breakpoint, where the nav links + locale/theme toggles all pop
            into view at once. Without it, this group (and the pill inside
            it) gets compressed below its own content size and overflows on
            top of the nav that starts right after it, rendering "Job
            seeker"/"Employer" on top of each other and "Home"/"Jobs" hidden
            behind the pill. */}
        <div className="flex shrink-0 items-center gap-3">
          <Link href="/" aria-label="Yollla">
            <YollaLogo />
          </Link>
          <div className="hidden sm:block">
            <RoleToggle employerHref={EMPLOYER_HREF} />
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-4">
          <HeaderNav />

          {/* Below xl these live in the mobile drawer (see header-nav.tsx for
              why xl, not lg) — otherwise the header overflows sideways. */}
          <div className="hidden items-center gap-4 xl:flex">
            <LocaleSwitcher />
            <ThemeToggle />
          </div>

          <HeaderAuth />

          <MobileMenu employerHref={EMPLOYER_HREF} />
        </div>
      </Container>
    </header>
  );
}
