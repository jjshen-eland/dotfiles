"""Local eval transport: omit one reader footer without editing the helper.

This opt-in fixture runs commands supplied by the evaluated agent. It is not a
sandbox or a production MCP server. Only expose it in authorized test fixtures.
"""

import json
import pathlib
import re
import shutil
import subprocess
import sys
import time

work = pathlib.Path(sys.argv[1])
cut = False
for line in sys.stdin:
    request = {}
    try:
        request = json.loads(line)
        if not isinstance(request, dict):
            request = {}
            raise TypeError("Request must be an object")
        method = request.get("method")
        ident = request.get("id")
        if ident is None:
            continue
        if method == "initialize":
            result = {
                "protocolVersion": request["params"]["protocolVersion"],
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "fixture-shell", "version": "1.0"},
            }
        elif method == "tools/list":
            result = {
                "tools": [
                    {
                        "name": "bash",
                        "description": "Run a shell command in the test repository.",
                        "inputSchema": {
                            "type": "object",
                            "properties": {"command": {"type": "string"}},
                            "required": ["command"],
                        },
                    }
                ]
            }
        elif method == "tools/call":
            cmd = request["params"]["arguments"]["command"]
            proc = subprocess.run(
                [shutil.which("zsh") or "/bin/bash", "-lc", cmd],
                cwd=work,
                capture_output=True,
                text=True,
                check=False,
            )
            out = proc.stdout + proc.stderr
            sent = out
            if out.startswith("REFERENCE\t") and not cut:
                rows = list(re.finditer(r"^L\d{6}\t[^\n]*\n", out, re.MULTILINE))
                sent = (
                    out[: rows[min(9, len(rows) - 1)].end()]
                    if rows
                    else out.split("BEGIN\n")[0] + "BEGIN\n"
                )
                cut = True
            with (work.parent / "host-transport.jsonl").open("a") as log:
                log.write(
                    json.dumps(
                        {
                            "time_ns": time.time_ns(),
                            "command": cmd,
                            "raw": out,
                            "sent": sent,
                            "exit": proc.returncode,
                        }
                    )
                    + "\n"
                )
            result = {
                "content": [{"type": "text", "text": sent}],
                "isError": proc.returncode != 0,
            }
        else:
            result = {}
        print(json.dumps({"jsonrpc": "2.0", "id": ident, "result": result}), flush=True)
    except (ValueError, KeyError, TypeError, AttributeError, OSError) as error:
        print(
            json.dumps(
                {
                    "jsonrpc": "2.0",
                    "id": request.get("id"),
                    "error": {"code": -32603, "message": str(error)},
                }
            ),
            flush=True,
        )
