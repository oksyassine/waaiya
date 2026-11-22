// Waaiya: what the "set up from a computer" page runs on the phone, and how it reads the answers.
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// The same commands as the on-phone setup (WirelessSetup.grantCommand), then the same check the app makes (are the
// permissions there?), and on phones that refuse the grants (Xiaomi, OPPO family) Waaiya's helper, started as
// CoverHelper.startCommand does. Kept free of the page so the tests run it against a real adbd.

// Waaiya moved to org.waaiya.app in 0.2.15 (docs/MOVE.md); phones may still have the old org.islamicmute.app.
export const PKG = "org.waaiya.app";
export const OLD_PKG = "org.islamicmute.app";
const HELPER = "waaiya_covers";

export const grants = (pkg) =>
  `cmd package grant ${pkg} android.permission.DUMP 2>&1; echo "dump=$?"; ` +
  `cmd appops set ${pkg} PROJECT_MEDIA allow 2>&1; echo "project_media=$?"; ` +
  `cmd package grant ${pkg} android.permission.WRITE_SECURE_SETTINGS 2>&1; echo "secure_settings=$?"`;

export const check = (pkg) =>
  `D=$(dumpsys package ${pkg} 2>/dev/null); ` +
  `echo "$D" | grep -q 'android.permission.DUMP: granted=true' && echo dump=granted; ` +
  `echo "$D" | grep -q 'android.permission.WRITE_SECURE_SETTINGS: granted=true' && echo secure_settings=granted; ` +
  `cmd appops get ${pkg} PROJECT_MEDIA 2>&1 | grep -q 'PROJECT_MEDIA: allow' && echo project_media=allow; ` +
  `true`;

/** The helper's class: in org.waaiya.app since 0.2.15 (versionCode 18), also in the old name's last version. */
export const helperClass = (version) => (version >= 18 ? "org.waaiya.app" : "org.islamicmute.app") + ".CoverHelper";

/** CoverHelper.startCommand, with the package, uid and version read from the phone instead of from the app. */
export function helperCommand(pkg, uid, version) {
  return `for p in $(pidof ${HELPER}); do kill $p; done; ` +
    `for i in 1 2 3 4 5; do pidof ${HELPER} >/dev/null || break; sleep 0.2; done; ` +
    `P=$(pm path ${pkg} | head -n 1 | cut -d: -f2); ` +
    `CLASSPATH=$P setsid app_process /system/bin --nice-name=${HELPER} ${helperClass(version)} ` +
    `${uid} ${version} </dev/null >/dev/null 2>&1 & ` +
    `for i in 1 2 3 4 5 6 7 8 9 10; do sleep 0.5; pidof ${HELPER} >/dev/null && break; done; ` +
    `pidof ${HELPER} >/dev/null && echo helper=started || echo helper=missing`;
}

const field = (out, re) => (out.match(re) || [])[1];

export function parsePhone(out) {
  const [sdk, release, maker, model] = out.split("\n").map((s) => s.trim());
  return { sdk: parseInt(sdk, 10) || 0, release, maker: (maker || "").toLowerCase(), model };
}

/** Which make's hidden switch makes the grants permanent ("xiaomi", "coloros" or ""). */
export function refusingMake(maker) {
  if (/xiaomi|redmi|poco/.test(maker)) return "xiaomi";
  if (/oppo|oneplus|realme/.test(maker)) return "coloros";
  return "";
}

/**
 * Runs the setup on a connected phone ([adb] has shell(cmd) -> output). [step] is told what is happening.
 * Returns { status, phone, log } with status one of:
 *   "done"      DUMP granted (projectMedia false: Android will ask before each start, as on vivo)
 *   "helper"    the grants were refused and Waaiya's helper runs instead (until the phone restarts)
 *   "refused"   the grants were refused and the helper could not be started (Android 10, or it did not start)
 *   "noapp"     Waaiya is not installed on this phone
 *   "tooold"    Android 9 or older
 */
export async function runSetup(adb, step = () => {}, { forceHelper = false } = {}) {
  const log = [];
  const sh = async (c) => { const o = await adb.shell(c); log.push("$ " + c.slice(0, 80) + "\n" + o.trim()); return o; };
  step("phone");
  const phone = parsePhone(await sh(
    "getprop ro.build.version.sdk; getprop ro.build.version.release; getprop ro.product.manufacturer; getprop ro.product.model"));
  if (phone.sdk && phone.sdk < 29) return { status: "tooold", phone, log };
  // the new app when it is installed (also while the old one is still there), else the old one
  const paths = await sh(`pm path ${PKG} >/dev/null 2>&1 && echo new=yes; pm path ${OLD_PKG} >/dev/null 2>&1 && echo old=yes; true`);
  const pkg = /new=yes/.test(paths) ? PKG : /old=yes/.test(paths) ? OLD_PKG : null;
  if (!pkg) return { status: "noapp", phone, log };

  step("grants");
  await sh(grants(pkg));
  const out = await sh(check(pkg));
  const result = { phone, log, pkg, projectMedia: /project_media=allow/.test(out),
                   secureSettings: /secure_settings=granted/.test(out) };
  if (/dump=granted/.test(out) && !forceHelper) return { ...result, status: "done" };

  // refused (Xiaomi, OPPO family): Waaiya's helper lists the sound sessions for the app, from Android 11
  if (phone.sdk < 30) return { ...result, status: "refused" };
  step("helper");
  const info = await sh(`dumpsys package ${pkg} 2>/dev/null | grep -E 'userId=|versionCode=' | head -n 4`);
  const uid = field(info, /userId=(\d+)/), version = field(info, /versionCode=(\d+)/);
  if (!uid || !version) return { ...result, status: "refused" };
  const started = /helper=started/.test(await sh(helperCommand(pkg, uid, +version)));
  return { ...result, status: started ? "helper" : "refused" };
}
