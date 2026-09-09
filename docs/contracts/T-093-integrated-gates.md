# T-093 — Integrated acceptance, full-run QA and candidate decision

**Date:** 2026-09-09. **Status:** Approved under D-135; assignment follows dependency gates. **Workstream:** ALL. **Owner:** Sol; Astra reviews. **Reviewer:** Astra, with Kevin/designated reviewer for named human gates.

This task inherits [the shared Phase 14 contract](presentation-v3.md), including authority, exclusive file leases, the 42-suite floor, matched performance limits, before/after evidence and failed-gate handling. Read the full critique and [verification](../reviews/critique-2026-09-09-verification.md) before work. Kevin approved D-135 on 2026-09-09. This contract is authorized subject to its dependency gates and Astra's explicit file lease.

## Dependencies

All six streams accepted, including final T-083 sound, T-089 non-elite matrix, T-090 crowd gate and T-092 elite matrix; no unresolved acceptance failure.

## Editable scope

**Isolated harness preparation lease — Astra, 2026-09-09, base `f8411ff`:** Sol/A may implement a new task-specific natural-run/strategy harness and evidence under T-093 while B/E/D implement disjoint source. Existing gameplay, presentation, export metadata and old diagnostic fixtures remain read-only. No Godot execution until the current runtime owner explicitly hands off; no claim of final integrated acceptance from preparation. Preserve the natural-run constraints below. Full native execution follows final interfaces; preparing this test does not waive human/source gates or permit RC promotion.

tests/presentation/ and tests/performance/ targeted final harness work; scripts/ existing test/export/package tools if required by changed layout; docs/reviews/presentation-v3/; final release report and package metadata only after gate approval. Feature fixes return to their owners.

All other files are read-only unless Astra revises the contract before granting a new lease. No owner writes the three planning logs; submit delivery facts for Astra to review and record.

## Required delivery

Run the complete 42+ suite aggregate from a clean import, native performance and pan/Alt matrix, all resolutions/input/settings/accessibility states, retained profile migration and packaged Start/build/pause/abandon/quit/reload. Perform an actual unaccelerated 15-minute Containment run and a defeat/retry run; record commands/state and video, not just a forced elapsed-time fixture. Review event ordering at collapse/victory/save, memory/voice/effect cleanup over repeated runs and long-session timing. Close every original T-079 row against its mapped live replacement, then obtain explicit final human presentation/listening acceptance. Only after all gates pass should the packaging owner update candidate metadata, freeze source hashes, export and validate the archive. No Steam activation, public publishing or store claim is inferred from this pass.

## Done condition

Astra signs the per-task acceptance matrix from independent reproduction; all 42+ suites, identity/state/input/save checks and matched performance pass. All required human art/comprehension/listening results are recorded and passed. T-079 is explicitly closed, not merely referenced. Full-duration natural-run and defeat evidence is retained; diagnostic fixtures are labeled. Final package identifies the tested source and passes owned-window lifecycle and archive/hash checks. A failure means no new candidate label/package promotion and an immediate report to Kevin with the repair owner.

## Evidence

Final matrix/index with before/after per stream, full-run recordings/traces, aggregate tests, native timing deltas, memory/resource observations, package lifecycle results and hash manifest. Save under `docs/reviews/presentation-v3/T-093/`, including a pass/fail table, actual commands, source identity and the shared fixture metadata. Preserve before evidence.

## Handoff and review

Continuation preparation (Astra source audit): `tests/performance/play_operation.gd` is an accelerated deterministic purchase bot, not native full-duration evidence. `test_release_candidate.gd` and `capture_release.gd` explicitly assign elapsed_seconds=900 and remain diagnostic lifecycle fixtures only. Final QA needs a separate native application harness with real fixed-step wall pacing, no elapsed/core/energy/target state assignments after a normal start, and logged successful/failed ordinary player commands. A deterministic strategy may be rehearsed separately to choose a legitimate sequence; preserve those outcomes and label the automated player. Final evidence records at least the complete natural run, actual outcome, pause/retry behavior, simulation versus monotonic wall time, frame timestamps/video and independent persisted reward readback. Do not assert victory merely because a harness loop reached its end. The isolated test profile must not alter the user profile.

The existing `scripts/smoke_targeted.ps1` assumes a2560x1440 logical frame and scales input to it; after T-087, adapt this owned-window checker to measured native client coordinates. Keep PID/window guards and avoid global input/focus. Existing export tooling uses pinned Mono4.7.2 templates while gameplay probes use standard4.7.2; record both identities and verify the actual exported backend. Do not update RC metadata or promote the package while source/human gates remain pending.

Plain-English executive report of choices, implementation architecture by owner, asset/audio provenance, provisional values, exclusions, evidence and remaining external Steam/commercial requirements.

Submit an atomic task commit or narrowly scoped reviewed patch, changed-file list, checks and their results. Stop at an unmet/failed gate and identify it; do not substitute assertions or defer it. Astra reproduces the exit check, returns regressions to this owner, and records accepted status. Partial deliveries remain partial until every task condition is met.
