#!/bin/bash

set -u

ROOT="$(pwd)"
REPORT="$ROOT/ANIMATOR_AUDIT_REPORT.txt"
START="$(date)"
PHASE1="src/evaluator.gleam"

exec > >(tee "$REPORT") 2>&1

echo "=================================================="
echo " CS61A ANIMATOR - COMPLETE PROJECT AUDIT"
echo "=================================================="
echo "Started: $START"
echo "Directory: $ROOT"
echo

if [ ! -f gleam.toml ] || [ ! -f package.json ]; then
  echo "ERROR: This does not appear to be the project root."
  exit 1
fi

echo "1. GIT STATUS"
echo "--------------------------------------------------"
git branch --show-current 2>&1 || true
git status --short 2>&1 || true
echo

echo "2. PROJECT FILE INVENTORY"
echo "--------------------------------------------------"
find . 
  -path './node_modules' -prune -o 
  -path './.git' -prune -o 
  -type f -print | sort
echo

echo "3. PROJECT DOCUMENTATION"
echo "--------------------------------------------------"
for f in README.md gleam.toml package.json vite.config.js; do
  if [ -f "$f" ]; then
    echo
    echo "### $f"
    cat "$f"
  fi
done

echo
echo "4. ASSIGNMENT DOCUMENTATION"
echo "--------------------------------------------------"
find . 
  -path './node_modules' -prune -o 
  -path './.git' -prune -o 
  -type f \( -iname '*assignment*' -o -iname '*specification*' -o -iname '*instruction*' -o -iname '*rubric*' \) -print

echo
echo "5. SOURCE AND TEST FILE REVIEW"
echo "--------------------------------------------------"
find src test -type f 2>/dev/null | sort

echo
echo "6. RESTRICTED FILE FINGERPRINT"
echo "--------------------------------------------------"
if [ -f "$PHASE1" ]; then
  shasum -a 256 "$PHASE1"
  echo "Phase 1 evaluator will NOT be modified."
else
  echo "Evaluator file not found at $PHASE1"
fi

echo
echo "7. VIDEO URL CONFIGURATION"
echo "--------------------------------------------------"
grep -n -C 3 'video_url' src/app.gleam 2>/dev/null || true

echo
echo "8. LOCALSTORAGE INVESTIGATION"
echo "--------------------------------------------------"
grep -RIn 
  --exclude-dir=node_modules 
  --exclude-dir=.git 
  -E 'localStorage|setItem|getItem|removeItem' src test 2>/dev/null || true

echo
echo "9. VITE AND DEPLOYMENT CONFIGURATION"
echo "--------------------------------------------------"
grep -RIn 
  --exclude-dir=node_modules 
  --exclude-dir=.git 
  -E 'base:|outDir:|docs|assetsDir|historyApiFallback' 
  vite.config.js package.json index.html src 2>/dev/null || true

echo
echo "10. FORMAT CHECK"
echo "--------------------------------------------------"
if command -v gleam >/dev/null 2>&1; then
  gleam format --check src test
  echo "Formatting exit code: $?"
else
  echo "Gleam is not installed or not on PATH."
fi

echo
echo "11. GLEAM COMPILATION"
echo "--------------------------------------------------"
if command -v gleam >/dev/null 2>&1; then
  gleam check
  echo "Compilation exit code: $?"
fi

echo
echo "12. COMPLETE TEST SUITE"
echo "--------------------------------------------------"
if command -v gleam >/dev/null 2>&1; then
  gleam test
  echo "Test exit code: $?"
fi

echo
echo "13. PRODUCTION BUILD"
echo "--------------------------------------------------"
if [ -d node_modules ]; then
  npm run build
  echo "Build exit code: $?"
else
  echo "node_modules is missing. Install dependencies with npm install."
fi

echo
echo "14. BUILD OUTPUT VERIFICATION"
echo "--------------------------------------------------"
if [ -f docs/index.html ]; then
  echo "PASS: docs/index.html exists."
  echo
  echo "Generated assets:"
  find docs -maxdepth 3 -type f | sort
  echo
  echo "HTML asset references:"
  grep -oE '(src|href)="[^"]+"' docs/index.html || true
else
  echo "FAIL: docs/index.html is missing."
fi

echo
echo "15. GIT STATUS AFTER AUDIT"
echo "--------------------------------------------------"
git status --short 2>&1 || true

echo
echo "16. FINAL PHASE 1 FINGERPRINT"
echo "--------------------------------------------------"
if [ -f "$PHASE1" ]; then
  shasum -a 256 "$PHASE1"
fi

echo
echo "=================================================="
echo " AUDIT FINISHED"
echo "=================================================="
echo "Report: $REPORT"
echo "No Git commit, push, or publication was performed."
