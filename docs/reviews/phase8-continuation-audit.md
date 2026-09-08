# Phase 6-8 continuation audit

2026-09-07. Kevin requested verification of Claude's work and continuation through the phases. Accepted D-086/D-087 scope and exceptions remain in force. Art remains undecided; four forthcoming mockups/rankings are references only.

## Baseline

All 18 existing suites exited 0 under pinned Godot4.7.2, sequential hidden tracked processes, workspace APPDATA/LOCALAPPDATA and 30-second suite limits. Logs `.godot/phase8-audit-test_*.log`. Passing baseline does not cover the additional defects below. Existing performance acceptance is not reopened; no new rendered performance result was collected for this baseline.

Phase 6 delivered corrected authoritative-HP HUD classification, regression coverage, cache-independent digest location, editor Retry/results and a documented state contract. D-032 explicitly chose editor-only/no save/export; D-086 explicitly deferred command recording. Those are not omissions to reimplement now.

Phase 7 delivered Repair/Reclaim, Armor/Repair Node, power budget/brownout and assimilation. D-087 expressly carries playable growth beyond three rings and the recovery payback check forward; independent relay damage remains a Sapper-era simplification. Phase 8 delivered three weapon rule layers but left their UI, terrain and abilities unfinished.

## Findings and assigned corrections

| Finding | Evidence | Disposition |
|---|---|---|
| Snapshot mutates live assimilation | Root probe appended expiry15 through targets_snapshot and observed live array `[15.0]`; `.godot/phase8-audit-probe.log` | T-043 public copy isolation and regressions |
| Occupied repair stops next tick | Same probe: repair_ok=true, next_tick_ok=false, invalid/intact cell error | Kevin approved D-094: reject occupied broken-wedge repair without charge; T-043 |
| Stun/assimilation metadata accepts malformed values | New fields lacked strict finite/type checks before coercion/iteration | T-043 validates and tests structured atomic failures |
| EMP/Lance targeting differs from approvals | EMP lacks own-ring restriction; Lance can target inward; both truncate approved all-target effects | T-043 restores D-088/D-089 selection and tests beyond old caps |
| Stun roundoff can add a frozen tick | Terra's before-fix tests reproduce expiry past the 90-tick1.5s interval | T-043 applies only existing roundoff tolerance |
| Assimilation knobs hardcoded | .05 damage bonus,10 stacks,15 seconds in live_simulation.gd | T-043 moves unchanged defaults to validated profile fields |
| Armor addition can overflow valid finite inputs | Terra reproduced HP1e308 + bonus1e308 returning successful nonfinite state | T-043 finite-result rejection before spending |
| Weapon power errors give wrong advice | Generic weapon failure told player to choose an empty slot | T-045 accurate shared insufficient-power message |
| Structure labels/variable quotes missing | Armor/Repair Node absent from name map; repair/reclaim spend without visible authoritative price | T-045 uses approved labels and existing status text for price preview |
| New weapons cannot be purchased in UI | T-040/041/042 explicitly deferred UI | T-045 integrates existing Weapons tab and live placement |
| Runner clean-copy safeguards incomplete | Bash-only runner lacks explicit import/version validation and can accept zero discovered suites | T-044 native Windows runner; preserves legacy invocation and honestly documents internal timing blocks |
| Logs/contract contradict completed work | D021/022/023 headers still pending despite resolutions; command contract overstates tick-only recovery and public-field isolation | Reconciled to existing approvals/actual transaction boundaries, no new authority |

## Remaining work, not closed by this audit

- Terrain: D-091/092/093 approved core shapes; D-095 now resolves Debris immunity, supporting-ring collapse and forbidden invulnerable seals. Exact composition/targeting interactions still need concrete contracts.
- Abilities: D-026 approves zero energy from ability kills; complete player targeting and effect-interaction contract is still needed before full integration.
- D-021 says destroyed occupants grant assimilation; D-022 retains occupants on individual broken wedges. Current implementation grants only on actual wall removal/full collapse. Do not delete retained buildings or invent extra grants to reconcile wording silently.
- Growing playable world, relay vulnerability/rebuild and brownout presentation, recovery payback, later enemies, progression, tutorial and final scale/readability remain tracked follow-ups, not newly completed features.
- Historical digest updates were documented, but a future all-fields mismatch is not by itself proof of harmless schema change. Retain old/new provenance and normalized behavior comparisons before replacing baselines.

## Verified continuation checkpoint

T-043/T-044/T-045 are accepted by Astra after source review and the native Windows runner's import plus 19 passing suites, exit 0: `.godot/test-logs/run-20260907-211539-711-40748/summary.json`. T-044 initially exposed a real PowerShell process-exit-code issue; retaining the process handle before waiting corrected it. The runner rejects absent exit codes rather than treating them as success.

T-045's final two prompt-only edits followed that aggregate run; the catalogue suite passed again (73 checks), captures passed (12 checks), and Astra inspected the final Structure PNG with plain-language prompts. The aggregate run therefore is not represented as covering later edits. T-043's focused gameplay checks total 2449, all passing. Reports T-043/T-044/T-045 contain the detailed evidence.

T-046 directed route support is accepted after source review and 287 focused checks including independent reference graphs. It preserves the default undirected API; this is not a new crowd-performance claim. T-047 growing-world and T-048 solar rules continue. D-096/D-097 settle shadow stacking and solar targeting. D-099/D-100 explicitly brief remaining terrain influence/support choices rather than inventing them.

Kevin has requested a playable industrial/painterly art comparison with a signature animated sun (D-098), assigned as T-049 after growing-world work. Final D-030 remains open. This checkpoint does not claim Phase 8 completion.

## Final effort result

The subsequent T-047 through T-051 deliveries close growing-world operation, terrain rules/controls, both solar abilities and the requested playable art studies. All are verified. T-052 ran a clean import and all 24 suites on frozen source: zero failed suites, no timeout or script/parse/shader error. Logs: `.godot/test-logs/run-20260907-220607-933-38624/summary.json`. Source and rendered review are complete; Phase 8 is ready for Kevin's D-101 checkpoint review.

The full user briefing is [phase8-effort-briefing.md](phase8-effort-briefing.md). It retains unresolved large-crowd performance, relay/brownout and recovery-payback work, and later phases. Final art is not selected. Earlier unfinished-item lists above describe the initial audit state, not the final delivery.
