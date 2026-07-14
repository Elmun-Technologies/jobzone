import { JsonLd } from "@/components/seo/json-ld";
import { faqPageJsonLd } from "@/lib/seo";

/**
 * Visible FAQ + FAQPage JSON-LD in one drop. Google's rich-results
 * policy requires the answer to be visible HTML on the page (no
 * cloaking), and LLMs pull the visible text more reliably than the
 * structured data alone, so both live in the same component.
 *
 * Details / summary is used deliberately: it keeps the accessible tree
 * clean, is keyboard-accessible out of the box, and Google's parser
 * finds text inside a closed `<details>` when the FAQPage schema
 * references it (verified via Rich Results Test).
 */
export function FaqSection({
  heading,
  items,
}: {
  heading: string;
  items: { question: string; answer: string }[];
}) {
  if (items.length === 0) return null;
  return (
    <section className="border-t border-border">
      <div className="mx-auto max-w-3xl px-4 py-14 sm:py-20">
        <h2 className="text-foreground text-2xl font-bold tracking-tight sm:text-3xl">
          {heading}
        </h2>
        <ul className="mt-6 divide-y divide-border">
          {items.map((it) => (
            <li key={it.question}>
              <details className="group py-4">
                <summary className="text-foreground flex cursor-pointer items-start justify-between gap-4 text-base font-semibold marker:content-[''] sm:text-lg">
                  <span>{it.question}</span>
                  <span
                    aria-hidden
                    className="text-muted-foreground mt-1 shrink-0 text-lg transition-transform group-open:rotate-45"
                  >
                    +
                  </span>
                </summary>
                <p className="text-muted-foreground mt-2 whitespace-pre-line text-base leading-relaxed">
                  {it.answer}
                </p>
              </details>
            </li>
          ))}
        </ul>
      </div>
      <JsonLd data={faqPageJsonLd(items)} />
    </section>
  );
}
