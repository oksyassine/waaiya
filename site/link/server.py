"""HTTP front for waaiya_link.py inside the locked-down container (oracle-trial, mhost); see README.md.

POST /  (form field "url") -> 200 audio/mp4 with X-Waaiya-Meta (JSON), or JSON {"error": code} with
400 (the page stops: invalid_url, unsupported_site, playlist, live, no_format) or 503 (the page tries the next
server: bot, limited, login, timeout, failed, busy, quota). One fetch at a time; per-address and daily caps.
The link itself is never logged.
"""
import json
import os
import subprocess
import sys
import tempfile
import threading
import time
from collections import defaultdict, deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs

ORIGINS = {"https://waaiya.mssid.org"}
STOP = {"invalid_url", "unsupported_site", "playlist", "live", "no_format"}
PER_IP, PER_IP_WINDOW = 6, 600     # fetches per address per 10 minutes
PER_DAY = 400                      # fetches per day on this server
HERE = os.path.dirname(os.path.abspath(__file__))
busy = threading.Lock()
seen = defaultdict(deque)
day = {"d": "", "n": 0}
guard = threading.Lock()


def allow(ip):
    now = time.time()
    with guard:
        today = time.strftime("%Y-%m-%d")
        if day["d"] != today:
            day.update(d=today, n=0)
        if day["n"] >= PER_DAY:
            return False
        q = seen[ip]
        while q and q[0] < now - PER_IP_WINDOW:
            q.popleft()
        if len(q) >= PER_IP:
            return False
        q.append(now)
        day["n"] += 1
        return True


class H(BaseHTTPRequestHandler):
    server_version = "waaiya-link"
    sys_version = ""

    def log_message(self, *a):  # no request lines: they would carry nothing useful, and never the link
        pass

    def cors(self):
        o = self.headers.get("Origin")
        if o in ORIGINS:
            self.send_header("Access-Control-Allow-Origin", o)
            self.send_header("Vary", "Origin")
            self.send_header("Access-Control-Expose-Headers", "X-Waaiya-Meta")

    def fail(self, code):
        body = json.dumps({"error": code}).encode()
        self.send_response(400 if code in STOP else 503)
        self.cors()
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.cors()
        self.send_header("Access-Control-Allow-Methods", "POST")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Max-Age", "86400")
        self.end_headers()

    def do_GET(self):  # health check for the deploy script
        self.send_response(204)
        self.end_headers()

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        if n <= 0 or n > 4096:
            return self.fail("invalid_url")
        url = (parse_qs(self.rfile.read(n).decode("utf-8", "replace")).get("url") or [""])[0]
        ip = (self.headers.get("X-Forwarded-For") or self.client_address[0]).split(",")[0].strip()
        if not allow(ip):
            return self.fail("quota")
        if not busy.acquire(blocking=False):
            return self.fail("busy")
        out = tempfile.mktemp(suffix=".m4a", dir="/tmp")
        try:
            try:
                r = subprocess.run([sys.executable, os.path.join(HERE, "waaiya_link.py"), url, out],
                                   capture_output=True, timeout=80)
                res = json.loads(r.stdout.decode().strip().splitlines()[-1])
            except subprocess.TimeoutExpired:
                res = {"ok": False, "error": "timeout"}
            except Exception:
                res = {"ok": False, "error": "failed"}
            if not res.get("ok"):
                return self.fail(res.get("error") or "failed")
            with open(out, "rb") as f:
                data = f.read()
            res.pop("ok", None)
            self.send_response(200)
            self.cors()
            self.send_header("Content-Type", "audio/mp4")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Waaiya-Meta", json.dumps(res))  # ASCII: json.dumps escapes the title
            self.end_headers()
            self.wfile.write(data)
        finally:
            busy.release()
            if os.path.exists(out):
                os.unlink(out)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8790"))), H).serve_forever()
