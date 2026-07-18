import { Fragment, type ReactNode } from "react";

/**
 * Minimal, dependency-free markdown renderer for job-post prose
 * (description / responsibilities / requirements / benefits). Employers may
 * write markdown and the AI assist can too; the mobile app renders it with
 * `MarkdownBody`, so without this the web showed raw `##`, `**`, and `-`
 * symbols instead of formatted text.
 *
 * Supported subset — deliberately small and predictable:
 *   - blank-line-separated paragraphs (single newlines become <br>)
 *   - `#`/`##`/`###` headings
 *   - `-`, `*`, or `•` bullet lists
 *   - `1.` numbered lists
 *   - `**bold**` inline
 *
 * XSS-safe by construction: every value is rendered as a React text node
 * (React escapes it) — never `dangerouslySetInnerHTML`. Anything that isn't
 * one of the patterns above is shown verbatim as plain text.
 */

const BOLD = /(\*\*[^*\n]+\*\*)/g;

function inline(text: string): ReactNode[] {
  return text.split(BOLD).map((part, i) =>
    /^\*\*[^*\n]+\*\*$/.test(part) ? (
      <strong key={i} className="text-foreground font-semibold">
        {part.slice(2, -2)}
      </strong>
    ) : (
      <Fragment key={i}>{part}</Fragment>
    ),
  );
}

function paragraph(block: string, key: number): ReactNode {
  const lines = block.split("\n");
  return (
    <p
      key={key}
      className="text-muted-foreground text-sm leading-relaxed"
    >
      {lines.map((line, i) => (
        <Fragment key={i}>
          {i > 0 ? <br /> : null}
          {inline(line)}
        </Fragment>
      ))}
    </p>
  );
}

export function RichText({ text }: { text: string }) {
  // Normalize CRLF, then split into blocks on blank lines.
  const blocks = text.replace(/\r\n/g, "\n").split(/\n{2,}/);

  return (
    <div className="space-y-3">
      {blocks.map((raw, bi) => {
        const block = raw.trim();
        if (!block) return null;
        const lines = block.split("\n");

        // Heading (single line starting with 1–3 #).
        const heading = lines.length === 1 && block.match(/^(#{1,3})\s+(.*)$/);
        if (heading) {
          return (
            <h3
              key={bi}
              className="text-foreground pt-1 text-base font-semibold"
            >
              {inline(heading[2])}
            </h3>
          );
        }

        // Bullet list — every line is a bullet.
        if (lines.every((l) => /^\s*[-*•]\s+/.test(l))) {
          return (
            <ul
              key={bi}
              className="text-muted-foreground list-disc space-y-1 pl-5 text-sm leading-relaxed"
            >
              {lines.map((l, i) => (
                <li key={i}>{inline(l.replace(/^\s*[-*•]\s+/, ""))}</li>
              ))}
            </ul>
          );
        }

        // Numbered list — every line is `N.` / `N)`.
        if (lines.every((l) => /^\s*\d+[.)]\s+/.test(l))) {
          return (
            <ol
              key={bi}
              className="text-muted-foreground list-decimal space-y-1 pl-5 text-sm leading-relaxed"
            >
              {lines.map((l, i) => (
                <li key={i}>{inline(l.replace(/^\s*\d+[.)]\s+/, ""))}</li>
              ))}
            </ol>
          );
        }

        return paragraph(block, bi);
      })}
    </div>
  );
}
