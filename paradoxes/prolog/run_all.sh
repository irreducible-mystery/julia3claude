#!/usr/bin/env bash
# Alternate runner (no process_create required).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
fail=0
echo "PARADOXES — Prolog suite (SWI-Prolog)"
for f in 01_liar_and_friends.pl 04_probability.pl 05_decision.pl \
         08_tensions.pl 10_prolog_expressibility.pl; do
  echo
  printf '%.0s═' {1..70}; echo
  echo "  $f"
  printf '%.0s═' {1..70}; echo
  if ! swipl -q -t halt -s "$HERE/$f"; then
    echo "** module exit nonzero **"
    fail=$((fail + 1))
  fi
done
echo
if [[ "$fail" -eq 0 ]]; then
  echo "══ ALL PROLOG MODULES GREEN ══"
  exit 0
else
  echo "══ $fail MODULE(S) RED ══"
  exit 1
fi
