# "Try it on your sound": the link servers

The landing page's try section (`site/try/`) filters sound in the visitor's browser with the app's own model. A file
from the visitor's device never leaves it. A link cannot be read by a browser, so the page asks these servers, in
order, for up to 60 s of the link's sound (from the link's `t=` time if it has one), as a mono M4A:

| # | Server | Endpoint | Runs |
|---|---|---|---|
| 1 | o2switch | `https://waaiya.mssid.org/api/link.php` | `link.php` → `~/waaiya-link/waaiya_link.py` (venv, Python 3.11) |
| 2 | oracle-trial | `https://link.waaiya.mssid.org/oracle` | container `waaiya-link` on 127.0.0.1:8791, Caddy `/etc/caddy/conf.d/waaiya-link.caddy` |
| 3 | mhost | `https://link.waaiya.mssid.org/mhost` | container on 127.0.0.1:8792, reached through `waaiya-link-tunnel` (user systemd, `ssh -R` to oracle-trial) |

The list is `LINK_ENDPOINTS` in `site/build.py`; an empty list hides the link box.

**Answers.** 200 `audio/mp4` with `X-Waaiya-Meta` (title, start, length), or JSON `{"error": code}`:
400 makes the page stop (`invalid_url`, `unsupported_site`, `playlist`, `live`, `no_format`); 503 makes it try the
next server (`bot`, `limited`, `login`, `timeout`, `failed`, `busy`, `quota`). If all fail the page says so.
Measured 2026-11-21: YouTube works from o2switch and mhost, not from oracle-trial ("confirm you're not a bot");
TikTok and SoundCloud work from all three; Vimeo needs a login everywhere.

**Safety.** Only links to the sites in `SITES`, yt-dlp's generic extractor off, playlists and live streams refused,
no shell anywhere; the media is downloaded by Python and ffmpeg only reads that local file (`-protocol_whitelist file`;
HLS, the rare case, is https-only). One fetch at a time per server, 6 per address per 10 min, 400 per day. The
containers run as a non-root user, read-only, without capabilities, 1 CPU / 768 MB, port on 127.0.0.1 only, no logs.
o2switch cannot be sandboxed: there it is a lock, a 55 s limit and the same caps. The link is sent by POST and never
logged; the temporary file is deleted after the answer.

**yt-dlp stays current.**
- o2switch: `link.php` runs `pip install -U yt-dlp yt-dlp-ejs` at most once a day after answering (no cron: that
  account's crontab is managed elsewhere).
- oracle-trial: cron at 03:17 runs `update.sh`, which rebuilds the image when PyPI has a new yt-dlp or yt-dlp-ejs and
  restarts the container.
- mhost: the user timer `waaiya-link-update.timer` runs the same `update.sh` daily (mhost has no cron).

**Install or update** all three: `site/link/deploy_link.sh` (or name one: `o2`, `oracle`, `mhost`), then
`site/deploy.sh` for `link.php`. oracle-trial's main Caddyfile ends with `import /etc/caddy/conf.d/*.caddy`; any
other copy of that Caddyfile applied to the machine must keep that line, or this site disappears (and mhost with it,
since mhost is reached through oracle-trial). DNS: `link.waaiya.mssid.org` is an A record to oracle-trial.

**Turn it off:** empty `LINK_ENDPOINTS` and deploy the site; then `docker rm -f waaiya-link` on oracle-trial and
mhost, `systemctl --user disable --now waaiya-link-tunnel waaiya-link-update.timer` on mhost, and remove the cron
line (`# waaiya-link`) on oracle-trial.
