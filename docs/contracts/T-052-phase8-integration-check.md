# T-052 — Phase 8 integrated correctness checkpoint

Owner Sol. Begin only after Astra explicitly freezes T-049/T-050/T-051. Own docs/reviews/T-052.md; no implementation edits or delegation. Use existing scripts/run_tests.ps1, pinned Godot 4.7.2 and workspace caches. No export, installation, profile retuning or performance baseline recording.

Run native Windows runner with clean import and all discovered correctness suites. Retain actual exit codes and individual suite results; fail on script/parse errors, timeouts, missing exit codes or empty discovery. Report exact source freeze timing, logs and suite count. If a suite fails, send precise evidence to its owner and release window before fixes; do not patch fixtures merely to obtain green results. Repeat affected checks or aggregate only as justified by the corrections.

Read T-049/T-050/T-051 reports and verify no headless-only item is claimed playable without UI evidence. Confirm documented art launch works with existing editor-only session scope, final art remains undecided, and cost/performance evidence remains properly scoped. No new performance claim from incidental test timings. Coordinate exclusive runtime window with Astra; report and release all tracked processes before the user review checkpoint.
