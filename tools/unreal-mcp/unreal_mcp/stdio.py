"""Local stdio MCP transport for Cursor / Codex (newline-delimited JSON-RPC).

Uses the existing Unreal_dev handlers directly. Does NOT require an HTTP bearer
token or expose a new TCP listener. All tools still enforce the workspace jail.
"""
from __future__ import annotations

import json
import sys
from typing import Any

from unreal_mcp import __version__
from unreal_mcp.server import SUPPORTED_PROTOCOL_VERSIONS, TOOL_DEFS, dispatch_tool


def handle_message(message: dict[str, Any]) -> dict[str, Any] | None:
    method = message.get("method")
    if "id" not in message:
        return None  # Notifications never have responses.
    req_id = message["id"]
    params = message.get("params") or {}
    try:
        if not isinstance(params, dict):
            raise ValueError("params must be an object")
        if method == "initialize":
            requested = str(params.get("protocolVersion", ""))
            version = (requested if requested in SUPPORTED_PROTOCOL_VERSIONS
                       else SUPPORTED_PROTOCOL_VERSIONS[-1])
            result = {"protocolVersion": version,
                      "capabilities": {"tools": {"listChanged": False}},
                      "serverInfo": {"name": "unreal-dev-context", "version": __version__}}
        elif method == "ping":
            result = {}
        elif method == "tools/list":
            result = {"tools": TOOL_DEFS}
        elif method == "tools/call":
            args = params.get("arguments") or {}
            if not isinstance(args, dict):
                raise ValueError("arguments must be an object")
            result = dispatch_tool(str(params.get("name", "")), args)
        else:
            return {"jsonrpc": "2.0", "id": req_id,
                    "error": {"code": -32601, "message": "method not found"}}
        return {"jsonrpc": "2.0", "id": req_id, "result": result}
    except (ValueError, TypeError) as exc:
        return {"jsonrpc": "2.0", "id": req_id,
                "error": {"code": -32602, "message": str(exc)}}


def main() -> None:
    # No print/logging to stdout: it is an MCP protocol channel.
    for raw in sys.stdin.buffer:
        if not raw.strip():
            continue
        if len(raw) > 2_000_000:
            continue
        try:
            req = json.loads(raw)
            if not isinstance(req, dict):
                continue
            reply = handle_message(req)
            if reply is not None:
                sys.stdout.buffer.write(
                    (json.dumps(reply, ensure_ascii=False, separators=(",", ":")) + "\n")
                    .encode("utf-8"))
                sys.stdout.buffer.flush()
        except (ValueError, UnicodeDecodeError) as exc:
            sys.stderr.write(f"Invalid MCP input: {type(exc).__name__}\n")


if __name__ == "__main__":
    main()
