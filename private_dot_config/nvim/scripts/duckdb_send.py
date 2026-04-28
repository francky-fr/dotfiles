#!/usr/bin/env python3
import sys
import json
import webbrowser
import duckdb

query = sys.stdin.read().strip()
if not query:
    sys.exit(0)

db_path  = sys.argv[1] if len(sys.argv) > 1 else ":memory:"
out_file = "/tmp/duckdb_result.html"

try:
    conn   = duckdb.connect(db_path)
    result = conn.execute(query).df()
    rows   = json.dumps(result.to_dict(orient="records"))
    cols   = json.dumps([
        {"field": c, "filter": True, "sortable": True, "resizable": True}
        for c in result.columns
    ])
    status  = f"{len(result)} ligne(s) · {len(result.columns)} colonne(s)"
    content = f"""
    <div class="meta">{status}</div>
    <div class="query"><code>{query}</code></div>
    <div id="grid" class="ag-theme-balham" style="height:85vh;width:100%;"></div>
    <script>
      agGrid.createGrid(document.getElementById('grid'), {{
        rowData: {rows},
        columnDefs: {cols},
        defaultColDef: {{ flex: 1, minWidth: 100, filter: true }},
      }});
    </script>
    """

except Exception as e:
    content = f'<div class="error"><h3>Erreur</h3><pre>{e}</pre><code>{query}</code></div>'
    status  = "Erreur"

html = f"""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>DuckDB result</title>
  <script src="https://cdn.jsdelivr.net/npm/ag-grid-community/dist/ag-grid-community.min.js"></script>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ font-family: sans-serif; padding: 1rem; background: #f8f9fa;
            display: flex; flex-direction: column; height: 100vh; gap: .75rem; }}
    .meta  {{ color: #888; font-size: .8rem; }}
    .query {{ background: #1e1e2e; color: #cdd6f4; padding: .75rem 1rem;
              border-radius: 6px; font-family: monospace; font-size: .8rem;
              white-space: pre-wrap; }}
    .error pre {{ background: #fee; padding: 1rem; border-radius: 6px; color: #c00; }}
  </style>
</head>
<body>
  {content}
</body>
</html>"""

with open(out_file, "w", encoding="utf-8") as f:
    f.write(html)

# Utilise le navigateur par défaut du système
webbrowser.open(f"file://{out_file}")
