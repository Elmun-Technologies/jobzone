import type { Metadata } from "next";
import { setRequestLocale } from "next-intl/server";

import { Container } from "@/components/ui/container";
import { formatDate } from "@/lib/format";
import { getPrivacyPolicy } from "@/lib/legal";
import { localeAlternates } from "@/lib/seo";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const doc = getPrivacyPolicy(locale);
  return {
    title: doc.title,
    description: doc.intro,
    alternates: localeAlternates(locale, "privacy"),
    // Legal pages are useful for humans + LLM indexing (Google policy /
    // Play Data Safety pointers) — keep them indexable.
    robots: { index: true, follow: true },
  };
}

export default async function PrivacyPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  setRequestLocale(locale);
  const doc = getPrivacyPolicy(locale);
  return (
    <Container className="max-w-3xl py-12">
      <h1 className="text-foreground text-3xl font-bold sm:text-4xl">
        {doc.title}
      </h1>
      <p className="text-muted-foreground mt-2 text-sm">
        {formatDate(doc.effectiveDate)}
      </p>
      <p className="text-foreground mt-6 text-base leading-relaxed">
        {doc.intro}
      </p>
      <div className="mt-8 space-y-8">
        {doc.sections.map((s) => (
          <section key={s.id} id={s.id}>
            <h2 className="text-foreground text-lg font-semibold">{s.title}</h2>
            <div className="mt-3 space-y-3">
              {s.paragraphs.map((p, i) => (
                <p
                  key={i}
                  className="text-muted-foreground text-sm leading-relaxed"
                >
                  {p}
                </p>
              ))}
            </div>
          </section>
        ))}
      </div>
      <section className="border-border mt-12 border-t pt-8">
        <p className="text-muted-foreground text-sm">{doc.contactLead}</p>
        <p className="text-primary mt-2 text-sm font-semibold">
          <a href={`mailto:${doc.contactEmail}`}>{doc.contactEmail}</a>
        </p>
      </section>
    </Container>
  );
}
