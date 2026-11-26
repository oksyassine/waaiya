/* Visit counting for this website only (the apps send nothing; see docs/PRIVACY.md, "The website's visit count").
   Pages seen, time on page, clicks on links and buttons, and a few named moments ("Try it on your sound" started,
   finished or failed and why, the tester form sent), batched to Mssid's own analytics server (Mishkat's, app
   "waaiya"). No cookie and no lasting id: the visit id lives in this tab's sessionStorage and dies with it. Nothing
   typed into a field, no file, link or sound is ever read. The server turns the address into a country and city and
   drops it. Off on /preview/, with Do Not Track or Global Privacy Control, and after ?stats=off. ?adm=1 marks this
   browser as the owner's, so the dashboard can leave its visits out (?adm=0 undoes it). */
(function () {
  "use strict";
  var ENDPOINT = "https://mishkat.mssid.org/api/t";
  var store = function (kind, k, v) {
    try {
      var s = kind === "local" ? localStorage : sessionStorage;
      if (v === null) s.removeItem(k); else if (v !== undefined) s.setItem(k, v);
      return s.getItem(k);
    } catch (x) { return null; }
  };
  var q = new URLSearchParams(location.search);
  if (q.get("stats") === "off") store("local", "waaiya.stats", "off");
  if (q.get("stats") === "on") store("local", "waaiya.stats", null);
  if (q.get("adm") === "1") store("local", "waaiya.stats.admin", "1");
  if (q.get("adm") === "0") store("local", "waaiya.stats.admin", null);
  var off = /^\/preview(\/|$)/.test(location.pathname) || location.protocol !== "https:" ||
    navigator.doNotTrack === "1" || window.doNotTrack === "1" || navigator.globalPrivacyControl === true ||
    store("local", "waaiya.stats") === "off";

  var queue = [], timer = null, sid, returning, landing, page;
  var today = function () { return new Date().toISOString().slice(0, 10); };
  function rid(n) {
    var cs = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789", a = new Uint8Array(n), s = "";
    crypto.getRandomValues(a);
    for (var i = 0; i < n; i++) s += cs[a[i] % cs.length];
    return s;
  }
  function b64url(o) {
    var bytes = new TextEncoder().encode(JSON.stringify(o)), bin = "";
    for (var i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
    return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }
  function ctx() {
    var tz, load;
    try { tz = Intl.DateTimeFormat().resolvedOptions().timeZone; } catch (x) {}
    try { var nav = performance.getEntriesByType("navigation")[0]; if (nav && nav.loadEventEnd > 0) load = Math.round(nav.loadEventEnd); } catch (x) {}
    return {
      lang: navigator.language, tz: tz, tzo: new Date().getTimezoneOffset(), scr: screen.width + "x" + screen.height,
      dark: (window.matchMedia && matchMedia("(prefers-color-scheme: dark)").matches) || undefined, plat: "web",
      ret: returning || undefined, ref: landing.ref, src: landing.src, utm: landing.utm,
      adm: store("local", "waaiya.stats.admin") ? 1 : undefined, load: load
    };
  }
  function flush() {
    if (timer) { clearTimeout(timer); timer = null; }
    if (!queue.length) return;
    var now = Date.now();
    var ev = queue.splice(0, 60).map(function (e) { var o = {}; for (var k in e) if (k !== "at") o[k] = e[k]; o.dt = now - e.at; return o; });
    var body = b64url({ sid: sid, app: "waaiya", ctx: ctx(), ev: ev }), sent = false;
    try { sent = !!(navigator.sendBeacon && navigator.sendBeacon(ENDPOINT, new Blob([body], { type: "text/plain" }))); } catch (x) {}
    if (!sent) {
      try { fetch(ENDPOINT, { method: "POST", body: body, keepalive: true, mode: "no-cors", headers: { "content-type": "text/plain" } }).catch(function () {}); } catch (x) {}
    }
    if (queue.length) flush();
  }
  function push(e) {
    e.at = Date.now();
    queue.push(e);
    if (queue.length >= 20) flush(); else if (!timer) timer = setTimeout(flush, 4000);
  }
  function pv() { if (page.sent) return; page.sent = true; push({ t: "pv", p: page.path, ti: document.title.slice(0, 200) }); }
  function leave() {
    var ms = page.ms + (page.since !== null ? Date.now() - page.since : 0);
    page.ms = 0;
    page.since = document.visibilityState === "visible" ? Date.now() : null;
    if (ms >= 300) push({ t: "leave", p: page.path, v: ms, pr: { scroll: Math.round(page.scroll) } });
  }

  // Named moments, for site/try/try.js and site/test/signup.js: a name, a few codes or numbers, never text people typed.
  window.waaiyaTrack = function (name, props, value) {
    if (off || !page) return;
    pv();
    push({ t: "ev", n: name, p: page.path, v: value, pr: props });
  };
  if (off) return;

  sid = store("session", "waaiya.sid") || store("session", "waaiya.sid", rid(16)) || rid(16);
  var first = store("local", "waaiya.first");
  returning = !!first && first < today();
  if (!first) store("local", "waaiya.first", today());
  landing = {
    ref: document.referrer || undefined, src: q.get("src") || undefined,
    utm: { s: q.get("utm_source") || undefined, m: q.get("utm_medium") || undefined, c: q.get("utm_campaign") || undefined }
  };
  page = { path: location.pathname.slice(0, 300), ms: 0, since: document.visibilityState === "visible" ? Date.now() : null, scroll: 0, sent: false };
  setTimeout(pv, 1200);

  var CLICKABLE = "a,button,[role=button],[data-track],summary,input[type=checkbox],input[type=radio],input[type=submit]";
  document.addEventListener("click", function (e) {
    var el = e.target && e.target.closest ? e.target.closest(CLICKABLE) : null;
    if (!el || el.closest("[data-track-off]")) return;
    var tag = el.tagName.toLowerCase();
    var label = el.getAttribute("data-track") || el.getAttribute("aria-label") || el.getAttribute("title") || "";
    if (!label) label = tag === "input" ? ((el.closest("label") || {}).innerText || el.getAttribute("name") || "") : (el.innerText || el.textContent || "");
    label = label.replace(/\s+/g, " ").trim().slice(0, 100);
    var href = tag === "a" ? (el.getAttribute("href") || "").slice(0, 300) : "";
    pv();
    push({ t: "click", p: page.path, n: label || tag, g: href || tag });
  }, true);
  document.addEventListener("scroll", function () {
    var d = document.documentElement;
    var pct = d.scrollHeight > 0 ? ((window.scrollY + window.innerHeight) / d.scrollHeight) * 100 : 100;
    if (pct > page.scroll) page.scroll = Math.min(100, pct);
  }, { passive: true });
  document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "hidden") { pv(); leave(); page.since = null; flush(); } else page.since = Date.now();
  });
  window.addEventListener("pagehide", function () { pv(); leave(); flush(); });
})();
