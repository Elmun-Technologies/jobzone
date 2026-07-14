// Deno tests for the Rahmat callback signature. Run with:
//   deno test supabase/functions/rahmat-merchant/sign_test.ts
//
// The expected hex values below are the deterministic sha1/md5 of the concat
// strings named in `sign.ts`; a regression that changes either the concat
// order or the algorithm choice will flip a value and fail the test.

import { assertEquals } from "jsr:@std/assert";
import { md5Hex, rahmatSign, sha1Hex } from "./sign.ts";

Deno.test("rahmatSign: 'webhooks' scheme = sha1(uuid + invoice_id + amount + secret)", async () => {
  const got = await rahmatSign({
    scheme: "webhooks",
    uuid: "u-1",
    invoiceId: "ord-1",
    amount: "7990000",
    secret: "s3cr3t",
    storeId: "6",
  });
  const expected = await sha1Hex("u-1ord-17990000s3cr3t");
  assertEquals(got, expected);
});

Deno.test("rahmatSign: 'success' scheme = md5(store_id + invoice_id + amount + secret)", async () => {
  const got = await rahmatSign({
    scheme: "success",
    uuid: "u-1",
    invoiceId: "ord-1",
    amount: "7990000",
    secret: "s3cr3t",
    storeId: "6",
  });
  const expected = await md5Hex("6ord-17990000s3cr3t");
  assertEquals(got, expected);
});

Deno.test("md5Hex: known vector", async () => {
  // Standard MD5 test vector — 'abc' → 900150983cd24fb0d6963f7d28e17f72.
  assertEquals(await md5Hex("abc"), "900150983cd24fb0d6963f7d28e17f72");
});

Deno.test("sha1Hex: known vector", async () => {
  // Standard SHA-1 test vector — 'abc' → a9993e364706816aba3e25717850c26c9cd0d89d.
  assertEquals(await sha1Hex("abc"), "a9993e364706816aba3e25717850c26c9cd0d89d");
});
