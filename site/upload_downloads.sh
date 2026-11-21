#!/bin/bash
# Puts a release's files on https://waaiya.mssid.org/downloads/ (the page's download links point here):
#   site/upload_downloads.sh 0.2.14
# Takes the signed APKs from build/apk/ and the desktop files + SHA256SUMS from the GitHub release (publish it first,
# with the signed APKs). waaiya.apk is the universal APK under a stable name. Then update VERSION in build.py and deploy.
# It also publishes the in-app update (make_update.py): patches/ and update.json, the release file read by the apps.
set -euo pipefail
V="$1"
D="/srv/build/waaiya-downloads/$V"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK_DIR="$REPO_DIR/build/apk"
mkdir -p "$D"
cd "$D"
gh release download "v$V" -R oksyassine/waaiya -p "waaiya-desktop-*" -p "waaiya-linux-*" -p SHA256SUMS --clobber
cp "$APK_DIR"/waaiya-v"$V"-{arm64-v8a,armeabi-v7a,universal}-release.apk .
cp waaiya-v"$V"-universal-release.apk waaiya.apk
sha256sum -c --ignore-missing SHA256SUMS
# in-app updates: patches from the last releases and update.json (make_update.py checks version and certificate)
python3 "$REPO_DIR/site/make_update.py" "$V"
rsync -a --partial --exclude /update/ ./ o2:waaiya.mssid.org/downloads/
ssh o2 "cd ~/waaiya.mssid.org/downloads && sha256sum -c --ignore-missing SHA256SUMS"
# the patches first, the release file last: a phone never reads an update.json whose files are not there yet
rsync -a --partial update/patches/ o2:waaiya.mssid.org/downloads/patches/
rsync -a update/update.json o2:waaiya.mssid.org/downloads/update.json.new
ssh o2 "mv ~/waaiya.mssid.org/downloads/update.json.new ~/waaiya.mssid.org/downloads/update.json"
echo "uploaded: https://waaiya.mssid.org/downloads/"
