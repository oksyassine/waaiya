(function () {
  "use strict";
  var d = document.documentElement;
  var G = window.gsap;
  var T = JSON.parse(document.getElementById("i18n").textContent);
  var rtl = d.dir === "rtl";
  var mq = window.matchMedia("(prefers-reduced-motion: reduce)");
  var reduce = function () { return mq.matches; };
  var $ = function (s, r) { return (r || document).querySelector(s); };
  var $$ = function (s, r) { return Array.prototype.slice.call((r || document).querySelectorAll(s)); };
  var esc = function (s) { return String(s).replace(/[&<>"]/g, function (c) { return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]; }); };

  // ---------- one switch filters the whole page ----------
  var strips = $$(".music i");
  var powers = $$("[data-power]");
  var readout = $("#readout");
  var capState = $(".cap-state");
  var isOn = function () { return d.getAttribute("data-filter") === "on"; };

  function paint(on) {
    powers.forEach(function (p) { p.setAttribute("aria-pressed", on ? "true" : "false"); });
    var t = $(".ps-t");
    if (t) t.textContent = on ? T.compact_on : T.compact_off;
    if (readout) readout.innerHTML = "<strong>" + esc(on ? T.r_on_h : T.r_off_h) + "</strong><span>" + esc(on ? T.r_on : T.r_off) + "</span>";
    if (capState) capState.textContent = on ? T.spec_cap_on : T.spec_cap_off;
  }

  function setFilter(on, animate) {
    if (on === isOn()) return;
    d.setAttribute("data-filter", on ? "on" : "off");
    try { localStorage.setItem("waaiya.filter", on ? "on" : "off"); } catch (x) {}
    paint(on);
    if (animate !== false && G && !reduce() && strips.length) {
      var away = rtl ? "inset(0% 100% 0% 0%)" : "inset(0% 0% 0% 100%)";   // leaves in the reading direction
      var back = rtl ? "inset(0% 0% 0% 100%)" : "inset(0% 100% 0% 0%)";   // and returns from the far side
      G.killTweensOf(strips);
      G.fromTo(strips, { clipPath: on ? "inset(0% 0% 0% 0%)" : back }, {
        clipPath: on ? away : "inset(0% 0% 0% 0%)", duration: 0.7, ease: "power3.inOut", stagger: 0.04,
        onComplete: function () { G.set(strips, { clearProps: "clipPath" }); }
      });
    }
    document.dispatchEvent(new CustomEvent("waaiya:filter", { detail: on }));
  }
  paint(isOn());
  powers.forEach(function (p) { p.addEventListener("click", function () { setFilter(!isOn()); }); });

  // a quiet invitation: the ring around the big switch answers twice, once, while filtering is still off
  var ring = $(".power-l .ring");
  if (ring && G && !reduce() && !isOn()) {
    var ping = G.timeline({ delay: 1.6, repeat: 1, repeatDelay: 0.5 });
    ping.fromTo(ring, { scale: 1, autoAlpha: 0.9 }, { scale: 1.35, autoAlpha: 0, duration: 1.1, ease: "power2.out" });
    document.addEventListener("waaiya:filter", function () { ping.kill(); G.set(ring, { autoAlpha: 0 }); }, { once: true });
  }

  // the compact switch appears in the bar once the hero's switch is out of view
  var bar = $(".bar");
  var big = $(".power-l");
  if (bar && big && "IntersectionObserver" in window) {
    new IntersectionObserver(function (es) {
      es.forEach(function (en) { bar.classList.toggle("show-power", !en.isIntersecting && en.boundingClientRect.top < 0); });
    }).observe(big);
  }

  // ---------- the hero picture opens once ----------
  var shutter = $(".shutter");
  if (shutter) requestAnimationFrame(function () { requestAnimationFrame(function () { shutter.classList.add("is-in"); }); });

  // ---------- entrances: the parts of each section arrive in reading order, once ----------
  var groups = [
    [".hero-text", "[data-e]"], [".hero-power", ".power-l, .readout"],
    [".hear", "h2 span, [data-e]"], [".opts", ".opt"], [".cover", "[data-e], .cover-frag"], [".wait", ".card, [data-e]"],
    [".langs", "[data-e], .ltabs li, .lshot"], [".phones", "h2, .tile"], [".how", "h2, li"], [".priv", "[data-e], .film"],
    [".faq", "h2, .qq, .qa:not([data-closed])"], [".dl", ".dl-line, .dl-rows li"]
  ];
  if (G && !reduce() && "IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (en) {
        if (!en.isIntersecting) return;
        io.unobserve(en.target);
        var parts = en.target._parts;
        G.to(parts, { autoAlpha: 1, y: 0, duration: 0.7, ease: "power3.out", stagger: parts.length > 6 ? { amount: 0.45 } : 0.075, clearProps: "transform,opacity,visibility" });
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });
    groups.forEach(function (g) {
      $$(g[0]).forEach(function (root) {
        var parts = $$(g[1], root);
        if (!parts.length) return;
        root._parts = parts;
        G.set(parts, { autoAlpha: 0, y: 24 });
        io.observe(root);
      });
    });
  }

  // ---------- hear the result: only the filtered sound, with its playhead ----------
  var player = $(".player");
  if (player) {
    var audio = $("audio", player), play = $(".play", player), playT = $(".play-t", player);
    var head = $(".playhead", player), spec = $(".pl-spec", player), now = $(".pl-now", player);
    var raf = 0;
    var fmt = function (s) { s = Math.max(0, Math.floor(s)); return "0:" + (s < 10 ? "0" : "") + s; };
    var draw = function () {
      var dur = audio.duration || 10;
      head.style.transform = "translateX(" + (audio.currentTime / dur) * (spec.clientWidth - 3) + "px)";
      now.textContent = fmt(audio.currentTime);
      if (!audio.paused) raf = requestAnimationFrame(draw);
    };
    play.addEventListener("click", function () {
      if (audio.paused) { var p = audio.play(); if (p && p.catch) p.catch(function () {}); } else audio.pause();
    });
    audio.addEventListener("play", function () { play.setAttribute("aria-pressed", "true"); playT.textContent = T.pause; player.classList.add("playing"); cancelAnimationFrame(raf); draw(); });
    audio.addEventListener("pause", function () { play.setAttribute("aria-pressed", "false"); playT.textContent = T.play; player.classList.remove("playing"); player.classList.add("played"); cancelAnimationFrame(raf); draw(); });
    audio.addEventListener("ended", function () { audio.currentTime = 0; draw(); });
    spec.addEventListener("click", function (ev) {
      var r = spec.getBoundingClientRect();
      var go = function () { audio.currentTime = Math.min(0.999, Math.max(0, (ev.clientX - r.left) / r.width)) * (audio.duration || 10); draw(); };
      if (audio.readyState < 1) { audio.addEventListener("loadedmetadata", go, { once: true }); audio.load(); } else go();
      player.classList.add("played");
    });
  }

  // ---------- options: each sentence has the app's switch ----------
  $$(".opt .sw").forEach(function (sw) {
    sw.addEventListener("click", function () {
      var on = sw.getAttribute("aria-checked") !== "true";
      sw.setAttribute("aria-checked", on ? "true" : "false");
      sw.parentNode.setAttribute("data-on", on ? "true" : "false");
    });
  });

  // ---------- cover by hand: drag a rectangle, it becomes an opaque cover in the app's style ----------
  var frag = $(".cover-frag");
  if (frag) {
    var pad = $(".pad", frag), img = $("img", pad), layer = $(".covers", pad);
    var add = $(".cover-add", frag), clear = $(".cover-clear", frag), hint = $(".tool-hint", frag);
    var count = 0, start = null, live = null;
    var setCount = function (n) { count = n; $(".n", clear).textContent = n; clear.disabled = n === 0; };
    var mode = function (on) { frag.classList.toggle("drawing", on); add.setAttribute("aria-pressed", on ? "true" : "false"); hint.textContent = on ? T.cover_hint : ""; };
    var place = function (c, r) { c.style.left = r.x * 100 + "%"; c.style.top = r.y * 100 + "%"; c.style.width = r.w * 100 + "%"; c.style.height = r.h * 100 + "%"; };
    // Like the app: the area under the cover is averaged into a few big cells, smoothed, then tinted almost opaque.
    var paintCover = function (c, r) {
      var bw = pad.clientWidth, bh = pad.clientHeight, nw = img.naturalWidth, nh = img.naturalHeight;
      var dpr = Math.min(2, window.devicePixelRatio || 1);
      var w = Math.max(1, Math.round(r.w * bw)), h = Math.max(1, Math.round(r.h * bh));
      c.width = w * dpr; c.height = h * dpr;
      var ctx = c.getContext("2d");
      if (nw && nh) {
        var s = Math.max(bw / nw, bh / nh), ox = (bw - nw * s) / 2, oy = (bh - nh * s) / 2;
        var sx = (r.x * bw - ox) / s, sy = (r.y * bh - oy) / s, sw = (r.w * bw) / s, sh = (r.h * bh) / s;
        var nx = Math.max(2, Math.round(w / 56)), ny = Math.max(2, Math.round(h / 56));
        var mid = document.createElement("canvas"); mid.width = nx * 8; mid.height = ny * 8;
        mid.getContext("2d").drawImage(img, sx, sy, sw, sh, 0, 0, mid.width, mid.height);
        var cells = document.createElement("canvas"); cells.width = nx; cells.height = ny;
        cells.getContext("2d").drawImage(mid, 0, 0, nx, ny);
        ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = "high";
        ctx.drawImage(cells, 0, 0, c.width, c.height);
      }
      ctx.fillStyle = "rgba(30, 30, 30, 0.78)";
      ctx.fillRect(0, 0, c.width, c.height);
    };
    var addCover = function (r) {
      var c = document.createElement("canvas");
      c.setAttribute("aria-hidden", "true");
      place(c, r); layer.appendChild(c); paintCover(c, r);
      if (G && !reduce()) G.from(c, { autoAlpha: 0, duration: 0.18, ease: "power1.out" });
      setCount(count + 1);
    };
    var pt = function (ev) {
      var b = pad.getBoundingClientRect();
      return { x: Math.min(1, Math.max(0, (ev.clientX - b.left) / b.width)), y: Math.min(1, Math.max(0, (ev.clientY - b.top) / b.height)) };
    };
    var rectOf = function (a, b) { return { x: Math.min(a.x, b.x), y: Math.min(a.y, b.y), w: Math.abs(a.x - b.x), h: Math.abs(a.y - b.y) }; };
    add.addEventListener("click", function (ev) {
      if (ev.detail === 0) { addCover({ x: 0.26, y: 0.36, w: 0.48, h: 0.34 }); return; } // keyboard: a default cover over the cone
      mode(!frag.classList.contains("drawing"));
    });
    pad.addEventListener("pointerdown", function (ev) {
      if (!frag.classList.contains("drawing")) return;
      ev.preventDefault();
      pad.setPointerCapture(ev.pointerId);
      start = pt(ev);
      live = document.createElement("canvas"); live.className = "live"; live.setAttribute("aria-hidden", "true");
      place(live, { x: start.x, y: start.y, w: 0, h: 0 }); layer.appendChild(live);
    });
    pad.addEventListener("pointermove", function (ev) {
      if (!start) return;
      var r = rectOf(start, pt(ev)); place(live, r);
      var ctx = live.getContext("2d"); live.width = 2; live.height = 2; ctx.fillStyle = "rgba(30,30,30,0.55)"; ctx.fillRect(0, 0, 2, 2);
    });
    var end = function (ev) {
      if (!start) return;
      var r = rectOf(start, pt(ev));
      live.remove(); live = null; start = null;
      if (r.w > 0.03 && r.h > 0.03) addCover(r);
      mode(false);
    };
    pad.addEventListener("pointerup", end);
    pad.addEventListener("pointercancel", function () { if (live) live.remove(); live = null; start = null; });
    clear.addEventListener("click", function () { layer.innerHTML = ""; setCount(0); add.focus(); });
  }

  // ---------- the stop that waits ----------
  var card = $(".card");
  if (card) {
    var st = $(".st", card), msg = $(".card-msg", card), stop = $(".c-stop", card), ok = $(".c-confirm", card), no = $(".c-cancel", card);
    var timer = 0, phase = "idle", WAIT = 10;
    var clock = function (t) {
      return new Date(t).toLocaleTimeString(d.lang === "ar" ? "ar-u-nu-latn" : "en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit", hour12: false });
    };
    var show = function () {
      var on = isOn();
      st.textContent = on ? T.card_on : T.card_off;
      stop.hidden = phase !== "idle";
      stop.textContent = on ? T.card_stop : T.card_start;
      ok.hidden = phase !== "ready";
      no.hidden = phase === "idle";
      if (!on && phase === "idle" && !msg.textContent) msg.textContent = T.card_hint;
      if (on && msg.textContent === T.card_hint) msg.textContent = "";
    };
    var reset = function (text) { clearInterval(timer); phase = "idle"; msg.textContent = text || ""; show(); };
    stop.addEventListener("click", function () {
      if (!isOn()) { setFilter(true); reset(""); return; }           // turning on always takes effect at once
      var endAt = Date.now() + WAIT * 1000;
      phase = "waiting"; show();
      var tick = function () {
        var left = Math.ceil((endAt - Date.now()) / 1000);
        if (left <= 0) {
          clearInterval(timer); phase = "ready"; msg.textContent = T.card_ready; show(); ok.focus(); return;
        }
        msg.innerHTML = esc(T.card_wait).replace("{time}", '<bdi dir="ltr"><b>' + esc(clock(endAt)) + "</b></bdi>") +
          " <span>" + esc(T.card_left).replace("{n}", '<bdi dir="ltr"><b>' + left + "</b></bdi>") + "</span>";
      };
      tick(); timer = setInterval(tick, 250);
      no.focus();
    });
    ok.addEventListener("click", function () { setFilter(false); reset(T.card_done); stop.focus(); });
    no.addEventListener("click", function () { reset(phase === "idle" ? "" : T.card_kept); stop.focus(); });
    document.addEventListener("waaiya:filter", function () { if (phase !== "idle") reset(""); else show(); });
    show();
  }

  // ---------- your language: the real app screen in each of its 18 languages ----------
  var shot = $(".lshot img"), cap = $(".lshot figcaption");
  var tabs = $$(".lt");
  if (shot && tabs.length) {
    var base = shot.getAttribute("src").replace(/[a-z]+\.webp$/, "");
    var pick = function (code) {
      tabs.forEach(function (b) { b.setAttribute("aria-pressed", b.getAttribute("data-lang") === code ? "true" : "false"); });
      var name = T.names[code];
      shot.classList.add("loading");
      shot.onload = function () { shot.classList.remove("loading"); };
      shot.src = base + code + ".webp";
      shot.alt = T.lang_alt.replace("{name}", name);
      cap.textContent = T.lang_cap.replace("{name}", name);
    };
    tabs.forEach(function (b) { b.addEventListener("click", function () { pick(b.getAttribute("data-lang")); }); });
    // start in the visitor's own language when the app has it
    var want = (navigator.languages || [navigator.language || ""]).map(function (l) { return String(l).toLowerCase().split("-")[0]; });
    for (var i = 0; i < want.length; i++) {
      var code = want[i] === "in" ? "id" : want[i];
      if (T.names[code]) { if (code !== d.lang) pick(code); break; }
    }
  }

  // ---------- questions: one answer at a time ----------
  var qb = $$(".qq button");
  qb.forEach(function (b) {
    b.addEventListener("click", function () {
      qb.forEach(function (o) {
        var open = o === b;
        o.setAttribute("aria-expanded", open ? "true" : "false");
        var a = document.getElementById(o.getAttribute("aria-controls"));
        if (open) a.removeAttribute("data-closed"); else a.setAttribute("data-closed", "");
      });
    });
  });

  // ---------- download: the visitor's platform first, the others listed below ----------
  var dlh = $("#dl-h"), go = $(".dl-go"), list = $(".dl-rows");
  if (dlh && go && list) {
    var ua = navigator.userAgent;
    var plat = /Android/i.test(ua) ? "android" : /Windows/i.test(ua) ? "windows" : /Linux|X11|CrOS/i.test(ua) ? "linux" : "android";
    dlh.textContent = T.dl_for[plat];
    $$(".dl-rows > li").forEach(function (r) {
      var mine = r.getAttribute("data-plat") === plat;
      r.classList.toggle("on", mine);
      if (mine) list.insertBefore(r, list.firstChild);
    });
    if (plat === "windows") {
      go.removeAttribute("href"); go.setAttribute("aria-disabled", "true"); go.classList.add("soon"); go.textContent = T.dl_soon;
    } else {
      go.href = plat === "android" ? T.apk : T.linux; go.textContent = T.dl_btn;
    }
  }

  // ---------- the introduction video (in the hero) plays muted while in view; its controls give the sound (voice only) ----------
  var v = $(".film video");
  if (v && "IntersectionObserver" in window && !reduce()) {
    new IntersectionObserver(function (es) {
      es.forEach(function (en) { if (en.isIntersecting) { var p = v.play(); if (p && p.catch) p.catch(function () {}); } else if (v.muted) v.pause(); });
    }, { threshold: 0.4 }).observe(v);
  }
})();
