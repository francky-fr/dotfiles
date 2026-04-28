#!/usr/bin/env python3
import sys
import os
import json
import logging
import subprocess
import time
import urllib.request
import fcntl
import duckdb

logging.basicConfig(
    filename="/tmp/duckdb_send.log",
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(message)s"
)

query = sys.stdin.read().strip()
if not query:
    sys.exit(0)

db_path   = sys.argv[1] if len(sys.argv) > 1 else ":memory:"
out_file  = "/tmp/duckdb_result.html"
json_file = "/tmp/duckdb_result.json"
lock_file = "/tmp/duckdb_server.lock"
port      = 8765

try:
    conn   = duckdb.connect(db_path)
    result = conn.execute(query).df()
    rows   = result.to_dict(orient="records")
    cols   = [
        {"field": c, "filter": True, "sortable": True, "resizable": True}
        for c in result.columns
    ]
    status  = f"{len(result)} ligne(s) · {len(result.columns)} colonne(s)"
    error   = None

except Exception as e:
    logging.error(f"DuckDB error: {e}")
    print(f"ERREUR DuckDB: {e}", file=sys.stderr)
    rows   = []
    cols   = []
    error  = str(e)
    status = "Erreur"

# Écrit le JSON (pollé par le JS)
ts = str(int(time.time()))
with open(json_file, "w") as f:
    json.dump({
        "ts":     ts,
        "rows":   rows,
        "cols":   cols,
        "status": status,
        "query":  query,
        "error":  error,
    }, f)

# Écrit le HTML une seule fois
if not os.path.exists(out_file):
    html = """<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>DuckDB result</title>
  <script src="https://cdn.jsdelivr.net/npm/ag-grid-community/dist/ag-grid-community.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: sans-serif; padding: 1rem; background: #f8f9fa;
           display: flex; flex-direction: column; height: 100vh; gap: .75rem; }
    .meta  { color: #888; font-size: .8rem; }
    .query { background: #1e1e2e; color: #cdd6f4; padding: .75rem 1rem;
             border-radius: 6px; font-family: monospace; font-size: .8rem;
             white-space: pre-wrap; }
    .error { background: #fee; padding: 1rem; border-radius: 6px; color: #c00; }
  </style>
</head>
<body>
  <div id="status" class="meta">Chargement…</div>
  <div id="query" class="query"></div>
  <div id="grid" class="ag-theme-balham" style="height:80vh;width:100%;"></div>
  <div id="error" class="error" style="display:none"></div>

  <script>
    let grid = null;
    let currentTs = null;

    async function fetchData() {
      try {
        const r = await fetch("/duckdb_result.json?_=" + Date.now());
        const d = await r.json();

        if (d.ts === currentTs) return;
        currentTs = d.ts;

        document.getElementById("status").textContent = d.status;
        document.getElementById("query").textContent  = d.query;

        if (d.error) {
          document.getElementById("error").style.display = "block";
          document.getElementById("error").textContent   = d.error;
          document.getElementById("grid").style.display  = "none";
          return;
        }

        document.getElementById("error").style.display = "none";
        document.getElementById("grid").style.display  = "block";

        if (!grid) {
          grid = agGrid.createGrid(document.getElementById("grid"), {
            rowData:    d.rows,
            columnDefs: d.cols,
            defaultColDef: { flex: 1, minWidth: 100, filter: true },
          });
        } else {
          grid.setGridOption("rowData",    d.rows);
          grid.setGridOption("columnDefs", d.cols);
        }
      } catch(e) {
        // serveur temporairement indisponible
      }
    }

    fetchData();
    setInterval(fetchData, 1000);
  </script>
</body>
</html>"""

    with open(out_file, "w", encoding="utf-8") as f:
        f.write(html)

# --- Serveur HTTP ---

server_script = f"""
import http.server, socketserver, os

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ping":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"pong")
        elif self.path.startswith("/duckdb_result.json"):
            try:
                with open("/tmp/duckdb_result.json", "rb") as f:
                    data = f.read()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                self.wfile.write(data)
            except Exception:
                self.send_response(500)
                self.end_headers()
        else:
            super().do_GET()
    def log_message(self, *a):
        pass

os.chdir("/tmp")
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", {port}), Handler) as httpd:
    httpd.serve_forever()
"""

def server_is_ours(p):
    try:
        with urllib.request.urlopen(f"http://127.0.0.1:{p}/ping", timeout=1) as r:
            return r.read().strip() == b"pong"
    except Exception:
        return False

def ensure_server_running(p):
    with open(lock_file, "w") as lf:
        try:
            fcntl.flock(lf, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            # Un autre process gère déjà le lancement, on attend
            logging.debug("Lock pris par un autre process, attente...")
            for _ in range(60):
                if server_is_ours(p):
                    return True
                time.sleep(0.1)
            return False

        if server_is_ours(p):
            logging.debug("Serveur OK")
            return True

        logging.debug(f"Serveur absent, lancement sur port {p}")
        subprocess.Popen(
            ["uv", "run", "python3", "-c", server_script],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
            cwd="/tmp",
        )
        for _ in range(60):
            if server_is_ours(p):
                logging.debug("Serveur OK")
                return True
            time.sleep(0.1)

        logging.error("Serveur HTTP n'a pas démarré dans les temps")
        print("ERREUR: serveur HTTP impossible à démarrer", file=sys.stderr)
        return False

if not ensure_server_running(port):
    sys.exit(1)

print(f"REMOTE:http://localhost:{port}/duckdb_result.html", flush=True)
