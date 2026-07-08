/**
 * Renders a schema.org JSON-LD block. Server-rendered into the page HTML.
 *
 * The payload carries raw employer text (job title/description, company name),
 * so `<`/`>`/`&` are escaped to their \uXXXX forms — JSON.stringify alone does
 * not, which would let `</script><script>…` break out of the tag (stored XSS).
 */
export function JsonLd({ data }: { data: Record<string, unknown> }) {
  const json = JSON.stringify(data)
    .replace(/</g, "\\u003c")
    .replace(/>/g, "\\u003e")
    .replace(/&/g, "\\u0026");
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: json }}
    />
  );
}
