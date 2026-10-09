#!/usr/bin/env python3
"""Check the human-authored DS1 Spec Kit seed artifacts; makes no system changes."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SPECS = ROOT / "specs"
REQUIRED = ("spec.md", "plan.md", "tasks.md", "quickstart.md")
errors = []
folders = sorted(p for p in SPECS.iterdir() if p.is_dir()) if SPECS.exists() else []
if not folders:
    errors.append("specs/: no feature directories")
ids = set()
for folder in folders:
    match = re.fullmatch(r"(\d{3})-[a-z][a-z0-9-]+", folder.name)
    if not match:
        errors.append(f"{folder}: noncanonical directory name")
        continue
    phase = match.group(1)
    if phase in ids:
        errors.append(f"{folder}: duplicate phase {phase}")
    ids.add(phase)
    for name in REQUIRED:
        p = folder / name
        if not p.is_file():
            errors.append(f"{p.relative_to(ROOT)}: missing")
            continue
        body = p.read_text(encoding="utf-8")
        if len(body.strip()) < 250:
            errors.append(f"{p.relative_to(ROOT)}: insufficient detail")
        if phase not in body:
            errors.append(f"{p.relative_to(ROOT)}: missing phase ID")
    if (folder / "spec.md").is_file():
        body = (folder / "spec.md").read_text(encoding="utf-8")
        for marker in ("## Contexto", "## Histórias de usuário", "## Requisitos", "## Critérios de aceite", "## Não escopo"):
            if marker not in body:
                errors.append(f"{folder.name}/spec.md: missing {marker}")
    if (folder / "tasks.md").is_file() and not re.search(r"(?m)^- \[ \] T\d+", (folder / "tasks.md").read_text(encoding="utf-8")):
        errors.append(f"{folder.name}/tasks.md: no actionable unchecked task IDs")
for special in ("AGENTS.md", ".specify/memory/constitution.md", "docs/phase-gates.md", "docs/notion-runbook-traceability.md", "docs/codex-speckit.md"):
    if not (ROOT / special).is_file():
        errors.append(f"missing {special}")
if errors:
    print("FAIL: spec checks:")
    for item in errors:
        print(" -", item)
    sys.exit(1)
print(f"PASS: {len(folders)} phase specifications and supporting files present; structural check only.")
