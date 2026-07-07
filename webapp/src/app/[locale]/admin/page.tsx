import { BarList } from "@/components/admin/bar-list";
import { TrendBarChart, TrendLineChart } from "@/components/admin/charts";
import { buttonVariants } from "@/components/ui/button";
import { StatCard } from "@/components/ui/stat-card";
import { ErrorState } from "@/components/ui/states";
import { getDashboardStats } from "@/lib/admin/data/stats";
import { adminStrings } from "@/lib/admin/strings";
import { FUNNEL_STAGES } from "@/lib/admin/types";
import { requireAdmin } from "@/lib/auth/require-admin";
import { groupNumber } from "@/lib/format";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

// Session-gated admin page — render per request (getCurrentUser()'s try/catch
// swallows the cookies() dynamic signal, so without this Next.js would
// prerender one shared, logged-out copy).
export const dynamic = "force-dynamic";

const RANGES = [30, 90] as const;

function Section({
  title,
  children,
  className,
}: {
  title: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <section
      className={cn("border-border bg-card rounded-xl border p-5", className)}
    >
      <h2 className="text-foreground text-sm font-semibold">{title}</h2>
      <div className="mt-4">{children}</div>
    </section>
  );
}

export default async function AdminDashboardPage({
  params,
  searchParams,
}: {
  params: Promise<{ locale: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { locale } = await params;
  await requireAdmin(locale);

  const sp = await searchParams;
  const rawDays = Number(Array.isArray(sp.days) ? sp.days[0] : sp.days);
  const days = RANGES.includes(rawDays as (typeof RANGES)[number])
    ? rawDays
    : 30;

  const stats = await getDashboardStats(days);
  if (!stats) {
    return (
      <ErrorState
        title={adminStrings.loadError}
        description={adminStrings.loadErrorHint}
      />
    );
  }

  const { totals, series, funnel, finance } = stats;
  const funnelItems = FUNNEL_STAGES.map((stage) => ({
    label: FUNNEL_LABELS[stage],
    value: funnel[stage] ?? 0,
  }));

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-foreground text-2xl font-bold">
            {adminStrings.panelTitle}
          </h1>
          <p className="text-muted-foreground mt-1 text-sm">
            Platforma bo&apos;yicha umumiy ko&apos;rsatkichlar
          </p>
        </div>
        <div className="flex gap-2">
          {RANGES.map((r) => (
            <Link
              key={r}
              href={{
                pathname: "/admin",
                query: r === 30 ? {} : { days: String(r) },
              }}
              className={cn(
                buttonVariants({
                  variant: r === days ? "primary" : "outline",
                  size: "sm",
                }),
              )}
            >
              {r} kun
            </Link>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 md:grid-cols-3 xl:grid-cols-5">
        <StatCard label="Ish izlovchilar" value={totals.seekers} />
        <StatCard label="Ish beruvchilar" value={totals.employers} />
        <StatCard
          label="Ochiq vakansiyalar"
          value={totals.jobsOpen}
          hint={`Jami: ${groupNumber(totals.jobsTotal)}`}
        />
        <StatCard label="Arizalar" value={totals.applications} />
        <StatCard
          label="Kompaniyalar"
          value={totals.companies}
          hint={`Tasdiqlangan: ${groupNumber(totals.companiesVerified)}`}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Section title={`Ro'yxatdan o'tishlar (${days} kun)`}>
          <TrendLineChart data={series.signups} />
        </Section>
        <Section title={`Joylangan vakansiyalar (${days} kun)`}>
          <TrendLineChart data={series.jobs} />
        </Section>
        <Section title={`Arizalar (${days} kun)`}>
          <TrendLineChart data={series.applications} />
        </Section>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Section title={`Daromad — promo buyurtmalar (${days} kun, so'm)`}>
          <TrendBarChart data={series.revenue} unit="so'm" />
        </Section>
        <Section title={`Hamyon to'ldirishlar (${days} kun, so'm)`}>
          <TrendBarChart data={series.topups} unit="so'm" />
        </Section>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Section title="Ariza voronkasi (barcha vaqt)">
          <BarList items={funnelItems} />
          <p className="text-muted-foreground mt-3 text-xs">
            Rad etilgan: {groupNumber(funnel.rejected ?? 0)}
          </p>
        </Section>
        <Section title="Top kategoriyalar (ochiq vakansiyalar)">
          <BarList
            items={stats.topCategories.map((c) => ({
              label: c.name,
              value: c.n,
            }))}
          />
        </Section>
        <Section title="Top shaharlar (ochiq vakansiyalar)">
          <BarList
            items={stats.topCities.map((c) => ({ label: c.city, value: c.n }))}
          />
        </Section>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Jami daromad (so'm)" value={finance.revenueTotal} />
        <StatCard
          label="Hamyon majburiyati (so'm)"
          value={finance.walletLiability}
        />
        <StatCard
          label="Kutilayotgan to'ldirishlar"
          value={finance.pendingTopups}
          hint={`${groupNumber(finance.pendingTopupSum)} so'm`}
        />
      </div>

      <p className="text-muted-foreground text-xs">
        Izoh: hodisalar jurnali hali yo&apos;q — seriyalar yozuvlar yaratilgan
        sanaga asoslangan (faollik/DAU emas).
      </p>
    </div>
  );
}

const FUNNEL_LABELS: Record<(typeof FUNNEL_STAGES)[number], string> = {
  submitted: "Yuborilgan",
  viewed: "Ko'rilgan",
  shortlisted: "Saralangan",
  interview: "Suhbat",
  offer: "Taklif",
  hired: "Ishga olingan",
};
