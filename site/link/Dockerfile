# Waaiya's link fetcher for oracle-trial (arm64) and mhost (x86_64). Rebuilt every day by update.sh so yt-dlp
# stays current; run only through run.sh (no root, read-only, no capabilities, CPU/memory caps, local port only).
FROM python:3.12-slim
ARG TARGETARCH
ARG QJS_VERSION=v0.18.0
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg curl ca-certificates \
 && case "$TARGETARCH" in \
      amd64) a=x86_64;  sum=85ded23b9fabe8c1644fc40a8d2bbdd71157affcbd807359c618cc717ee24d7d ;; \
      arm64) a=aarch64; sum=2c005c7171424a598d31c53c8dc4a0ae2e4958eb6fbb37908c885a307c78187c ;; \
      *) echo "unsupported arch $TARGETARCH"; exit 1 ;; esac \
 && curl -fsSL -o /usr/local/bin/qjs "https://github.com/quickjs-ng/quickjs/releases/download/$QJS_VERSION/qjs-linux-$a" \
 && echo "$sum  /usr/local/bin/qjs" | sha256sum -c - && chmod 755 /usr/local/bin/qjs \
 && apt-get purge -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# Latest yt-dlp and its YouTube challenge scripts. update.sh passes the versions PyPI has now, so this layer is
# rebuilt exactly when a new release is out.
ARG YTDLP_STAMP=none
RUN echo "$YTDLP_STAMP" && pip install --no-cache-dir --root-user-action=ignore -U yt-dlp yt-dlp-ejs
COPY waaiya_link.py server.py /app/
RUN useradd -r -u 10001 -d /tmp waaiya
USER waaiya
ENV WAAIYA_QJS=/usr/local/bin/qjs HOME=/tmp PYTHONDONTWRITEBYTECODE=1
EXPOSE 8790
CMD ["python", "/app/server.py"]
