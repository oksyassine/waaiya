#!/bin/bash
# Builds and uploads the landing page to waaiya.mssid.org (o2switch, ssh alias "o2"; docroot ~/waaiya.mssid.org).
# HTTPS: Let's Encrypt via acme.sh on o2 (dns_o2uapi), renewed by its daily cron.
set -euo pipefail
cd "$(dirname "$0")"
python3 build.py
cp htaccess public/.htaccess
rsync -a --delete public/ o2:waaiya.mssid.org/
echo "deployed: https://waaiya.mssid.org/"
