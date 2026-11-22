// Checks the parts of site/usb/adb.js that a phone without "Allow USB debugging?" never exercises, against
// independent implementations:
//   - signToken: OpenSSL (Node's publicDecrypt) recovers SHA-1 DigestInfo || token from the signature, which is
//     what adbd's RSA_verify(NID_sha1, token, ...) checks;
//   - publicKeyString: the same key through AOSP's own encoder, `adb pubkey <private key file>`;
//   - message headers: field order, checksum and magic.
// Usage: node site/usb/test/adb_unit.mjs [path to adb]   (the adb check is skipped when adb is not found)
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { generateKey, signToken, publicKeyString, encodeHeader, decodeHeader, CMD } from "../adb.js";

let failed = 0;
const ok = (cond, what) => { console.log((cond ? "ok   " : "FAIL ") + what); if (!cond) failed++; };

const jwk = await generateKey();
const pub = crypto.createPublicKey({ key: { kty: "RSA", n: jwk.n, e: jwk.e }, format: "jwk" });
const prefix = Buffer.from("3021300906052b0e03021a05000414", "hex");
for (let i = 0; i < 5; i++) {
  const token = crypto.randomBytes(20);
  const sig = signToken(jwk, token);
  const t = crypto.publicDecrypt({ key: pub, padding: crypto.constants.RSA_PKCS1_PADDING }, sig);
  ok(sig.length === 256 && t.equals(Buffer.concat([prefix, token])), `signature ${i + 1}: DigestInfo(SHA-1) || token`);
}

const ours = publicKeyString(jwk, "waaiya@test");
ok(ours.endsWith(" waaiya@test") && Buffer.from(ours.split(" ")[0], "base64").length === 524, "public key: 524 bytes + name");
const adb = process.argv[2] || [path.join(os.homedir(), "Android/Sdk/platform-tools/adb"), "/usr/bin/adb"].find((p) => fs.existsSync(p));
if (adb) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "waaiya-adbkey-"));
  const file = path.join(dir, "adbkey");
  fs.writeFileSync(file, crypto.createPrivateKey({ key: jwk, format: "jwk" }).export({ type: "pkcs8", format: "pem" }));
  const theirs = execFileSync(adb, ["pubkey", file], { encoding: "utf8" }).trim();
  fs.rmSync(dir, { recursive: true });
  ok(theirs.split(" ")[0] === ours.split(" ")[0], "public key: same bytes as `adb pubkey`");
} else console.log("skip public key against `adb pubkey` (no adb)");

const data = new TextEncoder().encode("host::\0");
const h = encodeHeader(CMD.CNXN, 0x01000001, 262144, data);
const m = decodeHeader(h);
const v = new DataView(h.buffer);
ok(m.cmd === CMD.CNXN && m.arg0 === 0x01000001 && m.arg1 === 262144 && m.length === data.length &&
   v.getUint32(16, true) === data.reduce((a, b) => a + b, 0) && v.getUint32(20, true) === (CMD.CNXN ^ 0xffffffff) >>> 0,
   "header: fields, byte sum, magic");
let threw = false;
try { h[20] ^= 1; decodeHeader(h); } catch (_) { threw = true; }
ok(threw, "header: a wrong magic is refused");

// A fake phone with "Allow USB debugging?" (adbd's auth): a token; a signature from a known key is accepted, else a
// new token; a public key is "allowed" (and remembered) as when its owner taps Allow with "Always allow".
class FakePhone {
  constructor(known) { this.known = known; this.out = []; this.inbuf = new Uint8Array(0); this.prompts = 0; }
  push(cmd, a0, a1, d = new Uint8Array(0)) { this.out.push(encodeHeader(cmd, a0, a1, d)); if (d.length) this.out.push(d); }
  token() { this.tok = crypto.randomBytes(20); this.push(CMD.AUTH, 1, 0, this.tok); }
  async read(n) {
    const b = this.out.shift();
    if (!b || b.length !== n) throw new Error("unexpected read of " + n);
    return b;
  }
  async write(d) {
    if (!this.hdr) { this.hdr = decodeHeader(d); if (this.hdr.length) return; d = new Uint8Array(0); }
    const m = this.hdr; this.hdr = null;
    if (m.cmd === CMD.CNXN) return this.token();
    if (m.cmd !== CMD.AUTH) throw new Error("unexpected command");
    if (m.arg0 === 2) {
      const good = this.known.some((k) => {
        try { return crypto.publicDecrypt({ key: k, padding: crypto.constants.RSA_PKCS1_PADDING }, d)
          .equals(Buffer.concat([prefix, this.tok])); } catch (_) { return false; }
      });
      return good ? this.push(CMD.CNXN, 0x01000001, 4096, new TextEncoder().encode("device::fake\0")) : this.token();
    }
    if (m.arg0 === 3) {
      const b64 = new TextDecoder().decode(d).split(" ")[0];
      this.prompts++;
      this.known.push(pubFromAdb(Buffer.from(b64, "base64")));
      return this.push(CMD.CNXN, 0x01000001, 4096, new TextEncoder().encode("device::fake\0"));
    }
  }
}
// adb's 524-byte key back to a Node key (little-endian modulus at 8, exponent at 520)
const pubFromAdb = (b) => crypto.createPublicKey({ format: "jwk", key: { kty: "RSA",
  n: Buffer.from(b.subarray(8, 264)).reverse().toString("base64url"),
  e: Buffer.from([1, 0, 1]).toString("base64url") } });   // 65537
const { Adb } = await import("../adb.js");
const phone = new FakePhone([]);
let prompted = 0;
await new Adb(phone).connect(jwk, { onPrompt: () => prompted++ });
ok(prompted === 1 && phone.prompts === 1, "auth: a new key is sent once and the prompt is reported");
prompted = 0;
await new Adb(phone).connect(jwk, { onPrompt: () => prompted++ });
ok(prompted === 0 && phone.prompts === 1, "auth: an allowed key gets in with its signature, no prompt");

console.log(failed ? `${failed} failed` : "all passed");
process.exit(failed ? 1 : 0);
