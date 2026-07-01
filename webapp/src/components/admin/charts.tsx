"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import type { SeriesPoint } from "@/lib/admin/types";
import { groupNumber } from "@/lib/format";

// Single-series charts throughout: the title names the series, so no legend
// (dataviz rule); color is the monochrome --chart-series token; grid and axis
// text stay in recessive UI tokens, never the series color.

/** "2026-06-21" -> "21.06" for axis ticks. */
function tick(d: string): string {
  const [, m, day] = d.split("-");
  return `${day}.${m}`;
}

function format(n: number, unit?: string): string {
  return unit ? `${groupNumber(n)} ${unit}` : groupNumber(n);
}

const AXIS_TICK = { fill: "var(--muted-foreground)", fontSize: 11 } as const;

function chartTooltip(unit?: string) {
  return (
    <Tooltip
      cursor={{ stroke: "var(--border)", fill: "var(--muted)", opacity: 0.6 }}
      contentStyle={{
        background: "var(--card)",
        border: "1px solid var(--border)",
        borderRadius: 8,
        color: "var(--foreground)",
        fontSize: 12,
      }}
      labelStyle={{ color: "var(--muted-foreground)" }}
      formatter={(value) => [format(Number(value), unit), ""]}
      separator=""
    />
  );
}

/** Daily-count trend as a 2px line with a hover crosshair. */
export function TrendLineChart({
  data,
  unit,
}: {
  data: SeriesPoint[];
  unit?: string;
}) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <LineChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
        <CartesianGrid vertical={false} stroke="var(--border)" strokeDasharray="0" />
        <XAxis
          dataKey="d"
          tickFormatter={tick}
          tick={AXIS_TICK}
          tickLine={false}
          axisLine={{ stroke: "var(--border)" }}
          minTickGap={28}
        />
        <YAxis
          tick={AXIS_TICK}
          tickLine={false}
          axisLine={false}
          width={44}
          tickFormatter={(v: number) => groupNumber(v)}
          allowDecimals={false}
        />
        {chartTooltip(unit)}
        <Line
          type="monotone"
          dataKey="n"
          stroke="var(--chart-series)"
          strokeWidth={2}
          dot={false}
          activeDot={{ r: 4, fill: "var(--chart-series)", stroke: "var(--card)", strokeWidth: 2 }}
        />
      </LineChart>
    </ResponsiveContainer>
  );
}

/** Daily-sum trend (e.g. UZS amounts) as thin columns with rounded tops. */
export function TrendBarChart({
  data,
  unit,
}: {
  data: SeriesPoint[];
  unit?: string;
}) {
  return (
    <ResponsiveContainer width="100%" height={220}>
      <BarChart data={data} margin={{ top: 8, right: 8, bottom: 0, left: 0 }} barCategoryGap="30%">
        <CartesianGrid vertical={false} stroke="var(--border)" strokeDasharray="0" />
        <XAxis
          dataKey="d"
          tickFormatter={tick}
          tick={AXIS_TICK}
          tickLine={false}
          axisLine={{ stroke: "var(--border)" }}
          minTickGap={28}
        />
        <YAxis
          tick={AXIS_TICK}
          tickLine={false}
          axisLine={false}
          width={60}
          tickFormatter={(v: number) => (v >= 1_000_000 ? `${v / 1_000_000}M` : groupNumber(v))}
          allowDecimals={false}
        />
        {chartTooltip(unit)}
        <Bar dataKey="n" fill="var(--chart-series)" radius={[3, 3, 0, 0]} maxBarSize={18} />
      </BarChart>
    </ResponsiveContainer>
  );
}
