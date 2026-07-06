import { Filter, MapPin, Send } from "lucide-react";
import { getTranslations } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { cn } from "@/lib/utils";

import { SectionHead } from "./section";

const STEPS = [
  ["how.steps.open", MapPin],
  ["how.steps.filter", Filter],
  ["how.steps.apply", Send],
] as const;

/**
 * "Three steps to a job" strip (open the map → filter → 2-click apply).
 * Self-contained section shared by `/about` and the home page. `background`
 * lets the caller slot it into either page's section rhythm (one bg class,
 * so no Tailwind conflict).
 */
export async function HowItWorks({
  background = "bg-muted/30",
}: {
  background?: string;
}) {
  const t = await getTranslations("landing");
  return (
    <section className={cn("border-border border-y", background)}>
      <Container className="py-16 sm:py-20">
        <SectionHead eyebrow={t("how.eyebrow")} title={t("how.title")} />
        <ol className="mt-10 grid gap-4 md:grid-cols-3">
          {STEPS.map(([key, Icon], i) => (
            <li
              key={key}
              className="border-border bg-card flex flex-col gap-3 rounded-2xl border p-6"
            >
              <div className="flex items-center justify-between">
                <span className="bg-primary text-primary-foreground flex size-10 items-center justify-center rounded-full">
                  <Icon className="size-5" />
                </span>
                <span className="text-muted-foreground/40 font-mono text-3xl font-bold">
                  0{i + 1}
                </span>
              </div>
              <h3 className="text-foreground text-lg font-bold">
                {t(`${key}.title`)}
              </h3>
              <p className="text-muted-foreground text-sm">
                {t(`${key}.body`)}
              </p>
            </li>
          ))}
        </ol>
      </Container>
    </section>
  );
}
