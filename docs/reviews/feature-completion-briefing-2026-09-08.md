# Feature-complete private test briefing — 2026-09-08

**Feature implementation and private package verification are complete. Large-swarm real-time performance remains inadequate and is the main engineering follow-up.**

## Launch and identify this candidate

Run [RingZero.exe](../../exports/windows/RingZero.exe). Keep `RingZero.pck`, `build_info.json` and the `licenses` folder beside it. Start with Tutorial to learn the controls, then try a normal run. The executable is local and unpublished; it does not need the Godot editor to launch here.

Frozen source identity: `b1df72c682cb1405d76422f67998cfdbffc2e858662c6a1b120e0507bd4f8fb3`, verified against 221 source files. Executable SHA-256: `16e0ec3cfd398b938f514de95ff2474b532b5061ada78f92226dba3f7584d55d`. PCK SHA-256: `7531c60ac7d4e1765c00513994642f2c16362c3e5f882299dcd91fe4ee667d78`.

Normal profiles and traces live under `%APPDATA%/Godot/app_userdata/RING ZERO/` (`profile.json` and `runs/`). Automated checks used separate workspace profiles and did not reset Kevin's progress. Traces are bounded per file to 16 MiB / 50,000 records; no automatic cross-run retention cleanup is introduced.

## What this effort completes

The repository now contains the full gameplay catalogue and seven enemy kinds, run configuration, persistent progression, an interactive tutorial and a coherent industrial interface. This is a private testing milestone. Final world assets/animations, release balance, publishing and Kevin's experience acceptance remain separate.

The audit found that Claude's completed enemy implementations were not all enabled by the normal live scene. It also found an inaccessible relay-rebuild command, a relay-power indicator based on structure presence rather than remaining health, post-hop Transfer wall/debris violations and free travel, and unguarded Assembler numerical growth. Those gaps have been corrected. The final mixed test additionally exposed a floating-point movement residue that rejected an otherwise valid tick; the narrowly bounded correction preserves slow movement and atomic rollback.

## Playable systems

- Full automatic weapon catalogue: Flak, Mass Driver, EMP Node, Lance Emitter and Point Defense.
- Whole-ring expansion, walls, armor, repair nodes, wedge repair, reclaim and independent relay destruction/rebuilding with outward power and brownouts.
- Debris, directed Tractor Lanes and non-stacking strongest Occlusion slowdown; targeted Focused Flare and EMP Burst.
- Normal machines, Tunnelers, Foundries, Transfers, Sappers, Breachers and Assemblers through the common continuous-pressure simulation and shared trial cap.
- Three doctrines, three loadouts and three combinable difficulty mutators with editable values and source-enforced unlocks.
- Results, one-time credits, seven tool/loadout unlocks, three capped upgrade tracks, saved settings and a complete return/retry/relaunch loop.
- Eleven-step isolated tutorial and in-game reference. Practice grants and scripted damage are explicit and cannot earn progression.

## Interface and controls

The UI follows the authorized gritty industrial/sci-fi direction: dark metal instrument housing, readable Barlow fonts, amber selection/action cues, explicit faults and distinct enemy placeholder shapes. It does not settle the final industrial-versus-painterly world treatment.

The application targets 1440 × 810, supports 1280 × 720 and 1920 × 1080, and preserves a 16:9 field with letterboxing in other window shapes. UI scales are 100%, 115% and 130%, with fullscreen, reduced motion and optional hit feedback.

Q buys one eligible whole ring immediately. Weapon/structure/terrain shortcuts otherwise select a tool for deliberate clicks and remain selected for repeated placement. G selects relay rebuilding. Tab collapses the catalogue; middle drag pans; wheel zooms; the minimap recenters. The final [controls reference](../CONTROLS.md) lists every binding.

Strategic zoom now hides indistinguishable empty slots and overlapping building text while retaining occupied, hovered and selected targets. Drawing cost in the repeated fixture fell from about 22 ms to 6 ms; total simulation cost still prevents real-time large swarms. [Final strategic view](artifacts/T-071-crowd-no-effects.png).

Visual examples: [Start and letterboxing](artifacts/T-067-letterbox-1600.png), [minimum-size HUD](artifacts/T-067-hud-1280.png), [relay failure/rebuild](artifacts/T-067-structure-relay-1280.png), [saved results](artifacts/T-067-results-130-1280.png), and [upgrade details](artifacts/T-067-shop-upgrades-130-1280.png).

## Decisions made for later confirmation

These are delegated implementation decisions, not individual approvals attributed to Kevin. Full reasoning and exact values are in [the decision register](delegated-decisions-2026-09-08.md) and [completion contract](../contracts/feature-completion-2026-09-08.md).

| Review | Implemented direction |
|---|---|
| D-112: run variety | Conservator emphasizes repair/armor, Prospector rewards kills at a durability cost, Interdictor emphasizes terrain. Balanced, Bulwark and Battery loadouts; Dense Swarm, Fragile Core and Rapid Elites mutators. |
| D-113: progression | Finite unlocks and three-level core/wedge/start-energy upgrades. Rewards combine survival, kills, expansion and three challenges. Prices, strengths and payout cadence are provisional. |
| D-114: opening | Keep the funded ring-1 starter rather than a clean slate; teach mechanics through separate full-access practice. |
| D-115: UI | Industrial housing, Barlow typography and the requested 16:9 field. Review readability and density in actual play. |
| D-116: persistence | Save settings/meta; no mid-run resume. Abandon, errors and practice earn zero. A crash before durable result settlement loses that unsaved run reward. |
| D-117: edge cases | Transfers use finite-speed inner-boundary routes after hopping and wait if entirely sealed. Sappers camp disabled relays. Assembler collapse attribution is preserved with overflow rejection. |
| D-118: diagnostics | Bounded local command traces identify the build, balance and tick order. No upload or mid-run resume; tutorial traces are explanatory unless their scripted mutations are reproduced. |
| D-119: strategic detail | Empty placement markers and building labels reduce when screen spacing becomes unreadable. Occupied, selected and hovered targets remain visible. |

## Verification and limitations

Final native clean-import correctness run: all 39 suites pass, with zero nonzero exits and zero timeouts (runner PID27708). [Machine-readable summary](../../.godot/test-logs/run-20260908-105749-616-27708/summary.json). The final Windows export and source identity verification passed. The exported main application then passed Start, Flak placement, cancellation, pause/resume, abandon, Quit and independent reload through events targeted only to its owned window. Both processes exited 0 through the UI. The real trace recorded 154 ticks, one accepted purchase, two pauses and one resume; the saved profile correctly retained zero reward for abandonment and was byte-identical after reload. [Package evidence](../../.godot/package-targeted/run-20260908-111224-267-39960/summary.json). A source snapshot/inventory is produced after this documentation freeze; its exact directory is identified in the final handoff. Focused coverage includes all 11 tutorial steps through actual controls, progression purchase/reload, 59 profile-store checks, 59 recorder checks, unchanged 246 stored gameplay digests and all 18 mixed 100/500/1,000-actor fixtures. Presentation verification includes 7,771 checks, 37 native capture checks and 539 strategic-detail checks; these overlap the aggregate and are not an additional unique-test total.

**Large-swarm performance is the main outstanding engineering limitation.** The 1,000-enemy cap remains an editable trial setting. The bounded headless 12-ring forced-volley fixture measured about 56 ms per simulation tick, above the 16.67 ms budget before rendering.

The rendered application probe used 12 rings, 1,000 actual mixed actors, 1440 × 810, VSync, a three-second warmup and 120 measured frames. Final effects off: median 198.582 ms/frame, p90 213.390 ms, 0.6714 simulated seconds per wall second. Final effects on: median 247.318 ms/frame, p90 265.468 ms, 0.5356 simulation/wall ratio. All 1,000 actors remained; no simulation errors occurred. An earlier pre-polish effects-on attempt exceeded its shorter deadline and is retained as incomplete evidence; both final runs completed all 120 frames. These are roughly 5.0 and 4.0 FPS by reciprocal median, not average FPS. This workload is not acceptably real-time, and disabling effects alone does not solve it.

Observed hardware: Intel Core i7-14700K, 28 logical processors, NVIDIA RTX 4080 with driver 610.88, Windows build 26200; pinned Godot 4.7.2 Compatibility renderer. These are bounded fixtures, not controlled comparative benchmarks or normal-run balance evidence. No cap reduction, discarded actors or timing-rule changes were used to claim a pass.

Human 15–25-minute sessions are still needed to assess pacing, recovery, dominant strategies, progression grind and whether losses are understandable. Feature implementation and correctness do not constitute final performance or gameplay acceptance.

Final star/world art, finished enemy/weapon/projectile assets, final animations, audio production and naming remain open. The earlier industrial/painterly art comparison remains an experiment, not an approved final art choice. Global foreground-input automation could not acquire a foreground window in this session; both guarded attempts aborted before input. The release executable also did not execute the external-script driver, so that attempt is not a pass. The successful check instead used owned-window Win32 messages against the actual exported main application, without embedded test hooks or gameplay grants. Ordinary physical desktop-input routing and clean-machine compatibility remain manual follow-up checks. No build is published or sent externally.
## Reproduce checks

From the repository root in PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run_tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/verify_build_info.ps1
```

Private export tooling is `scripts/export_private.ps1 -FrozenSource`; matching installed engine/template paths are documented in `scripts/README.md`. Source snapshots use `scripts/snapshot_source.ps1`. Do not treat a changed source tree as the same frozen build without regenerating and verifying its identity. Detailed evidence: [gameplay audit/corrections](T-065.md), [persistence](T-066.md), [application/UI](T-067.md), [final integration/package](T-068-verification.md), [headless matrix](T-068-performance.md), [movement correction](T-069.md), [diagnostics](T-070.md), and [final strategic/rendered results](T-071.md).