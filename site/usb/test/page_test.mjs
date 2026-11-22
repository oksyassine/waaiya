// Runs the built /usb/ page (site/public, from build.py) in headless Chromium with a simulated USB phone in place of
// navigator.usb, once per scenario, and checks what the page says. The simulated phone speaks ADB over the same
// WebUSB calls (transferOut/transferIn), so usb.js, adb.js, flow.js and setup.js all run as in a real browser.
//
//   python3 site/build.py --preview && node site/usb/test/page_test.mjs [chromium binary]
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { generateKey } from "../adb.js";

const PUB = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../../public");
const chrome = process.argv[2] || ["/usr/bin/chromium-browser", "/usr/bin/chromium", "/usr/bin/google-chrome"].find(fs.existsSync);

// The simulated phone, injected before the page's module script. ?s=<scenario> picks its answers.
// Key generation runs outside the headless clock (--virtual-time-budget), so the page gets a key made here, as a
// returning visitor has one in localStorage. The prompt case still treats it as new: the simulated phone refuses it once.
const KEY = JSON.stringify(await generateKey());
const MOCK = String.raw`
(() => {
  const s = new URLSearchParams(location.search).get("s");
  localStorage.setItem("waaiya.adbkey", JSON.stringify(__KEY__));
  if (s === "unsupported") { Object.defineProperty(navigator, "usb", { value: undefined }); return; }
  const enc = new TextEncoder(), dec = new TextDecoder();
  const C = { CNXN: 0x4e584e43, AUTH: 0x48545541, OPEN: 0x4e45504f, OKAY: 0x59414b4f, CLSE: 0x45534c43, WRTE: 0x45545257 };
  const q = [], waiting = [];
  const out = (b) => { const w = waiting.shift(); w ? w(b) : q.push(b); };
  const msg = (cmd, a0, a1, d = new Uint8Array(0)) => {
    const h = new DataView(new ArrayBuffer(24));
    h.setUint32(0, cmd, true); h.setUint32(4, a0, true); h.setUint32(8, a1, true); h.setUint32(12, d.length, true);
    h.setUint32(20, (cmd ^ 0xffffffff) >>> 0, true);
    out(new Uint8Array(h.buffer)); if (d.length) out(d);
  };
  const refuse = s === "helper" || s === "refused10";
  const answer = (c) => {
    if (c.startsWith("getprop")) return s === "helper" ? "34\n14\nXiaomi\nRedmi Note 13\n" : s === "refused10" ? "29\n10\nXiaomi\nRedmi 9\n" : "35\n15\nGoogle\nPixel 8\n";
    if (c.startsWith("pm path")) return s === "noapp" ? "" : "package:/data/app/x/base.apk\n";
    if (c.startsWith("cmd package grant")) return refuse ? "Exception occurred while executing 'grant':\njava.lang.SecurityException: grantRuntimePermission: Neither user 2000 nor current process has android.permission.GRANT_RUNTIME_PERMISSIONS.\ndump=255\nproject_media=0\nsecure_settings=255\n" : "dump=0\nproject_media=0\nsecure_settings=0\n";
    if (c.startsWith("D=$(dumpsys")) return refuse ? "project_media=allow\n" : s === "vivo" ? "dump=granted\nsecure_settings=granted\n" : "dump=granted\nsecure_settings=granted\nproject_media=allow\n";
    if (c.startsWith("dumpsys package")) return "  userId=10177\n    versionCode=17 minSdk=29 targetSdk=35\n";
    if (c.startsWith("for p in")) return "helper=started\n";
    return "";
  };
  let hdr = null, sigs = 0;
  window.__shell = [];
  const phone = (m, d) => {
    if (m.cmd === C.CNXN) return msg(C.AUTH, 1, 0, new Uint8Array(20).fill(7));
    if (m.cmd === C.AUTH && m.a0 === 2) return (s === "prompt" && ++sigs === 1) ? msg(C.AUTH, 1, 0, new Uint8Array(20).fill(8))
                                               : msg(C.CNXN, 0x01000001, 4096, enc.encode("device::ro.product.model=Pixel 8\0"));
    if (m.cmd === C.AUTH && m.a0 === 3) { window.__prompted = dec.decode(d).split(" ")[1]; return setTimeout(() => msg(C.CNXN, 0x01000001, 4096, enc.encode("device::x\0")), 300); }
    if (m.cmd === C.OPEN) {
      const c = dec.decode(d).replace(/^shell:/, "").replace(/\0$/, "");
      window.__shell.push(c);
      let pre = document.getElementById("mock-shell");
      if (!pre) { pre = document.createElement("pre"); pre.id = "mock-shell"; pre.hidden = true; document.body.append(pre); }
      pre.textContent += c.replace(/\n/g, " ") + "\n";
      msg(C.OKAY, 100 + m.a0, m.a0);
      const o = answer(c); if (o) msg(C.WRTE, 100 + m.a0, m.a0, enc.encode(o));
      return msg(C.CLSE, 100 + m.a0, m.a0);
    }
  };
  const intf = { interfaceNumber: 0, alternates: [{ alternateSetting: 0, interfaceClass: 0xff, interfaceSubclass: 0x42, interfaceProtocol: 1,
    endpoints: [{ endpointNumber: 1, direction: "in", type: "bulk", packetSize: 512 }, { endpointNumber: 2, direction: "out", type: "bulk", packetSize: 512 }] }] };
  const device = { configurations: [{ configurationValue: 1, interfaces: [intf] }], configuration: null,
    async open() {}, async selectConfiguration() { this.configuration = this.configurations[0]; }, async claimInterface() {},
    async releaseInterface() {}, async close() {}, async clearHalt() {},
    async transferOut(ep, data) {
      const b = new Uint8Array(data.buffer ? data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) : data);
      if (!hdr) {
        const v = new DataView(b.buffer);
        hdr = { cmd: v.getUint32(0, true), a0: v.getUint32(4, true), a1: v.getUint32(8, true), len: v.getUint32(12, true) };
        if (hdr.len) return { status: "ok", bytesWritten: b.length };
        const m = hdr; hdr = null; phone(m, new Uint8Array(0)); return { status: "ok", bytesWritten: b.length };
      }
      const m = hdr; hdr = null; phone(m, b); return { status: "ok", bytesWritten: b.length };
    },
    async transferIn(ep, len) {
      const b = q.length ? q.shift() : await new Promise((r) => waiting.push(r));
      if (b.length > len) throw new Error("babble: " + b.length + " > " + len);
      return { status: "ok", data: new DataView(b.buffer, b.byteOffset, b.length) };
    } };
  Object.defineProperty(navigator, "usb", { value: {
    async getDevices() { return []; },
    async requestDevice() { if (s === "none") throw new DOMException("No device selected.", "NotFoundError"); return device; } } });
  addEventListener("load", () => { const b = document.getElementById("usb-connect"); if (!b.disabled) b.click(); });
})();`;

const CASES = [
  ["done", "en", /Done: Waaiya has its permissions on Pixel 8\./, (sh) => sh.length === 4],
  ["prompt", "en", /Done: Waaiya has its permissions/, null],
  ["vivo", "en", /Android will ask at every start/, null],
  ["helper", "en", /Redmi Note 13 refused the permissions, so Waaiya's helper[\s\S]*USB debugging \(Security settings\)/,
   (sh) => sh.some((c) => c.includes("app_process /system/bin --nice-name=waaiya_covers org.islamicmute.app.CoverHelper 10177 17"))],
  ["refused10", "en", /refused the permissions[\s\S]*needs Android 11/, (sh) => !sh.some((c) => c.includes("app_process"))],
  ["noapp", "en", /not installed on this phone/, (sh) => sh.length === 2],
  ["none", "en", /No phone was chosen/, null],
  ["unsupported", "en", /cannot reach USB devices/, null],
  ["done", "ar", /تمّ: صارت لواعية أذوناتها على Pixel 8/, null],
];

const server = http.createServer((req, res) => {
  const u = new URL(req.url, "http://x");
  if (u.pathname.endsWith("/mock.js")) { res.setHeader("content-type", "text/javascript"); return res.end(MOCK.replace("__KEY__", KEY)); }
  let f = path.join(PUB, decodeURIComponent(u.pathname));
  if (f.endsWith("/")) f += "index.html";
  if (!f.startsWith(PUB) || !fs.existsSync(f)) { res.statusCode = 404; return res.end(); }
  let body = fs.readFileSync(f);
  if (f.endsWith("index.html") && f.includes("/usb/"))
    body = body.toString().replace('<script type="module"', '<script src="/mock.js"></script><script type="module"');
  res.setHeader("content-type", f.endsWith(".js") ? "text/javascript" : f.endsWith(".html") ? "text/html; charset=utf-8" : "application/octet-stream");
  res.end(body);
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const port = server.address().port;
// the simulated phone writes each command it ran into a hidden <pre id="mock-shell">, which --dump-dom carries
// (asynchronous: this process also serves the page)
const dump = async (url) => (await promisify(execFile)(chrome, ["--headless=new", "--no-sandbox", "--disable-gpu",
  "--virtual-time-budget=8000", "--dump-dom", url], { encoding: "utf8", timeout: 60000, maxBuffer: 1 << 24 })).stdout;

let failed = 0;
for (const [s, lang, want, check] of CASES) {
  const url = `http://127.0.0.1:${port}/${lang === "en" ? "en/" : ""}usb/?s=${s}`;
  const dom = await dump(url);
  const status = (dom.match(/<div id="usb-status"[^>]*>([\s\S]*?)<\/div>/) || [])[1] || "";
  const text = status.replace(/<[^>]+>/g, " ").replace(/&amp;/g, "&").replace(/\s+/g, " ").trim();
  const shell = ((dom.match(/<pre id="mock-shell"[^>]*>([\s\S]*?)<\/pre>/) || [])[1] || "")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&amp;/g, "&").split("\n").filter(Boolean);
  const fullOk = !check || check(shell);
  const good = want.test(text) && fullOk;
  console.log((good ? "ok   " : "FAIL ") + `${s} (${lang}): ${text.slice(0, 110)}`);
  if (!good) failed++;
}
server.close();
console.log(failed ? `${failed} failed` : "all passed");
process.exit(failed ? 1 : 0);
