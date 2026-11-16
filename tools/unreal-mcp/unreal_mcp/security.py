"""Path validation for context tools."""
import os
import re
from pathlib import Path


class PathValidationError(ValueError):
    """A path could not be opened within the project."""


SENSITIVE_NAME = re.compile(r"^(?:\.env(?:\..*)?|id_(?:rsa|dsa|ed25519|ecdsa)(?:\..*)?|authorized_keys)$|(?:\.pem|\.pfx|\.key)$", re.I)
PRIVATE_DIRS = {".git", ".codex", ".cursor", ".venv", ".venv312", "__pycache__"}


def resolve_workspace_path(workspace: Path, user_path: str) -> Path:
    if not user_path.strip() or "\0" in user_path:
        raise PathValidationError("path is required")
    workspace = workspace.resolve()
    raw = Path(user_path)
    candidate = raw if raw.is_absolute() else workspace / raw
    try:
        # Keep the original components for junction checks.
        relative = candidate.relative_to(workspace)
        if ".." in relative.parts:
            raise PathValidationError("parent traversal is not allowed")
        path = workspace
        for component in relative.parts:
            if ":" in component or component.lower() in PRIVATE_DIRS or SENSITIVE_NAME.search(component):
                raise PathValidationError("private path is not available")
            path /= component
            if path.is_symlink() or path.is_junction():
                raise PathValidationError("symbolic links and junctions are not available")
        resolved = path.resolve()
        if not resolved.is_relative_to(workspace):
            raise PathValidationError("path is outside the checkout")
        return resolved
    except PathValidationError:
        raise
    except ValueError as exc:
        raise PathValidationError("path is outside the checkout") from exc
    except (OSError, RuntimeError) as exc:
        raise PathValidationError("path cannot be resolved") from exc
