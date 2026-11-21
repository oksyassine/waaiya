#!/bin/sh
# Adds Waaiya to your applications menu, with its icon (for this user only; no root needed).
#   ./install-desktop-entry.sh            add or update the entry (run it again after moving this folder)
#   ./install-desktop-entry.sh --remove   take it out again
set -eu
dir=$(cd "$(dirname "$0")" && pwd)
apps="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
entry="$apps/org.islamicmute.waaiya_desktop.desktop"
if [ "${1:-}" = "--remove" ]; then rm -f "$entry"; echo "removed $entry"; exit 0; fi
mkdir -p "$apps"
cat > "$entry" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Waaiya
Name[ar]=واعية
Comment=Removes musical instruments from the sound of every app, keeps speech and Quran recitation
Comment[ar]=يزيل المعازف من صوت كل التطبيقات ويُبقي الكلام والتلاوة
Exec="$dir/waaiya_desktop"
Icon=$dir/data/waaiya.png
Terminal=false
Categories=AudioVideo;Audio;
StartupWMClass=org.islamicmute.waaiya_desktop
DESKTOP
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$apps" >/dev/null 2>&1 || true
echo "added $entry"
