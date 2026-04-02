#!/usr/bin/env bash
set -u

echo "==> Breakout demo quality checks"

PASS=0
FAIL=0

run_check() {
  local label="$1"
  shift
  echo
  echo "--> $label"
  if "$@"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
}

for script in \
  tools/verify_ba28.py \
  tools/verify_ba29.py \
  tools/verify_ba30.py \
  tools/verify_ba31.py \
  tools/verify_ba32.py \
  tools/verify_ba33.py \
  tools/verify_ba34.py
do
  if [ -f "$script" ]; then
    run_check "$script" python3 "$script"
  fi
done

if command -v flutter >/dev/null 2>&1; then
  run_check "flutter analyze --no-fatal-infos" flutter analyze --no-fatal-infos
  run_check "flutter test" flutter test
else
  echo
  echo "--> flutter not found in PATH; skipped analyze/test"
fi

echo
echo "==> Checks complete: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
