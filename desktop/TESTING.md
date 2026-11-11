# Desktop app: manual audio test (Linux)

The unit tests (`desktop/test/linux_engine_test.dart`) drive the engine host against fake `waaiya`, `pactl` and
`systemctl`. The real sound path needs a desktop session with PulseAudio or PipeWire (pipewire-pulse), so it is
checked by hand.

1. Unpack the CI artifact `waaiya-desktop-linux-x64.tar.gz` and run `waaiya/waaiya_desktop`.
2. Start a song with instruments and singing or speech in a browser (a nasheed with drums, or a talk with background
   music).
3. Tap the power button. The first time, it installs the engine (`~/.local/share/islamic-mute`), then shows
   "Filtering is on" within a few seconds. In the sound settings the output is now "Waaiya".
4. Listen: the instruments are gone, the voice stays (a short delay is normal).
5. Tap the button again. The music comes back unfiltered, and "Waaiya" disappears from the outputs.
6. Turn on "Start at login", log out and in: the filter runs without opening the app. Turn it off again.
7. Errors (optional): stop the sound server (`systemctl --user stop pipewire-pulse.socket pipewire-pulse` or
   `pulseaudio -k`) and tap Start; the screen names the problem instead of starting. Start the server again.

Command-line check of the same install: `~/.local/bin/waaiya status` (`version:` must equal `engine/VERSION` in the
app folder).

# Desktop app: manual screen-blur test (Linux)

What runs here without a screen: the unit tests (`make test-blur`, `desktop/test/linux_blur_test.dart`), a real X
server (`python3 linux/blur/test_x11.py`: Xvfb, covers over women, clicks through, nudity cover, fail modes, cost)
and a headless wlroots compositor (`python3 linux/blur/test_layer_shell.py`: sway, layer-shell covers). Not tested
by the machine: the screen-sharing portal and PipeWire (GNOME, KDE, wlroots), GNOME's XWayland overlay, a
compositor on X11, several monitors and HiDPI. Those are checked by hand, below.

Which session you are in: `echo $XDG_SESSION_TYPE` (`x11` or `wayland`) and `echo $XDG_CURRENT_DESKTOP`.

Common steps, every session:

1. Unpack the CI artifact and run `waaiya/waaiya_desktop`. The "Screen blur" card is there (on Windows it is not,
   and "Who is left uncovered" appears nowhere).
2. Open a page with photos of women and men (an image search for "family photo", or a news site).
3. Turn on "Blur women". Filtering does not need to be on. Within a few seconds the status line reads "Blur on…"
   and the women are covered by soft blurred blocks; men may stay clear (more of them with "Who is left
   uncovered: relaxed").
4. Click, scroll and select text **on a cover**: everything reaches the page under it.
5. Scroll the page: the covers follow, or clear and come back within about a second.
6. Turn on "Blur immodest images" and open a swimwear photo: the whole screen is covered (dark grey) and clicks
   still go through. Turn it off: the cover goes away within 3 s.
7. Fail mode: with "Cover the screen if the blur cannot keep up" on, run
   `pkill -STOP -f engine/build/im-blur` for 3 s, then `pkill -CONT -f engine/build/im-blur`: nothing changes while it
   is stopped (it cannot draw), but a slow frame later shows the full cover; turn the switch off for a red bar
   at the top instead. (A missing model gives the same: rename `engine/models/vision/gender_v2.onnx`, toggle a
   blur option, the status says the model is missing and the screen is covered.)
8. Cost: `top -p $(pgrep -f engine/build/im-blur)` on a still page (about 1-3 %), then while a video plays.
   Command-line view of the same: `waaiya/engine/build/im-blur --policy 1` prints its state and, every 5 s,
   `ms` (model time per analysed frame), `cpu` (% of one core) and `fps`.
9. Close the app: the covers disappear with it.

## X11 (Xorg: GNOME on Xorg, KDE on X11, Xfce, Cinnamon, MATE)

- The status reads "Blur on. This desktop shows the blur in its own screen capture…": expected on X11 (the covers
  are part of the root window, so a covered area stays covered until the scene changes or scrolls).
- With two monitors, check a woman on each.
- With a compositor (GNOME, KDE, Xfce with compositing on, picom) and without one: the covers look the same.
- A fullscreen video (F in a browser player): the covers stay above it.

## GNOME Wayland (mutter)

- First start: a GNOME "Share screen" dialog appears. Choose the screen (or each screen) and allow it. The status
  reads "Choose your screen in the screen-sharing window…" until then. Cancelling gives "The blur cannot see the
  screen. … screen sharing was not allowed".
- Stop and start the blur (turn the option off and on), and restart the app: **no dialog** this time (the
  permission is kept in `~/.config/waaiya/screencast-restore-token`; delete it to be asked again).
- GNOME has no layer-shell, so the covers are an XWayland window: check that they stay above normal windows and
  above a fullscreen video, and that clicks on them reach the app underneath (this is the part not tested by the
  machine). If they do not show, the status says so.
- GNOME shows a screen-sharing indicator in the top bar while the blur runs: expected.
- With fractional scaling (Settings > Displays, 125 %), check the covers are on the women, not shifted.

## KDE Plasma Wayland (KWin)

- First start: KDE's "Screen sharing" dialog; choose the screen(s), tick "Allow restoring on future sessions" if
  shown, and allow. Later starts ask nothing.
- The covers are a layer-shell overlay: check they are above windows, panels and a fullscreen video, and that
  clicks pass through.
- With two monitors of different scale (100 % and 150 %), check the covers on both.

## wlroots (sway, Hyprland, river, labwc)

- Needs `xdg-desktop-portal-wlr` (or `xdg-desktop-portal-hyprland` on Hyprland) running; without it the status
  reads "…no screen-cast portal…". On sway the portal may need `exec dbus-update-activation-environment
  WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway` in the config.
- The output chooser of xdg-desktop-portal-wlr (slurp / wofi, set in its config) appears once.
- Same checks as KDE (layer-shell overlay).

Report back: the session (`$XDG_SESSION_TYPE`, `$XDG_CURRENT_DESKTOP`), the status line text, a screenshot of a
covered page, and `top`'s CPU figure for `im-blur`.
