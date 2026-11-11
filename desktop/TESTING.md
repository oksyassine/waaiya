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
