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
  rsync -a --delete --exclude /downloads/ public/ o2:waaiya.mssid.org/preview/
  echo "deployed: https://waaiya.mssid.org/preview/"
else
  python3 build.py
  cp htaccess public/.htaccess
  mkdir -p public/api && cp link/link.php public/api/link.php   # "try a link", first server (link/README.md)
  # keep the preview folder when the live site is replaced
  rsync -a --delete --exclude /preview/ --exclude /downloads/ public/ o2:waaiya.mssid.org/
  echo "deployed: https://waaiya.mssid.org/"
  # tell the search engines that share IndexNow (Bing, Yandex, Seznam, Naver...) that the pages changed.
  # Google reads sitemap.xml (robots.txt names it). Only the public page addresses are sent.
  KEY=$(python3 -c "import build; print(build.INDEXNOW_KEY)")
  curl -sS -o /dev/null -w "IndexNow: %{http_code}\n" -H "Content-Type: application/json; charset=utf-8" \
    --data "{\"host\":\"waaiya.mssid.org\",\"key\":\"$KEY\",\"keyLocation\":\"https://waaiya.mssid.org/$KEY.txt\",\"urlList\":[\"https://waaiya.mssid.org/\",\"https://waaiya.mssid.org/en/\",\"https://waaiya.mssid.org/privacy.html\"]}" \
    https://api.indexnow.org/indexnow || true
fi
