#!/bin/bash
# Installs Waaiya's "try a link" fetcher on the three servers the landing page asks, in this order (README.md):
#   1. o2switch      https://waaiya.mssid.org/api/link.php   (link.php, from site/deploy.sh) + ~/waaiya-link here
#   2. oracle-trial  https://link.waaiya.mssid.org/oracle    container on 127.0.0.1:8791, Caddy conf.d file
#   3. mhost         https://link.waaiya.mssid.org/mhost     container on 127.0.0.1:8792, reverse SSH tunnel to
#                    oracle-trial's 127.0.0.1:8792 (user systemd service waaiya-link-tunnel)
# yt-dlp stays current: o2 updates itself from link.php once a day; oracle-trial (cron) and mhost (user systemd timer)
# rebuild daily with update.sh.
#
#   site/link/deploy_link.sh [o2|oracle|mhost ...]   (default: all three)
set -euo pipefail
cd "$(dirname "$0")"
QJS_VERSION=v0.18.0
QJS_X64_SHA=85ded23b9fabe8c1644fc40a8d2bbdd71157affcbd807359c618cc717ee24d7d
FILES="Dockerfile waaiya_link.py server.py run.sh update.sh"
targets=${*:-o2 oracle mhost}

for t in $targets; do
  case $t in
  o2)
    ssh o2 'mkdir -p ~/waaiya-link/state && chmod 700 ~/waaiya-link/state'
    scp -q waaiya_link.py o2:waaiya-link/
    ssh o2 bash -s "$QJS_VERSION" "$QJS_X64_SHA" <<'EOF'
set -e
cd ~/waaiya-link
rm -f probe.py qjs-x86_64
if ! echo "$2  qjs" | sha256sum -c --status 2>/dev/null; then
  curl -fsSL -o qjs.new "https://github.com/quickjs-ng/quickjs/releases/download/$1/qjs-linux-x86_64"
  echo "$2  qjs.new" | sha256sum -c --status && mv qjs.new qjs && chmod 755 qjs
fi
[ -x venv/bin/python ] || /opt/alt/python311/bin/python3 -m venv venv
venv/bin/pip install -q -U pip yt-dlp yt-dlp-ejs 2>&1 | grep -v "^$" || true
touch state/updated
echo "o2: yt-dlp $(venv/bin/python -c 'import yt_dlp; print(yt_dlp.version.__version__)')"
EOF
    ;;
  oracle)
    ssh oracle-trial 'mkdir -p ~/waaiya-link && rm -f ~/waaiya-link/probe.py ~/waaiya-link/qjs-aarch64'
    scp -q $FILES oracle-trial:waaiya-link/
    ssh oracle-trial bash -s <<'EOF'
set -e
cd ~/waaiya-link && chmod +x run.sh update.sh
./update.sh ~/waaiya-link 8791
d=$HOME/waaiya-link
( crontab -l 2>/dev/null | grep -v '# waaiya-link$' ; echo "17 3 * * * $d/update.sh $d 8791 >> $d/update.log 2>&1 # waaiya-link" ) | crontab -
conf=/etc/caddy/conf.d/waaiya-link.caddy
sudo mkdir -p /etc/caddy/conf.d
sudo tee $conf.new >/dev/null <<'CADDY'
# Waaiya's "try a link" (waaiya repo, site/link/). Both answer POST only; CORS is set by server.py.
link.waaiya.mssid.org {
	request_body {
		max_size 8KB
	}
	handle /oracle {
		reverse_proxy 127.0.0.1:8791
	}
	handle /mhost {
		reverse_proxy 127.0.0.1:8792
	}
	respond 404
}
CADDY
if ! sudo cmp -s $conf.new $conf; then
  sudo mv $conf.new $conf
  sudo restorecon -R /etc/caddy/conf.d 2>/dev/null || true
  sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null && sudo systemctl reload caddy
else
  sudo rm -f $conf.new
fi
echo "oracle: caddy $(systemctl is-active caddy)"
EOF
    ;;
  mhost)
    d=$HOME/waaiya-link
    mkdir -p "$d" && cp $FILES "$d/" && chmod +x "$d/run.sh" "$d/update.sh"
    "$d/update.sh" "$d" 8792
    mkdir -p ~/.config/systemd/user
    # no cron on mhost: a daily user timer runs update.sh
    cat > ~/.config/systemd/user/waaiya-link-update.service <<EOF
[Unit]
Description=Waaiya link fetcher: rebuild with the newest yt-dlp (waaiya repo, site/link/update.sh)

[Service]
Type=oneshot
ExecStart=$d/update.sh $d 8792
EOF
    cat > ~/.config/systemd/user/waaiya-link-update.timer <<EOF
[Unit]
Description=Daily yt-dlp update for the Waaiya link fetcher

[Timer]
OnCalendar=*-*-* 03:17:00
RandomizedDelaySec=600
Persistent=true

[Install]
WantedBy=timers.target
EOF
    cat > ~/.config/systemd/user/waaiya-link-tunnel.service <<EOF
[Unit]
Description=Waaiya link fetcher: reverse tunnel to oracle-trial 127.0.0.1:8792 (waaiya repo, site/link/)
After=network-online.target

[Service]
ExecStart=/usr/bin/ssh -NT -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o BatchMode=yes -R 127.0.0.1:8792:127.0.0.1:8792 oracle-trial
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now waaiya-link-update.timer
    systemctl --user enable --now waaiya-link-tunnel.service
    systemctl --user restart waaiya-link-tunnel.service
    echo "mhost: tunnel $(systemctl --user is-active waaiya-link-tunnel.service)"
    ;;
  *) echo "unknown target $t"; exit 2 ;;
  esac
done
