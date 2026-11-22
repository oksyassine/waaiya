#!/bin/bash
# Puts a release's files on https://waaiya.mssid.org/downloads/ (the page's download links point here):
#   site/upload_downloads.sh 0.2.14
# Takes the signed APKs from build/apk/ and the desktop files + SHA256SUMS from the GitHub release (publish it first,
# with the signed APKs). waaiya.apk is the universal APK under a stable name. Then update VERSION in build.py and deploy.
# It also publishes the in-app update (make_update.py): patches/ and the release files read by the apps:
# waaiya-update.json (org.waaiya.app) and, for 0.2.15 only, update.json (org.islamicmute.app: its last version, the
# move build, which installs the new app; docs/MOVE.md).
set -euo pipefail
V="$1"
D="/srv/build/waaiya-downloads/$V"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK_DIR="$REPO_DIR/build/apk"
mkdir -p "$D"
cd "$D"
gh release download "v$V" -R oksyassine/waaiya -p "waaiya-desktop-*" -p "waaiya-linux-*" -p SHA256SUMS --clobber
cp "$APK_DIR"/waaiya-v"$V"-{arm64-v8a,armeabi-v7a,universal}-release.apk .
# the old name's last version (0.2.15 only)
if [ -f "$APK_DIR/waaiya-v$V-move-universal-release.apk" ]; then
    cp "$APK_DIR"/waaiya-v"$V"-move-{arm64-v8a,armeabi-v7a,universal}-release.apk .
fi
cp waaiya-v"$V"-universal-release.apk waaiya.apk
sha256sum -c --ignore-missing SHA256SUMS
# in-app updates: patches from the last releases and the release files (make_update.py checks package, version and
# certificate)
python3 "$REPO_DIR/site/make_update.py" "$V"
rsync -a --partial --exclude /update/ ./ o2:waaiya.mssid.org/downloads/
ssh o2 "cd ~/waaiya.mssid.org/downloads && sha256sum -c --ignore-missing SHA256SUMS"
# the patches first, the release files last: a phone never reads a release file whose files are not there yet; and
# the new app's file before the old one's, since the old app's last version offers what waaiya-update.json lists
rsync -a --partial update/patches/ o2:waaiya.mssid.org/downloads/patches/
for f in waaiya-update.json update.json; do
    [ -f "update/$f" ] || continue
    rsync -a "update/$f" "o2:waaiya.mssid.org/downloads/$f.new"
    ssh o2 "mv ~/waaiya.mssid.org/downloads/$f.new ~/waaiya.mssid.org/downloads/$f"
done
echo "uploaded: https://waaiya.mssid.org/downloads/"
