# Security policy

Report vulnerabilities privately with GitHub's **"Report a vulnerability"** button (Security tab → Advisories).
Please do not open a public issue for them. You will get an answer within a week.

In scope, for example:

- a way for the filter to play unfiltered sound when it should be silent (fail-open);
- anything that lets a web page, a link or a downloaded file run code in the app, including the link feature
  (yt-dlp, QuickJS) and its self-update;
- leaks of audio, links or files to anyone other than the site the user opened.

The yt-dlp self-update (`android/app/src/main/python/im_update.py`) downloads code, so its rules are:

- PyPI only, over HTTPS; pure-Python wheels from files.pythonhosted.org, checked against the SHA-256 that PyPI
  publishes; not yanked; size capped; zip paths checked; only the `yt_dlp` and `yt_dlp_ejs` packages unpacked.
- Stable releases only, and only once the wheel has been on PyPI for 3 days. The newest release that old is
  taken. Nightly builds are considered only after a link fails, and only once they are 1 day old. The pinned
  yt-dlp-ejs wheel gets the same wait as the yt-dlp release that pins it. A missing upload time means no update.
- A new copy goes live only after it imports and reports the expected version; otherwise it is deleted.
- Requests use Python's default User-Agent, so they do not name the app.

Supported versions: the latest release.
