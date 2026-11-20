#!/bin/bash
# Puts a release's files on https://waaiya.mssid.org/downloads/ (the page's download links point here):
#   site/upload_downloads.sh 0.2.13
# Takes the signed APKs from build/apk/ and the desktop files + SHA256SUMS from the GitHub release (publish it first,
# with the signed APKs). waaiya.apk is the universal APK under a stable name. Then update VERSION in build.py and deploy.
set -euo pipefail
V="$1"
D="/srv/build/waaiya-downloads/$V"
APK_DIR="$(cd "$(dirname "$0")/.." && pwd)/build/apk"
mkdir -p "$D"
cd "$D"
gh release download "v$V" -R oksyassine/waaiya -p "waaiya-desktop-*" -p "waaiya-linux-*" -p SHA256SUMS --clobber
cp "$APK_DIR"/waaiya-v"$V"-{arm64-v8a,armeabi-v7a,universal}-release.apk .
cp waaiya-v"$V"-universal-release.apk waaiya.apk
sha256sum -c --ignore-missing SHA256SUMS
rsync -a --partial ./ o2:waaiya.mssid.org/downloads/
ssh o2 "cd ~/waaiya.mssid.org/downloads && sha256sum -c --ignore-missing SHA256SUMS"
echo "uploaded: https://waaiya.mssid.org/downloads/"
