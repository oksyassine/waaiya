#!/bin/bash
# Keeps https://waaiya.mssid.org in step with the main branch on GitHub: run every few minutes by a systemd user
# timer (install_auto_deploy.sh). It fetches main into its own clone (never a working checkout), and when a commit
# since the last deploy touched the page's sources (site/, docs/PRIVACY.md, models/SHA256SUMS), it runs
# site/deploy.sh from that clone. Nothing happens when main has not moved.
#
#   site/auto_deploy.sh <clone dir>     the clone is made on first run
# Env: WAAIYA_MODELS (the voice model folder for the "try it" section; build.py checks it against models/SHA256SUMS).
set -euo pipefail
CLONE=${1:?usage: auto_deploy.sh <clone dir>}
REMOTE=https://github.com/oksyassine/waaiya.git
STATE="$CLONE.deployed"   # the last commit deployed
exec 9>"$CLONE.lock"
flock -n 9 || { echo "another deploy is running"; exit 0; }

[ -d "$CLONE/.git" ] || git clone -q --branch main --single-branch "$REMOTE" "$CLONE"
cd "$CLONE"
git fetch -q origin main
NEW=$(git rev-parse origin/main)
OLD=$(cat "$STATE" 2>/dev/null || true)
[ "$NEW" = "$OLD" ] && exit 0

if [ -n "$OLD" ] && git cat-file -e "$OLD^{commit}" 2>/dev/null &&
   git diff --quiet "$OLD" "$NEW" -- site docs/PRIVACY.md models/SHA256SUMS; then
  echo "main moved to ${NEW:0:9}: nothing for the website"
  echo "$NEW" > "$STATE"
  exit 0
fi

git checkout -q --force --detach "$NEW"
git clean -qfdx -e site/public   # keeps nothing else from an earlier build
echo "deploying ${NEW:0:9}: $(git log -1 --format=%s)"
bash site/deploy.sh
# the live page still answers
curl -fsS -A "Mozilla/5.0 (Linux; Android 14) waaiya-auto-deploy" https://waaiya.mssid.org/ -o /dev/null
echo "$NEW" > "$STATE"
echo "deployed ${NEW:0:9}"
