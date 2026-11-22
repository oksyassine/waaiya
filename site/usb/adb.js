// Waaiya: a small ADB client for the "set up from a computer" page (waaiya.mssid.org/usb/).
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Just enough of the ADB protocol (AOSP packages/modules/adb, protocol.txt) to run a few shell commands:
// CNXN, AUTH (RSA signature, or the public key so that the phone asks "Allow USB debugging?"), OPEN/WRTE/OKAY/CLSE.
// The transport is anything with read(n) -> Uint8Array and write(Uint8Array): WebUSB on the page (usb.js), a TCP
// socket in the tests (test/adb_e2e.mjs). Runs unchanged in browsers and in Node 22 (Web Crypto, BigInt).
//
// The key: RSA-2048 made with Web Crypto, kept by the caller (the page keeps it in localStorage). ADB signs the
// phone's 20-byte token as if it were a SHA-1 digest (PKCS#1 v1.5 without hashing), which Web Crypto cannot do, so
// the signature is computed here with BigInt from the exported private key.

export const CMD = {
  CNXN: 0x4e584e43, AUTH: 0x48545541, OPEN: 0x4e45504f, OKAY: 0x59414b4f,
  CLSE: 0x45534c43, WRTE: 0x45545257, STLS: 0x534c5453,
};
const NAME = Object.fromEntries(Object.entries(CMD).map(([k, v]) => [v, k]));
const VERSION = 0x01000001;            // checksums optional (adbd skips them from this version on)
const MAX_DATA = 256 * 1024;
const AUTH_TOKEN = 1, AUTH_SIGNATURE = 2, AUTH_RSAPUBLICKEY = 3;
const enc = new TextEncoder(), dec = new TextDecoder();

// ---- messages --------------------------------------------------------------------------------------------------

export function encodeHeader(cmd, arg0, arg1, data) {
  const h = new DataView(new ArrayBuffer(24));
  let sum = 0;
  for (const b of data) sum = (sum + b) >>> 0;
  h.setUint32(0, cmd, true); h.setUint32(4, arg0 >>> 0, true); h.setUint32(8, arg1 >>> 0, true);
  h.setUint32(12, data.length, true); h.setUint32(16, sum, true); h.setUint32(20, (cmd ^ 0xffffffff) >>> 0, true);
  return new Uint8Array(h.buffer);
}

export function decodeHeader(b) {
  if (b.length !== 24) throw new AdbError("short header (" + b.length + " bytes)");
  const v = new DataView(b.buffer, b.byteOffset, 24);
  const m = { cmd: v.getUint32(0, true), arg0: v.getUint32(4, true), arg1: v.getUint32(8, true),
              length: v.getUint32(12, true) };
  if (((m.cmd ^ 0xffffffff) >>> 0) !== v.getUint32(20, true)) throw new AdbError("bad message magic");
  return m;
}

export class AdbError extends Error {}

// ---- RSA, in ADB's formats -------------------------------------------------------------------------------------

const b64urlToBig = (s) => {
  const bin = atob(s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4));
  let x = 0n;
  for (let i = 0; i < bin.length; i++) x = (x << 8n) | BigInt(bin.charCodeAt(i));
  return x;
};

function modPow(b, e, m) {
  let r = 1n;
  b %= m;
  while (e > 0n) {
    if (e & 1n) r = (r * b) % m;
    b = (b * b) % m;
    e >>= 1n;
  }
  return r;
}

function modInv(a, m) {
  let [r0, r1, s0, s1] = [a % m, m, 1n, 0n];
  while (r1 !== 0n) { const q = r0 / r1; [r0, r1] = [r1, r0 - q * r1]; [s0, s1] = [s1, s0 - q * s1]; }
  return ((s0 % m) + m) % m;
}

const bigToBytes = (x, n, littleEndian = false) => {
  const out = new Uint8Array(n);
  for (let i = 0; i < n; i++) { out[littleEndian ? i : n - 1 - i] = Number(x & 0xffn); x >>= 8n; }
  return out;
};

/** A new key as a JSON Web Key (keep it: the phone remembers it after "Always allow from this computer"). */
export async function generateKey() {
  const k = await crypto.subtle.generateKey({ name: "RSASSA-PKCS1-v1_5", modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-1" }, true, ["sign", "verify"]);
  const jwk = await crypto.subtle.exportKey("jwk", k.privateKey);
  return { kty: jwk.kty, n: jwk.n, e: jwk.e, d: jwk.d, p: jwk.p, q: jwk.q, dp: jwk.dp, dq: jwk.dq, qi: jwk.qi };
}

// DigestInfo for SHA-1 (RFC 8017 9.2): ADB's token takes the place of the hash.
const SHA1_PREFIX = [0x30, 0x21, 0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04, 0x14];

/** RSASSA-PKCS1-v1_5 over a 20-byte token as a SHA-1 digest, as adbd's RSA_verify(NID_sha1, ...) expects. */
export function signToken(jwk, token) {
  if (token.length !== 20) throw new AdbError("token of " + token.length + " bytes");
  const em = new Uint8Array(256);
  em[0] = 0; em[1] = 1;
  const t = [...SHA1_PREFIX, ...token];
  em.fill(0xff, 2, 256 - t.length - 1);
  em[256 - t.length - 1] = 0;
  em.set(t, 256 - t.length);
  let c = 0n;
  for (const b of em) c = (c << 8n) | BigInt(b);
  const [p, q, dp, dq, qi] = [jwk.p, jwk.q, jwk.dp, jwk.dq, jwk.qi].map(b64urlToBig);
  const m1 = modPow(c, dp, p), m2 = modPow(c, dq, q);       // CRT: about four times faster than c^d mod n
  const h = (qi * (((m1 - m2) % p) + p)) % p;
  return bigToBytes(m2 + h * q, 256);
}

/** The public key as adbd stores it (android_pubkey_encode, base64) followed by " <name>". */
export function publicKeyString(jwk, name) {
  const n = b64urlToBig(jwk.n), e = b64urlToBig(jwk.e);
  const b = new Uint8Array(524), v = new DataView(b.buffer);
  const R32 = 1n << 32n;
  v.setUint32(0, 64, true);                                          // modulus size in 32-bit words
  v.setUint32(4, Number((R32 - modInv(n % R32, R32)) % R32), true);   // n0inv = -1/n[0] mod 2^32
  b.set(bigToBytes(n, 256, true), 8);                                // modulus, little endian
  b.set(bigToBytes((1n << 4096n) % n, 256, true), 264);              // R^2 mod n, R = 2^2048
  v.setUint32(520, Number(e), true);
  let s = "";
  for (const x of b) s += String.fromCharCode(x);
  return btoa(s) + " " + name;
}

// ---- the connection --------------------------------------------------------------------------------------------

export class Adb {
  /** @param transport {read(n): Promise<Uint8Array>, write(Uint8Array): Promise<void>} */
  constructor(transport, { log = () => {} } = {}) {
    this.t = transport;
    this.log = log;
    this.nextId = 1;
    this.banner = "";
    this.maxData = 4096;
  }

  async send(cmd, arg0, arg1, data = new Uint8Array(0)) {
    if (typeof data === "string") data = enc.encode(data);
    await this.t.write(encodeHeader(cmd, arg0, arg1, data));
    if (data.length) await this.t.write(data);
  }

  async recv() {
    const m = decodeHeader(await this.t.read(24));
    m.data = m.length ? await this.t.read(m.length) : new Uint8Array(0);
    if (m.data.length !== m.length) throw new AdbError("short message");
    return m;
  }

  /**
   * CNXN and AUTH. [onPrompt] is called when the phone must show "Allow USB debugging?" (the key is new to it, or it
   * forgot it); the promise then waits until someone answers on the phone.
   */
  async connect(jwk, { name = "waaiya@browser", onPrompt = () => {} } = {}) {
    await this.send(CMD.CNXN, VERSION, MAX_DATA, "host::\0");
    let signed = false;
    for (;;) {
      const m = await this.recv();
      if (m.cmd === CMD.CNXN) {
        this.maxData = Math.min(m.arg1 || 4096, MAX_DATA);
        this.banner = dec.decode(m.data).replace(/\0+$/, "");
        this.log("connected: " + this.banner);
        return this.banner;
      }
      if (m.cmd === CMD.AUTH && m.arg0 === AUTH_TOKEN) {
        if (!signed) {
          signed = true;
          await this.send(CMD.AUTH, AUTH_SIGNATURE, 0, signToken(jwk, m.data));
        } else {
          // the phone does not know this key: send it, and the phone asks its owner
          await this.send(CMD.AUTH, AUTH_RSAPUBLICKEY, 0, publicKeyString(jwk, name) + "\0");
          onPrompt();
        }
        continue;
      }
      if (m.cmd === CMD.STLS) throw new AdbError("the phone asks for TLS (wireless debugging), not supported here");
      this.log("ignored " + (NAME[m.cmd] || m.cmd.toString(16)) + " before the connection");
    }
  }

  /** Runs one shell command (the legacy "shell:" service: stdout and stderr together) and returns its output. */
  async shell(command) {
    const local = this.nextId++;
    await this.send(CMD.OPEN, local, 0, "shell:" + command + "\0");
    let remote = 0, out = "";
    const d = new TextDecoder();
    for (;;) {
      const m = await this.recv();
      if (m.arg1 !== local) { this.log("message for another stream ignored"); continue; }
      if (m.cmd === CMD.OKAY) { remote = m.arg0; continue; }
      if (m.cmd === CMD.WRTE) {
        out += d.decode(m.data, { stream: true });
        await this.send(CMD.OKAY, local, m.arg0);
        continue;
      }
      if (m.cmd === CMD.CLSE) {
        if (remote) await this.send(CMD.CLSE, local, remote);
        else if (!out) throw new AdbError("the phone refused to open a shell");
        return (out + d.decode()).replace(/\r\n/g, "\n");
      }
    }
  }
}
