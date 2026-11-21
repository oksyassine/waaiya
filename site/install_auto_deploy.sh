#!/bin/bash
# Installs the website's automatic deploy (auto_deploy.sh) as systemd user units on the machine that can reach the
# host ("ssh o2" must work without a password). Needs lingering for the user (loginctl enable-linger) so it runs
# without a login session.
#
#   site/install_auto_deploy.sh <clone dir> [models dir]     install or update, then run once
#   site/install_auto_deploy.sh --remove
set -euo pipefail
UNITS=~/.config/systemd/user
if [ "${1:-}" = "--remove" ]; then
  systemctl --user disable --now waaiya-site-deploy.timer 2>/dev/null || true
  rm -f "$UNITS/waaiya-site-deploy.service" "$UNITS/waaiya-site-deploy.timer" ~/.local/bin/waaiya-site-deploy
  systemctl --user daemon-reload
  echo "removed"; exit 0
fi
CLONE=$(realpath -m "${1:?usage: install_auto_deploy.sh <clone dir> [models dir]}")
MODELS=${2:-}
mkdir -p "$UNITS" ~/.local/bin
install -m 755 "$(dirname "$0")/auto_deploy.sh" ~/.local/bin/waaiya-site-deploy
cat > "$UNITS/waaiya-site-deploy.service" <<EOF
[Unit]
Description=Waaiya website: deploy when main changes
After=network-online.target

[Service]
Type=oneshot
${MODELS:+Environment=WAAIYA_MODELS=$(realpath "$MODELS")}
ExecStart=%h/.local/bin/waaiya-site-deploy $CLONE
TimeoutStartSec=15min
Nice=10
EOF
cat > "$UNITS/waaiya-site-deploy.timer" <<EOF
[Unit]
Description=Waaiya website: look for changes on main every 5 minutes

[Timer]
OnBootSec=2min
OnUnitInactiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now waaiya-site-deploy.timer
systemctl --user start waaiya-site-deploy.service || true
journalctl --user -u waaiya-site-deploy.service -n 5 --no-pager
