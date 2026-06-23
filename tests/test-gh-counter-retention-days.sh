#!/usr/bin/env bash
set -euo pipefail

workflow="${1:-.github/workflows/gh-counter.yml}"
script="$(mktemp)"
trap 'rm -f "$script"' EXIT

awk '
  $0 == "      - name: Validate retention-days" {
    in_step = 1
    next
  }
  in_step && $0 == "        run: |" {
    in_run = 1
    next
  }
  in_run && $0 ~ /^      - name: / {
    exit
  }
  in_run {
    sub(/^          /, "")
    print
  }
' "$workflow" >"$script"

if [[ ! -s "$script" ]]; then
  echo "Validate retention-days script was not found in $workflow" >&2
  exit 1
fi

run_case() {
  local value="$1"
  local expected_status="$2"
  local actual_status

  set +e
  RETENTION_DAYS="$value" bash "$script" >/dev/null 2>&1
  actual_status="$?"
  set -e

  if [[ "$actual_status" != "$expected_status" ]]; then
    echo "RETENTION_DAYS=$value expected exit $expected_status, got $actual_status" >&2
    return 1
  fi
}

run_case "1" 0
run_case "30" 0
run_case "90" 0

run_case "" 2
run_case "0" 2
run_case "91" 2
run_case "14.5" 2
run_case "0100" 2
run_case "091" 2
run_case "-1" 2
