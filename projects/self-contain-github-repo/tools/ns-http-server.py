#!/usr/bin/env python3
"""Namespace-aware git smart-HTTP server (demo).

Serves ONE bare repository at many URLs:

    http://host:port/<repo>.git                -> default refs (refs/heads/*)
    http://host:port/~<ns>/<repo>.git          -> GIT_NAMESPACE=<ns>

<ns> may be hierarchical (a/b/c), which git stores as
refs/namespaces/a/refs/namespaces/b/refs/namespaces/c/.

This is exactly the deployment gitnamespaces(7) documents for
git-http-backend; it is ~80 lines because git does all the work.
"""
import os, re, subprocess, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.environ.get("REPO_ROOT", "/tmp/mono/server")
BACKEND = subprocess.run(["git", "--exec-path"], capture_output=True, text=True
                         ).stdout.strip() + "/git-http-backend"

# /~<namespace>/<repo>.git/<path>   (namespace may contain slashes)
NS_RE = re.compile(r"^/~(?P<ns>.+?)/(?P<rest>[^/]+\.git/.*)$")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _run(self, body=b""):
        path = self.path.split("?", 1)[0]
        query = self.path.split("?", 1)[1] if "?" in self.path else ""
        m = NS_RE.match(path)
        ns = ""
        if m:
            ns, path = m.group("ns"), "/" + m.group("rest")

        env = dict(os.environ)
        env.update(
            GIT_PROJECT_ROOT=ROOT,
            GIT_HTTP_EXPORT_ALL="1",
            PATH_INFO=path,
            QUERY_STRING=query,
            REQUEST_METHOD=self.command,
            CONTENT_TYPE=self.headers.get("Content-Type", ""),
            CONTENT_LENGTH=str(len(body)),
            REMOTE_USER="demo",
            REMOTE_ADDR=self.client_address[0],
            # the whole point:
            GIT_NAMESPACE=ns,
        )
        proto = self.headers.get("Git-Protocol")
        if proto:
            env["HTTP_GIT_PROTOCOL"] = proto

        p = subprocess.run([BACKEND], input=body, env=env, capture_output=True)
        head, _, payload = p.stdout.partition(b"\r\n\r\n")
        status, headers = 200, []
        for line in head.decode("latin-1").splitlines():
            if not line.strip():
                continue
            k, _, v = line.partition(":")
            if k.strip().lower() == "status":
                status = int(v.strip().split()[0])
            else:
                headers.append((k.strip(), v.strip()))
        self.send_response(status)
        for k, v in headers:
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        self._run()

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        self._run(self.rfile.read(n))

    def log_message(self, *a):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8178
    print(f"serving {ROOT} on :{port}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
