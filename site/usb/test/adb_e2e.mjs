// End-to-end check of site/usb/adb.js and flow.js against a real adbd: an emulator's adb port over TCP carries the
// same messages as USB. Usage (the adb server must not hold the emulator, so it is stopped first):
//
//   adb kill-server
//   node site/usb/test/adb_e2e.mjs 127.0.0.1:5581 [--setup] [--key FILE]
//
// Without --setup it connects and runs `id`; with --setup it runs the page's whole setup (runSetup) and prints the
// result (--helper: also starts Waaiya's helper, as on a phone that refused the grants). --key keeps the RSA key in FILE between runs (as the page keeps it in localStorage), so a run after
// "Always allow" on the phone shows the signature path.
import net from "node:net";
import fs from "node:fs";
import { Adb, generateKey } from "../adb.js";
import { runSetup } from "../flow.js";

const args = process.argv.slice(2);
const [host, port] = (args.find((a) => !a.startsWith("--") && a.includes(":")) || "127.0.0.1:5581").split(":");
const keyFile = args.includes("--key") ? args[args.indexOf("--key") + 1] : null;

class TcpTransport {
  constructor(sock) {
    this.sock = sock; this.buf = Buffer.alloc(0); this.waiters = []; this.closed = false;
    sock.on("data", (d) => { this.buf = Buffer.concat([this.buf, d]); this.wake(); });
    sock.on("close", () => { this.closed = true; this.wake(); });
  }
  wake() { const w = this.waiters; this.waiters = []; w.forEach((f) => f()); }
  async read(n) {
    while (this.buf.length < n) {
      if (this.closed) throw new Error("connection closed by adbd");
      await new Promise((r) => this.waiters.push(r));
    }
    const out = new Uint8Array(this.buf.subarray(0, n)); this.buf = this.buf.subarray(n); return out;
  }
  async write(d) { await new Promise((r, j) => this.sock.write(d, (e) => (e ? j(e) : r()))); }
}

const sock = net.connect(+port, host);
await new Promise((r, j) => { sock.once("connect", r); sock.once("error", j); });
let key;
if (keyFile && fs.existsSync(keyFile)) key = JSON.parse(fs.readFileSync(keyFile, "utf8"));
else { key = await generateKey(); if (keyFile) fs.writeFileSync(keyFile, JSON.stringify(key)); }

const adb = new Adb(new TcpTransport(sock), { log: (s) => console.error("[adb] " + s) });
const t0 = Date.now();
await adb.connect(key, { name: "waaiya@e2e", onPrompt: () => console.log("PROMPT: the phone asks to allow this key") });
console.log("CONNECTED in " + (Date.now() - t0) + " ms: " + adb.banner.slice(0, 60));
if (args.includes("--setup")) {
  const r = await runSetup(adb, (s) => console.log("STEP " + s), { forceHelper: args.includes("--helper") });
  console.log("RESULT " + JSON.stringify({ status: r.status, phone: r.phone, projectMedia: r.projectMedia,
                                           secureSettings: r.secureSettings }));
  if (args.includes("--log")) console.log(r.log.join("\n"));
} else {
  console.log("ID " + (await adb.shell("id")).trim());
}
sock.destroy();
