"""Forward test traffic to PBS and expose aggregate auction evidence."""

import json
import os
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener


UPSTREAM = os.environ.get("PBS_UPSTREAM", "http://pbs:8000")
DSP_UPSTREAM = "http://dsp:9800"
EXPECTED_CRID = os.environ.get("PBS_EXPECTED_CRID", "pbs-test-creative")
EXPECTED_SEAT = os.environ.get("PBS_EXPECTED_SEAT", "pubmatic")


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


opener = build_opener(NoRedirect)
lock = threading.Lock()
metrics = {"auctions": 0, "matching": 0, "bid_found": 0, "config_fetches": 0, "landing_hits": 0, "ready": 0, "last_status": None, "last_request_targeting": None, "last_bid_targeting": None}
cached_bids = {}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if urlsplit(self.path).path == "/cache":
            cache_id = parse_qs(urlsplit(self.path).query).get("uuid", [None])[0]
            with lock:
                cached = cached_bids.get(cache_id)
            if cached and cached[2] > time.time():
                self.respond(200, cached[0], cached[1])
            else:
                self.respond(404, b"not found", "text/plain")
            return
        if urlsplit(self.path).path == "/static/e2e-config.json":
            with open("/app/sdk-config.json", "rb") as config_file:
                config = config_file.read()
            with lock:
                metrics["config_fetches"] += 1
            self.respond(200, config, "application/json")
            return
        if urlsplit(self.path).path == "/__e2e/landing":
            with lock:
                metrics["landing_hits"] += 1
            self.respond(200, b"<html><body style='background:#0f8e58;color:white;font:24px sans-serif'><h1>PBS test landing page</h1></body></html>", "text/html; charset=utf-8")
            return
        if self.path == "/__e2e/metrics":
            with lock:
                self.respond(200, json.dumps(metrics).encode(), "application/json")
            return
        self.forward()

    def do_POST(self):
        if self.path == "/__e2e/ready":
            with lock:
                metrics["ready"] += 1
            self.respond(200, b"ok", "text/plain")
            return
        if urlsplit(self.path).path == "/cache":
            self.store_bids()
            return
        if self.path == "/__e2e/reset":
            with lock:
                metrics.update(auctions=0, matching=0, bid_found=0, config_fetches=0, landing_hits=0, ready=0, last_status=None, last_request_targeting=None, last_bid_targeting=None)
            self.respond(200, b"ok", "text/plain")
            return
        self.forward()

    def store_bids(self):
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if size <= 0 or size > 1_000_000:
                raise ValueError("invalid body size")
            puts = json.loads(self.rfile.read(size))["puts"]
            if not isinstance(puts, list) or not puts:
                raise ValueError("puts must be a nonempty list")
            responses = []
            for item in puts:
                kind = item["type"]
                if kind not in ("json", "xml"):
                    raise ValueError("unsupported cache type")
                value = item["value"]
                body = value.encode() if isinstance(value, str) else json.dumps(value).encode()
                if not body:
                    raise ValueError("empty cache value")
                cache_id = str(uuid.uuid4())
                expiry = time.time() + int(item.get("ttlseconds", 300))
                with lock:
                    cached_bids[cache_id] = (body, "application/json" if kind == "json" else "application/xml", expiry)
                responses.append({"uuid": cache_id})
            self.respond(200, json.dumps({"responses": responses}).encode(), "application/json")
        except (KeyError, TypeError, ValueError, json.JSONDecodeError):
            self.respond(400, b"invalid cache request", "text/plain")

    def forward(self):
        path = urlsplit(self.path).path
        size = int(self.headers.get("Content-Length", "0"))
        if size > 1_000_000:
            self.respond(413, b"request too large", "text/plain")
            return
        request_body = self.rfile.read(size) if size else b""
        headers = {"Content-Type": self.headers.get("Content-Type", "application/json")}
        if self.headers.get("User-Agent"):
            headers["User-Agent"] = self.headers["User-Agent"]
        upstream_url = DSP_UPSTREAM if path.startswith("/prebid/") else UPSTREAM
        request = Request(
            upstream_url + self.path,
            data=request_body if self.command == "POST" else None,
            headers=headers,
            method=self.command,
        )
        try:
            with opener.open(request, timeout=15) as upstream:
                status = upstream.status
                body = upstream.read()
                content_type = upstream.headers.get("Content-Type", "application/octet-stream")
                location = upstream.headers.get("Location")
        except HTTPError as error:
            status = error.code
            body = error.read()
            content_type = error.headers.get("Content-Type", "text/plain")
            location = error.headers.get("Location")
        except URLError as error:
            self.respond(502, str(error).encode(), "text/plain")
            return

        with lock:
            if self.command == "POST" and path == "/openrtb2/auction":
                metrics["auctions"] += 1
                metrics["last_status"] = status
                try:
                    auction = json.loads(request_body)
                    response = json.loads(body)
                    metrics["last_request_targeting"] = auction.get("ext", {}).get("prebid", {}).get("targeting")
                    metrics["last_bid_targeting"] = next((bid.get("ext", {}).get("prebid", {}).get("targeting") for seat in response.get("seatbid", []) for bid in seat.get("bid", [])), None)
                    matching = any(
                        imp.get("ext", {}).get("prebid", {}).get("storedrequest", {}).get("id")
                        == "test-imp-id"
                        for imp in auction.get("imp", [])
                    )
                    if matching:
                        metrics["matching"] += 1
                        if any(
                            bid.get("crid") == EXPECTED_CRID
                            for seat in response.get("seatbid", [])
                            if seat.get("seat") == EXPECTED_SEAT
                            for bid in seat.get("bid", [])
                        ):
                            metrics["bid_found"] += 1
                except (TypeError, ValueError, AttributeError):
                    pass
        self.respond(status, body, content_type, location)

    def respond(self, status, body, content_type, location=None):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        if location:
            self.send_header("Location", location)
        self.end_headers()
        self.wfile.write(body)


ThreadingHTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
