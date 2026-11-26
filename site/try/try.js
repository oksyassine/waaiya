/* "Try it on your sound": a file from the visitor's device, or a minute of a link fetched by our servers
   (site/link/), filtered here by try-worker.js; one switch moves between before and after at the same moment.
   Fail-closed: if filtering fails, nothing is played as "after". */
(function () {
  var root = document.getElementById("try");
  if (!root || !window.Worker || !window.WebAssembly) return;
  var T = JSON.parse(document.getElementById("i18n").textContent).try;
  var BASE = new URL(root.getAttribute("data-base"), location.href).href;
  var EP = JSON.parse(root.getAttribute("data-endpoints") || "[]");
  var STOP = { invalid_url: 1, unsupported_site: 1, playlist: 1, live: 1, no_format: 1 };
  var SR = 48000, MAX_S = 60, LONG_S = 600;
  var $ = function (s) { return root.querySelector(s); };
  var fileIn = $(".try-file input"), fileBtn = $(".try-file button"), form = $(".try-link"), linkIn = $(".try-link input"),
      linkBtn = $(".try-link button"), st = $(".try-status"), bar = $(".try-bar i"), deck = $(".try-deck"),
      src = $(".try-src"), sides = root.querySelectorAll(".try-ab button"), play = $(".try-play"), playT = $(".try-play span"),
      seek = $(".try-seek"), now = $(".try-now"), len = $(".try-len"), video = $(".try-video"), videoUrl = null;
  root.classList.add("try-on");
  if (!EP.length) form.hidden = true;

  var picture = null;  // the clip's video (a file or the link's small picture), shown muted in step with the sound
  var ctx = null, before = null, after = null, side = "after", nodes = null, startAt = 0, offset = 0, raf = 0, working = false;

  function say(msg, kind, p) {
    st.textContent = msg;
    root.setAttribute("data-state", kind || "");
    bar.style.transform = "scaleX(" + (p == null ? 0 : Math.max(0.02, p)) + ")";
  }
  function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2); }
  function busy(b) { working = b; fileBtn.disabled = b; linkBtn.disabled = b; root.classList.toggle("try-busy", b); }
  function audio() {
    if (!ctx) { var C = window.AudioContext || window.webkitAudioContext; ctx = new C(); }
    if (ctx.state === "suspended") ctx.resume();
    return ctx;
  }

  function decode(buf) {
    var C = window.OfflineAudioContext || window.webkitOfflineAudioContext, oc = new C(1, SR, SR);
    return new Promise(function (ok, no) { var p = oc.decodeAudioData(buf, ok, no); if (p && p.then) p.then(ok, no); });
  }
  function mono(ab) {  // the first minute, channels mixed (as the app's mono mode)
    var n = Math.min(ab.length, MAX_S * SR), out = new Float32Array(n), c = ab.numberOfChannels;
    for (var k = 0; k < c; k++) { var d = ab.getChannelData(k); for (var i = 0; i < n; i++) out[i] += d[i] / c; }
    return out;
  }
  function length(file) {  // duration from the file's own header, without decoding it
    return new Promise(function (ok) {
      var m = document.createElement(/^video/.test(file.type) ? "video" : "audio"), u = URL.createObjectURL(file), done = false;
      function end(d) { if (done) return; done = true; URL.revokeObjectURL(u); m.removeAttribute("src"); ok(isFinite(d) ? d : 0); }
      m.preload = "metadata"; m.muted = true;
      m.onloadedmetadata = function () { end(m.duration); };
      m.onerror = function () { end(0); };
      setTimeout(function () { end(0); }, 5000);
      m.src = u;
    });
  }

  async function fromFile(file) {
    say(T.reading, "work");
    var d = await length(file), part = file, cut = false;
    if (d > LONG_S || (!d && file.size > 80e6)) {  // a long file: decode only its beginning
      if (!d) throw "file_long";
      part = file.slice(0, Math.ceil(file.size * Math.min(1, (MAX_S + 20) / d) * 1.15) + 262144);
      cut = true;
    }
    try { return mono(await decode(await part.arrayBuffer())); } catch (e) { throw cut ? "file_long" : "decode"; }
  }

  async function fromLink(url) {
    var why = "all";
    for (var i = 0; i < EP.length; i++) {
      say(i ? T.next : T.fetching, "work");
      var ac = new AbortController(), timer = setTimeout(function () { ac.abort(); }, 100000);
      try {
        var r = await fetch(EP[i], { method: "POST", body: new URLSearchParams({ url: url }), signal: ac.signal });
        if (r.ok) {
          var meta = {};
          try { meta = JSON.parse(r.headers.get("X-Waaiya-Meta") || "{}"); } catch (e) {}
          var bytes = await r.arrayBuffer();
          var pcm = mono(await decode(bytes.slice(0)));
          clearTimeout(timer);
          return { pcm: pcm, meta: meta, picture: meta.video ? new Blob([bytes], { type: "video/mp4" }) : null };
        }
        var code = ((await r.json().catch(function () { return {}; })).error) || "";
        if (STOP[code]) { clearTimeout(timer); throw code; }
      } catch (e) {
        if (typeof e === "string") throw e;  // a definite answer: do not ask the other servers
      }
      clearTimeout(timer);
    }
    throw why;
  }

  function filter(pcm) {
    return new Promise(function (ok, no) {
      var w = new Worker(BASE + "try-worker.js");
      say(T.loading, "work", 0);
      w.onmessage = function (e) {
        var m = e.data;
        if (m.loaded) say(T.filtering.replace("{p}", "0"), "work", 0);
        else if (m.p != null) say(T.filtering.replace("{p}", Math.round(m.p * 100)), "work", m.p);
        else if (m.out) { w.terminate(); ok(m.out); }
        else if (m.error) { w.terminate(); no("filter"); }
      };
      w.onerror = function () { w.terminate(); no("filter"); };
      w.postMessage({ base: BASE, pcm: pcm.slice() });
    });
  }

  // the visit count (site/stats.js): where the sound came from, its length, and a fixed error code; never the sound,
  // the file's name or the link
  function count(name, src, extra, value) {
    if (!window.waaiyaTrack) return;
    var pr = { src: src };
    for (var k in extra || {}) pr[k] = extra[k];
    window.waaiyaTrack(name, pr, value);
  }

  async function run(get, label, kind) {
    if (working) return;
    busy(true); stop(); deck.hidden = true; before = after = null; picture = null; showPicture();
    audio();  // created on the visitor's tap, so it may play later
    count("try_start", kind);
    try {
      var got = await get();
      if (!got.length || got.length < SR / 2) throw "decode";
      var out = await filter(got);
      before = buffer(got); after = buffer(out);
      src.textContent = typeof label === "function" ? label() : label;
      len.textContent = fmt(before.duration); now.textContent = "0:00";
      seek.max = String(Math.floor(before.duration * 10)); seek.value = "0"; offset = 0;
      pick("after");
      showPicture();
      deck.hidden = false;
      say(T.ready, "done", 1);
      count("try_done", kind, null, Math.round(before.duration));
    } catch (e) {
      var why = typeof e === "string" && T.err[e] ? e : "all";
      say(T.err[why], "error");
      count("try_fail", kind, { why: why });
    } finally {
      busy(false);
    }
  }
  video.addEventListener("error", function () { if (videoUrl) video.hidden = true; });  // a codec this browser lacks
  function showPicture() {
    if (videoUrl) { URL.revokeObjectURL(videoUrl); videoUrl = null; }
    video.removeAttribute("src"); video.hidden = true;
    if (!picture) { try { video.load(); } catch (e) {} return; }
    videoUrl = URL.createObjectURL(picture);
    video.src = videoUrl; video.hidden = false; video.currentTime = 0;
  }
  // The picture follows what is heard: the audio clock minus the output's own latency (a Bluetooth headset can be
  // far behind), corrected when it drifts.
  function heard() { return Math.max(0, pos() - (ctx ? (ctx.outputLatency || 0) + (ctx.baseLatency || 0) : 0)); }
  function syncPicture(force) {
    if (!videoUrl || video.readyState < 1) return;
    var t = heard();
    if (force || Math.abs(video.currentTime - t) > 0.08) { try { video.currentTime = t; } catch (e) {} }
  }
  function buffer(f) { var b = audio().createBuffer(1, f.length, SR); b.copyToChannel ? b.copyToChannel(f, 0) : b.getChannelData(0).set(f); return b; }

  // ---------- playback: both versions run together; the switch only moves the volume between them ----------
  function start() {
    var c = audio(), t = c.currentTime + 0.05;
    nodes = [before, after].map(function (b, i) {
      var s = c.createBufferSource(), g = c.createGain();
      s.buffer = b; g.gain.value = (i === 0) === (side === "before") ? 1 : 0;
      s.connect(g); g.connect(c.destination); s.start(t, offset);
      return { s: s, g: g };
    });
    nodes[0].s.onended = function () { if (nodes && pos() >= before.duration - 0.05) { stop(); offset = 0; tick(); } };
    startAt = t - offset;
    if (videoUrl) { syncPicture(true); var vp = video.play(); if (vp && vp.catch) vp.catch(function () {}); }
    play.setAttribute("aria-pressed", "true"); playT.textContent = T.pause;
    cancelAnimationFrame(raf); loop();
  }
  function stop() {
    if (nodes) { offset = pos(); nodes.forEach(function (n) { n.s.onended = null; try { n.s.stop(); } catch (e) {} n.s.disconnect(); }); nodes = null; }
    cancelAnimationFrame(raf);
    if (videoUrl) { video.pause(); syncPicture(true); }
    play.setAttribute("aria-pressed", "false"); playT.textContent = T.play;
  }
  function pos() { return nodes ? Math.min(before.duration, Math.max(0, ctx.currentTime - startAt)) : offset; }
  function tick() { var p = pos(); now.textContent = fmt(p); seek.value = String(Math.round(p * 10)); }
  function loop() { tick(); syncPicture(false); raf = requestAnimationFrame(loop); }
  function pick(s) {
    side = s;
    for (var i = 0; i < sides.length; i++) sides[i].setAttribute("aria-pressed", String(sides[i].getAttribute("data-side") === s));
    root.setAttribute("data-side", s);
    if (nodes) {
      var t = ctx.currentTime;
      nodes[0].g.gain.setTargetAtTime(s === "before" ? 1 : 0, t, 0.015);
      nodes[1].g.gain.setTargetAtTime(s === "after" ? 1 : 0, t, 0.015);
    }
  }

  fileBtn.addEventListener("click", function () { fileIn.click(); });
  fileIn.addEventListener("change", function () {
    var f = fileIn.files && fileIn.files[0];
    if (f) run(function () { return fromFile(f).then(function (pcm) { if (/^video\//.test(f.type)) picture = f; return pcm; }); },
               T.src_file.replace("{name}", f.name), "file");
    fileIn.value = "";
  });
  form.addEventListener("submit", function (e) {
    e.preventDefault();
    var u = linkIn.value.trim();
    if (!/^https?:\/\/\S+$/i.test(u)) { say(T.err.invalid_url, "error"); linkIn.focus(); return; }
    var meta = null;
    run(function () { return fromLink(u).then(function (r) { meta = r.meta; picture = r.picture; return r.pcm; }); },
        function () { return T.src_link.replace("{title}", (meta && meta.title) || u); }, "link");
  });
  for (var i = 0; i < sides.length; i++) sides[i].addEventListener("click", function () { pick(this.getAttribute("data-side")); });
  play.addEventListener("click", function () { if (!before) return; if (nodes) stop(); else { if (offset >= before.duration - 0.05) offset = 0; start(); } });
  seek.addEventListener("input", function () {
    var was = !!nodes; if (was) stop();
    offset = Number(seek.value) / 10; now.textContent = fmt(offset); if (!was) syncPicture(true);
    if (was) start();
  });
  document.addEventListener("visibilitychange", function () { if (document.hidden && nodes) stop(); });
})();
