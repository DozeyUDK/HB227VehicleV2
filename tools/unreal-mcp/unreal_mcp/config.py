"""Workspace settings for the bundled MCP server."""
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    # tools/unreal-mcp/unreal_mcp/config.py -> repository root
    workspace: Path = Path(__file__).resolve().parents[3]
