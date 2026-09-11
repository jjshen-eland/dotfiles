#!/usr/bin/env python3
"""Atomically merge shared Codex defaults, runtime state, and local overrides."""

from __future__ import annotations

import base64
import binascii
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import Any


MANAGED_PREFIX = "# dotfiles-managed-paths: "


def fail(message: str) -> int:
    print(f"⚠️  Codex config unchanged: {message}", file=sys.stderr)
    return 1


def resolve_yq() -> str | None:
    requested = os.environ.get("YQ_BIN", "yq")
    if os.path.sep in requested:
        return requested if os.path.isfile(requested) and os.access(requested, os.X_OK) else None
    return shutil.which(requested)


def run_yq(yq: str, args: list[str], *, stdin: str | None = None) -> str:
    completed = subprocess.run(
        [yq, *args],
        input=stdin,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise ValueError(completed.stderr.strip() or f"yq exited {completed.returncode}")
    return completed.stdout


def load_toml(yq: str, path: Path, *, optional: bool = False) -> dict[str, Any]:
    if optional and (not path.exists() or path.stat().st_size == 0):
        return {}
    if not path.is_file():
        raise ValueError(f"missing {path}")
    raw = run_yq(yq, ["eval", "-p", "toml", "-o", "json", ".", str(path)])
    parsed = json.loads(raw)
    if not isinstance(parsed, dict):
        raise ValueError(f"top-level TOML value in {path} is not a table")
    return parsed


def leaf_paths(value: Any, prefix: tuple[str, ...] = ()) -> set[tuple[str, ...]]:
    if not isinstance(value, dict) or not value:
        return {prefix}
    result: set[tuple[str, ...]] = set()
    for key, child in value.items():
        result.update(leaf_paths(child, (*prefix, key)))
    return result


def load_previous_managed(path: Path) -> set[tuple[str, ...]]:
    if not path.exists():
        return set()
    try:
        with path.open(encoding="utf-8") as config_file:
            first_line = config_file.readline().rstrip("\n")
        if not first_line.startswith(MANAGED_PREFIX):
            return set()
        payload = first_line.removeprefix(MANAGED_PREFIX)
        decoded = base64.urlsafe_b64decode(payload.encode("ascii"))
        parsed = json.loads(decoded)
        if not isinstance(parsed, list) or not all(
            isinstance(parts, list) and all(isinstance(part, str) for part in parts)
            for parts in parsed
        ):
            raise ValueError("invalid managed-path manifest")
        return {tuple(parts) for parts in parsed}
    except (OSError, UnicodeError, ValueError, json.JSONDecodeError, binascii.Error) as error:
        raise ValueError(f"cannot read managed-path manifest: {error}") from error


def unmanaged_state(
    current: Any,
    managed: Any,
    previous_managed: set[tuple[str, ...]],
    prefix: tuple[str, ...] = (),
) -> Any:
    """Return current leaves absent from current and previous managed layers."""
    if not isinstance(current, dict):
        return {}
    result: dict[str, Any] = {}
    for key, value in current.items():
        path = (*prefix, key)
        if isinstance(managed, dict) and key in managed:
            if isinstance(value, dict) and isinstance(managed[key], dict):
                nested = unmanaged_state(value, managed[key], previous_managed, path)
                if nested:
                    result[key] = nested
            continue
        if isinstance(value, dict):
            nested = unmanaged_state(value, {}, previous_managed, path)
            if nested:
                result[key] = nested
        elif path not in previous_managed:
            result[key] = value
    return result


def deep_merge(left: dict[str, Any], right: dict[str, Any]) -> dict[str, Any]:
    result = dict(left)
    for key, value in right.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def digest(path: Path) -> str | None:
    if not path.exists():
        return None
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    repo = Path(os.environ.get("DOTFILES_DIR", Path(__file__).resolve().parent.parent))
    codex_home = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    base_path = Path(os.environ.get("CODEX_CONFIG_BASE", repo / "codex" / "config.toml"))
    target = Path(os.environ.get("CODEX_CONFIG_FILE", codex_home / "config.toml"))
    local_path = Path(os.environ.get("CODEX_CONFIG_LOCAL", codex_home / "config.local.toml"))
    lock = Path(f"{target}.lock")

    yq = resolve_yq()
    if yq is None:
        return fail("yq is required for TOML validation and rendering")

    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        lock.mkdir()
    except FileExistsError:
        return fail(f"another writer holds {lock}")

    temp_path: Path | None = None
    try:
        initial_digest = digest(target)
        try:
            base = load_toml(yq, base_path)
            current = load_toml(yq, target, optional=True)
            local = load_toml(yq, local_path, optional=True)
            previous_managed = load_previous_managed(target)
        except (ValueError, json.JSONDecodeError, OSError) as error:
            return fail(str(error))

        managed = deep_merge(base, local)
        generated = unmanaged_state(current, managed, previous_managed)
        merged = deep_merge(deep_merge(base, generated), local)
        managed_paths = [list(path) for path in sorted(leaf_paths(managed))]
        manifest = base64.urlsafe_b64encode(
            json.dumps(managed_paths, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        ).decode("ascii")
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".json", dir=target.parent, delete=False
        ) as json_file:
            json.dump(merged, json_file, ensure_ascii=False, separators=(",", ":"))
            json_path = Path(json_file.name)
        try:
            rendered = run_yq(yq, ["eval", "-p", "json", "-o", "toml", ".", str(json_path)])
        except (ValueError, OSError) as error:
            return fail(str(error))
        finally:
            json_path.unlink(missing_ok=True)

        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", prefix=".config.toml.", dir=target.parent, delete=False
        ) as output_file:
            output_file.write(f"{MANAGED_PREFIX}{manifest}\n{rendered}")
            temp_path = Path(output_file.name)
        os.chmod(temp_path, 0o600)
        try:
            load_toml(yq, temp_path)
        except (ValueError, json.JSONDecodeError, OSError) as error:
            return fail(f"rendered TOML failed validation: {error}")

        if digest(target) != initial_digest:
            return fail("config.toml changed while the merged candidate was being rendered")
        if target.exists() and target.read_bytes() == temp_path.read_bytes():
            return 0
        os.replace(temp_path, target)
        temp_path = None
        return 0
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)
        try:
            lock.rmdir()
        except OSError:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
