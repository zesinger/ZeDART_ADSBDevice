#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import subprocess
import datetime
import json
import re

PORT = 8765
READSB_CONFIG = "/etc/default/readsb"


def update_readsb_receiver(lat, lon):
    with open(READSB_CONFIG, "r", encoding="utf-8") as f:
        text = f.read()

    if 'RECEIVER_OPTIONS="' not in text:
        raise RuntimeError("RECEIVER_OPTIONS not found")

    def repl(match):
        opts = match.group(1)
        opts = re.sub(r"\s--lat\s+\S+", "", opts)
        opts = re.sub(r"\s--lon\s+\S+", "", opts)
        opts = opts.strip() + f" --lat {lat:.6f} --lon {lon:.6f}"
        return f'RECEIVER_OPTIONS="{opts}"'

    text = re.sub(r'RECEIVER_OPTIONS="([^"]*)"', repl, text)

    with open(READSB_CONFIG, "w", encoding="utf-8") as f:
        f.write(text)

    subprocess.run(["/bin/systemctl", "restart", "readsb"], check=True)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/zedart/time":
            now = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + "Z"
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(now.encode("utf-8"))
            return

        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)

        if parsed.path == "/zedart/time":
            self.handle_time_post()
            return

        if parsed.path == "/zedart/receiver":
            self.handle_receiver_post()
            return

        self.send_response(404)
        self.end_headers()

    def handle_time_post(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8").strip()

        try:
            dt = datetime.datetime.fromisoformat(body.replace("Z", "+00:00"))
            utc = dt.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]
            subprocess.run(["/bin/date", "-u", "-s", utc], check=True)
        except Exception as ex:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(str(ex).encode("utf-8"))
            return

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

    def handle_receiver_post(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length).decode("utf-8").strip()

        try:
            data = json.loads(body)
            lat = float(data["lat"])
            lon = float(data["lon"])

            if not (-90.0 <= lat <= 90.0):
                raise ValueError("Invalid latitude")
            if not (-180.0 <= lon <= 180.0):
                raise ValueError("Invalid longitude")

            update_readsb_receiver(lat, lon)
        except Exception as ex:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(str(ex).encode("utf-8"))
            return

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

    def log_message(self, format, *args):
        return


HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
