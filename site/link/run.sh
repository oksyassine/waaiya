#!/bin/sh
# (Re)start the waaiya-link container on this machine, listening on 127.0.0.1:$1 only.
#   run.sh 8791   on oracle-trial (Caddy: link.waaiya.mssid.org/oracle)
#   run.sh 8792   on mhost (reached through the reverse SSH tunnel, link.waaiya.mssid.org/mhost)
set -eu
port=${1:?port}
docker rm -f waaiya-link >/dev/null 2>&1 || true
docker run -d --name waaiya-link --restart unless-stopped \
  -p 127.0.0.1:$port:8790 \
  --read-only --tmpfs /tmp:rw,noexec,nosuid,size=96m \
  --cap-drop ALL --security-opt no-new-privileges \
  --cpus 1 --memory 768m --pids-limit 128 \
  --log-driver none \
  waaiya-link >/dev/null
echo "waaiya-link on 127.0.0.1:$port"
