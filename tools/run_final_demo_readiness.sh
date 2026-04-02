#!/usr/bin/env bash
set -u

echo "==> Breakout final demo readiness"

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

run_check "verify_ba35.py" python3 tools/verify_ba35.py

echo
echo "--> Demo handoff preview"
if [ -f docs/DEMO_HANDOFF.md ]; then
  sed -n '1,220p' docs/DEMO_HANDOFF.md
  PASS=$((PASS + 1))
else
  echo "docs/DEMO_HANDOFF.md missing"
  FAIL=$((FAIL + 1))
fi

echo
echo "==> Final readiness complete: PASS=$PASS FAIL=$FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
