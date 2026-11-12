#!/usr/bin/env python3
"""Generates ui/lib/l10n/app_ar.arb and app_en.arb from the Android string resources.

The Android strings (android/app/src/main/res/values{,-ar}/strings.xml) are the source: the Arabic texts are
reviewed there and are copied verbatim. Strings only the native side uses (notification, blur covers, accessibility
service) are left out. Flutter-only strings are in EXTRA below.

    python3 ui/tool/arb_from_android.py           # write the ARB files
    python3 ui/tool/arb_from_android.py --check   # fail if they are out of date (CI)

Then run `flutter gen-l10n` in ui/ (the generated Dart is committed: path dependencies do not run gen-l10n).
"""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
RES = REPO / "android/app/src/main/res"
OUT = REPO / "ui/lib/l10n"

# Native-only strings (notification, blur covers drawn by the service, accessibility service). The "Waaiya
# stopped" notice is also the desktop screen's text when the filter stopped by itself.
SKIP = re.compile(r"^(notif_(?!stopped_).*|blur_cover_.*|blur_not_working|blur_a11y_.*|link_channel)$")

# Android format arguments -> named placeholders, per string.
PLACEHOLDERS = {
    "state_on_detail": [("delayMs", "int")],
    "step_todo_cd": [("step", "int")],
    "setup_failed": [("details", "String")],
    "blur_setup_failed": [("details", "String")],
    "setting_language_title": [("language", "String")],
    "link_meta": [("first", "String"), ("second", "String")],
    "blur_strict_value": [("level", "String")],
    "state_blocked_silenced": [("apps", "String")],
    "state_blocked_unfiltered": [("apps", "String")],
}

# Strings the Flutter screens need that the Android screens did not have. The Arabic here is NOT reviewed yet.
EXTRA = {
    "desktop_preview": (
        "Preview: the filter engine is not connected on this computer yet. The button only shows how the app will work.",
        "معاينة: محرك التصفية غير موصول بهذا الحاسوب بعد. الزر يعرض فقط كيف سيعمل التطبيق.",
    ),
    "action_failed": (
        "That did not work: {details}",
        "تعذّر ذلك: {details}",
    ),
}
EXTRA.update({
    # Desktop engine host (DesktopBackend on Linux): filter.error codes, start at login, no measured delay.
    "state_on_detail_no_delay": (
        "Instruments are removed from all apps.",
        "تُزال الآلات من كل التطبيقات.",  # first sentence of the reviewed state_on_detail
    ),
    "engine_error_no_pactl": (
        "Sound tools not found (pactl). Waaiya needs PulseAudio, or PipeWire with pipewire-pulse.",
        "لم يُعثر على أدوات الصوت (pactl). تحتاج واعية إلى PulseAudio، أو PipeWire مع pipewire-pulse.",
    ),
    "engine_error_no_sound_server": (
        "The sound server is not running (PulseAudio or PipeWire).",
        "خادم الصوت لا يعمل (PulseAudio أو PipeWire).",
    ),
    "engine_error_no_systemd": (
        "This system has no systemd user session, which runs the filter in the background.",
        "لا توجد في هذا النظام جلسة systemd للمستخدم، وهي التي تشغّل التصفية في الخلفية.",
    ),
    "engine_error_no_output": (
        "No speakers or headphones found.",
        "لم يُعثر على مكبّرات صوت أو سماعات.",
    ),
    "engine_error_install_failed": (
        "Could not install the filter. Details:\n{details}",
        "تعذّر تثبيت التصفية. التفاصيل:\n{details}",
    ),
    "engine_error_start_failed": (
        "The filter did not start. Details:\n{details}",
        "لم تبدأ التصفية. التفاصيل:\n{details}",
    ),
    "engine_error_service_failed": (
        "The filter stopped with an error. Details:\n{details}",
        "توقّفت التصفية بسبب خطأ. التفاصيل:\n{details}",
    ),
    "autostart_title": ("Start at login", "التشغيل عند تسجيل الدخول"),
    "autostart_body": ("Filter the sound as soon as you log in.", "تصفية الصوت فور تسجيل الدخول."),
})
EXTRA.update({
    # Desktop screen blur (linux/blur/im-blur, driven by desktop/lib/linux_blur.dart): blur.error codes.
    "blur_body_desktop": (
        "Covers people and images on screen, over every window, while Waaiya is open (it works whether the sound "
        "filter is on or off). It runs on this computer; nothing is sent anywhere. Closing the Waaiya window stops "
        "the blur.",
        "يغطّي الأشخاص والصور على الشاشة، فوق كل النوافذ، ما دامت واعية مفتوحة (سواء كانت تصفية الصوت تعمل أم لا). "
        "يعمل على هذا الحاسوب، ولا يُرسَل شيء إلى أي مكان. إغلاق نافذة واعية يوقف التمويه.",
    ),
    "blur_fail_body_desktop": (
        "On: the whole screen is covered when the computer is too slow or the blur fails; clicks still reach the "
        "windows underneath. Off: the screen stays visible with a red bar at the top.",
        "مفعّل: تُغطّى الشاشة كلها إذا كان الحاسوب أبطأ من اللازم أو تعطّل التمويه، وتبقى النقرات تصل إلى النوافذ "
        "تحته. معطّل: تبقى الشاشة ظاهرة مع شريط أحمر في أعلاها.",
    ),
    "blur_status_on_visible_desktop": (
        "Blur on. This desktop shows the blur in its own screen capture, so a blurred area stays blurred until the "
        "scene changes.",
        "التمويه يعمل. يظهر التمويه في التقاط الشاشة على هذا الحاسوب، لذا تبقى المنطقة المموّهة مموّهة حتى يتغيّر المشهد.",
    ),
    "blur_status_no_capture": (
        "The blur cannot see the screen. Details:\n{details}",
        "لا يستطيع التمويه رؤية الشاشة. التفاصيل:\n{details}",
    ),
    "blur_status_no_overlay_desktop": (
        "The blur cannot draw over other windows on this desktop. Details:\n{details}",
        "لا يستطيع التمويه الرسم فوق النوافذ الأخرى في سطح المكتب هذا. التفاصيل:\n{details}",
    ),
    "blur_status_share_dialog": (
        "Choose your screen in the screen-sharing window and allow it. Waaiya asks only once; the picture stays on "
        "this computer.",
        "اختر شاشتك في نافذة مشاركة الشاشة واسمح بها. تسأل واعية مرة واحدة فقط، وتبقى الصورة على هذا الحاسوب.",
    ),
    "blur_status_exited": (
        "The blur stopped unexpectedly. Turn a blur option off and on to try again. Details:\n{details}",
        "توقّف التمويه على نحو غير متوقّع. أطفئ أحد خيارات التمويه ثم شغّله لتجرّب من جديد. التفاصيل:\n{details}",
    ),
})
EXTRA.update({
    # 0.2.9 parity on the desktop: what the daemon and the blur helper report.
    "engine_detector_failed": (
        "The women's singing detector did not load, so voices are muted while that option is on.",
        "لم يُحمَّل كاشف غناء النساء، لذا تُكتم الأصوات ما دام هذا الخيار مفعّلًا.",
    ),
    "blur_status_uncovered": (
        "A monitor is not covered by the blur: it was not shared with it, or it was plugged in later. Turn a blur "
        "option off and on, and choose every screen in the screen-sharing window.",
        "إحدى الشاشات لا يغطّيها التمويه: لم تُشارَك معه، أو وُصلت لاحقًا. أطفئ أحد خيارات التمويه ثم شغّله، "
        "واختر كل الشاشات في نافذة مشاركة الشاشة.",
    ),
    "blur_status_models_missing_desktop": (
        "The blur's models are missing from this installation, so it cannot cover anything; a red bar stays at the "
        "top of the screen. Reinstall Waaiya.",
        "نماذج التمويه غير موجودة في هذا التثبيت، لذا لا يستطيع تغطية شيء، ويبقى شريط أحمر في أعلى الشاشة. أعد "
        "تثبيت واعية.",
    ),
    "diag_note_desktop": (
        "What Waaiya sees on this computer. Copy it and give it to whoever helps you. The app itself sends nothing.",
        "ما تراه واعية على هذا الحاسوب. انسخه وأعطه لمن يساعدك. التطبيق نفسه لا يرسل شيئًا.",
    ),
})
EXTRA_PLACEHOLDERS = {
    "action_failed": [("details", "String")],
    "engine_error_install_failed": [("details", "String")],
    "engine_error_start_failed": [("details", "String")],
    "engine_error_service_failed": [("details", "String")],
    "blur_status_no_capture": [("details", "String")],
    "blur_status_no_overlay_desktop": [("details", "String")],
    "blur_status_exited": [("details", "String")],
}


def camel(name: str) -> str:
    head, *rest = name.split("_")
    return head + "".join(p[:1].upper() + p[1:] for p in rest)


def unescape(s: str) -> str:
    """Android resource escapes -> plain text."""
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            n = s[i + 1]
            out.append({"n": "\n", "t": "\t", "'": "'", '"': '"', "\\": "\\", "@": "@", "?": "?"}.get(n, n))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def load(path: Path) -> dict:
    strings = {}
    for el in ET.parse(path).getroot().findall("string"):
        strings[el.get("name")] = ("".join(el.itertext()), el.get("translatable") == "false")
    return strings


def convert(name: str, raw: str, places) -> str:
    text = unescape(raw)
    for idx, (pname, _) in enumerate(places or [], start=1):
        text = re.sub(r"%%%d\$[ds]" % idx, "{%s}" % pname, text)
    if re.search(r"%\d*\$?[ds]", text):
        raise SystemExit(f"{name}: format argument without a placeholder name: {text!r}")
    return text


def build() -> dict:
    en, ar = load(RES / "values/strings.xml"), load(RES / "values-ar/strings.xml")
    arb = {"ar": {"@@locale": "ar"}, "en": {"@@locale": "en"}}
    for name, (raw_en, untranslatable) in en.items():
        if SKIP.match(name):
            continue
        places = PLACEHOLDERS.get(name)
        if name in ar:
            raw_ar = ar[name][0]
        elif untranslatable:
            raw_ar = raw_en
        else:
            raise SystemExit(f"{name}: no Arabic text in values-ar/strings.xml")
        key = camel(name)
        arb["en"][key] = convert(name, raw_en, places)
        arb["ar"][key] = convert(name, raw_ar, places)
        meta = {"description": f"Android string {name}"}
        if places:
            meta["placeholders"] = {p: {"type": t} for p, t in places}
        arb["ar"]["@" + key] = meta
    for name, (text_en, text_ar) in EXTRA.items():
        key = camel(name)
        arb["en"][key] = text_en
        arb["ar"][key] = text_ar
        meta = {"description": "Flutter only. Arabic not reviewed yet."}
        if name in EXTRA_PLACEHOLDERS:
            meta["placeholders"] = {p: {"type": t} for p, t in EXTRA_PLACEHOLDERS[name]}
        arb["ar"]["@" + key] = meta
    return {lang: json.dumps(d, ensure_ascii=False, indent=2) + "\n" for lang, d in arb.items()}


def main() -> int:
    check = "--check" in sys.argv[1:]
    stale = []
    for lang, text in build().items():
        path = OUT / f"app_{lang}.arb"
        if check:
            if not path.is_file() or path.read_text(encoding="utf-8") != text:
                stale.append(str(path.relative_to(REPO)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
    if stale:
        print("Out of date with the Android strings (run python3 ui/tool/arb_from_android.py):", *stale, sep="\n  ")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
