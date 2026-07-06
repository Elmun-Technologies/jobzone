import { getTranslations } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { Link } from "@/i18n/navigation";
import { cn } from "@/lib/utils";

import { RatingCard, SectionHead } from "./section";

/**
 * Compact "flowers & flies" reputation teaser for the home page — a trust
 * signal that condenses the full `/about` reputation section into its
 * headline + the two rating chips, with a link out to the full story.
 */
export async function ReputationTeaser({
  background = "bg-background",
  moreHref = "/about#reputation",
  moreLabel,
}: {
  background?: string;
  moreHref?: string;
  moreLabel?: string;
}) {
  const t = await getTranslations("landing");
  return (
    <section className={cn("border-border border-y", background)}>
      <Container className="py-16 sm:py-20">
        <SectionHead
          eyebrow={t("reputation.eyebrow")}
          title={t("reputation.title")}
          body={t("reputation.body")}
        />
        <div className="mx-auto mt-8 grid max-w-3xl gap-3 sm:grid-cols-2">
          <RatingCard
            good
            name={t("reputation.good.name")}
            caption={t("reputation.good.caption")}
            score="9,2"
            marks="🌸🌸🌸🐝🐝"
          />
          <RatingCard
            name={t("reputation.bad.name")}
            caption={t("reputation.bad.caption")}
            score="3,1"
            marks="🦟🦟🦟"
          />
        </div>
        <p className="text-muted-foreground mt-4 text-center text-xs">
          {t("reputation.footnote")}
        </p>
        {moreLabel ? (
          <div className="mt-6 text-center">
            <Link
              href={moreHref}
              className="text-primary text-sm font-semibold hover:underline"
            >
              {moreLabel} →
            </Link>
          </div>
        ) : null}
      </Container>
    </section>
  );
}
