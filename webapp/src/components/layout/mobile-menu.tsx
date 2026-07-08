"use client";

import { Menu, X } from "lucide-react";
import { useTranslations } from "next-intl";
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";

import { buttonVariants } from "@/components/ui/button";
import { Link, usePathname } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

import { navModel } from "./nav-model";
import { RoleToggle } from "./role-toggle";

/**
 * The mobile navigation drawer (below `lg`, where the desktop nav is hidden).
 * A hamburger opens a slide-in sheet with the seeker⇄employer toggle, the
 * mode-aware links (same navModel as the desktop nav), and the primary CTA —
 * so a phone user can actually reach Jobs / Companies / About / Saved and
 * switch audience. Closes on navigation, backdrop tap, or Escape.
 */
export function MobileMenu({
  signedIn,
  isEmployerAccount,
  employerHref,
}: {
  signedIn: boolean;
  isEmployerAccount: boolean;
  employerHref: string;
}) {
  const t = useTranslations("nav");
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  // The overlay is portaled to <body>: the sticky header uses backdrop-blur,
  // which creates a containing block that would otherwise trap our `fixed`
  // overlay inside the 64px header instead of the viewport.
  const [mounted, setMounted] = useState(false);
  // eslint-disable-next-line react-hooks/set-state-in-effect
  useEffect(() => setMounted(true), []);
  const { links, cta } = navModel(pathname, signedIn, isEmployerAccount);

  // Close on route change.
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setOpen(false);
  }, [pathname]);

  // Lock body scroll + close on Escape while open.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    document.addEventListener("keydown", onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prev;
    };
  }, [open]);

  return (
    <div className="lg:hidden">
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label={t("openMenu")}
        aria-expanded={open}
        className={cn(
          buttonVariants({ variant: "outline", size: "sm" }),
          "px-2.5",
        )}
      >
        <Menu className="size-4" />
      </button>

      {open && mounted
        ? createPortal(
            <div className="fixed inset-0 z-[60]">
              <button
                type="button"
                aria-label={t("closeMenu")}
                onClick={() => setOpen(false)}
                className="bg-foreground/40 absolute inset-0 backdrop-blur-sm"
              />
              <div className="bg-background absolute inset-y-0 right-0 flex w-72 max-w-[85vw] flex-col gap-6 p-5 shadow-xl">
                <div className="flex items-center justify-between">
                  <RoleToggle employerHref={employerHref} />
                  <button
                    type="button"
                    onClick={() => setOpen(false)}
                    aria-label={t("closeMenu")}
                    className={cn(
                      buttonVariants({ variant: "outline", size: "sm" }),
                      "px-2.5",
                    )}
                  >
                    <X className="size-4" />
                  </button>
                </div>

                <nav className="flex flex-col gap-1">
                  {links.map((l) => {
                    const activePath =
                      l.href === "/"
                        ? pathname === "/"
                        : pathname.startsWith(l.href);
                    return (
                      <Link
                        key={l.href}
                        href={l.href}
                        className={cn(
                          "rounded-lg px-3 py-2.5 text-base font-medium transition-colors",
                          activePath
                            ? "bg-accent text-accent-foreground"
                            : "text-foreground hover:bg-muted",
                        )}
                      >
                        {t(l.labelKey)}
                      </Link>
                    );
                  })}
                </nav>

                <Link
                  href={cta.href}
                  className={cn(
                    buttonVariants({ variant: "primary", size: "md" }),
                    "mt-auto w-full gap-1.5",
                  )}
                >
                  <cta.Icon className="size-4" />
                  {t(cta.labelKey)}
                </Link>
              </div>
            </div>,
            document.body,
          )
        : null}
    </div>
  );
}
