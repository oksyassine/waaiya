#!/bin/bash
# Builds and uploads the landing page to waaiya.mssid.org (o2switch, ssh alias "o2"; docroot ~/waaiya.mssid.org).
# HTTPS: Let's Encrypt via acme.sh on o2 (dns_o2uapi), renewed by its daily cron.
#
#   site/deploy.sh             the live site (the docroot itself)
#   site/deploy.sh --preview   only https://waaiya.mssid.org/preview/ (noindex); the live root is not touched
set -euo pipefail
cd "$(dirname "$0")"
if [ "${1:-}" = "--preview" ]; then
  python3 build.py --preview
  cp htaccess public/.htaccess
  rsync -a --delete public/ o2:waaiya.mssid.org/preview/
  echo "deployed: https://waaiya.mssid.org/preview/"
else
  python3 build.py
  cp htaccess public/.htaccess
  # keep the preview folder when the live site is replaced
  rsync -a --delete --exclude /preview/ public/ o2:waaiya.mssid.org/
  echo "deployed: https://waaiya.mssid.org/"
fi
