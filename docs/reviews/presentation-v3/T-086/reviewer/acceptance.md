# T-086 early slice — independent review

Reviewer: Astra. Recovery continuation, 2026-09-08 local date. Baseline `a42b7a8` plus the recovered, repaired narrow T-086 patch; source hashes are in the delivery manifest.

Accepted the early CheckButton/OptionButton slice only. Full T-086 theme remains in progress and waits for T-081 and early T-083.

| Check | Result |
|---|---|
| Native before/after real start and settings, 1080/1440, 100/130% | PASS: explicit ON/OFF geometry and labels; no default toggle or arrow; original captures preserved |
| Disabled/hover/focus states | PASS: inspected native state gallery and real settings; distinct thumb positions remain visible in disabled states |
| Independent input/persistence reproduction | PASS: exit 0, 51 checks, zero failures; native mouse, Space, controller A, Tab traversal and profile reload |
| Regression floor | PASS: owner's tracked run reports 42 suites, zero failures; reviewed retained aggregate/log |
| Scope | PASS: theme, five SVGs, task capture/evidence only; no layout/renderer feature edit |
| Full instrument theme and Phase 14 acceptance | PENDING; this slice does not close either |

Independent command: pinned `E:/Godot/Godot_v4.7.2-stable_win64.exe --path "E:/AI Projects/Games/Ring Zero" --script res://tests/presentation/capture_t086.gd -- --after --evidence-dir=res://.godot/release-qa/t086-independent`, launched with `Start-Process -WindowStyle Hidden`, a 90-second timeout, tracked exit code, and APPDATA/LOCALAPPDATA inside that QA directory. Retained output records Godot 4.7.2, Compatibility, RTX 4080 and NVIDIA 610.88. See fixture manifest for native dimensions and state. The reproduced 1080p/130% settings image is retained here; the remaining repeated frames are in the ignored QA directory.

The first independent launch lacked isolated APPDATA and emitted a log-path permission diagnostic; it was rerun with local profiles. The final run emits a Windows certificate-store read diagnostic in this sandbox, with no script/import errors and all checks passing. This offline capture does not use network certificates. No performance result is inferred from this run.

Provisional values remain the delivered 104×36 native switch, 16 px icon gap, 12/6 px row insets, and 3 px focus border. Review confirms the switch is readable after 0.75× 1080p composition; later responsive work retains responsibility for its own physical-pixel checks.
