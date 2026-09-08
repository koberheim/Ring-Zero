#!/usr/bin/env bash
# One-command correctness runner (Phase 6 / A5).
# Runs every tests/**/test_*.gd suite headless and reports pass/fail per suite.
# Recommended Windows entry point: scripts/run_tests.ps1 (see scripts/README.md).
# This legacy Bash invocation remains available with Bash/GNU timeout and an
# already-imported project. It excludes standalone capture_*.gd/benchmark_*.gd
# and does not request --cost-* modes. Some test suites contain internal timing
# blocks, so this is not strict performance separation or benchmark evidence.
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/e/Godot/Godot_v4.7.2-stable_win64.exe}"
LOG_DIR="$PROJECT_DIR/.godot/test-logs"
SUITE_TIMEOUT="${SUITE_TIMEOUT:-90}"
mkdir -p "$LOG_DIR"

# An unhandled runtime error inside a suite's _run() aborts that call before it
# reaches its own quit() — Godot then never receives a quit request and the
# headless process idles forever instead of exiting nonzero (confirmed T-032/033:
# a GDScript index-out-of-bounds left three such processes running for hours).
# `timeout -k` guarantees this runner always terminates and reports a failure
# instead of hanging indefinitely on a crashed suite.

if [ ! -f "$GODOT_BIN" ]; then
	echo "Godot binary not found at $GODOT_BIN. Set GODOT_BIN=/path/to/Godot.exe and retry." >&2
	exit 2
fi

overall_status=0
suite_count=0

while IFS= read -r suite; do
	rel="${suite#"$PROJECT_DIR"/}"
	name="$(basename "$suite" .gd)"
	log="$LOG_DIR/$name.log"
	suite_count=$((suite_count + 1))
	timeout -k 10 "$SUITE_TIMEOUT" "$GODOT_BIN" --headless --path "$PROJECT_DIR" --script "$rel" --log-file "$log" >"$LOG_DIR/$name.stdout.log" 2>&1
	code=$?
	if [ $code -eq 124 ] || [ $code -eq 137 ]; then
		echo "FAIL  $rel (timed out after ${SUITE_TIMEOUT}s and was killed — likely an unhandled runtime error before quit()) — see $log"
		overall_status=1
	elif [ $code -ne 0 ]; then
		echo "FAIL  $rel (exit $code) — see $log"
		overall_status=1
	else
		summary="$(tail -n 1 "$LOG_DIR/$name.stdout.log" 2>/dev/null)"
		echo "pass  $rel${summary:+ — $summary}"
	fi
done < <(find "$PROJECT_DIR/tests" -type f -name 'test_*.gd' | sort)

echo "---"
echo "$suite_count suites run. $([ $overall_status -eq 0 ] && echo "all passed" || echo "at least one FAILED — see logs above")"
exit $overall_status
