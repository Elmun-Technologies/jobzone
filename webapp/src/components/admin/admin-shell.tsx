import { ShieldCheck } from "lucide-react";

import { SidebarNav } from "@/components/admin/sidebar-nav";
import { adminNav } from "@/lib/admin/nav";
import { adminStrings } from "@/lib/admin/strings";

/**
 * Admin panel chrome: an always-ink sidebar (volt accents) beside the page
 * content. On small screens the sidebar collapses to a horizontally scrolling
 * strip above the content.
 */
export function AdminShell({
  children,
  mock,
}: {
  children: React.ReactNode;
  mock: boolean;
}) {
  return (
    <div className="flex min-h-[70vh] items-stretch">
      <aside className="hidden w-60 shrink-0 bg-[#0a0a0a] px-3 py-6 md:block">
        <p className="flex items-center gap-2 px-3 pb-5 text-sm font-bold text-[#f3f3f1]">
          <ShieldCheck className="size-4 text-[#c7fb00]" aria-hidden />
          {adminStrings.brand}
        </p>
        <SidebarNav groups={adminNav} />
      </aside>

      <div className="min-w-0 flex-1">
        <div className="overflow-x-auto bg-[#0a0a0a] px-3 py-2 md:hidden">
          <SidebarNav groups={adminNav} />
        </div>
        {mock ? (
          <p className="border-border bg-muted text-muted-foreground border-b px-6 py-2 text-xs">
            {adminStrings.demoMode}
          </p>
        ) : null}
        <div className="px-4 py-8 sm:px-6 lg:px-8">{children}</div>
      </div>
    </div>
  );
}
