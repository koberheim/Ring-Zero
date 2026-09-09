# T-086 early toggle slice — recovered delivery

Owner: Stream D / Luna. Review: Astra independently reproduced and accepted early slice. Date: 2026-09-09 UTC. This is the approved D-135 early CheckButton/OptionButton slice only; T-086 remains In progress for later full-theme integration.

The real challenge and settings rows now use an explicit two-position selector: left/steel/OFF and right/amber/ON. Disabled selectors preserve their position and wording in neutral metal. Hover changes the recessed row surface; a light keyline marks keyboard focus. OptionButton uses a matching original engraved-bar arrow. No layout, renderer, simulation, settings persistence, or controller routing code changed.

## Recovery and source identity

The resumed checkout was `a42b7a8fb7cf85cae7f6385b1f0f0a24d310c037`, containing the interrupted theme patch, five SVG control assets, capture fixture and original before evidence. Original before images and manifest were preserved byte-for-byte. The before manifest records 23 checks / 0 failures; recovered original stdout/stderr are copied alongside this report. Its original source hash was not recorded, so no exact before tree hash is invented. The pre-change theme is available in HEAD; before evidence is attributed to the approved initial lease based on recovered session context. `source-manifest.json` hashes the final delivery inputs and records the reference commit.

Two SVG files contained only null bytes: `select_arrow.svg` and `switch_checked_disabled.svg`. The disabled ON asset was reconstructed from its valid ON counterpart using the same neutral colors as disabled OFF. The arrow was rebuilt as original vector bars and a chevron. Three otherwise-valid switch SVGs had corrupt imported `.ctex` cache files; a source comment forced their reimport. The first recovery capture returned 23 passing behavioral checks but emitted texture-load errors, so that capture was rejected. Its error logs remain in `recovery-failed/`; final after images replaced that invalid attempt. Final capture has no texture-load, script, or parse errors. Godot emits a root-certificate-store diagnostic on this machine, including the preserved before run; no network function is used by this fixture.

## Evidence and checks

| Gate | Result | Evidence |
|---|---|---|
| Real start/settings at 1920×1080 and 2560×1440, text scale 100%/130% | PASS, owner visual review | Matched `before/` and `after/` start/settings PNGs |
| OFF/ON, disabled OFF/ON, hover OFF/ON, visible focus | PASS, owner visual review | Native state-gallery PNGs at both resolutions/scales |
| Mouse, Space, controller A and disabled-input behavior | PASS | Final native capture: 51 checks, 0 failures, exit 0 |
| Settings survive reload | PASS | Actual persisted Reduced motion / Weapon feedback values loaded through profile store |
| Actual keyboard traversal and controller route | PASS | Two Tab focus-advance checks plus 25 timestamped native frames and controller A activation |
| Retained regression floor | PASS | 42 suites, 0 failures, runner exit 0; `suite-run.txt`, `test-summary.json` |
| Independent Astra review | PASS | Separate `.godot/release-qa/t086-independent` capture: exit 0, 51/51 checks; actual settings at 1080p/130% and final arrow inspected |
| Full T-086 theme, all widgets/fonts/layout screen matrix | PENDING | Later lease, gated by T-081/T-083; not claimed by this delivery |

The regression run is `.godot/test-logs/run-20260909-023650-095-29888`. It covers existing pause, cancel, remap migration, scale, persistence, picking and teardown assertions. No existing assertions changed. The task fixture adds narrow visual/input evidence rather than a redundant implementation-mirroring suite. No benchmark or performance claim is made; the initial capture and tests coexisted with Kevin's editor, which was later closed before the renderer benchmark lease.

Fixture: actual `scenes/application.tscn`, isolated `.godot/release-profiles/t086-<ticks>/profile.json`, native root-viewport PNGs after `RenderingServer.frame_post_draw`. Menu only: no gameplay camera/zoom, seed not applicable, simulation tick 0, active actors 0, palette 1. Internal stage 2560×1440; root 1920×1080 or 2560×1440; stage fit 0.75 or 1.0. The fixture stops menu processing after initialization and reuses identical setup for comparisons. State gallery is explicitly diagnostic. Final environment: Godot 4.7.2 stable official `ed1daf0bf`, OpenGL 3.3 Compatibility, NVIDIA GeForce RTX 4080, driver 610.88.

`focus-traversal.html` plays the lossless after PNG sequence with recorded frame timing. Frames show initial Reduced motion focus, Tab to Weapon feedback, Tab to Interface scale, controller pointer over Weapon feedback, and controller A enabling it. The controller uses the shipping virtual pointer; its location is fixture setup, and the button event follows the real route. There is no claim of a controller focus-navigation system. The recovered before evidence contains the two focus stills, not a historical traversal recording; the after sequence establishes current traversal behavior.

## Commands

Run from the repository root. Import, captures and suites were sequential tracked processes; captures used `Start-Process -WindowStyle Hidden -PassThru`, retained process handles, a 55-second bound, and exact-PID cleanup. APPDATA and LOCALAPPDATA were set to workspace `.godot/appdata` and `.godot/localappdata` for each capture.

```powershell
& 'E:/Godot/Godot_v4.7.2-stable_win64.exe' --headless --path 'E:/AI Projects/Games/Ring Zero' --editor --import --quit
powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/run_tests.ps1
& 'E:/Godot/Godot_v4.7.2-stable_win64.exe' --path 'E:/AI Projects/Games/Ring Zero' --script tests/presentation/capture_t086.gd --log-file 'E:/AI Projects/Games/Ring Zero/docs/reviews/presentation-v3/T-086/after-capture.log' -- --after
```

Direct invocation of the PowerShell runner was initially blocked by the machine's execution policy before any tests launched. A process-local `-ExecutionPolicy Bypass` ran the unchanged repository runner; no system policy changed. For independent evidence without overwriting retained PNGs, append `--evidence-dir=res://.godot/release-qa/t086-independent` after `--after`.

## Tokens, resources and changed paths

Provisional native pixel values: selector 104×36 (78×27 physical at 1080p), thumb 29×24, geometric lettering 12 px tall / 2 px strokes, arrow canvas 24×24, icon gap 16 px, row inset 12 px horizontal / 6 px vertical, focus keyline 3 px. These preserve a readable selector footprint as text scales and separate recessed choices from raised actions. Disabled text is `#94a2a9`. Existing Barlow body/semibold fonts remain; full typography tokens belong to the later lease.

`apply_switches(Theme)` applies four checked/unchecked/disabled icon resources (and mirrored aliases), six row surfaces (normal, hover, pressed, hover_pressed, disabled, focus), state text colors and OptionButton arrow. The ON/OFF words use paths, with no font dependency. These are original project SVGs; Blender/image generation is unnecessary for this control slice.

Changed runtime paths: `src/presentation/industrial_theme.gd`, `assets/ui/controls/README.md`, five SVG files and their `.import` metadata. Task paths: `tests/presentation/capture_t086.gd` plus UID, `docs/reviews/presentation-v3/.gdignore`, and this evidence directory. Preserved unrelated project settings, critique, T-089 contract and editor configuration. No commit or planning-log edits by this owner. Artifact SHA-256 coverage is in `artifact-manifest.json` (excludes itself); source hashes are separately recorded. Existing 130% start composition uses a scrollbar; broader layout and remaining default widgets are outside this early slice.
