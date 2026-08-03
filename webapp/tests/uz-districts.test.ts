import { readFileSync } from "node:fs";
import { join } from "node:path";

import { describe, expect, it } from "vitest";

import {
  districtsFor,
  UZ_DISTRICTS,
  UZ_REGION_NAMES,
} from "@/lib/uz-districts";
import { UZ_REGIONS } from "@/lib/uz-regions";

describe("uz-districts", () => {
  it("covers all 14 regions", () => {
    expect(UZ_REGION_NAMES).toHaveLength(14);
    expect(UZ_REGION_NAMES).toContain("Toshkent shahri");
    expect(UZ_REGION_NAMES).toContain("Qoraqalpog'iston");
  });

  it("is the single source the admin region filter also uses", () => {
    expect(UZ_REGIONS).toEqual(UZ_REGION_NAMES);
  });

  it("returns a region's districts, and nothing for an unknown one", () => {
    expect(districtsFor("Toshkent shahri")).toContain("Sergeli");
    expect(districtsFor("Toshkent shahri")).toContain("Chilonzor");
    expect(districtsFor("Atlantis")).toEqual([]);
    expect(districtsFor("")).toEqual([]);
    expect(districtsFor(null)).toEqual([]);
  });

  it("has no empty region and no duplicate district inside one", () => {
    for (const [region, districts] of Object.entries(UZ_DISTRICTS)) {
      expect(districts.length, region).toBeGreaterThan(0);
      expect(new Set(districts).size, region).toBe(districts.length);
    }
  });

  // The mobile employer form writes jobs.region/district from the Dart map;
  // the résumé's desired location is compared against those values with plain
  // string equality, so a name that exists on one side only is a silent
  // matching hole — exactly what this port was meant to close.
  it("matches the Dart map the mobile employer form writes from", () => {
    // vitest runs with the webapp as cwd; the Flutter app is its sibling.
    const dart = readFileSync(
      join(process.cwd(), "..", "lib/core/utils/uzbekistan_regions.dart"),
      "utf8",
    );
    const names = new Set(
      [...dart.matchAll(/'((?:[^'\\]|\\')*)'/g)].map((m) =>
        m[1].replace(/\\'/g, "'"),
      ),
    );
    for (const [region, districts] of Object.entries(UZ_DISTRICTS)) {
      expect(names.has(region), `region ${region}`).toBe(true);
      for (const d of districts) {
        expect(names.has(d), `${region} / ${d}`).toBe(true);
      }
    }
  });
});
