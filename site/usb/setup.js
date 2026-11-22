// Waaiya: the "set up from a computer" page (waaiya.mssid.org/usb/). Texts come from the page (build.py, #usb-text).
// SPDX-License-Identifier: AGPL-3.0-or-later
import { Adb, generateKey } from "./adb.js";
import { UsbTransport, UsbError, supported } from "./usb.js";
import { runSetup, refusingMake } from "./flow.js";

const T = JSON.parse(document.getElementById("usb-text").textContent);
const $ = (id) => document.getElementById(id);
const btn = $("usb-connect"), box = $("usb-status"), logBox = $("usb-log"), logPre = $("usb-log-text");
const KEY = "waaiya.adbkey";
const fill = (s, v) => s.replace(/\{(\w+)\}/g, (_, k) => v[k] ?? "");

function show(kind, lines) {
  box.hidden = false;
  box.className = "usb-status " + kind;
  box.replaceChildren(...lines.filter(Boolean).map((t) => { const p = document.createElement("p"); p.textContent = t; return p; }));
  box.focus();
}

async function key() {
  try {
    const k = JSON.parse(localStorage.getItem(KEY) || "null");
    if (k && k.d && k.p) return k;
  } catch (_) {}
  const k = await generateKey();
  try { localStorage.setItem(KEY, JSON.stringify(k)); } catch (_) {}   // without it the phone asks again next time
  return k;
}

function platformHint(kind) {
  const ua = navigator.userAgent;
  if (kind === "access") return /Windows/.test(ua) ? T.accessWindows : /Linux|CrOS/.test(ua) && !/Android/.test(ua) ? T.accessLinux : T.accessOther;
  return "";
}

function outcome(r) {
  const who = r.phone.model || T.thePhone;
  const make = refusingMake(r.phone.maker);
  const tip = make === "xiaomi" ? T.tipXiaomi : make === "coloros" ? T.tipColoros : "";
  switch (r.status) {
    case "done": return ["ok", [fill(T.done, { model: who }), r.projectMedia ? "" : T.noProjectMedia, T.doneAfter]];
    case "helper": return ["ok", [fill(T.helper, { model: who }), T.helperAfter, tip]];
    // Android 10 has no helper: the make's switch is the only way, and refusedOld names it
    case "refused": return ["bad", [T.refused, r.phone.sdk < 30 ? T.refusedOld : tip || T.refusedOther]];
    case "noapp": return ["bad", [T.noApp]];
    case "tooold": return ["bad", [T.tooOld]];
  }
  return ["bad", [T.error]];
}

async function connect() {
  btn.disabled = true;
  let transport = null, result = null;
  try {
    show("work", [T.choose]);
    const device = await UsbTransport.pick();
    show("work", [T.opening]);
    transport = await UsbTransport.open(device);
    const adb = new Adb(transport);
    await adb.connect(await key(), { name: "waaiya@" + (navigator.userAgentData?.platform || "browser").toLowerCase(),
                                     onPrompt: () => show("work", [T.allow, T.allowWhy]) });
    result = await runSetup(adb, (s) => show("work", [T["step_" + s]]));
    const [kind, lines] = outcome(result);
    show(kind, lines);
  } catch (e) {
    console.error(e);
    if (e instanceof UsbError) show(e.kind === "none" ? "info" : "bad", [T["err_" + e.kind] || T.error, platformHint(e.kind)]);
    else if (/disconnected|NetworkError|transfer/i.test(String(e))) show("bad", [T.lost]);
    else show("bad", [T.error, String(e.message || e)]);
  } finally {
    if (transport) await transport.close();
    if (result) { logPre.textContent = result.log.join("\n\n"); logBox.hidden = false; }
    btn.disabled = false;
  }
}

if (!supported()) {
  btn.disabled = true;
  show("bad", [T.unsupported]);
} else {
  btn.addEventListener("click", connect);
}
