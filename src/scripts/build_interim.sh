#!/usr/bin/env bash

# This script is for building a LaTeX document located in the project root directory.
# It runs pdflatex and bibtex as needed, captures logs, and organizes output files
# This script assumes that pdflatex and bibtex are installed and available in the system PATH.
# Also, don't worry about moving this script anywhere. It works out the box from this location.

# This script is for Linux/macOS users, if you are on Windows, please use the corresponding shell script in build_interim.ps1.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit 1

LOG_DIR="$PROJECT_ROOT/scripts/log"
mkdir -p "$LOG_DIR"

PARENT_DIR="$(dirname "$PROJECT_ROOT")"
AUXIL_DIR="$PARENT_DIR/auxil"
mkdir -p "$AUXIL_DIR"

BIB_SOURCE="$PROJECT_ROOT/interim_report.bib"
BIB_DEST="$PARENT_DIR/interim_report.bib"
if [ -f "$BIB_SOURCE" ]; then
  cp -f "$BIB_SOURCE" "$BIB_DEST"
fi

OUTPUT_PATH="$PARENT_DIR/Interim_FYP-DT-MSAR_23070854.pdf"

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$PARENT_DIR" interim_report.tex 2>&1 | tee "$LOG_DIR/pdflatex-pass1.scripts.log"

ORIGINAL_DIR=$(pwd)
cd "$PARENT_DIR" || exit 1
if [ -f interim_report.aux ]; then
  bibtex interim_report 2>&1 | tee "$LOG_DIR/bibtex.scripts.log"

  if [ -f "$BIB_DEST" ]; then
    rm -f "$BIB_DEST"
  fi
fi
cd "$ORIGINAL_DIR" || exit 1

pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$PARENT_DIR" interim_report.tex 2>&1 | tee "$LOG_DIR/pdflatex-pass2.scripts.log"
pdflatex -interaction=nonstopmode -halt-on-error -output-directory="$PARENT_DIR" interim_report.tex 2>&1 | tee "$LOG_DIR/pdflatex-pass3.scripts.log"

TEMP_PDF_PATH="$PARENT_DIR/interim_report.pdf"
if [ -f "$TEMP_PDF_PATH" ]; then
  mv "$TEMP_PDF_PATH" "$OUTPUT_PATH"

  if [ -f "$PARENT_DIR/interim_report.aux" ]; then
    mv "$PARENT_DIR/interim_report.aux" "$AUXIL_DIR/"
  fi
  if [ -f "$PARENT_DIR/interim_report.log" ]; then
    mv "$PARENT_DIR/interim_report.log" "$AUXIL_DIR/"
  fi
  if [ -f "$PARENT_DIR/interim_report.bbl" ]; then
    mv "$PARENT_DIR/interim_report.bbl" "$AUXIL_DIR/"
  fi
  if [ -f "$PARENT_DIR/interim_report.blg" ]; then
    mv "$PARENT_DIR/interim_report.blg" "$AUXIL_DIR/"
  fi

  shopt -s nullglob
  for f in *.out *.toc *.bbl *.blg; do
    if [ -f "$f" ]; then
      rm -f "$f"
    fi
  done

  PDF_WORDCOUNT=""
  if command -v pdftotext >/dev/null 2>&1; then
    RAW=$(pdftotext -layout -enc UTF-8 "$OUTPUT_PATH" - 2>/dev/null || true)
    if [ -n "$RAW" ]; then
      PDF_WORDCOUNT=$(printf "%s" "$RAW" | wc -w)
    fi
  elif command -v pdftohtml >/dev/null 2>&1; then
    RAW=$(pdftohtml -stdout -i -q "$OUTPUT_PATH" 2>/dev/null || true)
    if [ -n "$RAW" ]; then
      TEXT_ONLY=$(printf "%s" "$RAW" | sed -E 's/<[^>]*>/ /g')
      PDF_WORDCOUNT=$(printf "%s" "$TEXT_ONLY" | wc -w)
    fi
  elif command -v strings >/dev/null 2>&1; then
    RAW=$(strings "$OUTPUT_PATH" 2>/dev/null || true)
    if [ -n "$RAW" ]; then
      PDF_WORDCOUNT=$(printf "%s" "$RAW" | wc -w)
    fi
  else
    PDF_WORDCOUNT=""
  fi

  if [ -n "$PDF_WORDCOUNT" ] && [ "$PDF_WORDCOUNT" -gt 0 ]; then
    echo "Word count (PDF text): ${PDF_WORDCOUNT}/10,000"
    echo "Word count (PDF text): ${PDF_WORDCOUNT}/10,000" >> "$LOG_DIR/wordcount.scripts.log"
  else
    echo "Word count (PDF text): unavailable (no extractor found)/10,000"
  fi

  printf "Done. Output: %s. Log files cleaned up. Build logs: %s\n" "$OUTPUT_PATH" "$LOG_DIR"
else
  shopt -s nullglob
  for f in *.aux *.log *.out *.toc *.bbl *.blg; do
    if [ -f "$f" ]; then
      mv -f "$f" "$LOG_DIR/"
    fi
  done
  printf "PDF compilation failed. Logs: %s\n" "$LOG_DIR"
fi
