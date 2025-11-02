#!/usr/bin/env python3
"""
My Version Bump Script for GitHub Releases

Rules:
- If no existing tags, create v1.0.0
- Compare latest tag to HEAD for changes in src/interim_report.tex
  - If any added lines contain "\section{", bump minor (X.Y+1.0)
  - Else if any added lines contain "\subsection{" or any other added lines, bump patch (X.Y.Z+1)
  - If no relevant changes to the file, print an empty string (no release)

Outputs the new tag (e.g. v1.0.1) to stdout when a release is needed, or empty output when none.
"""
import subprocess
import sys
import re

FILEPATH = 'src/interim_report.tex'

def run(cmd):
    return subprocess.check_output(cmd, shell=True, text=True).strip()

try:
    latest_tag = run("git describe --tags --abbrev=0")
except subprocess.CalledProcessError:
    latest_tag = ''

if not latest_tag:
    print('v1.0.0')
    sys.exit(0)

m = re.match(r"v?(\d+)\.(\d+)\.(\d+)", latest_tag)
if not m:
    base_major, base_minor, base_patch = 1, 0, 0
else:
    base_major, base_minor, base_patch = map(int, m.groups())

diff = None
try:
    diff = run(f"git diff --unified=0 {latest_tag} HEAD -- {FILEPATH}")
except subprocess.CalledProcessError:
    print('')
    sys.exit(0)

if not diff:
    print('')
    sys.exit(0)

added_lines = [l for l in diff.splitlines() if l.startswith('+') and not l.startswith('+++')]

if not added_lines:
    print('')
    sys.exit(0)

section_added = any(re.search(r"\\section\s*\{", l) for l in added_lines)
subsection_added = any(re.search(r"\\subsection\s*\{", l) for l in added_lines)

if section_added:
    new_tag = f"v{base_major}.{base_minor+1}.0"
    print(new_tag)
    sys.exit(0)

if subsection_added or any(True for _ in added_lines):
    new_tag = f"v{base_major}.{base_minor}.{base_patch+1}"
    print(new_tag)
    sys.exit(0)

print('')
sys.exit(0)
