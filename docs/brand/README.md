# Waaiya's logo

The ع of واعية drawn as an ear: «وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ» (Al-Haqqah 69:12). The bowl of the letter is the vessel (وعى: to
hold, to keep) and the small arc inside it is the sound the ear keeps. One colour, no musical symbol, no sacred text
in the mark. 120-unit grid, monoline (stroke 12, inner arc 8); below about 40 px the small form `mark-mini.svg` is
used (no inner arc, stroke 16).

- `mark.svg`, `mark-white.svg`, `mark-mini.svg`: the symbol (layered: `wy-letter`, `wy-kept`).
- `mark-animated.svg`: the letter draws, three waves arrive and fade, the kept arc pulses; still under
  `prefers-reduced-motion`.
- `lockup-ar.svg`, `lockup-en.svg`, `wordmark-kufi*.svg`: with the name; the drawn Kufi «واعية» shares the mark's stroke.
- `favicon.svg`, `icon-squircle.svg`, `og.png`: icon and share card.

Where it is used: `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (launcher and themed icon),
`ic_notification.xml` (status bar, small form), `desktop/tool/make_icons.py` (Windows app icon and Store tiles),
`site/build.py` (`mark()`), `site/assets/logo.png` and `og.jpg`. Drawn 2026-11-21 (sources and the other four
concepts: /srv/build/waaiya-logo on the build host).
