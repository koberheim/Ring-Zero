# Phase 8 continuation — effort briefing

Final effort briefing, 2026-09-07. Phase 8 is implemented and verified, ready for Kevin's D-101 review. This does not mark the phase accepted by Kevin or lock the art direction.

## What this effort covers

Kevin asked Astra to audit Claude's completed Phases 6/7 and partial Phase 8, continue the approved phases, and then added a playable art comparison. The existing acceptance of Phases 1–7 stands. The original design specification was not edited.

## Verified audit corrections

- Public enemy snapshots now copy mutable status arrays; callers cannot change live assimilation through a returned snapshot.
- Broken-ground repair rejects a living occupant before spending energy, preventing the previously reproduced successful repair followed by a stopped simulation.
- Malformed stun/assimilation values fail through structured validation. Failed casts/ticks preserve committed state.
- EMP Node now affects every eligible target on its own ring; Lance fires outward along its own wedge column without the old target cap. Point Defense retains exact-cell targeting. Stun expiry no longer gains an extra frozen tick from roundoff.
- Assimilation's unchanged bonus, cap and duration are editable validated data. Armor HP arithmetic rejects nonfinite results before charging.
- The three added weapons are purchasable in the Weapons tab. Missing building labels, incorrect power errors and invisible repair/reclaim prices were corrected.
- The native Windows test runner validates the pinned engine, imports classes, discovers suites, runs bounded hidden processes and rejects missing exit codes. Its initial PowerShell process-handle defect was found and corrected.
- Stale decision headers and the command contract were reconciled to already approved behavior. Editor-only operation and deferred command recording were preserved as approved scope, not silently reinstated.

Evidence: [audit](phase8-continuation-audit.md), [gameplay corrections](T-043.md), [Windows runner](T-044.md), [weapon controls](T-045.md).

## World growth and solar rules

The main live scene now grows beyond the old three-ring view restriction. Actual-input tests buy through ring 12, select and build on outer ground, focus from the HUD, repair/reclaim, pan/zoom and retry. Growth preserves the camera; a fresh run deliberately resets it. Only required geometry is allocated. This verifies operation through twelve rings, not unlimited-size performance. [T-047 evidence](T-047.md).

Focused Flare and EMP Burst rules are implemented with independent cooldowns, clicked bearing/point targeting, underground immunity and no energy from ability kills. Cast kills are separate command events so the next simulation tick cannot credit them again. Long-range geometry uses double-precision polar calculations after review found a boundary miss through float32 rendering coordinates. All damage, ranges, cooldowns and stun durations remain editable testing values. [T-048 evidence](T-048.md).

## Art comparison

Kevin chose industrial and painterly for rough playable exploration. The preview shares the real live game and adds Art/Sun cycling controls, motion freeze, close-core and strategic-view shortcuts. Sun palettes are red giant, yellow and white. The sun uses animated procedural texture, slow swirling motion, a visible corona and wisps.

Industrial emphasizes shaded segmented plates and close-up structures. Painterly emphasizes quiet bands and graded stellar atmosphere. Detail and labels simplify at strategic zoom. The first captures were revised because the corona was hidden and the treatments differed too little. A cache regression involving retained occupants on broken wedges was also caught during review.

The revised limited rendered check used twelve rings and 100 durable enemies already at contact, with 120 measured frames per treatment. Both median frame intervals were about 16.67 ms with VSync enabled on the local RTX 4080. Drawing was about 4.62 ms. This supports the rough preview only; it is not a new 1,000-enemy or final-capacity claim. Initial measurements had a workload-comparability issue and remain historical, not a claimed controlled speedup.

Launch instructions: [ART-PREVIEW.md](../ART-PREVIEW.md). [Industrial close](artifacts/T-049-industrial-close.png), [painterly close](artifacts/T-049-painterly-close.png), [strategic view](artifacts/T-049-painterly-strategic.png), [six-second sun animation](artifacts/T-049-sun-motion.mp4).

These are intentionally rough procedural studies, not production assets or final D-030 approval. The test captures use fixture funding; the actual scene retains normal starting funds and pressure.

## Terrain rules verified

Debris Field blocks its outer boundary, cannot be damaged by enemies and cannot create an invulnerable seal. Tractor Lane applies a soft clockwise/counterclockwise preference to the adjacent approach band; it changes routes, not speed, and does not pull enemies away from contact attacks. Occlusion Screen slows surface movement in its outward wedge column; overlapping shadows use the strongest effect once and leave attacks, cooldowns and underground travel unchanged.

All terrain uses normal slots, becomes inactive on broken support, reactivates on repair and is removed on ring collapse. Repair and reclaim validate both frontier routes and current surface-enemy escape routes before committing. Review caught a pure-rule repair path that bypassed the live guard; both layers now reject forbidden seals. Shadow movement is split at the actual crossed boundaries rather than applying one cell's speed to the entire journey. [T-050 evidence](T-050.md) records 2,704 passing focused checks.

| Tool | Provisional starting values |
|---|---|
| Debris Field | 30 energy |
| Tractor Lane | 25 energy; preferred route cost multiplied by 0.5 |
| Occlusion Screen | 30 energy; three outward rings at 50% movement speed |
| Focused Flare | 60 damage; 30-second cooldown; eight-ring-width range; 60-degree sector |
| EMP Burst | 2 damage; 10-second cooldown; 1.5-ring-width radius; two-second stun |

These values are testing defaults under D-033, not final balance. Edit validated values in `data/balance/testing.json`; the [balance-data guide](../balance-data.md) describes the fields.

## Playable controls verified

T-051 connects every terrain purchase and both solar casts to normal live play and the art preview. The building menu retains three tabs. Solar buttons sit below them with ready/cooldown text. Right click cancels targeting; Menu/Retry clear it. Terrain inspection shows direction or shadow coverage/speed. Target outlines track pan/zoom and accept aiming outside the currently displayed build rings without allocating extra board geometry.

Both scenes passed 116 integrated input checks, with 500 focused presentation checks overall and 18 rendered capture checks. Astra inspected final captures, including the correction that removes a square atmosphere edge at the initial three-ring view. [T-051 evidence](T-051.md), [current playable art/terrain view](artifacts/T-051-art_preview-terrain.png), [Flare targeting](artifacts/T-051-art_preview-flare-aim.png), [EMP targeting](artifacts/T-051-live_view-emp-aim.png).

To try it: open `scenes/art_preview.tscn` in Godot 4.7.2 and press F6. Cycle Art and Sun on the right, try Close core and Strategic view, and use middle-drag/wheel for free camera control. The normal F5 main scene remains available. Starting funds are 160 energy with the existing ten-second normal-enemy arrival delay; the generous funding in capture screenshots is not the playable scene's balance.

## Work beyond this checkpoint

Independent relay targeting/destruction/rebuild, brownout presentation and the recovery payback measurement remain named follow-ups. Large crowds remain a material limitation: final T-050 short 1,000-machine fixtures measured roughly 42–65 ms per simulation step depending on scenario, above a 16.67 ms 60-Hz budget. These are separate from the 100-enemy rendered art comparison and do not establish sustained full-run performance. The approved trial cap and existing testing acceptance have not been silently lowered or replaced.

Phase 9 adds the remaining elites and Assemblers after a concrete D-019 briefing. Later phases cover doctrines/loadouts/mutators, persistent progression, tutorial/accessibility and integrated long-run/scale testing. No standalone export, save/resume or publishing readiness is claimed by this effort.

## Final integration and recommendation

After all implementation owners froze source, the native Windows runner imported successfully and passed **all 24 discovered suites**, runner exit 0, every child exit 0, no timeout. Run started 2026-09-07 22:06:07 UTC. Evidence: `.godot/test-logs/run-20260907-220607-933-38624/summary.json` and [T-052 report](T-052.md). Final logs contain no script/parse/shader error. Deliberate invalid-input diagnostics and the known offline certificate-store message are documented rather than mistaken for failed suites. All tracked test processes exited. No performance baseline was regenerated.

Astra recommends accepting the Phase 8 checkpoint (D-101) with the explicit remaining work above, then briefing the Phase 9 enemy roster under D-019. The alternative is to hold the checkpoint for specific corrections Kevin identifies during play. This acceptance covers tested functionality, not final balance, final D-030 art selection or publishing readiness. For the art review, compare ring/enemy readability at strategic zoom, useful close detail, and whether the sun's presence and animation feel strong enough. Kevin can prefer elements of either treatment without locking a final direction.
