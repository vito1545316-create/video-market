#!/usr/bin/env python3
"""Regenerates setup.ps1 by embedding the current build_reels.py into it.

Run this from inside scripts/ after editing build_reels.py:
    python3 gen_setup.py

setup.ps1 keeps a literal "__BUILD_REELS_PY__" placeholder line inside its
first here-string; this script only exists because that here-string has to
be regenerated (not hand-edited) whenever build_reels.py changes, and needs
UTF-8-with-BOM + CRLF so Windows PowerShell 5.1 parses the embedded Cyrillic
text in the generated scenario/prompt files correctly.
"""
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parent
build_py = (ROOT / "build_reels.py").read_text(encoding="utf-8")

# setup.ps1 itself is the template AND the output - it must already contain
# the __BUILD_REELS_PY__ placeholder from a previous generation. Read the
# placeholder-bearing template from setup.ps1.tmpl if present, else setup.ps1
# (first run only - after that, always edit setup.ps1.tmpl, not setup.ps1).
tmpl_path = ROOT / "setup.ps1.tmpl"
if not tmpl_path.exists():
    raise SystemExit(
        "setup.ps1.tmpl not found - it should contain the __BUILD_REELS_PY__ "
        "placeholder. Copy the non-embedded parts of setup.ps1 into it once, "
        "then rerun this script."
    )
template = tmpl_path.read_text(encoding="utf-8")

for line in build_py.splitlines():
    if line.strip() == "'@":
        raise SystemExit("UNSAFE: build_reels.py contains a line that would break the PowerShell here-string")

final = template.replace("__BUILD_REELS_PY__", build_py)

with io.open(ROOT / "setup.ps1", "w", encoding="utf-8-sig", newline="\r\n") as f:
    f.write(final)

print("Written setup.ps1:", (ROOT / "setup.ps1").stat().st_size, "bytes")
