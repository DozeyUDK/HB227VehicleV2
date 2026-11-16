"""Protocol metadata and context-tool dispatch for the alpha."""
from __future__ import annotations

import json
from typing import Any

from unreal_mcp.config import Settings
from unreal_mcp.tools import context_ops

SUPPORTED_PROTOCOL_VERSIONS = ("2024-11-05", "2025-03-26", "2025-06-18")

TOOL_DEFS: list[dict[str, Any]] = [
    {
        "name": "unreal.task_context",
        "description": "Compact, task-focused file outlines and x86/x64 package fingerprints. Topics: vehicle, camera, suspension, bridge, gates. Prefer before reading large files.",
        "inputSchema": {"type": "object", "properties": {
            "topic": {"type": "string", "enum": ["vehicle", "camera", "suspension", "bridge", "gates"], "default": "vehicle"}
        }},
    },
    {
        "name": "unreal.outline",
        "description": "Return names, signatures and line numbers of functions/classes without returning their bodies.",
        "inputSchema": {"type": "object", "properties": {
            "path": {"type": "string"}, "match": {"type": "string"},
            "max_symbols": {"type": "integer", "default": 65}
        }, "required": ["path"]},
    },
    {
        "name": "unreal.excerpt",
        "description": "Read only 1..70 numbered source lines, not the whole UnrealScript/C file.",
        "inputSchema": {"type": "object", "properties": {
            "path": {"type": "string"}, "start_line": {"type": "integer", "minimum": 1},
            "max_lines": {"type": "integer", "default": 30}
        }, "required": ["path", "start_line"]},
    },
    {
        "name": "unreal.search_code",
        "description": "Case-insensitive literal search in allowlisted source files with short bounded per-line matches; narrow root for fewer tokens.",
        "inputSchema": {"type": "object", "properties": {
            "query": {"type": "string"}, "root": {"type": "string", "default": "HB227VehicleV2"},
            "max_hits": {"type": "integer", "default": 30},
            "max_files": {"type": "integer", "default": 300}
        }, "required": ["query"]},
    },
    {
        "name": "unreal.log_digest",
        "description": "Read a compact digest of runtime PASS/FAIL/gates/errors, or filter latest log by literal substring. No megabyte log dump.",
        "inputSchema": {"type": "object", "properties": {
            "path": {"type": "string"}, "contains": {"type": "string"},
            "architecture": {"type": "string", "enum": ["x86", "x64"], "default": "x64"},
            "max_events": {"type": "integer", "default": 35}
        }},
    },
    {
        "name": "unreal.map_summary",
        "description": "Read-only .t3d actor/brush summary, or .unr binary file metadata (UnrealEd export needed for actors).",
        "inputSchema": {"type": "object", "properties": {
            "path": {"type": "string", "default": "Maps/SpireVillage.unr"},
            "max_actors": {"type": "integer", "default": 18}
        }},
    },
]

HANDLERS = {
    "unreal.task_context": context_ops.task_context,
    "unreal.outline": context_ops.outline,
    "unreal.excerpt": context_ops.excerpt,
    "unreal.search_code": context_ops.search_code,
    "unreal.log_digest": context_ops.log_digest,
    "unreal.map_summary": context_ops.map_summary,
}


def dispatch_tool(name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    try:
        if name not in HANDLERS:
            raise ValueError(f"Unknown tool: {name}")
        definition = next(d for d in TOOL_DEFS if d["name"] == name)
        allowed = definition["inputSchema"]["properties"]
        types = {"integer": int, "string": str}
        for key, value in arguments.items():
            if key not in allowed:
                raise ValueError(f"Unknown argument: {key}")
            expected = allowed[key]["type"]
            if type(value) is not types[expected]:
                raise ValueError(f"{key} must be a {expected}")
        result = HANDLERS[name](Settings(), **arguments)
        return {"content": [{"type": "text", "text": json.dumps(result, ensure_ascii=False)}]}
    except (ValueError, TypeError, OSError) as exc:
        return {"isError": True, "content": [{"type": "text", "text": str(exc)}]}
