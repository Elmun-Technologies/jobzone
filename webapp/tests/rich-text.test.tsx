import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { RichText } from "@/components/jobs/rich-text";

describe("RichText markdown rendering", () => {
  it("renders **bold** as a <strong>, not literal asterisks", () => {
    const { container } = render(<RichText text="Salary is **negotiable**." />);
    const strong = container.querySelector("strong");
    expect(strong?.textContent).toBe("negotiable");
    expect(container.textContent).toBe("Salary is negotiable.");
    expect(container.textContent).not.toContain("*");
  });

  it("renders a `-` block as a bullet list", () => {
    const { container } = render(
      <RichText text={"- Drive safely\n- Be on time\n- Keep records"} />,
    );
    const items = container.querySelectorAll("ul > li");
    expect(items).toHaveLength(3);
    expect(items[0].textContent).toBe("Drive safely");
    expect(container.textContent).not.toContain("- ");
  });

  it("renders a `1.` block as an ordered list", () => {
    const { container } = render(
      <RichText text={"1. First\n2. Second"} />,
    );
    expect(container.querySelectorAll("ol > li")).toHaveLength(2);
  });

  it("renders `##` as a heading, not literal hashes", () => {
    const { container } = render(<RichText text="## Responsibilities" />);
    const h = container.querySelector("h3");
    expect(h?.textContent).toBe("Responsibilities");
    expect(container.textContent).not.toContain("#");
  });

  it("splits blank-line-separated text into separate paragraphs", () => {
    const { container } = render(
      <RichText text={"First paragraph.\n\nSecond paragraph."} />,
    );
    expect(container.querySelectorAll("p")).toHaveLength(2);
  });

  it("keeps plain prose (no markdown) intact", () => {
    render(<RichText text="Just a normal sentence with no markup." />);
    expect(
      screen.getByText("Just a normal sentence with no markup."),
    ).toBeDefined();
  });

  it("does not treat the Uzbek text as unsafe or drop content", () => {
    const { container } = render(
      <RichText text={"**Vazifalar:**\n- Tungi smenada ishlash"} />,
    );
    expect(container.textContent).toContain("Vazifalar:");
    expect(container.textContent).toContain("Tungi smenada ishlash");
  });
});
