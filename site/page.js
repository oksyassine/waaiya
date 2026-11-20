(function () {
  var doc = document.documentElement;
  doc.classList.add("js");

  // The hero's power button: shows the same 10 seconds before and after Waaiya's filter.
  var frag = document.querySelector(".frag");
  var power = frag && frag.querySelector(".power");
  if (power) {
    power.addEventListener("click", function () {
      var on = frag.getAttribute("data-state") !== "on";
      frag.setAttribute("data-state", on ? "on" : "off");
      power.setAttribute("aria-pressed", on ? "true" : "false");
    });
    // once, a few seconds after load, so a visitor who does not touch it still sees the change
    var auto = setTimeout(function () {
      if (frag.getAttribute("data-state") === "off" && !matchMedia("(prefers-reduced-motion: reduce)").matches) power.click();
    }, 2600);
    power.addEventListener("pointerdown", function () { clearTimeout(auto); });
  }

  // The showcase: one name selected, its screen on the stage.
  var names = document.querySelectorAll(".show-name");
  names.forEach(function (b) {
    b.addEventListener("click", function () {
      var k = b.getAttribute("data-shot");
      names.forEach(function (n) { n.setAttribute("aria-pressed", n === b ? "true" : "false"); });
      document.querySelectorAll(".show-img, .show-text").forEach(function (el) {
        el.hidden = el.getAttribute("data-for") !== k;
      });
    });
  });

  // Download: the platform in the sentence decides where the button goes; preselected from the device.
  var sel = document.getElementById("platform");
  var btn = document.querySelector(".dl-btn");
  if (sel && btn) {
    var ua = navigator.userAgent;
    sel.value = /Android/i.test(ua) ? "android" : /Windows/i.test(ua) ? "windows" : /Linux|X11/i.test(ua) ? "linux" : "android";
    var set = function () { btn.href = sel.options[sel.selectedIndex].getAttribute("data-href"); };
    sel.addEventListener("change", set);
    set();
  }

  // Section entrances: the parts of each section arrive in reading order, once.
  var items = document.querySelectorAll(".reveal");
  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (!en.isIntersecting) return;
        var el = en.target;
        var sibs = el.parentElement ? Array.prototype.filter.call(el.parentElement.children, function (c) { return c.classList.contains("reveal"); }) : [el];
        el.style.transitionDelay = Math.min(sibs.indexOf(el), 6) * 75 + "ms";
        el.classList.add("in");
        io.unobserve(el);
      });
    }, { rootMargin: "0px 0px -8% 0px" });
    items.forEach(function (el) { io.observe(el); });
  } else {
    items.forEach(function (el) { el.classList.add("in"); });
  }

  // The film plays muted when it comes into view; the controls give the sound.
  var v = document.querySelector(".film-video");
  if (v && "IntersectionObserver" in window && !matchMedia("(prefers-reduced-motion: reduce)").matches) {
    new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { v.play().catch(function () {}); } else if (v.muted) { v.pause(); } });
    }, { threshold: 0.4 }).observe(v);
  }
})();
