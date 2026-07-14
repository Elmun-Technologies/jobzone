// Rahmat (Multicard) callback-signature helpers, extracted for unit testing.
// The edge-function entry point (`./index.ts`) delegates the actual hex here.
// Kept side-effect-free so a Deno test can import + exercise both schemes.
//
// Schemes (per Multicard's Mesh docs):
//   'webhooks': sha1(uuid + invoice_id + amount + secret)
//   'success' : md5(store_id + invoice_id + amount + secret)
// The secret is the RAHMAT_SECRET set in the merchant cabinet.

import { crypto } from "jsr:@std/crypto";

export type CallbackScheme = "webhooks" | "success";

export interface RahmatSignInput {
  scheme: CallbackScheme;
  uuid: string;
  invoiceId: string;
  amount: string;
  secret: string;
  storeId: string;
}

/** Computes the lowercase hex signature for a Rahmat callback payload. */
export async function rahmatSign(i: RahmatSignInput): Promise<string> {
  if (i.scheme === "success") {
    return await md5Hex(`${i.storeId}${i.invoiceId}${i.amount}${i.secret}`);
  }
  return await sha1Hex(`${i.uuid}${i.invoiceId}${i.amount}${i.secret}`);
}

export async function md5Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("MD5", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function sha1Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-1", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
