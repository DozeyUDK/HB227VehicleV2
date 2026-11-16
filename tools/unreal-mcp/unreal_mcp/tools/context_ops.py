"""Bounded UnrealScript / native / UnrealEd context tools.

Read-only, scoped to this checkout. Intentional small responses
for coding agents; never scans package binaries or blindly returns whole logs.
"""
from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import os
import re

from unreal_mcp.config import Settings
from unreal_mcp.security import PathValidationError, resolve_workspace_path

SOURCE_EXTS = {".uc", ".c", ".cpp", ".h", ".hpp", ".ps1", ".cmd", ".md"}
OUTLINE_EXTS = {".uc", ".c", ".cpp", ".h", ".hpp"}
SKIP_NAMES = {".git", ".venv", ".venv312", "venv", "node_modules", "__pycache__",
              ".pytest_cache", "build", "intermediate", "saved", ".cursor", ".vs"}
HEAD_RE = re.compile(
    r"^\s*(?:(?:simulated|static|native|final|singular|exec|event|private|protected|"
    r"public|intrinsic|iterator|latent|reliable|unreliable|const|inline|virtual|"
    r"override)\s+)*(?:function|event)\s+"
    r"(?:(?:bool|byte|int|float|string|vector|rotator|name|actor|void|"
    r"[A-Za-z_]\w*(?:<[^>]+>)?)\s+)?([A-Za-z_]\w*)\s*\("
    r"|^\s*(?:class|struct|enum|state)\s+([A-Za-z_]\w*)"
    r"|^\s*(?:static\s+)?(?:int|void|float|double|unsigned\s+int)\s+"
    r"(HBV3_[A-Za-z_]\w*)\s*\(", re.IGNORECASE
)
ERROR_RE = re.compile(
    r"\b(error|fatal|critical|assert|exception|traceback|"
    r"fail(?:ed|ure)?|FAIL_\w+|GATE_\w+|PASS_\w+|NOT_IMPLEMENTED)\b", re.IGNORECASE
)
VALID_TASKS = {
    "vehicle": [
        "HB227VehicleV2/Classes/HB2Body.uc",
        "HB227VehicleV2/Classes/HB2WorldQuery.uc",
        "HB227NativeBridge/Inc/HBVehicleCore3D.h",
        "HB227NativeBridge/Src/HBVehicleCore3D.c",
    ],
    "camera": [
        "HB227VehicleV2/Classes/HB2Driver.uc",
        "HB227VehicleV2/Classes/HB2Input.uc",
    ],
    "suspension": [
        "HB227VehicleV2/Classes/HB2Body.uc",
        "HB227NativeBridge/Src/HBVehicleCore3D.c",
        "HB227NativeBridge/Inc/HBVehicleCore3D.h",
    ],
    "bridge": [
        "HB227NativeBridge/Classes/HBVehicleBridge3D.uc",
        "HB227NativeBridge/Src/HB227NativeBridgeMain.cpp",
        "HB227NativeBridge/Inc/HBVehicleCore3D.h",
    ],
    "gates": [
        "HB227VehicleV2/Classes/HB2TestGame.uc",
    ],
}

def _target(s: Settings, path: str, *, suffixes: set[str] | None = None) -> Path:
    p = resolve_workspace_path(s.workspace, path)
    if not p.is_file():
        raise PathValidationError("not a file")
    if suffixes and p.suffix.lower() not in suffixes:
        raise PathValidationError("unsupported file type for this tool")
    return p

def _relative(s: Settings, p: Path) -> str:
    return p.relative_to(s.workspace).as_posix()

def _read_lines(p: Path, max_size: int = 1_000_000) -> list[str]:
    if p.stat().st_size > max_size:
        raise PathValidationError("source exceeds size limit; choose a smaller input file")
    return p.read_text(encoding="utf-8-sig", errors="replace").splitlines()

def _is_junction(p: Path) -> bool:
    return bool(getattr(p, "is_junction", lambda: False)())

def _source_paths(s: Settings, root: str, max_files: int = 700):
    base = resolve_workspace_path(s.workspace, root)
    if not base.is_dir():
        raise PathValidationError("search root must be directory")
    seen = 0
    for folder, dirs, files in os.walk(base):
        # Prune symlinks/junctions even when they resolve within workspace.
        dirs[:] = sorted(d for d in dirs if d.lower() not in SKIP_NAMES
                         and not (Path(folder) / d).is_symlink()
                         and not _is_junction(Path(folder) / d))
        for name in sorted(files):
            p = Path(folder) / name
            if p.suffix.lower() not in SOURCE_EXTS or p.is_symlink():
                continue
            try:
                _target(s, str(p))
            except PathValidationError:
                continue
            seen += 1
            if seen > max_files:
                return
            yield p

def outline(s: Settings, path: str, match: str = "", max_symbols: int = 65) -> dict:
    p = _target(s, path, suffixes=OUTLINE_EXTS)
    lines = _read_lines(p)
    needle = match.casefold().strip()[:120]
    hits = []
    for i, line in enumerate(lines, 1):
        m = HEAD_RE.search(line)
        if not m:
            continue
        sym = next((g for g in m.groups() if g), "")
        if needle and needle not in sym.casefold():
            continue
        hits.append({"line": i, "symbol": sym, "signature": line.strip()[:170]})
        if len(hits) >= min(150, max(1, max_symbols)):
            break
    return {"file": _relative(s, p), "lines": len(lines),
            "symbols": hits, "limited": len(hits) >= min(150, max(1, max_symbols))}

def excerpt(s: Settings, path: str, start_line: int, max_lines: int = 30) -> dict:
    p = _target(s, path, suffixes=SOURCE_EXTS | {".t3d", ".log", ".txt"})
    if p.suffix.lower() == ".log":
        raise PathValidationError("use unreal.log_digest for log files")
    lines = _read_lines(p)
    begin = max(0, min(len(lines), int(start_line) - 1))
    length = max(1, min(70, int(max_lines)))
    return {"file": _relative(s, p), "total_lines": len(lines),
            "start_line": begin + 1,
            "lines": [{"n": i + 1, "text": lines[i][:250]}
                      for i in range(begin, min(len(lines), begin + length))]}

def search_code(s: Settings, query: str, root: str = "HB227VehicleV2",
                max_hits: int = 30, max_files: int = 300) -> dict:
    if not (2 <= len(query.strip()) <= 100):
        raise PathValidationError("query length must be 2..100")
    needle = query.casefold()
    hit_cap = max(1, min(int(max_hits), 60))
    file_cap = max(1, min(int(max_files), 700))
    hits = []
    scanned = 0
    for p in _source_paths(s, root, max_files=file_cap):
        scanned += 1
        if p.stat().st_size > 600_000:
            continue
        lines = _read_lines(p)
        for i, line in enumerate(lines, 1):
            if needle in line.casefold():
                hits.append({"path": _relative(s, p), "line": i,
                             "text": line.strip()[:180]})
                if len(hits) >= hit_cap:
                    return {"query": query, "root": root, "scanned_files": scanned,
                            "hits": hits, "truncated": True}
    return {"query": query, "root": root, "scanned_files": scanned,
            "hits": hits, "truncated": scanned >= file_cap}

def _tail_lines(p: Path, max_bytes: int = 800_000) -> list[str]:
    with p.open("rb") as f:
        f.seek(0, os.SEEK_END)
        size = f.tell()
        f.seek(max(0, size - max_bytes))
        b = f.read(max_bytes)
    if size > max_bytes:
        b = b.partition(b"\n")[2]  # first line possibly incomplete
    return b.decode("utf-8-sig", errors="replace").splitlines()

def log_digest(s: Settings, path: str = "", contains: str = "",
               max_events: int = 35, architecture: str = "x64") -> dict:
    if architecture not in ("x64", "x86"):
        raise PathValidationError("architecture must be x86 or x64")
    folder = s.workspace / ("System64" if architecture == "x64" else "System")
    if path:
        p = _target(s, path, suffixes={".log"})
        if p.parent not in (folder, s.workspace / "logs"):
            raise PathValidationError("log path must be in the selected System folder or logs")
    else:
        folder = resolve_workspace_path(s.workspace, str(folder))
        candidates = []
        for candidate in folder.glob("*.log"):
            if not candidate.name.lower().startswith(("hb2", "p06_")):
                continue
            try:
                candidates.append(_target(s, str(candidate), suffixes={".log"}))
            except PathValidationError:
                continue
        if not candidates:
            return {"found": False, "reason": "no matching runtime log", "arch": architecture}
        p = max(candidates, key=lambda f: f.stat().st_mtime)
    cap = max(1, min(int(max_events), 70))
    key = contains.casefold().strip()[:120]
    lines = _tail_lines(p)
    events = [(i + 1, line.strip()[:330]) for i, line in enumerate(lines)
              if (key in line.casefold() if key else ERROR_RE.search(line))]
    # Always show latest relevant markers, not thousands of HB2_STATE entries.
    selected = events[-cap:]
    gates = [v for _, v in events if "GATE_DONE" in v or "GATE_STATIONARY" in v]
    errors = [v for _, v in events if re.search(r"\bFAIL_\w+\b|\b(?:Fatal|Critical|Error)\b", v, re.I)]
    return {
        "found": True, "file": _relative(s, p), "bytes": p.stat().st_size,
        "matched_events": len(events), "events": [{"tail_line": i, "text": v}
                                                 for i, v in selected],
        "last_gate": gates[-1] if gates else None,
        "last_error": errors[-1] if errors else None,
        "truncated": len(events) > len(selected),
        "tail_window_bytes": 800_000,
    }

def map_summary(s: Settings, path: str = "Maps/SpireVillage.unr",
                max_actors: int = 18) -> dict:
    p = _target(s, path, suffixes={".unr", ".t3d"})
    out = {"file": _relative(s, p), "size_bytes": p.stat().st_size,
           "modified_utc": datetime.fromtimestamp(
               p.stat().st_mtime, tz=timezone.utc).isoformat(),
           "format": p.suffix.lower()}
    if p.suffix.lower() == ".unr":
        out["note"] = ("Native Unreal package: binary metadata only. Export actors "
                       "as .t3d from UnrealEd for structured actor/brush inspection.")
        return out
    if p.stat().st_size > 4_000_000:
        raise PathValidationError("T3D exceeds 4MB limit")
    lines = _read_lines(p, max_size=4_000_000)
    classes, examples = Counter(), []
    for i, line in enumerate(lines, 1):
        if not re.search(r"^\s*Begin Actor\b", line, re.I):
            continue
        m = re.search(r"\bClass=(\w+)", line, re.I)
        name = m.group(1) if m else "Unknown"
        classes[name] += 1
        if len(examples) < max(0, min(int(max_actors), 30)):
            examples.append({"line": i, "class": name})
    out["actor_count"] = sum(classes.values())
    out["actor_classes"] = dict(classes.most_common(45))
    out["examples"] = examples
    out["brush_blocks"] = sum(bool(re.search(r"^\s*Begin Brush\b", ln, re.I)) for ln in lines)
    return out

def _sha256(p: Path) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def task_context(s: Settings, topic: str = "vehicle") -> dict:
    key = topic.casefold().strip()
    if key not in VALID_TASKS:
        raise PathValidationError("topic must be: " + ", ".join(VALID_TASKS))
    summaries = []
    for rel in VALID_TASKS[key]:
        try:
            p = resolve_workspace_path(s.workspace, rel)
        except PathValidationError as exc:
            if str(exc) != "path not found":
                raise
            summaries.append({"path": rel, "missing": True})
            continue
        if not p.is_file():
            summaries.append({"path": rel, "missing": True})
            continue
        summary = outline(s, rel, max_symbols=18)
        summaries.append({"path": rel, "lines": summary["lines"],
                          "symbols": summary["symbols"], "limited": summary["limited"]})
    binaries = []
    for f in ("HB227NativeBridge.dll", "HB227NativeBridge.u", "HB227VehicleV2.u"):
        candidates = []
        for arch in ("System", "System64"):
            try:
                p = _target(s, f"{arch}/{f}")
            except PathValidationError:
                continue
            candidates.append({"arch": arch, "size": p.stat().st_size,
                               "sha256": _sha256(p)[:16]})
        binaries.append({"artifact": f, "builds": candidates,
                         "matching": len(candidates) == 2 and
                         candidates[0]["sha256"] == candidates[1]["sha256"]
                         if f.endswith(".u") else None})
    return {"topic": key, "recommended_files": summaries, "artifacts": binaries,
            "next": "Use unreal.outline then unreal.excerpt for precise code; "
                    "unreal.log_digest for runtime gates. No entire-file dumps."}
