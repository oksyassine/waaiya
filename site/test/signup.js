// The /test/ page (TEST in build.py): sends the sign-up form to the endpoint (site/test/signup.php) and says what
// happened, without leaving the page. Without JavaScript the form posts as usual and the endpoint sends the browser
// back to #done, #removed or #oops.
(function () {
  var T = JSON.parse(document.getElementById("test-text").textContent);
  document.querySelectorAll("form.tst-form").forEach(function (form) {
    var status = form.querySelector(".tst-status"), btn = form.querySelector("button[type=submit]");
    var remove = form.elements.mode.value === "remove";
    function say(cls, msg) {
      status.hidden = false;
      status.className = "tst-status " + cls;
      status.textContent = msg;
      if (cls !== "work") status.focus();
    }
    form.addEventListener("submit", function (ev) {
      ev.preventDefault();
      var email = form.elements.email;
      email.value = email.value.trim();
      if (!email.value || !email.checkValidity()) { say("bad", T.invalid_email); email.focus(); return; }
      btn.disabled = true;
      say("work", T.sending);
      fetch(form.getAttribute("action"), { method: "POST", body: new FormData(form), headers: { Accept: "application/json" } })
        .then(function (r) { return r.json(); })
        .catch(function () { return { error: "failed" }; })
        .then(function (res) {
          btn.disabled = false;
          var track = window.waaiyaTrack || function () {};  // the visit count (site/stats.js): that it worked, never the address
          if (res && res.ok) {
            track(remove ? "signup_remove" : "signup");
            say("ok", remove ? T.removed : T.done);
            form.reset();
          } else {
            track("signup_fail", { why: res && T[res.error] ? res.error : "failed" });
            say("bad", T[res && res.error] || T.failed);
          }
        });
    });
  });
})();
