#!/usr/bin/env bash

# This script is for building a LaTeX document named 'main.tex' located in the project root directory.
# It runs pdflatex and bibtex as needed, captures logs, and organizes output files
# This script assumes that pdflatex and bibtex are installed and available in the system PATH.
# Also, don't worry about moving this script anywhere to work with main.tex. It works out the box from this location.

# This script is for Linux/macOS users, if you are on Windows, please use the corresponding shell script in build_latex.ps1.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit 1

LOG_DIR="$PROJECT_ROOT/scripts.log"
mkdir -p "$LOG_DIR"

pdflatex -interaction=nonstopmode -halt-on-error main.tex 2>&1 | tee "$LOG_DIR/pdflatex-pass1.scripts.log"
if [ -f main.aux ]; then
  bibtex main 2>&1 | tee "$LOG_DIR/bibtex.scripts.log"
fi
pdflatex -interaction=nonstopmode -halt-on-error main.tex 2>&1 | tee "$LOG_DIR/pdflatex-pass2.scripts.log"
pdflatex -interaction=nonstopmode -halt-on-error main.tex 2>&1 | tee "$LOG_DIR/pdflatex-pass3.scripts.log"

shopt -s nullglob
for f in *.aux *.log *.out *.toc *.bbl *.blg; do
  if [ -f "$f" ]; then
    mv -f "$f" "$LOG_DIR/"
  fi
done

printf "Done. Output: %s. Logs: %s\n" "$PROJECT_ROOT/main.pdf" "$LOG_DIR"
