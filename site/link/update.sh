#!/bin/sh
# Daily (cron): rebuild the image with the newest yt-dlp + yt-dlp-ejs and restart the container only if it changed.
#   update.sh <dir holding Dockerfile, waaiya_link.py, server.py, run.sh> <port>
set -eu
cd "${1:?dir}"; port=${2:?port}
old=$(docker image inspect -f '{{.Id}}' waaiya-link 2>/dev/null || true)
v() { curl -fsS --max-time 20 "https://pypi.org/pypi/$1/json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["info"]["version"])'; }
stamp="$(v yt-dlp || date +%F) $(v yt-dlp-ejs || true)"
docker build -q --pull --build-arg "YTDLP_STAMP=$stamp" -t waaiya-link . >/dev/null
new=$(docker image inspect -f '{{.Id}}' waaiya-link)
if [ "$old" != "$new" ] || ! docker ps -q -f name=^waaiya-link$ | grep -q .; then
  ./run.sh "$port"
  docker image prune -f >/dev/null
fi
docker run --rm --entrypoint python waaiya-link -c "import yt_dlp; print('yt-dlp', yt_dlp.version.__version__)"
