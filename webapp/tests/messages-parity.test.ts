import { describe, expect, it } from "vitest";

import en from "../messages/en.json";
import ru from "../messages/ru.json";
import uz from "../messages/uz.json";

type Tree = { [key: string]: string | string[] | Tree };

/** Flattens a message catalog to a sorted list of dotted key paths. */
function keyPaths(obj: Tree, prefix = ""): string[] {
  return Object.entries(obj)
    .flatMap(([key, value]) => {
      const path = prefix ? `${prefix}.${key}` : key;
      if (Array.isArray(value)) return [path];
      return typeof value === "object" ? keyPaths(value, path) : [path];
    })
    .sort();
}

describe("message catalog parity", () => {
  const base = keyPaths(en as Tree);

  it("has a non-empty base catalog (en)", () => {
    expect(base.length).toBeGreaterThan(0);
  });

  it("ru defines exactly the same keys as en", () => {
    expect(keyPaths(ru as Tree)).toEqual(base);
  });

  it("uz defines exactly the same keys as en", () => {
    expect(keyPaths(uz as Tree)).toEqual(base);
  });
});
