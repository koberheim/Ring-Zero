# Phase 5 evidence — Kevin-only engineering review (D-031 Option B)

2026-09-07. Scope approved by Kevin this session: readability at scale, relay-status presentation, wedge scaling math, and death-spiral behavior, using existing fixtures/captures only — no new implementation. Run sameness (D-029) is out of scope for this engineering pass; it is a content/variety question, not something this review measures. No numeric pass/fail thresholds are set here; Kevin judges the evidence below.

## 1. Readability at scale (D-008, D-024, D-030, D-031 risk)

The D-024 persistent ring-status HUD (T-029) was reviewed and accepted this session:
- [T-029-mixed-status.png](artifacts/T-029-mixed-status.png) — 3-ring case. A broken wedge, a collapsed ring, a critical wedge, and a surviving relay are all clearly distinguishable at a glance, off to the side from the main selected view.
- [T-029-twelve-ring-readability.png](artifacts/T-029-twelve-ring-readability.png) — 12-ring case. Functionally correct (verified by 26 independent checks) but visually dense: broken/critical marks are thin slivers with no visible per-wedge divider lines. This matches the density risk D-024's own option comparison flagged for Option A in advance.

**Reading:** readability holds at the current 3-ring slice scale. It measurably degrades by ring 12, in the specific way anticipated when Option A was chosen over Option B (scrolling/filtering). No time-to-identify measurement beyond visual inspection was taken (no external participants in this Kevin-only pass); the HUD's own accepted captures are the evidence.

## 2. Relay-status presentation (D-023, D-024 risk)

Per D-041, power and brownouts are deferred; relay status in this slice means structure present/destroyed only. The T-029 capture shows a white ring marker on the relay's wedge on ring 2 (present) and no marker on ring 1 after its collapse clears `state.rings[1].relay` (destroyed). This is the full extent of relay information in the current slice — there is no separate relay HP, connectivity, or brownout state to evaluate, because none is implemented (correctly, per D-041).

**Reading:** the presentation matches the approved scope exactly. Relay-frustration risk from *power* mechanics (D-023) remains entirely untested, because those mechanics don't exist yet in the slice.

## 3. Wedge scaling math (D-012, D-014, D-031 risk)

Both ring cost and wedge max HP use `scaling.claim_cost_ring_exponent` / `scaling.wedge_hp_ring_exponent` = 1.0 (linear) against `economy.ring_plate_base_cost` = 10 and `health.wedge_base_hp` = 100 (`data/balance/testing.json`):

| Ring | Whole-ring cost (12 × 10 × ring) | One wedge max HP (100 × ring) | Cost per total ring HP (12 wedges) |
|---|---|---|---|
| 1 | 120 | 100 | 0.1 |
| 2 | 240 | 200 | 0.1 |
| 3 | 360 | 300 | 0.1 |
| 6 | 720 | 600 | 0.1 |
| 12 | 1,440 | 1,200 | 0.1 |

Whole-ring cost divided by the sum of all twelve wedges' maximum HP is constant at 0.1 across the listed rings. This establishes only the behavior of these two linear curves; it does not establish expansion difficulty, economic viability or an optimal radius. Frontage, build slots, actual weapon coverage, kill throughput and delivered power were not measured here.

**Correction found and fixed during this review:** T-029's HUD critical-threshold check (`live_view.gd::_ring_status_records`) compared each wedge's live HP against the flat `health.wedge_base_hp` (100) instead of that ring's actual scaled max HP. Because HP scales linearly with ring, this made the "critical" (<25%) mark on rings beyond ring 1 harder to trigger than intended — e.g. a ring-3 wedge at 50 HP (16.7% of its true 300 max, genuinely critical) would have read as "ok" (50/100 = 50% of the wrong reference). Fixed to use `wedge_base_hp × ring^wedge_hp_ring_exponent`; the existing 71 live-view checks (including the 5 HUD checks) still pass, and the visual captures were unaffected because their fixture values were extreme enough to read correctly either way. This is exactly the kind of finding this review category exists to catch.

## 4. Death-spiral behavior (D-005, D-021, D-022, D-031 risk)

D-005/D-041 exclude assimilation, retaking, and any recovery mechanic from this slice. Existing fixtures (`test_live_simulation.gd`, `test_live_view.gd`'s `collapse_fixture`) confirm: a ring collapses once 7 of 12 wedges break; every occupant and slot on that ring is cleared with no refund; outer rings and their relays survive independently; the game continues with the reduced owned area.

**Reading:** by construction, this slice has no comeback mechanic at all — any ring lost is permanent for the rest of the run. That is not a bug; it is the deliberately deferred state (D-021/D-022 remain open exactly because recovery rules haven't been designed). It does mean the current slice cannot demonstrate anything about comeback quality or death-spiral *severity* — only that loss is currently absolute. Evaluating whether that absoluteness itself feels fair is closer to a playtesting question (D-031 Option A, deferred) than an engineering one.

## Summary for Kevin

- Readability: acceptable at slice scale (3 rings); degrades in the specific, already-anticipated way at 12.
- Relay presentation: matches approved scope; power-related relay frustration is untested because power doesn't exist yet.
- Wedge scaling: linear and consistent through ring 12; no degenerate values. One real HUD correctness bug found and fixed along the way.
- Death spiral: not yet answerable beyond "loss is currently permanent by design," since recovery rules are still undesigned (D-021/D-022).

No further engineering scenario is queued; this covers the approved Phase 5 scope. Kevin decides whether this warrants further work, closes Phase 5, or reopens D-031 toward broader playtesting.

## Audit correction - 2026-09-07

After Kevin requested the post-slice audit, Astra corrected the table above: the original 1.2 divided whole-ring cost by one wedge's HP. Cost per total ring HP is 0.1. The constant-ratio observation survives; the original inference that rising difficulty comes entirely from spawning was too broad and is narrowed above. Phase 5 acceptance remains unchanged.

The twelve-ring image validates the HUD's status rendering only: its fixture leaves the world grid at three rings. It does not validate building or world selection at ring 12. The existing scaled-HP fix works for unmodified profile-derived maxima, but a new audit probe finds that it still ignores valid per-wedge max_hp values; regression coverage must be added. See post-slice-audit.md for reproduced evidence and proposed follow-up. These corrections do not reopen the accepted HUD density or current performance limitations.
