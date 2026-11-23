# Waaiya's logo

The ع of واعية drawn as an ear: «وَتَعِيَهَا أُذُنٌ وَاعِيَةٌ» (Al-Haqqah 69:12). The bowl of the letter is the vessel (وعى: to
hold, to keep) and the small arc inside it is the sound the ear keeps. One colour, no musical symbol, no sacred text
in the mark. 120-unit grid, monoline (stroke 12, inner arc 8). Small sizes keep the ear (without the arc only a plain ع
was seen): the Android status bar draws the whole mark filling its 22dp; on Windows (taskbar, the icon next to the clock)
it is drawn larger with thinner strokes (desktop/tool/make_icons.py), and so are the website's tab icons (`site/assets/favicon-16/32/48.png`,
`favicon.svg`: `make_icons.py --site`). `mark-mini.svg` (no inner arc, stroke 16) is no longer used.

- `mark.svg`, `mark-white.svg`, `mark-mini.svg`: the symbol (layered: `wy-letter`, `wy-kept`).
- `mark-animated.svg`: the letter draws, three waves arrive and fade, the kept arc pulses; still under
  `prefers-reduced-motion`.
- `lockup-ar.svg`, `lockup-en.svg`, `wordmark-kufi*.svg`: with the name; the drawn Kufi «واعية» shares the mark's stroke.
- `favicon.svg`, `icon-squircle.svg`, `og.png`: icon and share card.

Where it is used: `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (launcher and themed icon),
`ic_notification.xml` (status bar and Quick Settings tile, the whole mark), `desktop/tool/make_icons.py` (Windows app icon and Store tiles),
`site/build.py` (`mark()`), `site/assets/logo.png` and `og.jpg`. Drawn 2026-11-21 (sources and the other four
concepts: /srv/build/waaiya-logo on the build host).
