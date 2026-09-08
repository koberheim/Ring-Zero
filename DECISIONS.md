# RING ZERO — Decisions

## Current authority and later review

**Updated:** 2026-09-08. Kevin authorizes feature completion and delegates non-art choices, to be logged and highlighted for later confirmation. This supersedes earlier individual phase/design approval stops. UI direction is explicitly gritty industrial sci-fi. **Final world art direction is now decided (D-120, resolving D-030)** — see `docs/art-direction-style-guide.md` and `docs/art-asset-pipeline.md`. That pass also produced two rule/UI decisions: D-121 (wedge destruction destroys occupants, with salvage refund) and D-122 (Alt-held tactical overlay); both need implementation.

**Status:** Feature implementation and private package verification are complete. All 39 final suites pass; exported Start/build/pause/abandon/Quit/reload passes through owned-window input. Later reviews cover the delegated decisions below, final art and measured large-crowd performance. No new approval is needed to try the candidate.

**Provisional decisions to confirm later:** [D-111 through D-119](docs/reviews/delegated-decisions-2026-09-08.md). D-028/D-029/D-042 and non-art D-032/D-035 details are resolved provisionally there under delegated authority; historical pending entries below are retained as history, not active blockers. D-034 final branding remains Kevin's review; **D-030 is now resolved by D-120** (final art direction decided 2026-09-08), with D-121/D-122 raised by that pass and awaiting implementation. D-007 final crowd capacity and balance quality remain measured/playtest reviews, not permission blockers for implementation.
## Authority and coverage

### D-102 — Interim hotkeys and UI usability
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin (requested scope); Astra (reversible key/layout mapping)
**Status:** Authorized, implementation underway

Kevin requested hotkeys for all building categories and less empty menu space before testing and before Phase 9. T-053 provides direct tool selection, persistent deliberate-click placement, a compact hideable catalogue, concise status/help and collapsed art settings. The chosen key map is documented in its contract and will be visible in game. These are interim usability changes, not final art or balance. They reduce repetitive selection and battlefield obstruction; the tradeoff is learning shortcuts, mitigated by labels/help and retained mouse controls. Key mappings/layout are cheap to revise after play. D-101 checkpoint review remains pending this follow-up; no Phase 9 advancement.

### Active continuation decisions (2026-09-07)
D-096/D-097 are approved (shadow composition and solar targeting). D-098 authorizes exploratory industrial/painterly live art with animated sun variants; D-030 final art is still open. D-099/D-100 terrain approach/support packages below are approved and clear terrain implementation. These implementations are now verified. D-101 is the current checkpoint review.

Kevin's kickoff, received 2026-09-06, requires planning only in the first session, no delegation or implementation until review and blocking decisions are cleared, no spec edits by Astra, and Kevin's approval for creative, scope, expensive, or ambiguous decisions. These are standing decisions, not questions being reopened. BUILD-PLAN.md records the fixed spec requirements; this log records new planning choices and unresolved questions.

Read all 18 spec sections. Coverage: title → D-034; §§1–4 → D-007–D-008, D-025–D-026, D-031, D-035; §5 → D-006, D-009, D-011–D-012; §§6–7 → D-010, D-013, D-017, D-029; §8 → D-023–D-024; §9 → D-011, D-014–D-016, D-027; §10 → D-016–D-019, D-021; §§11–12 → D-015, D-020–D-022; §13 → D-026; §14 → D-028–D-029, D-032, D-034; §15 → D-030; §16 → D-007–D-009, D-016–D-017; §17 → risk table below; §18 → D-004–D-006, D-031. D-033 prevents unresolved tuning fields becoming silent defaults.

The grid retains 12 wedges. Kevin approved a collapse threshold of 7 and a menu-pause exception in D-039, superseding the original spec wording. Run length 15–25 minutes is the full-game target; slice test length remains a separate choice. The spec's §7 points variety readers to §13, but the actual meta/doctrine material is §14; use §14 without editing the source.

| Flagged risk | Open decision records |
|---|---|
| Run sameness — highest priority | D-029, D-031 |
| Death spiral | D-005, D-021, D-022, D-031 |
| Readability at scale | D-008, D-024, D-030, D-031 |
| Relay frustration | D-023, D-024, D-031 |
| Wedge scaling math | D-012, D-014, D-031 |

Unchosen numbers are grouped with the rule they control. Each relevant brief must enumerate and receive approval for all required values; this inventory is not a hidden balance sheet. Existing illustrative doctrine names are not final selections.

## Recorded Tier 1 decisions

---
### D-001 — Keep the spec separate from planning
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
These three Markdown files record plans, tasks, and decisions; the design specification remains untouched. Open questions cite its section numbers.

**What we get**
Kevin can distinguish the game definition from a proposal.

**What it costs us**
Readers must follow links between the spec and logs.

**What happens if we're wrong**
File organization is cheap to revise; the original spec remains available.

**Blocking:** None.

---
### D-002 — Plan later phases without premature task backlogs
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
Only phase one receives task IDs. Later phases record deliverables, owners, dependencies, and checks, with detailed briefs written only after approval.

**What we get**
The memory stays useful without inventing future implementation detail.

**What it costs us**
Later sessions must define tasks as each phase approaches.

**What happens if we're wrong**
Adding or moving unassigned tasks is cheap. This does not approve a phase or change its scope.

**Blocking:** None.

---
### D-003 — Keep agent ownership and review boundaries explicit
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
Each eventual brief belongs to one implementation owner. Astra defines shared contracts before sequential handoffs; delivered work must be reviewed before integration.

**What we get**
Agents need less context and cannot silently invent incompatible interfaces.

**What it costs us**
Astra must prepare contracts and review each handoff.

**What happens if we're wrong**
Briefs and paths can be revised before assignment with little cost. No agent has been assigned.

**Blocking:** None.

## Tier 2 decision history

---
### D-004 — Approve the phased slice plan
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** Kickoff; §18

**What this is about**
The proposed phases stop at evaluating the vertical slice. Kevin must approve scope and sequencing before any implementation or assignment.

**The options**
- **Option A:** Approve BUILD-PLAN.md with the decision gates shown.
- **Option B:** Revise phase boundaries or deliverables before approval.

**What we get**
Approval gives every owner a clear handoff and stopping point.

**What it costs us**
Later phases remain estimates of work, not scheduled commitments; revisions may change dependencies.

**What happens if we're wrong**
Editing the plan now is cheap. Changing it after implementation may discard work.

**My recommendation**
Approve the sequence subject to the separate scope and foundation answers below. It proves the grid before investing in combat.

**Blocking:** None for the approved foundation; remaining follow-ups are stated above.

**Resolution - 2026-09-06**
Kevin said: "D-004, D-006 through D-009 are approved." Recorded as approval of the recommendations. Approved the recommended phase sequence and its separate decision gates. This clears assignment of foundation work; it does not approve other pending choices.

---
### D-005 — Decide which wider rules belong in the slice
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§8, 10.4, 12, 13, 18

**What this is about**
The slice lists four build items and one elite, but does not explicitly include relays, assimilation, retaking, or abilities. These rules affect whether ring loss is survivable, so neither omission nor inclusion should be assumed.

**The options**
- **Option A:** Keep the explicit §18 list; explicitly defer power, assimilation, retaking, and abilities, and limit conclusions about recovery.
- **Option B:** Add assimilation and retaking to the slice; defer power and abilities.
- **Option C:** Also include relays and brownouts, with abilities decided separately.

**What we get**
A keeps the experiment small. B tests the specified death spiral and comeback together. C also tests cascading power loss.

**What it costs us**
Each addition increases implementation and test work. A cannot establish whether the full loss-and-recovery loop works.

**What happens if we're wrong**
Adding omitted systems later is possible, but earlier balance and loss verdicts may need repeating.

**My recommendation**
Choose B if the slice must judge the complete collapse/comeback tension. Kevin should explicitly accept the added scope; keep the other systems deferred unless essential to his intended test.

**Blocking:** None. Explicit slice scope is approved.

**Resolution - 2026-09-06**
Kevin explicitly chose Option A: use the listed section 18 scope. Defer relays/power, assimilation, retaking, and abilities. Collapse tests judge readability and immediate setback only; they cannot validate the full death-spiral/comeback loop. The full-game design remains unchanged.

**Amendment - 2026-09-06**
Kevin's D-011/D-041 now includes a relay structure with each full-ring purchase. Working power and brownouts, assimilation, retaking, and abilities remain deferred. This later instruction supersedes only the relay-structure exclusion.

---
### D-006 — Define three rings and the core
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§5, 6, 11, 18

**What this is about**
Ring 0 is the core, while the slice says three rings. The spec does not say whether that means rings 0–2 or core plus rings 1–3, or whether the core has wedges, build slots, and its own defeat threshold.

**The options**
- **Option A:** Core plus three buildable rings; core is one separate HP pool with no build slots.
- **Option B:** Three bands total including the core; core is one separate HP pool.
- **Option C:** Core uses the same 12-wedge model; Kevin specifies whether it counts among the three.

**What we get**
A exposes three full expansion bands. B gives the smallest scene. C reuses wedge rules.

**What it costs us**
Core shape affects selection, attacks, the HUD, starting defenses, and the meaning of defeat. A is larger than B.

**What happens if we're wrong**
Changing core representation later touches rules, rendering, and saved data.

**My recommendation**
Use a separate core plus rings 1–3, subject to Kevin confirming that interpretation. Decide core HP with D-015 and starting defense with D-010.

**Blocking:** None for the approved foundation; remaining follow-ups are stated above.

**Resolution - 2026-09-06**
Kevin said: "D-004, D-006 through D-009 are approved." Recorded as approval of the recommendations. Approved Option A: separate core at ring 0 with no build slots, plus buildable rings 1-3. Core HP and starting defenses remain with D-015 and D-010.

**Explicit confirmation - 2026-09-06**
Kevin subsequently specified Option A.

---
### D-007 — Choose the runtime and performance target
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§1, 16

**What this is about**
Godot 4 is fixed, but its release, scripting language, renderer, target hardware, machine cap, and performance budget are not. These choices determine what a meaningful load test is.

**The options**
- **Option A:** Approve a Windows desktop prototype, GDScript, compatibility renderer, and a provisional 60 FPS target; name reference hardware.
- **Option B:** Approve a Windows desktop prototype using C# and another renderer; name reference hardware and frame target.

**What we get**
A reduces setup for a small prototype. B can support a different toolchain or rendering need.

**What it costs us**
Hardware is currently unknown. Either choice needs the installed Godot version checked and pinned after approval; no performance claim is possible yet.

**What happens if we're wrong**
Language migration is substantial. A renderer or version change can break scenes or effects.

**My recommendation**
Prefer A for this placeholder slice. Start by measuring 500 and 1,000 active machines on Kevin's reference machine before asking him to approve a hard cap; these are proposed test loads, not selected limits. Fix the simulation rate at a proposed 60 updates/second only with approval.

**Blocking:** None for the approved foundation; remaining follow-ups are stated above.

**Resolution - 2026-09-06**
Kevin said: "D-004, D-006 through D-009 are approved." Recorded as approval of the recommendations. Approved recommended Windows/GDScript/compatibility setup, provisional 60 FPS goal, 60 physics updates per second, and later 500/1,000-machine measurements. Verified installed Godot 4.7.2.stable.official.ed1daf0bf and pinned it for the foundation. Reference hardware and measured hard cap remain unset; they do not block grid work.

**Explicit confirmation - 2026-09-06**
Kevin subsequently specified Option A.

**Performance follow-up - 2026-09-06**
Kevin specifies hundreds/thousands of simultaneous enemies for final gameplay (They Are Billions reference). The 2/second test rate in D-017 is not a density limit. Initial 500/1,000-machine checks are a starting measurement set, not a final ceiling; extend measurements into several thousand before claiming the intended scale. A live-run hard cap remains a separate measured decision.

**Diagnostic follow-up - 2026-09-07**
Astra reran the existing T-023 instrumented headless cost review (`tests/gameplay/test_live_simulation.gd -- --cost-angular-only/--cost-sealed-only --cost-no-digest`, unchanged fixture, 1,000 machines, 120 measured ticks, source unmodified) to find why T-028's rendered angular fixture regressed to 101-104 ms/frame with only 65-66 of 120 frames continuous, versus the earlier accepted 49.120 ms/120-of-120 result. Finding: pure simulation cost (`LiveSimulation.step`, no rendering) is unchanged and not the cause of any code regression. Sealed mode costs 10,327 us median / 10,889 us p90 — comfortably inside the 16,667 us (60 Hz) budget. Angular mode (the funneling/continuous-motion case) costs 15,878.5 us median / 16,414 us p90 by itself, leaving under 800 us of margin for Godot's own draw/UI work before a frame misses budget. T-028 added Tunneler draw calls (triangles, countdown text, warning marker); that small added draw cost is enough to push angular frames over budget, and each miss queues an extra catch-up simulation tick on the next frame, compounding into the observed 101-104 ms readings and failed continuity. This is not a bug introduced by any single task — every prior angular measurement back to T-021 (14.6-17.3 ms headless) shows the same near-zero margin; T-028 is simply the first to add enough rendering cost to expose it consistently. No gameplay or simulation source was changed by this diagnostic.

This sharpens the still-open final-capacity question: at 1,000 concurrent machines in the funneling/angular case, GDScript simulation alone already consumes ~95% of the 60 Hz frame budget before any drawing, independent of further rendering optimization. Closing this gap requires one of: a lower tested/shipped concurrent-machine cap, a coarser simulation update rate for large crowds, or a lower-level reimplementation of the hot per-machine movement/combat path (typed-array batching, a compute approach, or C#/GDExtension) — each a real scope and effort tradeoff.

**Resolution - 2026-09-07**
Kevin chose to accept current performance for this testing stage: the 1,000-machine editable trial cap stays, and dropped frames/catch-up backlog under worst-case angular load are accepted as a known, documented limitation rather than blocking further slice work. This does not select a final shipped capacity, does not authorize claiming 60 Hz at 1,000 machines, and does not rule out later optimization or a lower final cap — it only clears T-022/T-028 to close on their remaining performance-review question and lets other Phase 2/3/4 work continue. Revisit before any final-capacity or ship claim.

---
### D-008 — Choose grid dimensions and placeholder projection
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§1, 4, 5.1, 15, 16

**What this is about**
The view is 2.5D above the pole, but radial spacing, core radius, screen compression, and exact bearing boundaries are unspecified. Even temporary appearance and camera feel belong to Kevin.

**The options**
- **Option A:** Preview concentric circles with north centered on wedge 12, core radius 96 world units, and ring width 96.
- **Option B:** Preview the same geometry compressed vertically to 75% for a tilted appearance.
- **Option C:** Kevin supplies another projection and dimensions before the preview is built.

**What we get**
A preserves clock-face geometry directly. B expresses a tilted presentation.

**What it costs us**
Either view needs selection to match the drawn grid. Compression can reduce readability; equal widths only approximate the stated area scaling.

**What happens if we're wrong**
Early dimension edits are cheap. Later edits change coverage and placement balance.

**My recommendation**
Use A as a proposed inspection view, with boundary ties assigned clockwise. Do not treat it as final art or as approval to reinterpret the requested semi-isometric view. Kevin must choose before Luna implements it.

**Blocking:** None for the approved foundation; remaining follow-ups are stated above.

**Resolution - 2026-09-06**
Kevin said: "D-004, D-006 through D-009 are approved." Recorded as approval of the recommendations. Approved recommended circular inspection view: core radius 96, ring width 96, north centered on wedge 12, and clockwise boundary ties. This is an inspection projection, not final art.

**Explicit confirmation - 2026-09-06**
Kevin subsequently specified Option A.

---
### D-009 — Define positions within a ring and wedge
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§5, 5.1, 16

**What this is about**
The authoritative position must remain polar. Multiple build slots and moving machines need more detail than two whole numbers, but the spec does not define that detail.

**The options**
- **Option A:** Store ring and wedge plus fractional radial and angular offsets; assign buildings stable slot identifiers.
- **Option B:** Subdivide each wedge into a fixed small polar grid and move between those positions.

**What we get**
A supports smooth motion and increasing slot counts. B simplifies occupancy checks.

**What it costs us**
A needs consistent boundary conversion. B can make movement coarse and harder to scale across rings.

**What happens if we're wrong**
Changing this after pathing and placement exist would affect almost every system.

**My recommendation**
Choose A. Astra will define exact fields, units, signatures, and ownership after approval, without introducing Cartesian gameplay positions.

**Blocking:** None for the approved foundation; remaining follow-ups are stated above.

**Resolution - 2026-09-06**
Kevin said: "D-004, D-006 through D-009 are approved." Recorded as approval of the recommendations. Approved Option A: ring/wedge plus fractional radial and angular offsets, with future stable building-slot identifiers. Exact reversible API conventions are in the foundation contract.

---
### D-010 — Choose the run's starting state
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A with recorded qualifications
**Source:** §§6, 7, 18

**What this is about**
Kill-only income cannot bootstrap an empty defense without some initial assets or energy. Starting wedges, weapons, balance, and the first enemy arrival are unspecified.

**The options**
- **Option A:** Begin with one complete inner ring, one Flak Emplacement, and enough initial energy for one additional Flak; combat starts immediately.
- **Option B:** Begin with one complete inner ring and enough initial energy for two Flak Emplacements; first contact follows a short travel distance.

**What we get**
A guarantees a way to earn. B lets the player choose both weapon positions.

**What it costs us**
A partly determines the opening strategy. B risks a no-income failure before the player understands placement. Initial energy is a starting grant, never ongoing income.

**What happens if we're wrong**
Easy to change as data, but opening-run tests must be repeated.

**My recommendation**
Prefer A for early testing. Kevin should approve the exact starting wedge ownership and weapon bearing; derive the grant from D-013 prices rather than inventing another income source.

**Blocking:** None for approved balance data; follow-up rules are listed in the resolution.

**Resolution - 2026-09-06**
Option A is approved FOR TESTING: one complete inner ring, one Flak, and starting energy equal to one additional Flak purchase (20 at current tuning). Flag a possible clean-slate opening for final gameplay; Kevin confirms new players will have a tutorial. Final opening remains undecided under D-042.

---
### D-011 — Define claiming and build-slot rules
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A with recorded qualifications
**Source:** §§5.1, 9, 10.1

**What this is about**
Ring Plate claims a wedge, but claim adjacency, disconnected claims, slot allocation, item footprints, and occupied-cell restrictions are unstated. Deliberate gaps must remain possible.

**The options**
- **Option A:** Claims require an owned inward neighbor; fixed generated slots hold one item each; walls use separate edge positions.
- **Option B:** Claims require any owned neighboring wedge; buildings and walls share slots.

**What we get**
A makes outward expansion easy to understand and preserves wall edges. B permits more flexible shapes.

**What it costs us**
A restricts sideways recovery. B can permit long disconnected-looking chains and competition between walls and weapons.

**What happens if we're wrong**
Changing slots later may invalidate layouts and require new placement code.

**My recommendation**
Prefer A, with explicit exceptions for rebuilding approved by D-022. Ask Kevin to settle terrain/relay footprints with their own catalogue decisions; do not silently make them free-slot items.

**Blocking:** None for approved balance data; follow-up rules are listed in the resolution.

**Resolution - 2026-09-06**
Option A is approved with Kevin's overriding expansion rule: one purchase establishes the ENTIRE next ring, all 12 wedges, with a relay included. Individual wedges may be destroyed. Retain one building per generated slot and walls on separate edges. Whole-ring expansion supersedes individual-wedge claiming and player-left initial gaps; adjacency and damaged-inner-ring eligibility need a later exact placement rule. D-040 fixes the ring price; D-041 includes only relay structure in the slice.

---
### D-012 — Choose scaling curves and guard against one best radius
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A with recorded qualifications
**Source:** §§5.1, 17 risk 5

**What this is about**
Build slots, claim cost, and wedge HP increase outward while available power decreases. No formulas are supplied; weapon coverage may also make one radius always optimal.

**The options**
- **Option A:** Trial linear growth: slots equal ring index, claim cost and HP equal their base times ring index, available power equal base divided by ring index.
- **Option B:** Trial slower growth: slots increase every two rings, cost and HP grow by 50% of base per added ring, power falls more gradually.

**What we get**
A is simple to inspect. B softens early expansion steps.

**What it costs us**
A may punish the rim too much. B may remove the intended pressure. Neither automatically reproduces real wedge area or useful turret coverage.

**What happens if we're wrong**
Data changes are cheap; moving slots can invalidate existing layouts, and all balance results may change.

**My recommendation**
Trial A only with Kevin's approval and compare costs, coverage, survival, and payback at rings 1–3 and inspection scales 10–12. Keep fixed weapon range as a separate D-014 decision; do not assume range scales.

**Blocking:** None for approved balance data; follow-up rules are listed in the resolution.

**Resolution - 2026-09-06**
Option A linear scaling approved: slots per wedge equal ring index; per-wedge claim price and HP scale by ring index; relative power falls as 1/ring index. ALL economy values must be easy to adjust during testing, polish, and post-release. Store balance values separately from mechanics; power behavior remains deferred.

---
### D-013 — Choose kill credit and purchase prices
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A with recorded qualifications
**Source:** §§7, 9, 12

**What this is about**
The per-kill amount is flat, but its value and all purchase prices are missing. Elite rewards, selling, and initial versus recurring energy also need explicit treatment.

**The options**
- **Option A:** Trial 1 energy per eligible kill; base Ring Plate 10, wall 5, Flak 20, Mass Driver 40; no selling or ordinary refunds.
- **Option B:** Trial 5 energy per eligible kill; base Ring Plate 40, wall 20, Flak 80, Mass Driver 160; decide a separate selling rule.

**What we get**
A uses small readable numbers. B reaches purchases after fewer kills despite larger displayed numbers.

**What it costs us**
Both are untested proposals. B adds another interaction if selling is allowed; neither may refund collapse losses.

**What happens if we're wrong**
Prices are easy to edit but change all expansion and recovery results.

**My recommendation**
Prefer A as a transparent first tuning set, with the same flat reward for every eligible machine. Keep selling absent unless Kevin requests it, and apply outward cost growth from D-012.

**Blocking:** None for approved balance data; follow-up rules are listed in the resolution.

**Resolution - 2026-09-06**
Option A approved: 1 energy per eligible kill; base per-wedge Ring Plate price 10, wall 5, Flak 20, Mass Driver 40; no selling or ordinary refunds. Whole-ring purchase sums 12 scaled wedge prices under D-040 and includes its relay.

---
### D-014 — Choose weapon numbers and targeting rules
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A with recorded qualifications
**Source:** §9.1

**What this is about**
Flak and Mass Driver have roles but no damage, cycle, range, arc, target selection, shot travel, or power response values. These numbers decide whether funneling and Tunnelers have meaningful counters.

**The options**
- **Option A:** Trial Flak damage 2, cycle 0.25 seconds, range 2 ring widths, 90-degree arc, up to 5 targets; Mass Driver damage 20, cycle 2 seconds, range 4 widths, one target.
- **Option B:** Use the same relative roles with full-circle targeting and moving projectiles; Kevin supplies initial damage and timing targets.

**What we get**
A creates distinct volume and single-target weapons with a small implementation. B emphasizes positioning and visible travel differently.

**What it costs us**
A's proposed instantaneous hits and nearest-in-range targeting reduce interception behavior. B adds travel and collision rules. Neither is approved balance.

**What happens if we're wrong**
Editing values is cheap; changing shot behavior and aiming rules requires code and another feel review.

**My recommendation**
Prefer A for the first slice comparison, with fixed world-space ranges and no automatic outward range growth. Kevin must approve arcs, radial aiming, and friendly-fire behavior; propose no friendly fire.

**Blocking:** None for approved balance data; follow-up rules are listed in the resolution.

**Resolution - 2026-09-06**
Option A approved for testing: Flak 2 damage, 0.25-second cycle, range 2 ring widths, 90-degree arc, up to 5 targets; Mass Driver 20 damage, 2-second cycle, range 4 ring widths, one target. ALL damage, health, and other battle-related values must be easily adjustable during testing, polish, and post-release. Remaining aiming/targeting details must be settled before consumers implement them.

---
### D-015 — Choose health, attack, and repair rules
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A with recorded qualifications
**Source:** §§5.1, 9.2, 10, 11

**What this is about**
Wedge HP is distinct from ring collapse, but base HP, core HP, machine attack rates, wall HP, and whether buildings take direct damage are unstated. Broken-wedge repair is also unclear.

**The options**
- **Option A:** Trial base wedge HP 100, core HP 200, wall HP 50; standard machine HP 10 and 5 damage per second. Wedge attacks damage the wedge; special targets can take direct damage.
- **Option B:** Use tougher wedges and burst attacks; all buildings can be targeted individually as well as wedges.

**What we get**
A separates structural integrity from individual targets. B makes each building's placement more consequential.

**What it costs us**
A needs an explicit wall/relay damage route. B requires more targeting rules and per-item health numbers.

**What happens if we're wrong**
Values are cheap to change; changing who can be attacked alters AI, UI, and collapse tests.

**My recommendation**
Prefer A as a proposed baseline. A broken wedge stays broken until explicitly reclaimed; do not let ordinary healing secretly reverse a break. Kevin should confirm simultaneous attacks, wall attack eligibility, and the core defeat condition.

**Blocking:** None for approved balance data; follow-up rules are listed in the resolution.

**Resolution - 2026-09-06**
Option A approved: base wedge HP 100, core HP 200, wall HP 50, standard-machine HP 10 and damage 5/second. Wedge attacks damage wedges; special targets can take direct damage. ALL damage, health, and other battle values must be easily adjustable during testing, polish, and post-release. No unselected relay HP, attack eligibility, or repair rules are implied.

---
### D-016 — Resolve blocked paths, gaps, and movement detail
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§9.2–9.3, 10.1, 16

**What this is about**
Normal machines detour around walls, but a fully sealed route has no stated fallback. Flow-field resolution, diagonals, crowd overlap, wall orientation, and rebuild responsiveness are also unspecified.

**The options**
- **Option A:** Machines seek a reachable exposed wedge; if every route is sealed, attack a reachable ring surface while leaving elite-only wall breaking intact.
- **Option B:** Machines wait at sealed routes until a legal path opens; defenders can create complete blockades.

**What we get**
A keeps pressure active. B takes impassable barriers literally.

**What it costs us**
A needs Kevin to approve exactly what is attackable through a sealed arrangement. B may allow permanent safety and a solved strategy.

**What happens if we're wrong**
Changing movement rules later invalidates funneling conclusions.

**My recommendation**
Prefer A, provided it preserves standard machines pathing around walls. Propose angular/radial neighbors only, soft crowd overlap, and flow-field refresh before the next movement update after structure changes. Kevin must approve these feel and rule choices.

**Blocking:** No behavior/profile approval block. Measured capacity and required implementation contracts remain.

**Resolution - 2026-09-06**
Kevin approved Option A through the live-enemy clarification: normal machines detour around walls, attack a reachable exposed ring surface when routes are sealed, and do not smash walls. This authorizes the behavior, not unchosen wall-edge placement details.

---
### D-017 — Choose continuous spawning and escalation
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - testing profile only
**Source:** §§1, 6, 10.1, 16

**What this is about**
All-bearing pressure and stat-based scaling are fixed, but spawn radius, rates, cap handling, escalation curves, and slice duration are not. Camera edges must not become a way to move the horde.

**The options**
- **Option A:** Spawn on a ring two band-widths beyond the outermost owned ring, initially 2 machines/second; raise health and damage 10% per minute; stop admitting machines at the cap.
- **Option B:** Use a fixed arena boundary with evenly scheduled bearings and a faster stat curve.

**What we get**
A follows expansion without tying spawning to the screen. B makes arrival distance consistent in the bounded slice.

**What it costs us**
A needs a rule for already-spawned enemies after expansion. B does not naturally extend to unbounded rings. Neither curve is tested.

**What happens if we're wrong**
Data tuning is cheap, but spawn geometry changes movement tests and pressure timing.

**My recommendation**
Prefer A with equal bearing coverage over time and reproducible test seeds. Leave existing machines in place on expansion. Confirm an initial speed, proposed one ring width per second, and resolve cap size via D-007.

**Blocking:** No behavior/profile approval block. Measured capacity and required implementation contracts remain.

**Resolution - 2026-09-06**
Kevin approved the proposed TESTING settings: 2 machines per second, one ring-width per second movement, spawn two ring-widths beyond the outer owned ring, even bearing coverage, health/damage +10% per minute. These are temporary tuning values. Final gameplay must support hundreds/thousands of enemies, with They Are Billions as the named density reference. Do not treat the prototype rate as final pressure or approve a hard concurrent cap without measurement. All future pressure values must stay editable data.

---
### D-018 — Define the Tunneler's exception and numbers
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved through D-018, D-075 and D-076
**Source:** §§9.1, 10.2, 18

**What this is about**
The Tunneler surfaces inside the perimeter, but depth, warning, invulnerability, frequency, and damage are unspecified. Its named counter, Point Defense, is absent from the slice.

**The options**
- **Option A:** Skip one intact ring, warn for 2 seconds, surface on the next inward owned band; use 20 HP and standard damage, one arrival every 30 seconds after minute 1.
- **Option B:** Allow deeper coreward travel, but expose Tunnelers to attacks while underground and reduce their health.

**What we get**
A provides a readable defense-in-depth test using existing weapons. B makes tunnel travel itself interact with defenses.

**What it costs us**
A needs a fallback when no inner band exists and may threaten the core abruptly. B adds presentation and targeting complexity.

**What happens if we're wrong**
Changing depths or warning timing is easy; changing underground targeting requires system changes.

**My recommendation**
Prefer A, with no direct core surfacing in the first test unless Kevin approves it. Keep Point Defense outside the slice unless D-005 is amended. Verify Flak and Mass Driver can actually answer this threat.

**Blocking:** None for this resolved umbrella. D-079 separately gates shared-cap tie handling; D-077 gates presentation.

**Current briefing:** Kevin approved bypassing exactly one intact ring. Kevin also approved untargetable underground, vulnerable after surfacing, with a warning before emergence. Recommendation: bypass one intact ring; untargetable underground with warning before surfacing. These answers settle only depth/vulnerability. Surfacing fallback, structure changes during travel, timing, presentation and editable test values still require a concrete follow-up before implementation. No Tunneler task is assigned.

**Partial resolution:** Kevin selected one intact ring of penetration. Kevin also approved untargetable underground and vulnerable after surfacing, with a warning before emergence. Timing, warning appearance, surfacing fallback, structure-change behavior and test values remain pending.


**Completed gameplay resolution:** The approved D-075/D-076 packages settle the remaining emergence and testing rules and supersede the original provisional Option A wording above. Gameplay foundation is authorized. D-077 presentation and D-079 shared-cap tie remain separately pending.

---
### D-019 — Define later elites and Assemblers
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Awaiting decision
**Source:** §§10.2–10.3

**What this is about**
Transfer, Foundry, Sapper, Breacher, and Assembler roles are fixed, but spawn intervals and their movement, health, damage, targeting, and growth numbers are missing. 'Interception' has no defined action yet.

**The options**
- **Option A:** Tune one type at a time after slice acceptance, keeping each named role and defining all its numbers before assignment.
- **Option B:** Approve a complete later enemy balance sheet before slice implementation.

**What we get**
A uses evidence from the core game. B establishes future range requirements early.

**What it costs us**
A leaves later balance open. B spends planning effort on enemies that may need retuning after the slice.

**What happens if we're wrong**
Early tuning tables are cheap to replace; implemented special rules are more expensive.

**My recommendation**
Choose A. Later briefs must settle hop distance/timing and interception for Transfer, grind rate for Foundry, relay targeting for Sapper, wall damage for Breacher, and Assembler interval, consumption range, stat growth, and any growth cap.

**Blocking:** Post-slice enemy work; no Phase 1 block.

**Superseded - 2026-09-07**
Chose Option A in practice: each remaining elite/boss now has its own concrete rule-shape decision — D-106 (Foundry), D-107 (Transfer, including hop distance/timing and what "interception" means), D-108 (Sapper's relay targeting), D-109 (Breacher's wall damage), D-110 (Assembler interval and growth). This entry stays as the historical record of the original open question; track the actual decisions in D-106 through D-110.

---
### D-020 — Define partial rings and the result of an inner collapse
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A
**Source:** §§5, 8, 10.1, 11

**What this is about**
The approved threshold is 7 of 12 (D-039), and purchases establish complete rings (D-011). It remains unclear what happens to surviving outer rings and the displayed radius after an inner ring disappears. Earlier questions about partly purchased rings are superseded by whole-ring purchasing.

**The options**
- **Option A:** Only previously claimed, destroyed wedges count as broken; outer rings remain, but lose power if power is included; gaps permit legal passage.
- **Option B:** Use the same break accounting but collapse disconnected outer rings too.

**What we get**
A follows the explicit per-ring destruction and outward brownout wording most closely. B gives a contiguous perimeter.

**What it costs us**
A permits disconnected structures and needs clear radius reporting. B adds destruction beyond the stated ring and requires Kevin's spec approval.

**What happens if we're wrong**
This changes layout survival and loss severity; switching later requires replaying collapse tests.

**My recommendation**
Prefer A, counting distinct broken wedges once. Retaking is deferred for the slice. Kevin still needs to decide disconnected-ring survival and radius reporting; the threshold and whole-ring purchasing are already approved.

**Blocking:** None for ring destruction. Detailed radius HUD remains D-024.

**Resolution:** Kevin approved outer rings surviving inner collapse; enemies may traverse the missing ring. Power is deferred. Seven broken wedges trigger total loss on that ring only, without refunds.

---
### D-021 — Choose assimilation strength and decay
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - see 2026-09-07 resolution
**Source:** §§10.4, 17 risk 2

**What this is about**
Destroyed structures buff active machines without adding enemies, and stacks must decay. The affected stats, amount per object, decay shape, cap, eligibility of Ring Plates, and treatment of later spawns are unspecified.

**The options**
- **Option A:** Trial +5% damage per destroyed built item, capped at +50%, each contribution expiring after 15 seconds; only machines active at the event receive it.
- **Option B:** Trial damage, speed, and armor increases with gradual decay and a shared global stack count.

**What we get**
A isolates one cause and follows 'existing machines.' B makes losses more varied and immediately visible.

**What it costs us**
A needs per-cohort expiry bookkeeping. B can slow recovery severely and may affect future spawns contrary to the stated rule.

**What happens if we're wrong**
Values are cheap to change; changing recipient rules requires implementation changes and fresh death-spiral tests.

**My recommendation**
Option A. It isolates one cause, matches "existing machines" exactly, and its hard per-stack 15s expiry is the simplest possible reading of the spec's own tuning note ("model it as a spike the player must survive, not a permanent tax") — Option B's gradual multi-stat decay is more expressive but risks exactly the unrecoverable-spiral failure mode the spec warns against, for no clear gameplay gain at this stage.

**Phase 7 first-pass numbers (D-033 delegated tuning; adjust after play):**
- Trigger: every destroyed occupant (weapon, wall, relay, terrain) grants one stack at the moment its wedge breaks or its ring collapses — a collapse counts each of its wedges' occupants once each, never a separate "collapse bonus" on top (resolves the double-counting risk noted above).
- Recipients: only machines active in the simulation at the instant the stack is granted; future spawns are unaffected, per spec.
- Effect: +5% `damage_per_second` per stack. Speed/armor buffs are deferred — one lever is enough to test the spike-and-recover shape; add more only if damage alone can't be measured or doesn't move the needle.
- Cap: +50% (10 stacks) per machine.
- Decay: each stack expires independently exactly 15 seconds after being granted (a hard per-stack timer, not a gradual global decay) — simplest to implement and to reason about in a death-spiral test.

**Blocking:** Phase 4 if included; death-spiral evidence.

**Resolution - 2026-09-07**
Kevin approved Option A with the first-pass numbers above. This authorizes implementation; the specific values (+5%/stack, +50% cap, 15s decay) remain provisional under D-033 and may move after gameplay testing.

---
### D-022 — Choose retake cost and what reclamation restores
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - see 2026-09-07 resolution
**Source:** §§6, 12, 17 risk 2

**What this is about**
Retaking must be a real comeback path, but the rebuild unit, cost, restored HP, delay, enemy occupancy rules, and any effect on assimilation are missing. The payback requirement has no time horizon.

**The options**
- **Option A:** Reclaim broken wedges with Ring Plate, restoring only that wedge at normal claim cost; no restored objects or automatic buff removal.
- **Option B:** Reclaim an entire lost ring at a discounted bundle price, with a delay and only empty plates restored.

**What we get**
A reuses building and respects total loss. B offers a clearer comeback action and possible discount.

**What it costs us**
A may be unaffordable. B adds an interaction and can grant large safe areas abruptly. Neither guarantees payback.

**What happens if we're wrong**
Prices are easy to change; switching the unit of reclamation changes placement and UI.

**My recommendation**
A and B aren't really alternatives — they answer two different situations. A single broken wedge (0 HP, but its ring hasn't hit the 7-of-12 collapse threshold) is a different problem from a fully collapsed ring (every wedge, occupant, and the relay gone). I recommend building **both**, as two tiers of the same comeback idea:

**Tier 1 — Repair, for a broken-but-not-collapsed wedge.** A manual purchase (click the broken wedge, pay, it's restored to full HP immediately; any occupant that was still there — only a full collapse clears occupants, a lone broken wedge doesn't — keeps working). First-pass cost: `10 × ring index` energy (a broken wedge's proportional share of that ring's `120 × ring` whole-ring price), scaled down for partial damage: `10 × ring × (missing_hp / max_hp)`. This is prevention — it stops a ring from ever reaching collapse — and needs no new building or D-027 catalogue item to test.

**Tier 2 — Reclaim, for a fully collapsed ring.** Re-run the exact same whole-ring purchase path already implemented (`RingPurchaseRules`) against a collapsed ring's slot, at a discount instead of full price: first-pass **75% of the normal `120 × ring` claim cost**, reusing the existing "no reachable enemies occupying the candidate ring" block rather than inventing a new occupancy rule. Restores empty plates + a relay at full HP, exactly like a brand-new ring purchase — weapons must be rebought. This is the real comeback the spec asks for (§12: "expensive but a genuine comeback path").

**Payback check (must hold before either price ships beyond testing):** discounted reclaim/repair cost should be recoverable from that ring's own kill income within roughly 60 seconds of owning it again, matching the spec's explicit balance requirement in §12 ("retake cost must sit below the energy income generated by the throughput the ring provides, or nobody will ever do it... if retaking is never correct, cut it rather than shipping a dead button"). Measure this once implemented; 75%/`10×ring` are first-pass numbers, not final.

**Assimilation interaction:** reclaiming does not retroactively clear an enemy's already-granted assimilation stacks — they expire on D-021's own 15-second timer regardless. No special-case cancellation rule.

**Blocking:** Phase 4 if included; comeback and death-spiral verdict.

**Resolution - 2026-09-07**
Kevin approved both tiers as recommended: Tier 1 Repair (single broken wedge, `10×ring` cost, scaled for partial damage) and Tier 2 Reclaim (whole collapsed ring via the existing purchase path, 75% of normal cost). Both ship as first-pass numbers under D-033, subject to the 60-second payback check once measurable.

---
### D-023 — Choose relay and power rules
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - see 2026-09-07 resolution
**Source:** §§5.1, 8, 17 risk 4

**What this is about**
Power flows outward and destroyed relays cause minimal output, but supply, falloff, demand, relay cost/HP, placement, rebuilding, and minimum turret output are unchosen. Banked purchase energy and delivered power need distinct displays without a second spendable currency.

**The options**
- **Option A:** One relay per ring, continuous capacity reduced by radius, weapons share available output proportionally; trial brownout output 10%.
- **Option B:** One relay per ring with fixed powered/unpowered output per ring; apply outer-ring output penalties from a table.

**What we get**
A models limited throughput directly. B is easier to explain and inspect.

**What it costs us**
A adds demand math and may surprise players. B may undersell competing power demand; Kevin must confirm it preserves the intended scarcity.

**What happens if we're wrong**
Changing the supply model after weapon balancing can invalidate much of the economy.

**My recommendation**
Option B. A continuous proportional-sharing model (Option A) means every weapon's effective output depends on every other weapon on its ring, recomputed as buildings are added/destroyed — a new per-tick cost in the combat hot path we just spent T-021/T-023 optimizing, for a mechanic players are unlikely to distinguish from a simpler table. Option B's fixed per-ring capacity, enforced only at *placement time* (like an existing slot-count check), keeps power out of the hot loop entirely and is easier to show the player as a plain number.

**Phase 7 first-pass numbers (D-033 delegated tuning; adjust after play):**
- Each ring's table output when its relay (and every relay inward of it) is intact: `100 / ring index` — this finally wires up `scaling.power_ring_exponent: -1.0`, present in balance data since T-007 but never used. Ring 1 = 100, ring 2 = 50, ring 3 ≈ 33, ring 6 ≈ 17, ring 12 ≈ 8.
- Each weapon/structure that needs power declares a `power_demand` in balance data (first pass: Flak 10, Mass Driver 25, Armor Plating/Wall 0 — passive structure draws nothing). A slot on a ring may only be armed if the ring's remaining output can cover that item's demand — checked once, at placement time, exactly like the existing slot-count check; nothing recomputes every tick.
- **Brownout:** destroying a ring's relay drops that ring's output to **10%** of table value, and cascades outward to every ring beyond it (§8: "browns out rings 4, 5, 6 and everything beyond"), matching how ring-loss already cascades in this codebase. At 10% output, any weapon whose demand no longer fits goes fully inert (0 effective fire rate) rather than partially throttled — the clearest possible signal, and simplest to test against relay-frustration risk (§17 risk 4: "a brownout the player doesn't understand is a bug report, not a mechanic").
- Relay: first-pass cost 30 energy, HP 75 (between Wall's 50 and a weapon-tier building — it's the single most valuable target on a ring). Rebuilding is an ordinary purchase into an empty slot on that ring; no new mechanic.
- **Presentation follow-up (not part of this decision):** once this rule is approved, the D-024 ring-status HUD needs a third status category — a brownout marker per ring — as its own small, separate task after the rule lands, not before.

**Blocking:** Phase 2/4 if included; relay-frustration risk. (This specifically blocks Phase 7's power/relay deliverable.)

**Resolution - 2026-09-07**
Kevin approved Option B with the first-pass numbers above: `100/ring index` table output, placement-time demand checks, 10% cascading brownout with weapons going fully inert when they no longer fit, relay cost 30/HP 75. Provisional under D-033; the HUD brownout marker is a separate follow-up task once this lands.

---
### D-024 — Define persistent ring status and large-scale navigation
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§4, 17 risks 3–4

**What this is about**
A compact radial display of wedge integrity and relay state is required, but its exact layout, aggregation, warning thresholds, and behavior at many rings are not. Art deferral does not authorize Astra to choose this UX.

**The options**
- **Option A:** Keep every ring visible in a compact radial display, using symbols plus color and click-to-focus; warn below 25% wedge HP.
- **Option B:** Scroll or filter radial bands while pinning the most threatened rings and core.

**What we get**
A preserves the whole shape. B preserves individual cell size at extreme counts.

**What it costs us**
A becomes dense. B can hide context and needs prioritization rules. Both require Kevin's presentation choice.

**What happens if we're wrong**
A HUD redesign is moderate work and may require new data, though the grid can stay unchanged.

**My recommendation**
Prefer testing A through ring 12, with labels/symbols that do not rely only on color and explicit downstream brownout markers if relays exist. Beyond that, bring measured readability failures back to Kevin before choosing aggregation.

**Blocking:** Phase 4 HUD; readability and relay-frustration risks.

**Resolution - 2026-09-07**
Kevin accepted Option A: every ring stays visible in a compact radial display, using symbols plus color and click-to-focus, warning below 25% wedge HP. Testing proceeds through ring 12 per the recommendation; labels/symbols must not rely on color alone, and relay information here means structure present/destroyed only, since power remains deferred. This clears the HUD direction; exact layout, symbol treatment, and any aggregation beyond ring 12 still require a concrete presentation brief before implementation.

---
### D-025 — Choose controls and loss feedback
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§4, 6, 9, 11, 14.1, 18

**What this is about**
The game is cursor-only and never pauses for building, but click behavior, hotkeys, zoom limits/speed, warnings, and collapse effects are not specified. These are creative and interaction decisions.

**The options**
- **Option A:** Left click selects/places, right click cancels, middle drag pans, wheel zooms; simple labels and an immediate visible collapse state, without camera shake.
- **Option B:** Use a persistent paint-to-build mode with edge panning and stronger motion feedback.

**What we get**
A is a small, inspectable input set. B may make rapid construction easier.

**What it costs us**
A may need more clicks. B increases accidental spending and motion/accessibility concerns.

**What happens if we're wrong**
Input and feedback are reversible, but playtest findings depend on them.

**My recommendation**
Prefer A for Kevin's approval, with keyboard alternatives and reduced-motion support designed before effects are added. Choose zoom steps, pan speed, warning duration, and effect timing in the brief review; propose 10% zoom steps and a 1-second collapse highlight. No pause during building or time-stopping feedback; opening the menu pauses gameplay under approved D-039.

**Blocking:** None for the approved controls/automatic combat rules.

**Partial resolution - 2026-09-06**
Kevin approved left click to select, middle-button drag to pan, wheel zoom in 10% steps, and fixed north-up for the grid inspection scene. This clears the controls gate on T-004 only. Build interactions, warning and collapse feedback, and remaining accessibility choices are not approved by this answer.

**Resolution - 2026-09-06**
Kevin selected Option A: left click selects/places, right click cancels, middle drag pans, wheel zooms, simple labels, immediate visible collapse state, and no camera shake. Existing 10% zoom and D-039 menu-pause exception remain approved. This clears build-input implementation; no solar ability or new art style is added.

---
### D-026 — Define ability numbers and kill-credit interaction
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§2, 7, 13

**What this is about**
Abilities cost only cooldowns and cannot grant energy, yet all kills award energy. It is unclear whether ability kills credit energy; choosing either interpretation affects the stated separation of time and space.

**The options**
- **Option A:** Ability kills award no energy; weapon kills retain flat credit.
- **Option B:** Ability kills award the normal flat credit; 'never grant energy' means no direct currency payout.

**What we get**
A preserves a strict separation. B preserves a universal kill-reward rule.

**What it costs us**
A creates an exception players need to understand. B indirectly converts cooldowns into building funds. Kevin must settle the apparent tension.

**What happens if we're wrong**
Changing reward attribution after implementation needs kill-source tracking and rebalancing.

**My recommendation**
Prefer A if Kevin intends the strictest separation, but do not implement that exception without his ruling. Before ability work, also choose Flare damage, width, range and cooldown, EMP damage, radius, stun duration and cooldown, targeting, cooldown start state, and later ability count.

**Blocking:** Ability/economy contract if abilities are admitted; otherwise post-slice.

**Clarification - 2026-09-06**
Kevin confirms a few player-targeted attacks from the sun, distinct from automatically targeting/firing buildings. This does not approve ability numbers, kill-credit treatment, or inclusion in the current slice.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended, as part of the Phase 8 rule-shape package: ability kills award no energy; weapon kills retain flat credit. This preserves the strict time-vs-space separation the spec calls for in §13. Focused Flare and EMP Burst's actual numbers (damage, width/radius, range, cooldown, stun duration, targeting, cooldown start state) are first-pass values under D-033 once implementation begins; later ability count stays open per D-028/D-029.

---
### D-027 — Complete the remaining build catalogue rules and numbers
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Awaiting decision
**Source:** §§9.1–9.3

**What this is about**
Most catalogue items have roles but no prices, footprints, HP, ranges, timing, stacking, or limits. Those omissions should remain visible without adding their implementation to this slice.

**The options**
- **Option A:** Resolve each item family after the slice using measured combat and power results.
- **Option B:** Approve one full balance and placement sheet now.

**What we get**
A avoids premature tuning. B exposes future occupancy conflicts earlier.

**What it costs us**
A defers content answers. B creates a large speculative tuning exercise.

**What happens if we're wrong**
Data is reversible; terrain placement and stacking rules may require changes to movement and occupancy.

**My recommendation**
Prefer A for the catalogue as a whole — EMP Node, Lance Emitter, Point Defense, Debris Field, Tractor Lane, and Occlusion Screen stay deferred to Phase 8 per the full-game plan, resolved after measured combat/power results rather than guessed now.

**Phase 7 partial resolution — Armor Plating and Repair Node only** (the full-game plan's Phase 7 needs these two now; the rest of this decision stays open for Phase 8):
- **Armor Plating**: occupies a normal build slot like a weapon. First-pass cost 15 energy (between Wall's 5 and Flak's 20 — it's pure durability, no damage output), grants **+50 max HP** to its wedge, stacking additively up to 2 per wedge (i.e., at most +100 max HP) so one wedge can't become effectively immortal. HUD/critical-threshold math already reads each wedge's own `max_hp` field (T-031's fix), so this needs no HUD change — it will just show a visibly tougher wedge automatically.
- **Repair Node**: occupies a normal build slot. First-pass cost 40 energy (Mass-Driver tier, reflecting ongoing value rather than one-time). Passively heals **2% of max HP per second** to whichever wedge in its own ring currently has the lowest HP fraction above zero (one target at a time, sequential — never a broken/0-HP wedge, which needs the D-022 Tier-1 Repair purchase instead, and never a wedge on a different ring). No power demand for now, pending D-023.
- Both are numeric first-pass values under D-033; adjust after play. Their rule shape (slot-occupying, per-wedge, no cross-ring effect) is the part that's a real decision here, not just numbers.

**Blocking:** Post-slice catalogue; no Phase 1 block. (Armor Plating/Repair Node specifically block Phase 7's exit check.)

**Partial resolution - 2026-09-07**
Kevin approved the Armor Plating/Repair Node subset as recommended (15/+50 HP stacking to 2; 40 energy/2% max HP per second to the most-damaged wedge in its own ring). The rest of D-027 (EMP Node, Lance Emitter, Point Defense, Debris Field, Tractor Lane, Occlusion Screen) remains open for Phase 8.

---
### D-088 — EMP Node rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §9.1

**What this is about**
"Pulsed area stun/slow, minimal damage" needs a concrete mechanic before it can be built as a weapon occupant alongside Flak/Mass Driver.

**The options**
- **Option A:** Periodic pulse (own cooldown, like other weapons): every cooldown period, apply a fixed-duration **stun** (skip movement and attack) to every machine within a fixed radius on its own ring, plus a small flat damage tick. No targeting, no pierce — an area-of-effect burst like Flak but timed rather than per-shot.
- **Option B:** Always-on field: any machine inside its radius continuously has movement/attack speed reduced by a flat percentage while inside range, no discrete stun and no cooldown gating.

**What we get**
A matches the spec's literal wording ("pulsed") and reuses the existing cooldown/weapon-slot machinery `WeaponRules` already has. B is a persistent zone-control tool, more forgiving to place but stronger passively.

**What it costs us**
A needs a new "stunned" status flag threaded through movement/attack (`LiveSimulation` doesn't track per-machine status effects yet — this is genuinely new state, not a numeric tweak). B needs the same status machinery but as a continuous multiplier instead of a binary flag, and risks becoming a always-take crowd-control staple that trivializes funneling if not carefully capped.

**What happens if we're wrong**
Either shape requires new per-machine status state; changing which one later means migrating that state's semantics, not just its numbers.

**My recommendation**
Option A — it matches the spec's own word ("pulsed") and fits the existing per-weapon-cooldown pattern instead of inventing a second, different kind of area effect. Radius, stun duration, damage, and cooldown are numeric first-pass values under D-033 once the shape is approved.

**Blocking:** Phase 8 weapon-catalogue work; needs a new per-machine status-effect field before any weapon uses it.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: periodic pulse, fixed-radius area stun with minor damage, on the existing per-weapon cooldown model. Radius, stun duration, damage, and cooldown are first-pass numeric values under D-033.

---
### D-089 — Lance Emitter rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §9.1

**What this is about**
"Piercing beam along a radial line. Clears a wedge corridor" needs a concrete firing mechanic — specifically whether it pierces (hits everything in the line at once) or just has long range.

**The options**
- **Option A:** Discrete burst on cooldown (like Mass Driver): every cooldown period, deal a single damage instance to **every** machine currently standing in its own wedge, across all rings outward to a max range — one shot, many targets, no per-target falloff.
- **Option B:** Sustained beam: while a target remains in the wedge, the Lance Emitter continuously deals damage each tick to everything in the column, no cooldown between "shots," just an on/off beam state.

**What we get**
A fits the existing discrete-shot combat resolution (`WeaponRules._step_impl` already models cooldown-gated single instances) with no new tick-by-tick beam state. B reads more literally as a "beam" but requires new sustained-effect bookkeeping.

**What it costs us**
A slightly undersells the "beam" flavor (it's really a burst that happens to hit a whole column). B needs new per-tick beam-active state and a decision about whether it can be disrupted (walls in the way, its own wedge collapsing mid-beam).

**What happens if we're wrong**
Low cost either way — reworking cooldown-vs-continuous fire is a self-contained change to one weapon's resolution step, similar in scope to a numeric retune.

**My recommendation**
Option A — it slots directly into the existing discrete-shot model that Flak, Mass Driver, and (per D-088) EMP Node all already use, keeping one uniform combat-resolution shape across the whole weapon catalogue rather than adding a second sustained-damage system for one item.

**Blocking:** Phase 8 weapon-catalogue work.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: discrete cooldown-gated burst hitting every machine in its own wedge column across all rings out to a max range, using the existing discrete-shot combat model.

---
### D-090 — Point Defense rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§9.1, 10.2

**What this is about**
"Very short range, high rate of fire, defends only its own tile. The answer to burrowers and jumpers" needs a concrete range rule — specifically whether "its own tile" means literally zero range (only threats already on its wedge) or a small nonzero range.

**The options**
- **Option A:** Range is exactly its own wedge — it can only engage a machine that is already standing on/in the same wedge as the Point Defense itself (a Tunneler surfacing there, or a Transfer elite landing there). It cannot help a neighboring wedge at all.
- **Option B:** Range covers its own wedge plus immediately adjacent wedges on the same ring, giving it slightly broader utility as a cheap area-denial option.

**What we get**
A is the sharpest, most literal read of "defends only its own tile" and gives Tunneler/Transfer (both of which appear directly at a wedge rather than approaching from the map edge) a precise, per-wedge counter. B is more forgiving to place and useful against ordinary funneled traffic too, not just the two elites it's meant to counter.

**What it costs us**
A means a player needs one per wedge they want covered against surprise arrivals — expensive in slots, but that expense is presumably the point (Tunneler/Transfer are meant to be a real threat, not trivially blanketed). B risks making Point Defense a cheap Flak substitute rather than a specialist counter.

**What happens if we're wrong**
Range is a pure numeric/rule-shape parameter, cheap to widen later if Option A proves too weak in play.

**My recommendation**
Option A — the spec's own wording ("only its own tile") is unusually specific for this catalogue, and keeping it a precise counter (not a general-purpose weapon) preserves the elite/counter design table in §10.2 rather than diluting it.

**Blocking:** Phase 8 weapon-catalogue work.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: range is exactly its own wedge — it can only engage a machine already standing in the same wedge (Tunneler surfacing, Transfer landing there).

---
### D-091 — Debris Field rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§9.3, 11

**What this is about**
Debris Field is the first Terrain-category item to implement. "Impassable. Free perimeter" needs a concrete durability rule — specifically whether it can ever be destroyed like a Deflector Wall, or is permanent once placed.

**The options**
- **Option A:** Indestructible terrain — it occupies a wedge slot and machines detour around it exactly like an intact wall (per D-066-068's funneling rules), but it has no HP, is never a wall-break target, and never contributes to a ring's collapse-threshold count. Once placed, it is permanent until the player removes it (if removal is even offered).
- **Option B:** Has HP like a (cheaper/weaker) wall — sealed-in machines can eventually break through it under the same sealed-ring exception that lets machines attack walls today.

**What we get**
A gives Terrain a genuinely distinct role from Structure's Deflector Wall — permanent, free, but presumably weaker in some other way (footprint, or it can't be built everywhere) — which the spec's phrasing ("free perimeter") supports. B keeps a uniform destructible-obstacle rule across both categories, at the cost of Debris Field becoming just a discount wall.

**What it costs us**
A needs a new "affects pathing, but exempt from wall-break/collapse accounting" occupant flag. B needs nothing new but makes Debris Field redundant with Wall.

**What happens if we're wrong**
Moderate — indestructible terrain that turns out overpowered (free, permanent funneling) is harder to walk back than a numeric nerf, since players will have built around its permanence.

**My recommendation**
Option A — "free perimeter" reads as the entire point of the item (it costs nothing ongoing and never needs defending), and Option B would make it a strictly worse Wall with no reason to ever build it. Cost and footprint (how many wedges one Debris Field claims, if not exactly one) are numeric first-pass values under D-033.

**Blocking:** Phase 8 terrain-catalogue work; first Terrain-category item, sets precedent for D-092/D-093.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: indestructible terrain, no HP, exempt from wall-break/collapse accounting, permanent once placed. Cost and footprint are first-pass numeric values under D-033.

---
### D-092 — Tractor Lane rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §9.3

**What this is about**
"Reroutes movement without blocking it. Pulls machines along a chosen path, into kill boxes" needs a concrete pathing mechanic — specifically whether this is a steering nudge within the existing route-field model, or a discrete relocation.

**The options**
- **Option A:** Placed on a wedge; it applies a path-cost bias in the existing `PolarRouteField` routing so machines that would path through or near it are steered toward a player-chosen adjacent wedge instead — a soft preference, not a hard redirect. Machines can still resist it if a shorter path exists elsewhere.
- **Option B:** Placed as a two-endpoint lane (an entry wedge and an exit wedge); any machine that reaches the entry wedge is instantly relocated to the exit wedge, a hard teleport rather than a steering nudge.

**What we get**
A fits directly into the existing route-field infrastructure with no new "teleport" special case in movement code. B reads more literally as "pulls machines... into kill boxes" (an obvious, guaranteed funnel) but is a bigger mechanical departure.

**What it costs us**
A is a softer effect that a determined/short-pathing machine could partially ignore, which may undersell the "kill box" fantasy the spec describes. B needs new movement-teleport handling and raises questions this session hasn't addressed (does it interrupt combat mid-tick, can Tunnelers/other pathing-ignoring elites be pulled at all).

**What happens if we're wrong**
A is the lower-risk starting point — if steering proves too weak to feel like a real "lane," strengthening the path-cost bias is a numeric change; moving from A to B later is a rule-shape change, not just a retune.

**My recommendation**
Option A — it reuses `PolarRouteField`, the same routing model walls and funneling already depend on, rather than adding a second, incompatible movement mechanic (instant relocation) for one terrain item.

**Blocking:** Phase 8 terrain-catalogue work.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: path-cost bias in `PolarRouteField` steering machines toward a player-chosen adjacent wedge, a soft preference rather than a hard teleport.

---
### D-093 — Occlusion Screen rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §9.3

**What this is about**
"Casts a shadow. Solar-powered machines move slowly in shadow. Kill-box multiplier" needs a concrete shadow-shape rule — specifically where the shadow falls relative to where the Occlusion Screen is placed.

**The options**
- **Option A:** Fixed shadow — placed on a wedge, it slows machines by a flat percentage while they occupy that same wedge column on some number of rings further outward (toward the map edge, the direction the horde approaches from). No player-chosen bearing or shape.
- **Option B:** Player-aimed shadow — the player chooses a bearing/direction for the shadow independent of the Occlusion Screen's own wedge, letting one screen protect a different corridor than the one it sits in.

**What we get**
A needs no new aiming/targeting UI and composes naturally with existing wedge-column terrain (a Tractor Lane or a chokepoint) to build the "kill-box multiplier" the spec describes. B is more flexible placement but requires a new UI interaction pattern this project doesn't have yet for any other item.

**What it costs us**
A is less flexible (a screen's shadow is tied to where it's built). B is a real scope increase — no other build in the catalogue lets the player choose an independent facing/bearing at placement time.

**What happens if we're wrong**
Low — this is a placement/UI constraint, easy to loosen later without touching the slow effect's actual math.

**My recommendation**
Option A — it keeps every Terrain item's UI identical (pick a wedge, confirm), avoiding a one-off bearing-picker for a single build item.

**Blocking:** Phase 8 terrain-catalogue work.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: fixed shadow tied to the Occlusion Screen's own wedge column, extending outward toward the map edge, no player-chosen bearing.

---
### D-028 — Choose meta rewards, upgrade costs, and limits
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Awaiting decision
**Source:** §14

**What this is about**
Survival, kills, and milestones award persistent currency, but rates, rounding, challenge definitions, costs, stat increments, caps, and starting unlocks are unspecified. None belong in the slice.

**The options**
- **Option A:** Use capped permanent stats and let most later spending unlock build/loadout choices.
- **Option B:** Allow continuing stat growth alongside unlocks.

**What we get**
A protects readable balance and makes choices matter. B offers a longer numerical progression.

**What it costs us**
A needs enough meaningful unlocks. B risks making success depend mainly on accumulated playtime.

**What happens if we're wrong**
Changing purchased upgrades later can invalidate player expectations and saved progress.

**My recommendation**
Prefer A after slice acceptance. Approve survival and kill conversion rates, milestone payouts, challenge list, prices, stat caps, refund/reset policy, and unlock prerequisites together before persistent progress is implemented.

**Blocking:** Post-slice progression.

---
### D-029 — Resolve run sameness through doctrines, loadouts, and mutators
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Awaiting decision
**Source:** §§7, 14.1–14.2, 17 risk 1

**What this is about**
This is the spec's highest-priority risk. The doctrines are illustrative, and no launch count, starting access, modifiers, loadout sizes, mutator list, or reward multipliers are selected.

**The options**
- **Option A:** After the slice, prototype three strongly different doctrines based on the examples, then expand only after variety tests.
- **Option B:** Plan a larger initial roster, proposed six doctrines, with fewer unique mechanics per doctrine.

**What we get**
A tests whether choices actually change play. B gives more combinations at once.

**What it costs us**
A is not a claim that three are enough for launch. B costs more content work and can still produce shallow variation.

**What happens if we're wrong**
Roster revisions are manageable before release; changing unlocked cores later is disruptive.

**My recommendation**
Prefer A as a proposed later experiment, never a launch commitment. Kevin must approve roster, names, loadout slot counts, each modifier, mutator stacking rules and earnings multipliers, plus a repeat-run variety test. Keep the rejected difficulty ladder rejected.

**Blocking:** Post-slice variety work and launch scope; no slice block.

---
### D-030 — Choose final art direction
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Resolved 2026-09-08 by D-120
**Source:** §15

**Resolution - 2026-09-08:** Superseded by **D-120**. None of the four original candidates was chosen outright: the decided direction is industrial hardware as the lit figure on a near-black ground, with the painterly candidate's contribution delivered as light and atmosphere (corona bleed through open void) rather than as surface treatment, and the schematic candidate borrowed only as a strategic-zoom state-colouring layer. See `docs/art-direction-style-guide.md`.

**What this is about**
Art direction is explicitly undecided and reserved for Kevin. Style-agnostic slice placeholders are already authorized but do not settle any production style.

**The options**
- **Option A:** Schematic readout.
- **Option B:** Gritty industrial.
- **Option C:** Painterly / awe.
- **Option D:** Retro terminal / CRT.

**What we get**
Schematic favors far-zoom clarity; industrial adds material weight; painterly emphasizes the star; CRT offers a compact visual identity.

**What it costs us**
Their stated risks are cold destruction, expensive detail that becomes unreadable, weak combat readability, and limited color channels respectively.

**What happens if we're wrong**
Switching after asset and shader production is expensive; postponing it during procedural placeholder work is cheap.

**My recommendation**
Schematic is my provisional recommendation for scale readability and production effort, not a selection. Decide only after comparing Kevin-approved references at close and ring-12 views.

**Blocking:** Final art only; explicitly not a vertical-slice dependency.

---
### D-031 — Approve the slice evaluation and risk gates
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option B
**Source:** §§1, 17–18

**What this is about**
The slice has three qualitative questions but no test duration, player count, measurements, or pass criteria. Its three-ring scope also cannot alone prove readability at ring 10+.

**The options**
- **Option A:** Run a small formative test with Kevin and 2 additional players, proposed 10-minute runs, plus ring-12 inspection, matched wall layouts, and recovery comparisons where in scope.
- **Option B:** Kevin alone reviews shorter engineering scenarios first, then decides whether broader playtesting is warranted.

**What we get**
A reveals misunderstandings a developer may miss. B is cheaper and needs no external scheduling.

**What it costs us**
A needs participant availability and does not prove broad appeal. B risks overestimating readability. A 10-minute test does not validate the full 15–25-minute run target.

**What happens if we're wrong**
Tests are easy to repeat, but false confidence can send months of work in the wrong direction.

**My recommendation**
Prefer A when the slice is ready; Kevin must authorize participants and any invitations separately. Record time to identify a failing bearing, enemy concentration under walls, and player descriptions of loss fairness. Compare recovery payback, relay comprehension if present, and per-ring efficiency. Do not invent numeric pass thresholds; agree them before testing. A bad collapse verdict blocks expansion until Kevin revisits the rule.

**Blocking:** Phase 5 acceptance; all five flagged risks.

**Resolution - 2026-09-07**
Kevin chose Option B: Kevin alone reviews shorter engineering scenarios first; broader/external playtesting (Option A's formative test with additional players) is deferred until Kevin decides afterward whether it's warranted. This clears Phase 5 to begin as a Kevin-only engineering evaluation; no external participants are authorized or invited by this resolution. Astra still needs Kevin's input on what specific scenarios/measurements to review and what would constitute a pass, since no numeric thresholds are agreed — that detail is the next step before Phase 5 evidence-gathering begins.

---
### D-032 — Decide what must persist and how a slice is delivered
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§1, 14, 16; kickoff

**What this is about**
Persistent meta progress is required later, but mid-run saves, restart behavior, supported export platforms, and settings persistence are unspecified. Adding them now changes slice scope.

**The options**
- **Option A:** Slice runs in the editor or one agreed desktop export with restart-from-beginning; defer mid-run saves.
- **Option B:** Include resumable runs and settings persistence in the slice.

**What we get**
A keeps the proof small. B allows longer interrupted sessions and earlier save testing.

**What it costs us**
A loses run state on exit. B needs format versioning and testing of damaged or old saves.

**What happens if we're wrong**
Saving later is feasible if state boundaries are clear, but retrofitting stable identifiers can cost work.

**My recommendation**
Prefer A with a Windows export only if Kevin wants one. Sol should not implement saving before its scope is approved; later choose save timing, retention, migration, and reset behavior.

**Blocking:** Slice packaging decision; post-slice save/load work.

**Resolution - 2026-09-07**
Kevin chose Option A, editor-only variant: the Phase 6 test build runs from the Godot editor with restart-from-beginning (the existing Retry flow from T-033); no mid-run save/resume and no standalone Windows export for now. This keeps Phase 6's stable content-ID/command-interface work minimal (no persistence format to design against yet) and defers the private export until it's actually wanted. Revisit before Phase 11 (persistence) and before Phase 13 (private test handoff), which assumes a build Kevin can launch without the editor.

---
### D-033 — Approve how provisional tuning becomes implementation input
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option B
**Source:** §§5–14, 16–18; kickoff decision protocol

**What this is about**
Many missing values are grouped above by system to keep the log readable. Proposed numbers are not permissions, and an agent must not fill remaining blanks from personal taste.

**The options**
- **Option A:** Kevin approves a complete small parameter sheet for each system before its task; unresolved fields keep that task blocked.
- **Option B:** Kevin delegates bounded tuning authority with explicit ranges and records which creative/rule choices remain reserved.

**What we get**
A keeps all design control with Kevin. B reduces repeated review for closely related number changes.

**What it costs us**
A requires more decisions as systems arrive. B changes the current authority boundary and must be explicit.

**What happens if we're wrong**
Approval records are easy to revise before work; silent defaults are expensive to discover after balance tests.

**My recommendation**
Prefer A under the current kickoff. Before each brief, inventory all runtime rates, dimensions, prices, limits, ranges, timings, and modifiers it requires. Record exact approved values or approved experiments; unused future values can remain deferred.

**Blocking:** Each future gameplay/presentation brief with unresolved parameters; not additional Phase 1 scope.

**Resolution - 2026-09-07**
Kevin chose Option B: "Codex or Claude will perform first pass tuning and then gameplay testing will adjust." This delegates bounded authority over **numeric tuning values only** — rates, costs, HP, damage, timings, ranges, thresholds, and similar balance-data fields — for systems whose *rules/mechanics* are already approved. An implementing agent may choose reasonable first-pass numbers without a pre-implementation parameter-sheet review, provided:
- The values go into versioned balance data (never hardcoded), are stated plainly in the task's TASKS.md entry, and are clearly labeled provisional/first-pass.
- Kevin's actual gameplay testing is the adjustment mechanism going forward, not another round of a priori approval — expect values to change after play, not before.
- This does **not** extend to creative/rule/mechanic choices, new system scope, art direction, or naming — those stay reserved to Kevin under the standing "Authority and coverage" rules regardless of this delegation. If a brief can't be reduced to "which numbers" without also deciding a rule question, that rule question still comes to Kevin first.
- Existing precedent values already recorded in this log (e.g., Kevin's "hundreds/thousands of weaker enemies" pressure intent, established costs/HP curves) constrain first-pass choices; an agent shouldn't invent numbers that contradict a preference Kevin has already stated elsewhere.

No specific numeric ranges were dictated, so first-pass values are bounded by consistency with existing approved data and rules rather than a pre-stated min/max; if a value is genuinely ambiguous or high-stakes (e.g., it could make the game unplayable, not just imbalanced), flag it rather than guess.

---
### D-034 — Confirm title and player-facing names
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Awaiting decision
**Source:** Title; §§9–10, 13–15

**What this is about**
RING ZERO is a working title with three alternatives, and core doctrines are illustrative. Meta currency has no name; final labels and any new fiction are creative decisions.

**The options**
- **Option A:** Retain RING ZERO as the working label through the slice; defer final naming.
- **Option B:** Choose RING ZERO, ECLIPTIC, PERIHELION, or OCCULTATION as final now and approve associated terminology.

**What we get**
A avoids branding work before the play test. B provides a stable public identity.

**What it costs us**
A leaves production text unfinished. B can commit to a name before the tone and art are settled.

**What happens if we're wrong**
Working labels are cheap to replace; public branding and finished assets are more costly.

**My recommendation**
Prefer A. Use existing spec labels only as working labels. Kevin chooses final title, currency name, doctrine names, and any new player-facing terms.

**Blocking:** Final naming and branding; no Phase 1 block.

---
### D-035 — Choose audio character and accessibility details
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Awaiting decision
**Source:** §§3–4, 15, 17; kickoff creative boundary

**What this is about**
The fiction fixes a maintenance intelligence facing machine pressure, but sound character, music, warning cues, motion limits, and visual accessibility details are not selected. Even placeholder audio would imply a creative choice.

**The options**
- **Option A:** Keep the slice silent with readable text/symbol cues; decide audio character after the visual experiment.
- **Option B:** Approve minimal warning and impact sounds for the slice, with separate volume controls and visual equivalents.

**What we get**
A avoids audio production scope. B tests whether warnings and collapse feel improve with sound.

**What it costs us**
A limits the loss-feel verdict. B needs Kevin's sound direction and additional work; mandatory audio cues could exclude players.

**What happens if we're wrong**
Temporary sounds are replaceable; feedback timings and player expectations may still need retesting.

**My recommendation**
Prefer B only if Kevin considers sound necessary to answer the collapse question; otherwise explicitly accept A's limitation. Kevin must approve palette/contrast, text size, remapping needs, warning priorities, motion intensity, and any sound references before implementation.

**Blocking:** Audio and accessibility presentation briefs; Phase 5 interpretation of loss feel.

---
## Session handoff

2026-09-06: First-session inventory complete. No Tier 2 decision was answered during this session. No numbers, creative direction, or scope proposals above authorize implementation. At the next session, raise the pending list, record Kevin's answers with date and resulting task changes, and remove resolved items from the top queue while preserving their entries.

---
### D-036 - Foundation API and installed runtime pin
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
The approved foundation now has a shared contract at docs/contracts/phase-1-foundation.md. Use core identifier (0,0), invalid-cell identifier (-1,-1), normalized within-cell fractions, outward ownership of radial boundaries, deterministic neighbor order, explicit invalid-input handling, and separate files for positions and geometry. These are reversible implementation conventions, not enemy pathing rules. Pin the locally verified Godot 4.7.2 runtime. Sol owns the empty launch scene and headless geometry checks; Luna owns the later interactive view.

**What we get**
Both agents can use one grid representation. Boundary and round-trip checks catch errors before movement and placement depend on it. An empty launch scene validates setup without pending input choices.

**What it costs us**
Changing these conventions after dependent systems exist will need coordinated edits. No machine performance claim is made from geometry tests.

**What happens if we're wrong**
Before other systems are built, revise the small contract and its tests together. No gameplay data or user saves exist to migrate.

**Blocking:** None.

2026-09-06 approval follow-up: D-004 and D-006-D-009 resolved. T-002 contract completed and reviewed against those approvals. T-003 will proceed with Sol; D-005 and D-025 remain open. Earlier first-session notes above are historical.

2026-09-06 further answers: D-005 resolved to Option A; D-006-D-008 explicitly confirmed as Option A. D-025 foundation controls approved. Luna may proceed after T-003 review.

---
### D-037 — Inspection handoff and review conventions
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
The prepared T-004 brief uses the approved neutral inspection view and controls. Luna owns the presentation files and consumes Sol's grid. Use a reversible 1280x900 initial window, viewport-based fit, center-fixed inverse wheel steps, drag motion adjusted for zoom, default text, and generated grayscale boundaries. A persistent selection readout exposes cell identifiers. These are implementation conventions for the approved placeholder, not final art or added game rules. Keep Godot-generated script identifiers. Redirect automated engine caches inside .godot rather than changing user settings.

**What we get**
The scene can be checked at three and twelve bands with actual rendered images. Separate core and presentation checks catch handoff errors.

**What it costs us**
The placeholder does not establish final readability or style. Kevin still reviews the running view; a rendered image alone cannot prove usability.

**What happens if we're wrong**
These settings and inspection files are easy to replace before gameplay depends on them. Any creative change outside the approved placeholder returns to Kevin.

**Blocking:** None. T-004 starts after T-003 passes review.

**Plan correction:** Removed D-019 from Phase 3 prerequisites because it concerns post-slice enemies. This fixes a mistaken dependency without changing scope.

---
### D-038 — Accept the Phase 1 inspection view
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** Approved BUILD-PLAN.md Phase 1 exit; D-008 inspection projection

**What this is about**
The foundation now runs with the approved core plus three bands and controls. Astra accepted Sol's engine and Luna's presentation after checking source, tests, and actual three-band, twelve-band, and panned-selection images. Phase 1 still requires Kevin's human readability review.

**The options**
- **Option A:** Accept this neutral foundation view and close Phase 1; Phase 2 still waits for its own gameplay decisions.
- **Option B:** Request specific inspection-view or control corrections before acceptance.

**What we get**
A lets the project proceed from a reviewed foundation. B resolves usability concerns before combat makes them harder to isolate.

**What it costs us**
This empty grid cannot establish readability under attack, satisfying funneling, or fair collapse. Accepting it is not a final-art decision or a completed vertical-slice verdict.

**What happens if we're wrong**
The presentation is isolated from the grid, so corrections remain inexpensive now. Delaying known corrections until combat exists creates more retesting.

**My recommendation**
Accept as an engineering foundation if the running view feels clear to Kevin. The rendered geometry and camera-aligned selection passed Astra review; physical mouse usability and Kevin's preferences remain his assessment.

**Review material:** [Three bands](docs/reviews/artifacts/T-004-three-bands.png), [twelve bands](docs/reviews/artifacts/T-004-twelve-bands.png), [panned selection](docs/reviews/artifacts/T-004-panned-selected.png), and [project.godot](project.godot). Open the project in Godot 4.7.2 and run the main scene.

**Blocking:** None. Phase 1 is complete; Phase 2 decisions remain pending.

**Resolution - 2026-09-06**
Kevin said: "Accept D-038 Option A." The inspection foundation is accepted and Phase 1 is closed. This approval does not select pending gameplay values or final art.

---
### D-039 - Resolve plan/spec differences on collapse and menu pause
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option B (both plan changes)
**Source:** BUILD-PLAN.md fixed-rules summary versus spec sections 6, 11, and 18

**What this is about**
The current build-plan summary now says collapse at 7 broken wedges and allows an opening-menu pause. The spec and the plan's Phase 4 checks still say 5 wedges; the spec says no pauses. These edits were not made by Astra during this approval update, and have been preserved. Their intended authority needs confirmation.

**The options**
- **Option A:** Keep the existing spec rules: 5 broken wedges and no gameplay pause.
- **Option B:** Confirm both plan edits as Kevin's intended revisions: 7 broken wedges and the stated menu-pause exception. Clarify which menu and whether it stops an active run before implementing it.
- **Option C:** Confirm only one change and specify which rule applies to each.

**What we get**
A keeps the original balance baseline. B permits more wedge losses before collapse and a menu exception. C allows separate decisions without bundling their consequences.

**What it costs us**
Seven wedges changes ring-loss severity; pausing an active run changes continuous pressure. Leaving contradictory text unmarked could cause agents to implement different rules.

**What happens if we're wrong**
No collapse or pause system is implemented yet, so confirmation is cheap now. Changing these after combat testing would require repeated balance and usability tests.

**My recommendation**
Confirm whether the plan edits were intentional before choosing either rule. I have no basis to override Kevin's possible edits. Preserve both source files for now, and withhold only the affected implementation choices.

**Blocking:** None. Apply both approved changes in future contracts.

**Resolution - 2026-09-06**
Kevin answered "Confirm both plan changes." Collapse occurs at 7 broken wedges out of 12: six do not collapse the ring; the seventh does. Opening the menu pauses gameplay; the pause exception does not authorize paused building. These approved revisions supersede the old 5-wedge/no-pause wording for future work. The original design-spec file remains untouched under the kickoff restriction; read it together with this approved revision. BUILD-PLAN.md and its Phase 4 checks are synchronized.

---
### D-040 — Price a complete ring
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved

**What this is about**
The approved per-wedge price must fund a whole-ring purchase. Kevin selected the sum of twelve wedge prices, with the relay included.

**The options**
- **Option A:** Sum 12 scaled wedge prices: 120 times ring index at current tuning.
- **Option B:** Charge one scaled price for the entire ring: 10 times ring index.

**What we get**
A preserves the approved cost per wedge while making expansion one transaction.

**What it costs us**
Expansion requires saving a larger amount at once. Ring 2 costs 240 and ring 3 costs 360 under current trial values.

**What happens if we're wrong**
The data can be retuned cheaply; changing the transaction unit later would affect purchases and UI.

**My recommendation**
Use the approved sum. Derive it from grid wedge count, base price, and the approved scaling exponent; do not duplicate 240/360 in implementation.

**Blocking:** None.

**Resolution / instruction record — 2026-09-06**
Kevin selected “Sum of 12 wedges: 120 × ring index.” Relay included; no extra relay purchase price is implied.

---
### D-041 — Include relay structure and defer power behavior
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved

**What this is about**
Whole-ring expansion now includes a relay, amending D-005's earlier slice exclusion. Kevin selected a relay structure without working power behavior for this slice.

**The options**
- **Option A:** Include the relay structure; defer power routing and brownouts.
- **Option B:** Include working power and brownouts now.

**What we get**
A fulfills the new purchase rule while limiting the slice to its main combat experiment.

**What it costs us**
A cannot test relay vulnerability or power comprehension. Relay placement and slot use still need specification before placement work.

**What happens if we're wrong**
Adding power later will require new rules and tuning, but the ring-level relay identity can remain.

**My recommendation**
Follow approved A. Do not invent relay HP, minimal weapon output, or power budgets in the balance task.

**Blocking:** Relay position/footprint still blocks T-008; power values do not block data work.

**Resolution / instruction record — 2026-09-06**
Kevin selected “Include relay; defer power behavior.”

---
### D-042 — Revisit final starting state with the tutorial
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** PENDING — needs Kevin
**Status:** 🟡 Deferred — final gameplay

**What this is about**
D-010 Option A is approved for testing only. Kevin flagged a potential clean-slate start for final gameplay and confirmed that new players will have a tutorial.

**The options**
- **Option A:** Retain the starter ring and Flak in final runs; teach controls through the tutorial.
- **Option B:** Use a clean-slate final opening with the tutorial; later define starting funds/assets so kill-only income can begin.

**What we get**
A guarantees a working income source. B gives the player more ownership of the opening layout.

**What it costs us**
A predetermines part of the opening. B needs a clear bootstrap rule and tutorial design; an entirely empty, unfunded player cannot earn kill income.

**What happens if we're wrong**
Keep starting setup in data so the profile can change later. Tutorial content and onboarding will still need separate implementation.

**My recommendation**
Keep the approved testing setup now. Revisit the final opening after combat works and before tutorial production; do not let the temporary profile become a final design by accident.

**Blocking:** Final opening/tutorial design only; no slice data block.

**Resolution / instruction record — 2026-09-06**
Kevin's instruction flags clean-slate final gameplay as a possibility, not a selection. The tutorial is intended for new players; it is not added to this slice.

---
### D-043 — Store tuning separately from game rules
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
Use one versioned JSON testing profile and a Godot loader with strict validation, alternate input paths, and isolated overrides. Numeric defaults live in the data file; consumers will read them instead of repeating them in code.

**What we get**
Kevin and implementation agents can change economy and battle values without editing mechanics. The starting grant tracks Flak price automatically.

**What it costs us**
The format and validation must evolve when future systems add fields. This task provides loading, not a remote update service, hot reload, or save migration.

**What happens if we're wrong**
A JSON schema and loader are cheap to revise before consumers exist. Preserve version markers and explicit failures to avoid silently corrupting later data.

**Blocking:** None.

**Resolution / instruction record — 2026-09-06**
T-006 contract at docs/contracts/T-007-balance-data.md defines files, API, approved values, units, validation, and tests. T-007 belongs only to Terra; Astra reviews the delivery.

---
### D-044 — Set test positions and bundled relay placement
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A

**What this is about**
The approved test start has a Flak and full ring; full-ring purchases now include relays. Exact positions and relay slot use need to be explicit before state/placement implementation.

**The options**
- **Option A:** Approve starting Flak at wedge 12 and relay at wedge 6; relay uses a normal building slot. Choose the relay slot as part of each later ring purchase.
- **Option B:** Defer these positions and footprint for Kevin's preferred setup.

**What we get**
The proposed setup separates the starter weapon from the relay and uses the existing slot rule.

**What it costs us**
It occupies one slot that could otherwise hold a weapon, and adds a placement choice to a ring purchase.

**What happens if we're wrong**
Positions are simple data edits. Changing slot use after layout logic exists requires more changes.

**My recommendation**
Approve for testing only if these positions suit Kevin. Do not make this the final starting layout by accident.

**Blocking:** None for the approved rule.

**Resolution - 2026-09-06**
Kevin approved the testing/relay setup: starter Flak wedge 12; starter relay wedge 6; relay occupies one normal building slot. The player chooses its slot as part of later full-ring purchases.

---
### D-045 — Expand beyond a damaged surviving ring
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option B

**What this is about**
Purchases now establish complete rings, so the old per-wedge inward-neighbor rule needs clarification when the inner ring has broken wedges. Retaking remains outside the slice.

**The options**
- **Option A:** Allow buying the next whole ring while the current outer ring survives, even if individual wedges are broken.
- **Option B:** Require all twelve wedges of the current outer ring to be intact.

**What we get**
A preserves expansion as an option under pressure. B requires a fully intact foundation.

**What it costs us**
A permits new wedges outside gaps. B can permanently stop expansion after one break while retaking is absent.

**What happens if we're wrong**
Eligibility is cheap to revise as a rule, but it changes expansion and loss experiments.

**My recommendation**
Prefer A so one broken wedge does not silently lock a main game action for the rest of this slice.

**Blocking:** None for the approved rule.

**Resolution - 2026-09-06**
Kevin selected "Require all inner wedges intact." Buying the next full ring is disallowed if any wedge of the inner ring is broken. Retaking is outside the slice, so a broken wedge prevents further expansion; this is an explicit approved consequence, not a reason for Astra to change the rule. Partial HP damage without a broken wedge is not defined as a break.

---
### D-046 — Define startup and purchase transitions separately from presentation
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
T-008 defines a snapshot-based startup and purchase interface. It consumes BalanceProfile, uses the grid's wedge count, validates the current state at purchase time, and returns a new state only when every check succeeds. No consumer feature is assigned by the contract itself.

**What we get**
A failed purchase cannot spend funds or leave half a ring. Tests can inspect state changes without a build menu. Current costs derive from data rather than repeated ring-specific prices.

**What it costs us**
Later consumers must use the interface and explicit starting placements. Physical slot geometry and weapon aiming remain separate gameplay/presentation choices. A future tuning profile that produces fractional costs needs an explicit presentation/rounding policy; the contract forbids silent rounding.

**What happens if we're wrong**
These interfaces remain cheap to revise before consumers are implemented. They do not change the approved prices, expansion condition, or starting setup.

**Blocking:** None for the current approved integer-cost profile.

**Review record:** T-007 accepted after source/data/test/log review: 131 checks passed, import exit 0. T-008 contract is docs/contracts/T-008-purchases.md. No gameplay integration was performed.

---
### D-047 — Set physical slots and weapon aiming before combat integration
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A

**What this is about**
D-011/D-012 fix slot counts and D-014 fixes weapon numbers, but exact slot positions and the Mass Driver's firing arc remain unstated. These affect coverage and must not be invented by a combat or presentation agent. This follow-up preserves the already approved values.

**The options**
- **Option A:** Space slots evenly across each wedge at the band's middle radius. Flak faces outward with its approved 90-degree arc; Mass Driver swivels through 360 degrees. Use nearest eligible targets, instantaneous hits, and no friendly fire.
- **Option B:** Use another slot arrangement and player-selected aiming; Kevin specifies Mass Driver arc, target preference, and shot behavior before implementation.

**What we get**
A supplies a clear initial coverage test with little aiming input. B gives more direct control over firing lanes.

**What it costs us**
A fixes Flak orientation and may make single-target coverage generous. B adds controls and can make the initial funneling test harder to interpret.

**What happens if we're wrong**
Changing physical slots later can invalidate layouts and alter range tests. Changing arcs or aiming affects input and combat tests, even if numeric stats remain in data.

**My recommendation**
Approve A as a testing baseline if it matches Kevin's intent. Keep all numeric combat settings in editable data when implemented. Do not treat the proposal as selected just because the other weapon values are approved.

**Blocking:** None for the approved controls/automatic combat rules.

**Resolution - 2026-09-06**
Kevin selected Option A: slots evenly spaced across each wedge at middle radius; Flak faces outward with its data arc; Mass Driver swivels through 360 degrees; nearest eligible targets, instantaneous hits, and no friendly fire. All armed buildings auto-attack and auto-target. A few player-targeted solar attacks belong to the separate ability system; their existing slice deferral and pending D-026 remain unchanged.

---
### D-048 — Separate automatic rules from the build view and future enemy loop
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
T-010 implements startup/purchase transitions, physical slot helpers, and automatic combat against supplied target records. T-011 consumes those APIs for the build view. The engine loop and enemy generation remain separate because D-016/D-017 are still pending. This does not add player firing commands or solar abilities.

**What we get**
Purchase failures are atomic, targeting can be tested without invented spawns, and UI code cannot silently duplicate prices or placement rules. Mass Driver's approved 360-degree arc is added to editable data.

**What it costs us**
The intermediate build view has no live enemy pressure and is not the completed Phase 2 loop. Deflector Wall's edge/path integration remains for the enemy-path handoff. Combat uses a fixed-step function rather than elapsed-time catch-up; Sol's later loop must honor that contract.

**What happens if we're wrong**
These new APIs can be corrected during review before the live loop depends on them. No saved games or released builds depend on them yet.

**Implementation conventions**
Use stable ring/wedge/slot weapon identifiers, deterministic weapon and target tie order, copied result states, explicit errors, transient Cartesian geometry only for distance checks, and no silent cost rounding. One click places one weapon then clears the mode; invalid attempts retain the mode. Controls consume UI clicks before world actions. The neutral build view reuses the inspector while preserving the original scene. Menu UI continues processing while gameplay is paused so Resume works. All are implementations of approved controls and rules.

**Blocking:** None for T-010/T-011. D-016/D-017 were subsequently approved for test behavior; live movement/spawning still need engine integration and measured capacity.

---
### D-049 — Measure crowd foundations before selecting capacity
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
T-012 gives Sol the generic fixed-step clock and reusable entity storage already needed by Phase 2. It measures 500, 1,000, and 5,000 records and supplied combat targets against the current automatic-weapon implementation. This responds to Kevin's stated final crowd scale without selecting a cap or inventing live enemy rules.

**What we get**
We can identify storage or target-search costs before wiring the live loop. Stable lifetime IDs prevent stale enemy references from affecting a reused record. Paused time does not accumulate for catch-up.

**What it costs us**
Headless measurements omit rendering, movement, path updates, and most gameplay. A fast pool does not establish a playable frame rate, and a small armed-ring benchmark does not represent a fully built arena.

**What happens if we're wrong**
The generic modules and measurement fixtures are isolated. Performance findings can return to the owning agent before integration; no live capacity is committed by these tests.

**Implementation conventions**
Explicit constructor capacity, reusable payload dictionaries, monotonically increasing IDs, constant-time lookup/free-slot bookkeeping, independent active-ID snapshots, and a 60 Hz callback clock with fractional-time accumulation. Pause drops paused wall time rather than simulating it on resume. Benchmark three warmups and ten samples where practical; report all reductions and missing hardware inventory. A one-ring combat fixture arms its eleven non-relay slots with Flak, using test-only funds and a durable polar target set.

**Blocking:** None for measurement. D-007 live capacity remains a Kevin decision after representative evidence.

---
### D-050 — Accept the build view for this stage and keep slots revisable
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved for this stage

**What this is about**
Kevin reviewed the current build view and said it is fine for this stage. He explicitly left placement slots open to later adjustment. This accepts the current view without making its layout permanent or declaring Phase 2 complete.

**The options**
- **Option A:** Accept the stage view and preserve later slot-layout changes.
- **Option B:** Request visual or placement corrections before continuing.

**What we get**
The current construction view can support subsequent gameplay integration. Slot geometry stays behind a shared helper used by both input and rendering.

**What it costs us**
Later layout changes still require coverage and selection checks. This is not approval of final art or a live-combat readability verdict.

**What happens if we're wrong**
The helper centralizes slot positions, so changes do not need independent coordinate fixes in the HUD and rules. Existing saved layout compatibility is not yet a release concern.

**My recommendation**
Keep the accepted placeholder and revisit slot placement when real combat provides evidence.

**Blocking:** None. T-011 is complete after its final input correction.

**Resolution:** Kevin said, “Visual view is fine for this stage. Placement slots may be adjusted later.”

---
### D-051 — Optimize repeated targeting work without changing behavior
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** 🟢 Decided

**What this is about**
T-012's headless eleven-Flak ready-volley measurement exceeded a 60 Hz tick interval at 1,000 and 5,000 targets. T-013 sends the implementation back to Terra to cache per-step derived geometry and avoid sorting an entire crowd when only a few nearest targets are needed. Polar positions remain authoritative.

**What we get**
Remove repeated computation while preserving target choice, exact tie order, damage, rewards, timing, validation, and result isolation. Compare before and after with the same benchmark and independent reference checks.

**What it costs us**
Per-step caches use temporary memory, and the optimized selector needs equivalence tests. Headless gains still cannot establish full-game capacity or frame rate.

**What happens if we're wrong**
The change is limited to one rule implementation and its tests, and can be reverted if behavior or performance regresses. No lower density, target cap, or simulation rate is authorized as a shortcut.

**Blocking:** None for this corrective optimization. D-007 live capacity remains open.

**T-013 outcome (2026-09-06):** Astra accepted the behavior-preserving optimization after source/reference review and 219 passing checks. Unchanged benchmark medians improved to 3.119/6.250/35.246 ms at 500/1,000/5,000 targets. D-007 capacity remains open; these are headless targeting timings only.

---
### D-052 - Prepare approved pressure data before live behavior
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-014 gives the four approved D-017 testing values named fields in the existing balance profile. It does not invent growth, movement, or capacity rules. The internal prototype retains schema version 1 because no released data migration exists.

**What we get**
Future spawning reads editable data through the already validated profile API.

**What it costs us**
Hand-authored complete profiles must include the new required fields. No hidden defaults conceal omissions.

**What happens if we're wrong**
Field names and schema version can be changed cheaply before live consumers or released saves exist.

---
### D-053 - Define escalation timing and which enemies receive it
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A for testing only

**What this is about**
D-017 approves 10% health/damage growth per minute for testing but does not define additive versus compounded growth or whether existing enemies change. Live spawning needs exact behavior.

**The options**
- **Option A:** Each completed minute adds 10% of original stats to newly spawned enemies; existing enemies keep spawn stats. Minute 2 is 120%.
- **Option B:** Each completed minute multiplies new-spawn stats by 1.1; existing enemies keep spawn stats. Minute 2 is 121%.

**What we get**
A has predictable linear growth. B produces stronger late-run escalation. Both keep already visible enemies' health stable.

**What it costs us**
A may grow too slowly later; B grows increasingly quickly. Neither tests a system that strengthens living enemies.

**What happens if we're wrong**
The formula is simple to replace, but difficulty conclusions must be retested.

**My recommendation**
A for the first controlled testing loop. Keep the coefficient editable under D-017.

**Blocking:** None for testing escalation.

**Resolution:** Kevin chose Option A for now: additive increases on completed minutes for new spawns; existing enemies retain spawn stats. He explicitly questioned additive escalation for final gameplay and prefers larger numbers of weaker enemies (swarms) over smaller numbers of stronger enemies. This is a final-design preference, not an approved final spawn curve or cap.

---
### D-054 - Define crowd overlap and movement neighbors
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
D-016 settles detours and sealed-route behavior, but crowd contact and neighbor movement were recommendations rather than explicit approvals. These change wall funneling and large-crowd simulation cost.

**The options**
- **Option A:** Enemies may overlap, use radial/angular neighbors, and receive refreshed routes before the next movement update following structural changes.
- **Option B:** Enemies physically block one another and queue, requiring a contact/queue contract before implementation.

**What we get**
A supports straightforward large-crowd route tests. B makes bodies restrict chokepoints.

**What it costs us**
A has no physical crowd queues or pushing. B adds simulation work and needs more behavior details.

**What happens if we're wrong**
Changing contact behavior changes effective wall strength and invalidates funneling conclusions.

**My recommendation**
A for the first test, with no implied final capacity verdict. This is a gameplay choice, not an optimization Astra can silently make.

**Blocking:** None for this behavior.

**Resolution:** Kevin approved Option A: enemies may overlap, use radial/angular neighbors, and refresh routes before the next movement update after structural changes.

**Continuation outcome:** T-014 accepted after 535 passing balance/building/weapon checks. D-053/D-054 questions remain pending; no answer inferred from elapsed time. D-020 wording was corrected to reference already approved D-039 seven-wedge collapse and D-011 whole-ring purchases, without resolving outer-ring survival.

---
### D-055 - Compute shared routes from explicit traversal costs
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-015 gives Sol an engine-only route map. Gameplay supplies traversable cells, legal connections, costs, and destinations. Many enemies can query a single computed map instead of finding paths independently.

**What we get**
Efficient deterministic routes on the approved polar neighbors, without selecting wall-placement or gameplay travel-cost rules. Replacing a snapshot after structure changes prevents mixed old/new route data.

**What it costs us**
Gameplay must assemble the graph in a subsequent handoff. The generic utility cannot decide which ring surface an enemy should attack.

**What happens if we're wrong**
This small utility is independent of enemy state and can be replaced without changing balance data or presentation. Equal routes use stable cell ordering as a reversible technical tie rule.

---
### D-056 - Reject route costs that lose all precision during accumulation
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
A tiny positive path cost added to an enormous accumulated distance can round back to the same value. T-015 rejects that unrepresentable addition with a clear error instead of claiming positive progress and risking cycles in equal-distance choices.

**What we get**
Deterministic routes and explicit invalid-data feedback for extreme numeric inputs.

**What it costs us**
Such extreme mixtures of costs cannot be used in one reachable route field. Ordinary game-scale positive costs are unaffected.

**What happens if we're wrong**
The guard can be replaced with a different numeric representation later, without changing the gameplay neighbor rule. Focused coverage checks the exceptional case.

**Current continuation outcome:** D-053 is approved for testing only, with final gameplay favoring larger swarms of weaker enemies; D-054 Option A is approved. T-014/T-015 are accepted. No decision is needed to accept these completed utilities. Live enemy rules and scene integration are still outstanding and will receive separate handoffs with any remaining rule choices explicitly briefed.

---
### D-057 - Deterministic testing spawn schedule
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-016 translates approved rate and even-bearing coverage into reproducible testing arrivals: first arrival after one spawn interval, then wedge12,1 through11, repeating. Interval queries count scheduled arrivals without allocating a potentially huge backlog.

**What we get**
Tests can compare split time updates to one interval and reproduce the same spawn times and bearings.

**What it costs us**
This is a regular test pattern, not final enemy variety or random distribution. A tiny count-boundary tolerance absorbs numerical roundoff only.

**What happens if we're wrong**
The deterministic pattern is isolated in one helper and can be replaced before final pressure tuning.

---
### D-058 - Expansion into an occupied ring
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option B

**What this is about**
A whole-ring purchase may otherwise create structure around machines already occupying that band.

**The options**
- **Option A:** Keep machines in place and have them attack the new wedge.
- **Option B:** Reject the purchase while living enemies occupy any part of the proposed ring.

**What we get**
B makes clearing the new ring a prerequisite to claiming it and avoids enclosing enemies in new structure.

**What it costs us**
Expansion can be blocked under continuous pressure even when the player has enough energy.

**What happens if we're wrong**
Changing this changes the difficulty and opportunity to expand, so live tests must be repeated.

**My recommendation**
A was proposed; Kevin chose B. Implement B without silently preserving the recommendation.

**Blocking:** None. Resolution received through the live-test briefing.

---
### D-059 - Editable 1,000-enemy live trial
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - testing only

**What this is about**
The first live test needs bounded reusable storage before complete-loop measurements exist. Targeting-only results do not establish final capacity.

**The options**
- **Option A:** 1,000 simultaneous enemies; skip scheduled arrivals at capacity without a later burst.
- **Option B:** Start with 500 for more initial headroom.

**What we get**
A exercises the requested swarm scale while leaving a measurable starting point for optimization.

**What it costs us**
The full rendered loop may still need optimization; this is not a final performance guarantee.

**What happens if we're wrong**
The test limit remains editable. Any final capacity or gameplay density decision still belongs to Kevin after measurement.

**My recommendation**
A for the measured trial. Kevin approved A.

**Blocking:** None for the live trial. D-007 final capacity remains open.

---
### D-060 - Sequence the first live loop and retain destroyed ring IDs
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-017 connects the Phase 2 normal-machine loop before Phase 3 wall funneling. With no walls present, machines advance radially on their bearing, stop at intact wedges, and proceed through broken gaps. Shared angular routing remains the next wall-pathing integration, not a claim made by this first loop.

Destroyed rings retain empty records with their original IDs so surviving outer rings are not renumbered. A separate query reports the outer surviving ring for spawning. Fixed ticks admit arrivals, move/apply enemy damage in lifetime-ID order, then resolve automatic weapon damage and bank kills. New arrivals receive only the remaining time after their scheduled arrival.

**What we get**
The first playable combat loop can be verified without silently choosing wall-edge geometry. Stable IDs preserve building references and collapse records. Tick order is deterministic and testable.

**What it costs us**
The state validator must distinguish a destroyed ring record from an intact one. Simultaneous enemy/weapon events resolve in the documented fixed order. Walls remain required later in the slice.

**What happens if we're wrong**
Tick ordering and internal record layout can be changed with focused regression tests. Neither changes approved costs, damage, collapse threshold, or outer-ring survival. T-017 must report blockers rather than invent missing gameplay rules.

---
### D-061 - Minimal presentation for the live test
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
The accepted construction view has no enemy markers or damage feedback. The first visible live test needs a minimal readable treatment before final art is chosen.

**The options**
- **Option A:** Extend the existing grayscale view with small filled machine circles, plain core HP/enemy count, darker broken wedges, and immediate removal of collapsed buildings.
- **Option B:** Keep this step headless until Kevin chooses a presentation treatment.

**What we get**
A allows inspecting combat and destruction directly. B postpones visual choices.

**What it costs us**
A is provisional and does not establish final art, effects, audio, or the complete ring-status HUD.

**What happens if we're wrong**
These simple presentation elements can be changed without gameplay changes.

**My recommendation**
A, following the already accepted neutral construction view. No shake or effects are proposed.

**Blocking:** None. Kevin approved the proposed live-test placeholders. T-018 follows T-017 technical acceptance.

---
### D-062 - Roll back failed simulation admissions without reusing IDs
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
The existing pool assigns lifetime IDs on admission and has no reservation transaction. T-017 validates before admission, then stages gameplay changes. If an unexpected downstream rule fails, it releases newly admitted machines and leaves gameplay state/time/counters/events unchanged, while consumed IDs remain consumed.

**What we get**
Failed gameplay updates do not leave partially moved machines or credited energy, and stale IDs can never refer to later machines.

**What it costs us**
Rare failing updates may leave gaps in the ID sequence. IDs are identifiers, not spawn counts.

**What happens if we're wrong**
A future pool reservation API can replace this internal rollback without changing player rules. No new engine subsystem is needed now.

**T-017 review measurement clarification (D-060):** Measure and label both normal cooldown steps and forced-ready weapon steps at1000 machines. Record hit counts, because3 warmups plus10 samples can otherwise omit every ready volley after the first warmup. This changes only measurement coverage, not gameplay cadence.

**T-017 acceptance:** Astra verified all820 checks and accepted the live gameplay interface for Luna. The forced-ready1000-machine rerun measured12.858ms median/13.159ms p90 headlessly; this does not resolve final capacity. T-018 is now authorized under approved D-061 placeholders.

---
### D-063 - Profile and reduce live presentation overhead without changing the test
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-018's initial rendered1000-machine fixture measured37.698ms median frame interval and46.556ms p90, above the provisional16.667ms target. Its simulation CPU summed per frame was22.619ms median/31.269ms p90 because frames can contain several fixed updates. Astra sent presentation back to Luna for measured sync/draw overhead and cheap exact-behavior fixes before final handoff.

**What we get**
Find repeated quote scans, derived coordinate work, or individual marker drawing costs. Identical circle markers may be batched while retaining approved size/color and all gameplay updates.

**What it costs us**
Profiling and a second unchanged120-frame fixture are required. Renderer/VSync conditions may limit conclusions.

**What happens if we're wrong**
Presentation changes remain reversible and must preserve screenshots and control tests. No lower cap, density, simulation rate, smaller fixture, or new visual treatment is authorized. If the main cost is gameplay or external rendering conditions, report the evidence for a separate corrective handoff.

---
### D-064 - Review the first playable live prototype
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
The main Godot scene now connects construction, live normal machines, automatic kills and energy, wedge damage, seven-break ring collapse with outer survivors, and core loss. Astra has verified the implementation, input/pause checks and rendered screenshots. Kevin requested continued work until a review or decision point; this is the first complete visible live-loop handoff.

Run project.godot in Godot with F5. Review enemy/building readability, construction controls under live pressure, and break/collapse/core-loss feedback. The unchanged hands-off setup loses the core in about20seconds, so this is still a short testing setup. Restart the project to repeat a run; there is no new in-game restart control.

**The options**
- **Option A:** Accept this first live prototype for the current stage, then continue to the wall/funneling handoff and its remaining rule briefings.
- **Option B:** Identify controls/readability/feedback changes to make before continuing.

**What we get**
A confirms this integration is a usable basis for the next work. B corrects user-facing problems before they spread into further systems.

**What it costs us**
A leaves current testing balance, final art, and final performance capacity open. The current1000-machine steady-contact rendered fixture is near60FPS, but has no spawn/kill churn and is not a final guarantee.

**What happens if we're wrong**
Presentation remains isolated from gameplay and can be revised later. This review does not permanently fix slots or approve final tuning.

**My recommendation**
A if controls and feedback are clear when played. Technical checks and rendered inspection pass; the short survival time should be treated as testing balance to revisit, not silently accepted as final gameplay.

**Blocking:** None for live-prototype acceptance. Kevin chose Option A. This does not declare Phase2 or the slice complete; walls and later slice features remain.

**Evidence:** docs/reviews/T-018-acceptance.md and docs/reviews/T-018.md; final screenshots under docs/reviews/artifacts/T-018-*.png.

---
### D-065 - Define wall edges, placement and support
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
Deflector Walls must steer machines around barriers, but their exact edges and controls remain unspecified. Existing cost5 and HP50 are already approved. Walls use edge occupancy, separate from building slots.

**The options**
- **Option A:** One wall along an intact owned wedge's curved outer edge. Choose Wall, click the wedge, and draw a neutral edge line. A supporting wedge break disables blocking; whole-ring collapse removes the wall.
- **Option B:** Also allow the two straight side edges, with additional edge-selection controls to be specified before implementation.

**What we get**
A provides clear inward barriers and deliberate gaps. B allows more elaborate funnels.

**What it costs us**
A limits layout flexibility. B needs more controls and shared-edge ownership rules. The stated support behavior is part of A's proposed package, not previously implemented logic.

**What happens if we're wrong**
The edge model and input would need revision, and funneling tests repeated. No final art commitment is implied by the neutral line.

**My recommendation**
A for the first wall test, on any intact owned wedge, at the already approved fixed price and HP.

**Blocking:** None for these placement rules. Kevin approved Option A.

---
### D-066 - Resolve a completely wall-covered perimeter
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Option C approved; numeric and closure details pending

**What this is about**
D-016 approves detouring to reachable exposed ring surfaces and forbids ordinary machines smashing walls. A fully wall-covered perimeter may leave no such surface. The fallback must be made explicit before wall routing; it cannot silently be treated as already approved.

**The options**
- **Option A:** When no exposed wedge is reachable, attack the underlying ring wedge at a wall without damaging the wall itself. When the supporting wedge breaks, its wall stops blocking.
- **Option B:** Reject placement of a wall that would seal all reachable ring surfaces, guaranteeing a gap remains.

**What we get**
A maintains pressure and permits closed layouts. B keeps machines' attacks strictly on exposed surfaces.

**What it costs us**
A explicitly extends the earlier exposed-surface fallback to a covered surface. B adds a construction restriction and needs global layout validation.

**What happens if we're wrong**
This materially changes wall strength and funneling conclusions; changing it requires new gameplay tests.

**My recommendation**
A, retaining normal detours whenever an exposed wedge is reachable. Normal machines still do not damage wall HP.

**Blocking:** Wall combat/routing still needs the reduced damage multiplier and exact closure condition in D-067/D-068.

**Resolution:** Kevin chose his own Option C: enemies can damage walls if the entire perimeter has walls; normal enemies deal reduced damage. This supersedes the earlier normal-enemies-never-damage-walls rule in this condition. Options A/B above are not approved. The underlying wedge is not substituted as the damage target. D-067/D-068 brief the remaining multiplier and closure details.

---
### D-067 - Reduced normal-enemy wall damage
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A for testing

**What this is about**
Kevin's D-066 Option C allows normal enemies to damage walls at a reduced rate only for a completely walled perimeter. The multiplier is not yet specified and must remain editable balance data.

**The options**
- **Option A:** 25% of the enemy's normal damage for testing. At base5DPS and50wallHP, one machine takes40seconds to destroy a wall.
- **Option B:** 50% damage. The same single-machine breach takes20seconds.

**What we get**
A gives sealed walls a stronger delaying role. B makes brute-force breaches faster. Multiple machines combine their damage in either case.

**What it costs us**
A risks long stalls; B risks walls feeling too weak. These times exclude weapons killing attackers and later enemy stat escalation.

**What happens if we're wrong**
The coefficient is cheap to tune, but wall strength and funneling conclusions must be retested.

**My recommendation**
A as an explicitly temporary25% starting value, not final balance.

**Blocking:** None for the coefficient. Kevin approved25% for testing, stored as editable data; D-068 closure condition remains pending.

---
### D-068 - Define a completely walled perimeter
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
Surviving wedges can form an uneven perimeter across different rings. We need to determine when Kevin's wall-attack exception applies and when machines resume seeking openings.

**The options**
- **Option A:** Allow wall attacks when walls leave no reachable exposed ring surface. This includes mixed-ring sealed layouts; once a wall falls and exposes a route, normal enemies resume detouring toward the opening.
- **Option B:** Require all12 walls on the same intact ring before wall attacks become legal.

**What we get**
A follows reachable geometry on uneven perimeters. B is easier to explain as a12-wall condition.

**What it costs us**
A needs connected-region detection and route updates. B can leave a sealed mixed-ring arrangement unresolved.

**What happens if we're wrong**
Changing this condition changes which layouts are safe and requires repeating route and breach tests.

**My recommendation**
A to cover the already approved survival of outer rings after inner losses.

**Blocking:** None. Kevin approved the no-reachable-exposed-surface condition and resuming detours when an opening appears.

---
### D-069 - Store optional outer-edge walls on wedge records
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-019 stores the approved one-per-wedge outer wall as an optional wall record, separate from building occupants. Positive HP records may remain inactive on broken supports; collapsed rings cannot retain walls. Future combat erases a destroyed wall record.

**What we get**
Existing wall-free states remain valid. Placement can be tested independently without choosing the pending attack coefficient or sealed-layout condition.

**What it costs us**
The runtime collapse transition must erase wall records in the subsequent handoff before wall placement is exposed in the live scene. T-019 adds no live button or routing behavior.

**What happens if we're wrong**
This isolated optional field is inexpensive to revise before UI/runtime consumers are connected. Existing validation and transaction tests protect the accepted live prototype.

---
### D-070 - Reuse a supplied-segment polar motion utility
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-020 gives Sol a generic constant-speed radial/arc motion helper. Gameplay supplies legal segment endpoints; the helper returns movement and consumed time without selecting routes or targets.

**What we get**
One tested scalar-precision implementation handles seams and leftover travel time, while polar coordinates remain authoritative.

**What it costs us**
Callers must supply one-axis legal segments. Numerical equality uses small documented tolerances only.

**What happens if we're wrong**
The helper is isolated behind one API and can be corrected without altering wall or combat rules.

---
### D-071 - Build shared wall routes at contact boundaries
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
T-021 uses open polar cells with route nodes at their inner curved boundary and center bearing, preserving the existing ring-surface contact radius. Radial edges cost one ring width; angular edges cost their physical arc length. Two shared maps find exposed targets first and walls only when exposed targets are unreachable, implementing D-068 per connected region.

**What we get**
No per-machine path searches, no diagonal cuts through intact wedges, and no all12-wall shortcut that misses uneven perimeters. Shared routes refresh before movement after a topology change; partial health changes alone do not rebuild them.

**What it costs us**
Machines retain temporary waypoints while traversing segments, with staged rollback and invalidation when layout changes. Synthetic old inner-collapse tests must leave a physically open outer-wedge approach instead of injecting a normal machine inside intact structure.

**What happens if we're wrong**
Node layout and cache internals are reversible technical choices. Tests cover contact timing, legal paths, mixed-ring sealing, same-tick breach redirection and outer-ring survival. No new damage, cost, density, visual or enemy-contact rule is introduced.

---
### D-072 - Profile and remove repeated simulation work
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
The rendered wall test cannot keep up with 1,000 enemies: slow simulation ticks accumulate further catch-up work. T-023 measures the cost of each simulation stage and removes redundant work while preserving the approved rules and public data isolation. Benchmark runs are serialized between agents.

**What we get**
A measured correction with the same enemy count, speed, attack cadence and rollback behavior. Immutable route results may be cached per navigation revision if measurement proves useful; callers still receive independent results.

**What it costs us**
Wall prototype review waits for corrected rendered verification. Test fixtures must keep health subtraction numerically observable and enemies moving throughout the sample; fixture-only durability and geometry changes are disclosed.

**What happens if we're wrong**
Revert an unhelpful optimization independently. Do not lower the cap, discard clock time, or alter gameplay to claim success. Core changes require a separate bounded Sol handoff.

---
### D-073 - Review the wall prototype for this stage
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
The live Structure tab now places a wall on an intact wedge's outer edge for5 energy, independent of building slots. Neutral edge lines and selected-wall health show the structure. Machines detour toward reachable openings; sealed routes allow25% wall damage. A breach removes the line and redirects enemies; ring collapse removes its walls while outer structures survive. Functional tests and four rendered examples are ready. Crowd performance remains a separate open engineering issue.

**The options**
- **Option A:** Accept the wall controls and placeholder feedback for this stage, with balance, art, placement details and crowd performance still provisional.
- **Option B:** Describe what is unclear or should change in these controls or feedback before accepting the stage.

**What we get**
Your review checks whether walls and their loss are understandable in the live view before further presentation work builds on them.

**What it costs us**
The temporary circles and lines provide limited combat feedback. This review does not establish final swarm capacity or resolve the remaining Tunneler rules.

**What happens if we're wrong**
Controls and placeholder drawing can be revised locally. Approved gameplay rules remain recorded separately; changing them requires an explicit revision.

**My recommendation**
Option A if the examples are readable at this stage. Keep performance work open and use the next gameplay briefing to settle the Tunneler separately.

**Blocking:** None for stage presentation. Performance correction remains independently authorized.

**Review artifacts:** docs/reviews/T-022.md and artifacts/T-022-open-gap-funnel.png, T-022-sealed-wall-damage.png, T-022-wall-breach.png, T-022-wall-ring-collapse.png.

**Resolution:** Kevin accepted Option A. Wall controls and placeholder feedback are accepted for this stage. Balance, final art, placement details and crowd performance remain provisional; T-022 performance verification is not closed.

---
### D-074 - Reuse exclusively owned combat staging
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
The live tick already builds private target records, but combat copies them again. T-025 introduces an internal ownership contract allowing combat to update those private health values. Public pure calls still copy their results, and every position remains read-only to combat.

**What we get**
A measured reduction in repeated copying without changing targeting or attack cadence.

**What it costs us**
Internal callers must own their scratch records exclusively and discard them on failure. Tests must prove that failed combat cannot change live state and public results remain independent.

**What happens if we're wrong**
Revert the isolated internal call path. No schema, balance, crowd size or gameplay rule changes.

---
### D-075 - Set the Tunneler's emergence and fallback rules
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
D-018 approves bypassing one intact ring and being untargetable underground, then vulnerable after surfacing. Proposed first-test route: on the scheduled bearing, find the outermost intact wedge and the next intact wedge inward. Begin underground at the outer edge of the first; emerge in the middle of the next inward wedge, damage that wedge, then use normal inward movement/attacks after it breaks. Broken gaps do not count as an intact ring bypassed. Lock the destination when burrowing begins; if it breaks or collapses during travel, emerge at the planned location and follow the now-open routes. Expansion does not relocate a burrowing enemy.

**The options**
- **Option A:** Require both intact wedges before admitting that arrival. If no inner destination exists, skip that arrival without saving it for later.
- **Option B:** When only one intact wedge remains on that bearing, bypass it and emerge at the core boundary instead, then attack the core.

**What we get**
A gives interior weapons a predictable defense test and avoids direct core emergence in the first prototype. B keeps Tunnelers threatening a one-ring base.

**What it costs us**
A means Tunnelers cannot arrive on bearings without an eligible inner target, including the one-ring start. B can damage the core with little interior coverage available.

**What happens if we're wrong**
The eligibility/fallback rule can be revised in its own gameplay service, but changes the threat players plan around.

**My recommendation**
Option A for the first test, with the common route and destination-change rules above. Evaluate direct-core emergence separately after interior defense is visible.

**Blocking:** Tunneler movement/damage implementation. No implementation assigned.


**Resolution:** Kevin approved Option A as briefed. Use the common emergence/destination rules and skip arrivals without an intact inner target; no direct-core emergence fallback.

---
### D-076 - Set editable Tunneler test values
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
Proposed test package: one scheduled Tunneler arrival every30seconds, first at60seconds; bearings cycle12,1 through11; arrival begins already underground at the chosen perimeter. Two seconds of burrow travel and destination warning, then emergence. BaseHP20; normal-machine damage, post-emergence speed, kill reward and provisional spawn-time stat growth. Shared1000-machine trial cap; ineligible or capacity-blocked arrivals are skipped without backlog. All values remain editable balance data. Burrow duration determines travel speed to the locked destination; it is distinct from surfaced movement speed.

**The options**
- **Option A:** Use this package for testing only.
- **Option B:** Revise the arrival timing, burrow duration or combat values before implementation.

**What we get**
A sparse, predictable elite test that uses existing weapons and economy, with an explicit two-second response warning.

**What it costs us**
Arriving directly underground gives no exposed approach phase. These provisional values do not establish final pacing; the current short-lived default run may need isolated fixtures to exercise late arrivals.

**What happens if we're wrong**
Data values are easy to adjust. Adding an exposed approach phase later changes the state sequence and requires another behavior decision.

**My recommendation**
Option A as an isolated mechanics test. Keep final swarm pressure and additive growth open.

**Blocking:** Tunneler profile, schedule and lifecycle implementation.


**Resolution:** Kevin approved Option A as briefed. Use the complete editable testing package, including direct underground arrival, two-second burrow/warning and shared crowd capacity.

---
### D-077 - Choose a neutral Tunneler warning and marker
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
The underground warning needs to show where the enemy will emerge, and surfaced Tunnelers must be distinguishable from normal circles. Propose a hollow circle at the locked destination with a countdown while burrowing, then a filled triangle for the surfaced enemy. Use the current grayscale treatment and fixed screen-size markers. No new sound, shake or final art.

**The options**
- **Option A:** Use the hollow-circle countdown and surfaced triangle for this stage.
- **Option B:** Specify another placeholder warning/marker treatment.

**What we get**
The warning identifies the threatened inner wedge, and shape distinguishes the elite without choosing final art.

**What it costs us**
A countdown adds small text near the action; crowded warnings need later readability review.

**What happens if we're wrong**
These local presentation elements are inexpensive to replace independently of gameplay.

**My recommendation**
Option A for the first visible Tunneler test.

**Blocking:** Tunneler presentation only; gameplay can proceed once D-075/D-076 are approved.


**Resolution:** Kevin approved Option A. Use the hollow-circle countdown at the destination and filled triangle after emergence, in current grayscale placeholders.

---
### D-078 - Separate Tunneler foundation from visible integration
**Date:** 2026-09-06
**Tier:** 1
**Decided by:** Astra
**Status:** Decided

**What this is about**
Terra first implements editable Tunneler data and pure arrival/destination rules in T-026. A later runtime task consumes that contract. The current visible scene must not accidentally render underground Tunnelers as ordinary circles before D-077 is approved.

**What we get**
Approved gameplay work proceeds while the presentation choice remains pending, with clear data and test boundaries.

**What it costs us**
A separate small foundation handoff precedes live integration. Existing normal-machine snapshots and tests retain their established contract.

**What happens if we're wrong**
These module and staging choices are reversible without changing the approved enemy behavior.

---
### D-079 - Resolve simultaneous arrivals at the shared cap
**Date:** 2026-09-06
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
Normal and Tunneler arrivals can be due at exactly the same time with only one shared pool slot free. Both respect the approved1000 trial cap and skipped-arrival rule; their tie priority is unspecified.

**The options**
- **Option A:** Admit the eligible Tunneler first, skipping the normal arrival if no slot remains.
- **Option B:** Preserve normal-arrival priority and skip the Tunneler if no slot remains.

**What we get**
A keeps the sparse elite schedule from being crowded out. B prioritizes normal pressure.

**What it costs us**
At that exact capacity tie, one scheduled threat replaces the other. Neither option queues a later burst.

**What happens if we're wrong**
An isolated tie-break can be changed later, but affects which enemies actually reach play under sustained load.

**My recommendation**
Option A. Check Tunneler eligibility before spending a slot; an ineligible elite must not displace a normal arrival. Earlier arrival times retain chronological priority.

**Blocking:** Live mixed-enemy admission. T-026 pure data/destination work remains independent.


**Resolution:** Kevin approved Option A. An eligible Tunneler gets priority over a normal arrival at an exact simultaneous shared-cap tie. Earlier arrivals remain chronological; ineligible Tunnelers consume no slot.

---
### D-080 - Review visible Tunneler testing stage
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
Tunneler warning/countdown, emergence triangle, inside damage and inner collapse are implemented. Independent presentation checks pass 197/197; runtime checks passed 761/761. Review docs/reviews/T-028-astra-review.md and artifacts/T-028-underground-warning.png, T-028-surfaced-triangle.png, T-028-surfaced-overlap.png and T-028-inner-collapse.png.

**The options**
- Option A: Accept these placeholders and behavior for this testing stage, retaining the known small-triangle/building overlap issue for later readability work.
- Option B: Request a visibility adjustment before accepting the stage; Kevin specifies the desired change before implementation.

**What we get**
A closes the visible Tunneler stage review and allows the next work briefing. B improves enemy distinction before further evaluation.

**What it costs us**
A leaves a tiny triangle difficult to distinguish over a filled building marker. B requires another approved presentation change and verification.

**What happens if we're wrong**
These local placeholders can be revised without changing Tunneler rules. No final art, balance or capacity acceptance follows either option.

**My recommendation**
Option A for this early testing stage. Countdown is readable; the overlapping triangle is a documented limitation. The 1,000-enemy angular test currently fails full-window movement verification and remains a separate unresolved performance issue.

**Blocking:** Human acceptance of the visible Tunneler stage only. Pausing here follows Kevin's instruction to continue until a concrete review/decision point.

**Resolution:** Kevin said "accept" on 2026-09-07. Testing presentation and behavior accepted as Option A. Marker/building overlap remains deferred; final art, balance and swarm capacity are not accepted by this review.

### D-024 current briefing - 2026-09-07
The next unapproved presentation direction is the persistent ring-status HUD. Existing world selection and transient break text cannot identify an off-screen failing bearing. The spec requires a compact radial minimap of wedge integrity and relay status. Power remains deferred, so relay information here means structure present/destroyed only, never invented power/brownout state.

Recommend Option A for testing: show all rings in a persistent radial overview with fixed clock-face bearings, wedge HP and distinct broken/critical marks, a critical threshold below 25% HP, and click-to-focus without pausing. Verify the three-ring slice and a separate twelve-ring readability fixture. Option B uses scrolling/filtering and pins threatened rings; it preserves marker size at larger scales but can hide spatial context and requires prioritization rules. Neither selects final art or resolves unbounded-ring aggregation. Exact layout and symbol treatment still require a concrete presentation brief after this direction is chosen; no HUD implementation assigned.

---
### D-081 — Accept Phase 3 completion
**Date:** 2026-09-07
**Tier:** 1
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** BUILD-PLAN.md Phase 3 exit check

**What this is about**
Phase 3's deliverable (continuous inward pressure, flow-field pathing, wall detours/gaps, Tunneler bypass, entity reuse under load) is implemented and task-accepted (T-019 through T-028, all Done). The remaining open item — whether the frame-time target holds at the tested crowd size — was resolved this session: Kevin accepted current 1,000-machine angular performance for testing, with the shortfall diagnosed as near-zero simulation margin rather than a defect. This is a process checkpoint, not a new creative/scope choice, so it is Tier 1, but phase transitions have previously gone to Kevin for explicit sign-off (D-038 for Phase 1), so it is offered rather than assumed.

**Exit check against evidence**
- Otherwise-identical layouts with/without walls compared; normal machines detour, never cross intact occupied barriers, and handle a fully sealed perimeter under the approved 25% conditional-damage rule (D-065-D-068, T-019-T-022).
- Tunneler exceptions (untargetable underground, timed emergence, single-ring bypass) are distinct and independently verified (T-026-T-028, D-018/D-075-D-080).
- Spawn/pressure timing is driven by simulation-elapsed seconds in `LiveSimulation.step`, not by rendering; code inspection confirms camera zoom/position affect only draw calls in `live_view.gd`, never the simulation clock, so pressure is independent of camera position.
- The agreed machine cap and frame-time target: does not literally hold at 1,000 machines in the angular case (~15.9 ms/tick alone, versus a 16.667 ms budget) — Kevin explicitly accepted this as sufficient for the current testing stage rather than the target being met outright.

**The options**
- **Option A:** Accept Phase 3 as complete for this testing stage on the evidence above; proceed to Phase 4 (ring-loss clarity and the now-approved D-024 HUD) under its stated dependencies.
- **Option B:** Hold Phase 3 open for further verification or performance work before starting Phase 4.

**What we get**
A unblocks Phase 4 HUD/loss-clarity work, all of whose stated dependencies (D-005, D-006, D-015, D-020, D-024, D-025) are now approved. B delays Phase 4 for more certainty on an already-accepted tradeoff.

**What it costs us**
A carries forward the known, accepted crowd-performance limitation into a phase that adds more UI (the HUD) without first re-testing headroom. B spends more time on a question Kevin already answered this session.

**What happens if we're wrong**
Phase boundaries are a planning convenience; reopening Phase 3 work later costs little since T-019 through T-028 remain intact and reviewed either way.

**My recommendation**
Option A. Every stated Phase 3 dependency and exit-check item is either met or explicitly accepted by Kevin; nothing new would be learned by holding the phase open.

**Blocking:** Phase 4 task assignment.

**Resolution - 2026-09-07**
Kevin accepted Option A. Phase 3 is complete; T-019 through T-028 stand as delivered. Phase 4 (ring-loss clarity: independent wedge HP, 7-of-12 collapse, complete destruction without refunds, core defeat, and the D-024 persistent ring-status HUD) is now open for task assignment under its approved dependencies.

---
### D-082 — Accept Phase 4 completion
**Date:** 2026-09-07
**Tier:** 1
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** BUILD-PLAN.md Phase 4 exit check

**What this is about**
Phase 4's deliverable (independent wedge HP, 7-of-12 collapse, complete destruction without refunds, core defeat, and persistent ring-integrity information) is complete. The wedge-HP/collapse/destruction/defeat rules were already implemented and exercised in Phase 2/3 gameplay work (T-017/T-018); T-029 just added the remaining piece, the D-024 ring-status HUD, which Kevin accepted this session for the current testing stage. As with D-081, this is a process checkpoint rather than a new creative/scope choice, offered for explicit sign-off rather than assumed.

**Exit check against evidence**
- Six broken wedges do not collapse a ring; the seventh does — covered by existing `test_live_simulation.gd`/`test_live_view.gd` collapse fixtures.
- Unclaimed/collapsed-ring wedges follow the approved rule (occupants and slots cleared, no refund) — same fixtures.
- Every object on a collapsed ring is removed once and movement updates accordingly — same fixtures; also exercised live in T-018/T-022 rendered captures.
- A player can identify a failing bearing while viewing somewhere else — T-029's persistent ring-status HUD, accepted this session.
- Assimilation/retaking/recovery comparisons: out of scope per D-005/D-041 (deferred beyond this slice), so the exit check's conditional "if enabled" clause does not apply.

**The options**
- **Option A:** Accept Phase 4 as complete; proceed to Phase 5 (evaluate the vertical slice) once D-031 (the evaluation plan) is also settled.
- **Option B:** Hold Phase 4 open for further work first.

**What we get**
A moves toward the slice evaluation Kevin ultimately wants; nothing further is scoped for Phase 4 itself. B delays that with no identified remaining Phase 4 work.

**What it costs us**
A carries forward the same accepted HUD/performance limitations already recorded. B spends time without a concrete task to spend it on.

**What happens if we're wrong**
Low cost either way; Phase 4's underlying rules and the HUD remain intact regardless of when the phase is formally closed.

**My recommendation**
Option A. Every exit-check item is met or explicitly accepted, and no Phase 4 task remains open.

**Blocking:** Phase 5 start (jointly with D-031).

**Resolution - 2026-09-07**
Kevin accepted Option A. Phase 4 is complete.

---
### D-084 — Accept the Phase 5 engineering-review evidence
**Date:** 2026-09-07
**Tier:** 1
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** docs/reviews/phase-5-evidence.md; D-031 Option B scope

**What this is about**
Astra assembled the Phase 5 evidence report under Kevin's approved Kevin-only engineering scope (readability at scale, relay-status presentation, wedge scaling math, death-spiral behavior; run sameness out of scope for this pass). The report found the current slice has no recovery mechanic at all — any ring lost is permanent, since D-021/D-022 remain undesigned — and that HUD readability holds at 3 rings but degrades by ring 12, as anticipated. It also reports a real bug found and fixed in T-029 (critical-threshold check compared against a flat HP value instead of each ring's scaled max HP).

**Resolution - 2026-09-07**
Kevin accepted the evidence report ("Phase 5 accepted, continue"). Phase 5 is complete; the vertical slice as scoped by BUILD-PLAN.md's approved phase sequence (Phases 1-5) is now evaluated and accepted. This does not select a final death-spiral answer, final crowd capacity, final art, or any post-slice feature — those remain open under their own decision records (D-019, D-021-D-023, D-026-D-030, D-032-D-035, D-042, and the D-007 capacity follow-up). It clears the way for Kevin to direct what comes next, since the approved plan intentionally stopped at slice evaluation (D-002, D-004).

---
### D-085 - Plan the full game for private testing
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A
**Source:** Kevin's post-Phase-5 audit/planning request; specification sections 1-18

**What this is about**
Kevin authorized review and planning beyond the accepted slice, targeting a fully testable game rather than publishing readiness. T-030 delivered the audit and docs/FULL-GAME-TEST-PLAN.md. The proposed endpoint includes all named gameplay systems, a complete repeatable player session, progression and tutorial with functional placeholders and private test delivery. It excludes publication work and final production assets.

**The options**
- Option A: Approve the proposed Phases 6-13 roadmap and begin Phase 6 through bounded contracts; resolve D-032/D-033 before their dependent implementation. Preserve existing system-specific decisions for later cohesive briefings.
- Option B: Amend the endpoint or priority order before post-slice implementation, identifying which planned system or phase should change.

**What we get**
A provides a complete dependency-led path: reliable sessions, recovery/power, tactical catalogue, full horde, variety, progression, onboarding and integrated evaluation. B lets Kevin choose a different development priority without implicitly removing specified full-game systems.

**What it costs us**
A is substantially more work than another slice increment. It requires design decisions for systems intentionally deferred, and repeated real-game testing. Final art/branding/publication remain outside the work; no calendar estimate or launch content count is promised.

**What happens if we're wrong**
Phase gates allow balance, recovery, power comprehension and run variety to redirect work before committing to a full content build. Architecture remains incremental; prototype evidence is not treated as proof of fun or sufficient full-game performance.

**My recommendation**
Option A. Start with the reproduced HP/HUD gap, reliable baseline and session loop, then establish recovery/power before balancing the full tactical and enemy roster. Discuss doctrine/loadout contracts early to address the highest-priority run-sameness risk.

**Blocking:** New implementation phases, not this completed audit/plan. This approval would not choose still-open mechanics, numbers, final art, participant invitations or publishing actions.

**Resolution - 2026-09-07**
Kevin said: "There is now a full build out plan. Review and then continue with Phase 6." Recorded as approval of Option A: the Phases 6-13 roadmap is approved, and Phase 6 is authorized to begin through bounded contracts. This does not answer D-032 (session/export/persistence scope) or D-033 (tuning authority) — Phase 6 work that doesn't depend on those (the reproduced A1/A4 correctness gap, regression coverage, and reproducibility/runner infrastructure) proceeds now; the private-export and persistence-shaped deliverables wait for those two answers per the plan's own "Decision package first" note.

---
### D-086 — Accept Phase 6 completion
**Date:** 2026-09-07
**Tier:** 1
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** FULL-GAME-TEST-PLAN.md Phase 6 deliverables/exit check

**What this is about**
Phase 6's deliverable list (correct A1/A3, add A4 regressions; a recoverable/tracked source baseline, pinned engine instructions, a one-command correctness runner, opt-in performance commands; session lifecycle — new run, pause/resume, core defeat, result summary, retry; stable content IDs and an authoritative command/tick/commit interface) is complete: T-031 through T-034. D-085/D-032/D-033, the "decision package first" this phase named, are all settled. As with D-081/D-082, this is a process checkpoint offered for explicit sign-off rather than assumed.

**Exit check against evidence**
- All 17 regression suites pass via the new one-command `scripts/run_tests.sh` (10,000+ checks across core/gameplay/presentation).
- Start → play → loss → retry works repeatedly, including mid-run (not only after loss), across three consecutive cycles with no residual walls, machines, or wedge damage carried into the next run (T-033/T-034).
- A clean project copy can reproduce correctness checks: the T-023 baseline digest moved from the gitignored `.godot/` cache to tracked `tests/performance/baselines/`, with provenance and an explicit no-silent-regeneration note (T-032).
- Every error is reported as failure rather than swallowed: `run_tests.sh` timeout-wraps each suite, so a runtime error that aborts a suite before its own `quit()` call (a real, reproduced defect that left three Godot processes hanging for hours this session) now reports as a timed-out FAIL instead of hanging indefinitely.
- Stable content IDs and the authoritative command/tick/commit interface: documented in [docs/contracts/phase-6-command-interface.md](../docs/contracts/phase-6-command-interface.md) as the existing `StringName`-kind convention and `LiveSimulation.step()`'s stage-then-commit pattern, which Phase 7+ systems extend rather than replace. Run/profile/build identifiers are satisfied by the existing per-report documentation convention given D-032's editor-only scope; a recorded command-log/seed scheme is explicitly deferred until external testers or Phase 11 persistence need one.
- Private Windows export: explicitly out of scope per D-032 Option A (editor-only).

**The options**
- **Option A:** Accept Phase 6 as complete; proceed to Phase 7 (expansion, power, genuine recovery) once its rule decisions (D-021, D-022, D-023, a D-027 repair/armor subset) are briefed and answered.
- **Option B:** Hold Phase 6 open for further work first.

**What we get**
A moves toward the systems the Phase 5 evidence report flagged as unresolved (no recovery mechanic exists yet). B delays that with no identified remaining Phase 6 task.

**What it costs us**
A means Phase 7 briefings (recovery/power/assimilation) are now the next real design decisions asked of Kevin — a bigger ask than the process checkpoints so far. B spends more time without a concrete Phase 6 task to spend it on.

**What happens if we're wrong**
Low cost; Phase 6's infrastructure (test runner, baseline tracking, session lifecycle, the command-interface contract) stays useful regardless of when the phase is formally closed.

**My recommendation**
Option A. Every stated deliverable and exit-check item is met; the honest next step is briefing Phase 7's rule decisions, not inventing more Phase 6 work.

**Blocking:** Phase 7 task assignment.

**Resolution - 2026-09-07**
Kevin accepted Option A. Phase 6 is complete. Phase 7 (expansion, power, genuine recovery) is open pending its rule briefing: D-021 (assimilation), D-022 (retake/reclaim), D-023 (relay/power), and a repair/armor subset of D-027.

---
### D-087 — Accept Phase 7 completion
**Date:** 2026-09-07
**Tier:** 1
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** FULL-GAME-TEST-PLAN.md Phase 7 deliverables

**What this is about**
Phase 7's full rule scope, approved earlier this session, is now implemented and tested end-to-end: D-021 assimilation (T-039), D-022 Repair/Reclaim (T-035), the D-027 Armor Plating/Repair Node subset (T-036), and D-023 power (T-037), plus UI wiring for all of the player-facing pieces (T-038, capture accepted). As with D-081/D-082/D-086, this is a process checkpoint, offered for explicit sign-off rather than assumed.

**Exit check against evidence**
- Growing world beyond three rings: not specifically extended this session (the A2 audit gap — playable UI/camera/selection at ring counts beyond 3 — remains open; ring_limit itself was always just a number, and Reclaim/Repair were verified at ring indices up to 3 in tests). This is the one Phase 7 deliverable from the plan's dependency order not addressed.
- Destruction/restoration contract: Repair (single wedge) and Reclaim (whole collapsed ring) both implemented and playable, with a documented 60-second-payback check still pending real measurement.
- Armor and repair: Armor Plating and Repair Node implemented and playable.
- Relay power: fixed per-ring table, placement-time capacity checks, and brownout-driven inert weapons all implemented; independent relay-destruction (separate from full collapse) remains a documented, explicit simplification pending a relay-targeting elite (Phase 9 Sapper).
- Assimilation: destroyed-occupant grants, 5%/stack damage, 15s decay, +50% cap all implemented; no UI needed (passive effect).
- All 18 regression suites pass (2,000+ checks); the T-023 performance baseline was deliberately, verifiably re-recorded after a real (not silent) shape change.

**The options**
- **Option A:** Accept Phase 7 as complete given the above, with the growing-world gap explicitly carried forward (not silently dropped) rather than blocking this checkpoint; proceed to Phase 8 (full tactical catalogue and abilities) once its rules are briefed.
- **Option B:** Hold Phase 7 open until the growing-world gap (or the relay/payback follow-ups) is addressed first.

**What we get**
A keeps momentum toward the tactical catalogue and horde work the plan sequences next. B closes the growing-world gap before it accumulates alongside more systems built on the current three-ring assumption.

**What it costs us**
A means Phase 8's new catalogue items (and Phase 9's enemies) get built and tested at the same three-ring scale Phase 7 was, deferring the large-world question further. B is real, currently-unscoped work (Luna/Sol's presentation and world-sync layer) with no briefing prepared yet.

**What happens if we're wrong**
Low cost either way; nothing here is destructive or hard to revisit. The growing-world gap doesn't get harder to close by waiting, since Phase 7's rule layer is ring-index-generic already (Repair/Reclaim/power all take a `ring` parameter, not a hardcoded 1-3).

**My recommendation**
Option A. The growing-world gap is a presentation/UI-sync task, not a rule gap — nothing in Phase 7's actual rules assumes three rings. Closing Phase 7 on its rule scope and carrying the world-scale gap forward as a named, tracked item (rather than pretending it's done) is more honest than blocking on it now.

**Blocking:** Phase 8 task assignment.

**Resolution - 2026-09-07**
Kevin accepted Option A. Phase 7 is complete. The growing-world gap (playable UI/camera/selection beyond three rings) and the unmeasured D-022 60-second payback check both carry forward as named, open items — not resolved by this acceptance. Phase 8 (full tactical catalogue and abilities) is open pending its rule briefing.

---
### D-094 - Repair of enemy-occupied broken wedges
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - block occupied broken-wedge repair

**What this is about**
The current successful repair can make an enemy's cell intact and cause the next simulation tick to fail. Root reproduced it in .godot/phase8-audit-probe.log.

**The options**
- Block repair of a broken wedge while any living enemy occupies that exact cell; keep repairs of still-intact damaged wedges available.
- Permit restoration and add rules for trapped enemies attacking from inside.

**What we get**
The first choice matches existing expansion/reclaim occupancy restrictions and keeps restoration from invalidating simulation state.

**What it costs us**
Players must clear broken ground before restoring it.

**What happens if we're wrong**
Occupancy policy is localized but affects recovery tactics and would need a new rule review.

**My recommendation**
Block occupied broken-wedge repair.

**Blocking:** Correct repair quote/purchase validation.

**Resolution - 2026-09-07**
Kevin selected the recommended block. T-043 implements consistent quote and purchase checks with no energy spent on rejection. Still-intact damaged wedges remain repairable.

---
### D-095 - Debris support loss and sealed layouts
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - proposed testing package

**What this is about**
D-091 approves indestructible terrain but does not settle supporting-ring collapse or a completely invulnerable sealed perimeter.

**The options**
- Enemy attacks cannot damage debris; supporting-ring collapse removes it with other contents; reject placement that leaves approaching normals with neither reachable exposed surface nor destructible wall target.
- Keep debris permanently through collapse and permit fully sealed layouts, with a separate enemy fallback rule still needed.

**What we get**
The first choice preserves funneling while avoiding invulnerable seals and respects total ring-content loss.

**What it costs us**
Placement must validate routes and can reject a final sealing piece.

**What happens if we're wrong**
This affects terrain layout strategy; changing lifetime or sealed-region policy later requires explicit rule review.

**My recommendation**
Use the first testing package.

**Blocking:** Debris live navigation/placement integration.

**Resolution - 2026-09-07**
Kevin approved the proposed testing package. Debris remains immune to enemy damage and has no individual HP, but is removed with its supporting ring on collapse. Placement cannot leave approaching normals without either an exposed surface or a destructible wall target. No removal tool, new art or terrain tuning value was chosen by this resolution.

### Art reference follow-up - 2026-09-07
Kevin will add four mockups in a repository folder and rank them. He explicitly remains undecided. Record rankings as preferences when supplied; do not treat the highest-ranked mockup as final D-030 approval. Continue functional placeholder work independently.

### D-096 — Overlapping Occlusion Screen shadows
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved

Overlapping shadows use the strongest slowdown once. They affect surface movement only, not attacks, weapon cooldowns or underground burrowing. Kevin approved this recommendation over multiplied slows. Several screens extend coverage without compounding into a freeze; stacking is therefore less powerful. Changing this later requires a gameplay rule review. This clears the shadow-composition blocker for Phase 8.

### D-097 — Solar ability targeting
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved

Focused Flare fires outward from the core along the clicked bearing. EMP Burst affects an area around the clicked world point. Both affect only targetable enemies, preserving underground Tunneler immunity. A valid cast starts its cooldown; cancellation or invalid targeting does not. Ability kills grant no energy, as already approved in D-026. Damage, sizes and timings remain editable testing values under D-033. This gives explicit targeting and cancellation behavior; underground enemies remain unavailable as targets. Changing targeting later requires gameplay and input revisions. Kevin approved the recommended package, clearing the solar targeting blocker.

### Continuation sequencing — 2026-09-07 (Tier 1, Astra)
T-046 extends the existing route field with optional directed costs before Tractor Lane integration. Existing callers remain undirected. This permits a preference toward the chosen adjacent wedge without also discounting reverse travel. The added API is small and reversible; gameplay terrain remains Terra's responsibility.

### D-098 — Playable industrial and painterly art experiments
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved for exploration; final D-030 remains open

Kevin requested one or two rough playable art options, close detail and wide strategic zoom inspired by the feel of Stellaris, and a signature animated central sun with possible red giant, yellow and white options. He selected industrial plus painterly for the first comparison. T-049 uses the four supplied references, an actual live preview scene, procedural detail that simplifies at wide zoom, and slowly swirling sun/corona variants. No external game's assets are used. These are visual experiments, not final style approval or star-type gameplay. The benefit is comparing readability and atmosphere during play; the cost is temporary rendering work that may be discarded. Keeping it in a separate preview makes removal cheap.

### D-099 — Tractor Lane influence area
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved

An intact supporting wedge cannot be entered by approaching normals, so a route bias applied inside it has no effect. Recommend applying the chosen clockwise/counterclockwise bias in the approach band immediately outside it. This changes route preference only, not speed or an enemy's decision to attack on contact. It helps wall detours but is weaker on a completely exposed perimeter. Stronger forced steering is an alternative requiring a new movement/attack rule. Reversal is localized but changes terrain tactics. Kevin approved approach-band steering. T-050 implements it after T-048.

### D-100 — Terrain support and lane composition
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved

Recommended testing package: terrain consumes normal slots; effects stop on broken support, return on repair, and collapse removes contents. Debris protects the outer boundary like an indestructible wall, including when a normal wall is behind it. One Tractor Lane per wedge, selecting clockwise or counterclockwise; a blocked preferred route falls back to ordinary routing. This avoids conflicting lane directions and follows supported-building behavior. It limits stacking and makes support loss disable terrain. Different lifetime/stacking rules would require additional tactical choices and regressions. Kevin approved the entire proposed testing package. T-050 implements it after T-048.

### Terrain safety implementation — 2026-09-07 (Tier 1, Astra)
Apply the approved no-trap route check to all ground-restoration commands when terrain is present, not merely repair of a debris-bearing wedge. Sol identified a case where repairing an adjacent ordinary wedge seals an enemy behind existing debris. This preserves the approved no-invulnerable-seal behavior and prevents a stopped simulation. It adds validation work but is localized and reversible; no cost, damage or new enemy fallback rule is introduced. Shadow motion splits travel at actual cell boundaries, sampling the interval ahead to preserve the approved area effect without changing physical speed outside it.

### D-101 — Review the completed Phase 8 checkpoint
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - Option A

**What this is about**
The tactical catalogue and two solar abilities are playable, the old three-ring view restriction is closed, and the requested industrial/painterly art studies are playable with animated sun variants. Audit fixes and final integration passed all 24 suites. Full briefing: docs/reviews/phase8-effort-briefing.md.

**The options**
- **Option A:** Accept this tested Phase 8 checkpoint with the explicitly retained swarm-performance, relay/brownout and recovery-payback follow-ups; proceed next to a concrete Phase 9 enemy-roster briefing under D-019.
- **Option B:** Hold the checkpoint for specific corrections identified during review/play.

**What we get**
A completes the tactical-tools gate and lets the remaining enemies be designed against real counters. B addresses a concrete playability concern before adding enemy complexity.

**What it costs us**
A carries known performance/recovery/relay work forward; it does not make the game fully testable across all planned systems yet. B delays the enemy handoff until the identified correction is verified.

**What happens if we're wrong**
The checkpoint can be reopened for a reproduced issue. Art experiments remain separate and final D-030 selection is not implied. Balance values remain provisional editable data.

**My recommendation**
Option A after Kevin tries the new controls and art comparison. All requested technical work for this checkpoint is verified; final art, full swarm performance, progression, tutorial and publishing readiness are not claimed.

**Blocking:** Next phase handoff. This is the review point Kevin explicitly requested, not a new safety or publication approval flow.

**Resolution - 2026-09-07**
Kevin accepted Option A after live-testing the checkpoint and raising a round of follow-up items (recorded separately: D-104 relay decoupling, D-105 per-wedge slot capacity, plus starting-energy tuning, a projectile-visual gap, and an art-direction style-guide outline). Phase 8 is closed on its tested scope; the named follow-ups (swarm performance, relay independence/brownout, recovery payback, and this round's items) carry forward, not silently dropped. Astra proceeds to the Phase 9 enemy-roster briefing under D-019.

---
### D-104 — Decouple the relay from wedge-slot occupancy
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved - decouple now; independent killability deferred

**What this is about**
Kevin observed that today's relay occupies one of a wedge's finite weapon slots and can only be lost via full ring collapse (no independent relay-destruction path exists). He wants the relay to float within the ring — not tied to any specific wedge/slot — while remaining something that can eventually be killed independently, at which point it would brown out its ring and everything chained outward. This matches the design spec's own framing (§8: relays are destructible, a "second, invisible perimeter") better than the current slot-attached implementation, and lines up with a Phase 8 follow-up already named in the effort briefing ("independent relay vulnerability/rebuild").

**The options**
- **Option A:** Decouple the relay from wedge-slot occupancy now (every owned, non-collapsed ring simply has a relay; it no longer competes with weapons for a slot or needs a placement click). Leave independent targeting/destruction as a deferred mechanic, most naturally introduced alongside Phase 9's Sapper elite (§10.2: "beelines for relays specifically") since nothing in the game currently has a reason to attack a relay on its own.
- **Option B:** Do both now — also design a generic relay-attack rule before any elite exists to justify it.
- **Option C:** Leave the relay as-is (slot-attached, collapse-only loss) for now.

**What we get**
A removes a real resource-tax on ring-1 (single-slot) wedges immediately and simplifies the ring-purchase flow (no more "click a slot to place the relay" step — buying a ring becomes one action). It sequences the harder half (what attacks a relay, on what timer, with what counter-play) alongside the elite that actually needs it, rather than inventing a mechanic with no user yet.

**What it costs us**
A is still a real cross-cutting change: the relay's ring-record shape, `RingPurchaseRules` (validate_state, create_testing_state, quote/purchase_next_ring, quote/reclaim_ring), `BuildingRules.create_default_testing_state`, and every UI call site that currently passes a relay wedge/slot into ring purchase/reclaim (a scoped audit found roughly 105 call sites across 29 files, including the live/build/art-preview views and the HUD relay marker). This is a delegated implementation task (T-055), not a quick edit — flagged rather than rushed given active parallel work on the same UI files this session.

**What happens if we're wrong**
Reversible in principle (put the slot back), but every call site touched once would need touching again; better to get the shape right before Phase 9 elite work builds on it.

**My recommendation**
Option A, sequenced as T-055 after T-053/T-054 freeze to avoid colliding with the in-flight hotkey/UI work, with actual relay killability designed together with Sapper in the Phase 9 briefing rather than guessed at now.

**Blocking:** Ring-purchase UX simplification; Phase 9's Sapper design (needs a real relay-attack target to exist).

**Resolution - 2026-09-07**
Kevin approved Option A. T-055 is queued (see TASKS.md) for delegated implementation after T-053/T-054 freeze. Independent relay destruction/rebuild stays an explicit open item, to be designed alongside Sapper in the Phase 9 briefing rather than built ahead of any elite that needs it.

**Implementation - 2026-09-07 (T-055)**
Implemented directly (not delegated — T-053's suite was already passing cleanly, so the collision risk that motivated delegation did not materialize). Ring records' `relay` field is now `{"active": true}` (owned, non-collapsed) or `{}` (never owned yet, or collapsed) — no wedge/slot reference. `RingPurchaseRules.quote_next_ring`/`purchase_next_ring`/`quote_reclaim_ring`/`reclaim_ring` all dropped their `relay_wedge`/`relay_slot` parameters; buying or reclaiming a ring is now a single action with no follow-up slot click. `starting_test_setup.relay_wedge`/`relay_count` removed from the schema (vestigial once relay placement stopped being a startup placement entry). UI: `build_view.gd`'s expand/reclaim input branches just confirm a click on the correct ring band; `live_view.gd`/`art_preview.gd` inherit this; `ring_status_hud.gd`'s relay marker is now a single ring-level indicator (drawn at a fixed reference angle) rather than a per-wedge mark, since there is no wedge to point at. Updated roughly 40 call sites across `ring_purchase_rules.gd`, `building_rules.gd`, `live_simulation.gd`, `build_view.gd`, `live_view.gd`, `ring_status_hud.gd`, and ~15 test files (mechanical argument removal plus relay-shape assertion updates). Full 25-suite run passes; T-023 baseline re-recorded (see `tests/performance/baselines/README.md`).

---
### D-105 — Per-wedge weapon capacity vs. a core-facing coverage gap
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A

**What this is about**
Kevin noticed no weapon can kill a machine that breaches into the core interior when every ring-1 wedge is filled with cheap Flak (Flak's arc is a 90-degree outward cone; it physically cannot point back at the core). Mass Driver already fires 360 degrees and could reach a core-breaching machine, but it is slow (one target every 2 seconds) and expensive, so an all-Flak ring-1 (which the just-approved 200-energy starting grant specifically enables) has zero core-facing coverage. Kevin's first proposal was to make Flak itself rotate 360 degrees at a shorter range (2.0 to 1.1 ring-widths); on reflection he asked to instead reconsider whether wedges should support more than one weapon at once, for deliberate multi-modal coverage, rather than reworking Flak's own targeting shape.

**What's already true and may not be obvious**
Multi-slot wedges already exist as a mechanic: `scaling.slots_per_wedge_per_ring` (currently 1) is multiplied by the ring index, so ring 2 wedges already have 2 slots, ring 3 have 3, and so on — outer rings are already "spacious" in this sense (§6's stated inner/outer tradeoff). Ring 1 is deliberately the tightest (1 slot per wedge), which is exactly why an all-Flak ring-1 loadout has no room to also place a Point Defense or Mass Driver on the same tile for mixed coverage.

**The options**
- **Option A:** Raise `scaling.slots_per_wedge_per_ring` from 1 to 2 (a first-pass numeric value under D-033, since the multi-slot mechanic itself is already approved and built — this only retunes its density). Combined with D-104's relay decoupling, every ring-1 wedge would then have 2 free weapon slots, letting a player deliberately pair an outward-facing weapon (Flak) with a core-facing or specialist one (Point Defense, whose exact-cell targeting already covers the core-breach case) on the same tile. No change to any weapon's targeting logic at all.
- **Option B:** Keep 1 slot per wedge on ring 1, and instead give one specific existing or new item genuine omnidirectional short-range coverage (Kevin's original Flak proposal, or a cheap dedicated "core coverage" item) — accepting the role-overlap with Point Defense/Mass Driver that comes with it.
- **Option C:** Both — raise slot density a smaller amount (not necessarily to full parity with Option A) and still adjust Flak somewhat.

**What we get**
A solves the coverage gap without touching any weapon's balance or identity — it's purely a capacity/economy change, and it's already the mechanism outer rings use. B keeps ring-1 tight and interesting (forces a real choice: wide-arc Flak or core coverage, not both) but blurs Flak/Point Defense's distinct roles from the spec's own catalogue table (§9.1). C hedges but is the least clean single design statement.

**What it costs us**
A roughly doubles ring-1's weapon-and-power economy (twice the slots to fill and power to budget for) — a real balance shift needing its own pass, not just a UI/rule tweak. B keeps the balance surface smaller but reopens the specific overlap concern D-090 tried to avoid (Point Defense as a distinct specialist, not "a worse Flak").

**What happens if we're wrong**
Both are numeric/rule-shape changes that are reversible without touching the underlying occupant-kind architecture; A is the lower-risk direction since it changes a number, not a targeting rule.

**My recommendation**
Option A. It reuses a mechanism the game already has rather than inventing a new targeting shape for one weapon, and it directly addresses the specific failure mode Kevin hit (an all-Flak ring-1 with the new 200-energy grant) without touching Flak/Mass Driver/Point Defense's established roles. Recommend pairing it with D-104's relay decoupling so the freed slot and the new slot both land together, and re-examining the exact slot count (2 vs. more) once Kevin has actually played a multi-slot ring 1.

**Blocking:** T-055 scope (whether it includes the slot-density change alongside relay decoupling).

**Resolution - 2026-09-07**
Kevin approved proceeding ("yes, go ahead") without specifying a different number, so T-055 implemented Option A at the proposed default: `scaling.slots_per_wedge_per_ring` 1→2. Every ring-1 wedge now has 2 slots; combined with D-104's relay decoupling, the starter ring has 2 slots on every one of its 12 wedges (23 free after the pre-placed starter Flak) rather than the 10 free single slots the 200-energy grant was originally sized against. This numeric interaction (energy vs. new slot capacity) is flagged as a fresh, unreviewed balance question — Kevin's own play is the way to judge whether 200 energy / 2 slots feels right, per D-033. Not yet re-tuned pending that feedback.

---
### D-106 — Foundry elite rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §10.2

**What this is about**
"Armored, enormous HP. Parks on a wedge and grinds it down. Counter: Mass drivers, focused fire." Of the four remaining elites, this is the one with no special movement or targeting behavior implied by its own description — it reads as a standard machine with very different stats, not a new mechanic.

**The options**
- **Option A:** Implement Foundry as a scheduled-arrival variant of the standard machine (its own `foundry.first_arrival_seconds`/`arrival_interval_seconds`, mirroring Tunneler's admission pattern), with much higher HP, higher damage, and lower speed than a standard machine, using the existing `_advance_machine` movement/funneling/attack code path completely unchanged. No new engine mechanic at all — just a new spawn-descriptor source and a new occupant-agnostic "kind" tag for rendering/identification.
- **Option B:** Give Foundry a genuine behavior difference beyond stats — e.g., once it starts attacking a wedge, it cannot be redirected by newly-opened detour routes (breaking the "always reroute toward the newest opening" rule from D-066-068) so it truly "parks," even if a gap opens elsewhere.

**What we get**
A is the cheapest to build and test (reuses everything Tunneler already proved out for scheduled-elite admission, zero new movement logic) and matches the spec's own wording, which gives Foundry no special verb the other four elites don't already have ("parks" reads as a consequence of being slow and tanky, not a distinct rule). B adds a genuine "commitment" mechanic that makes Foundry feel meaningfully different from a big standard machine, at the cost of a new pathing exception.

**What it costs us**
A risks Foundry feeling like "a standard machine with a stat multiplier" rather than a distinct threat with its own counter-play texture. B requires new state (has this machine ever started attacking a wedge, and does that lock its target) and a new interaction with the existing reroute-on-wall-break logic.

**What happens if we're wrong**
Low — Option A is trivially extended to B later (add a "committed" flag) without redoing the admission/stats work.

**My recommendation**
Option A first. "Mass drivers, focused fire" as its stated counter already implies the answer is "bring enough single-target DPS," which a stat-only implementation delivers; a parking/commitment mechanic can be added later as a numeric-adjacent follow-up if playtesting shows it doesn't feel distinct enough from a tanky standard machine.

**Blocking:** Phase 9 elite work; simplest item, good first implementation.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended, as part of the bundled Phase 9 briefing. Numeric values (HP multiplier, damage, speed, arrival cadence) are first-pass under D-033, tuned later by Kevin's own play.

---
### D-107 — Transfer elite rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §10.2

**What this is about**
"Executes an orbital hop, skipping one ring outright. Counter: Interception, defense in depth." This needs a concrete rule for when the hop happens and how many times, since "interception" as a stated counter only makes sense if the hop is limited/predictable rather than something Transfer can do at every ring it meets.

**The options**
- **Option A:** Transfer paths inward as a standard machine. The first time it reaches an intact ring's boundary, it performs a single hop directly to the boundary of the ring immediately behind it — skipping that one ring's wedge/wall entirely, dealing no damage to it and taking none in return — then behaves as an entirely standard machine for the rest of its life (normal pathing, normal wall/wedge interaction) with its hop already spent. It can never hop again.
- **Option B:** Transfer can hop at any ring boundary it reaches, every time, effectively ignoring every ring's defenses the way a Tunneler does but without needing to burrow first.
- **Option C:** The hop is not automatic on contact — it triggers on a timer/cooldown independent of position, so a Transfer might hop mid-corridor between rings rather than exactly at a boundary.

**What we get**
A matches "skipping one ring" literally (singular) and keeps "defense in depth" meaningful — the ring behind the one it skips still stops it normally. B would make Transfer as dangerous as Tunneler with less counter-play, contradicting the spec's distinct counters for the two elites. C adds unpredictability at the cost of a much fiddlier implementation (timers unrelated to position) for a benefit hard to distinguish from A in practice.

**What it costs us**
A means Transfer is only unusual once per lifetime — after its hop, it's mechanically a standard machine, so its distinct identity is entirely front-loaded into a single moment. This is a deliberate, bounded scope, not an oversight.

**What happens if we're wrong**
Extending A to allow multiple hops later (e.g., one hop per N seconds) is a small, additive change; walking back from B or C to A is more disruptive since it changes the fundamental threat model players would have adapted to.

**My recommendation**
Option A. It's the literal reading of the spec text, keeps Transfer meaningfully weaker than Tunneler (which truly ignores all walls for its whole burrow), and "interception" as a counter only makes sense if there's a specific, single moment (the hop) worth intercepting.

**Blocking:** Phase 9 elite work.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: exactly one hop, at the first intact ring boundary Transfer reaches, then it behaves as a standard machine for the rest of its life. Numeric values (hop trigger range if any, stats) are first-pass under D-033.

---
### D-108 — Sapper elite rule shape and relay damage
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A + C
**Source:** §§8, 10.2; D-104

**What this is about**
"Beelines for relays specifically. Counter: Relay placement, point defense." This is the elite that finally needs the relay to be a real, independently-attackable thing — the one gap D-104 explicitly deferred ("independent relay targeting/destruction... most naturally introduced alongside Phase 9's Sapper elite"). Two things need concrete rules: what does Sapper actually attack now that the relay has no wedge position (D-104 made it float, not slot-attached), and what happens when it succeeds.

**The options for what Sapper attacks**
- **Option A:** Give every ring a new `relay_hp`/`relay_max_hp` pool, separate from any wedge's HP. Sapper paths and interacts with walls/wedges exactly like a standard machine (funneling, wall detours, and wall-breaking on a sealed ring all apply to it unchanged) — the only difference is that once it is in attack contact with any wedge of its target ring, its damage applies to that ring's `relay_hp` instead of the wedge's HP. Reaching zero relay HP browns out the ring (see below) but does not touch wedge HP or occupants.
- **Option B:** Sapper ignores walls/funneling entirely (like Tunneler) and beelines directly to a fixed reference point on its target ring, attacking `relay_hp` once there, bypassing wall/wedge defense entirely.

**What we get**
A keeps "wall redundancy" and ordinary structural defense meaningful against Sapper (the counters the spec lists — "relay placement, point defense" — read as *positioning/response* counters, not "walls don't matter"), and reuses all existing movement code, needing only a new attack-target branch. B makes Sapper as unstoppable as Tunneler via a completely different route, which risks making relays feel unfairly fragile since nothing but Point Defense can ever react to it.

**What it costs us**
A means "relay placement" (one of the spec's own stated counters) has less meaning post-D-104, since the relay is a ring-wide target now, not a specific wedge the player chose — Sapper can attack the relay from wherever it happens to breach. This is a direct, known side effect of D-104's decoupling, flagged here explicitly rather than glossed over.

**The options for relay loss consequence**
- **Option C (paired with A):** Relay HP reaching zero browns out the ring (10% power, per D-023's existing `power.brownout_fraction`) without collapsing it — wedges, walls, and weapons on that ring remain intact and present, just unpowered. A new purchase, **Rebuild Relay**, restores `relay_hp` to full for an energy cost, giving the "rebuild" half of the follow-up its own concrete answer.
- **Option D:** Relay loss instead triggers full ring collapse, reusing the existing collapse/reclaim machinery rather than adding a new partial-loss state.

**What we get**
C creates a real, distinct middle failure state between "fine" and "collapsed," matching the spec's framing of the relay as "a second, invisible perimeter" — losing it is bad (brownout) but not run-ending the way collapse is, and rebuilding it is a meaningful, immediate response rather than the much larger Reclaim purchase. D is simpler (one failure state, already fully built) but makes relay loss just a second way to trigger the exact same outcome as losing 7 wedges, which undersells it as its own threat.

**What it costs us**
C is new state and a new purchase (`relay_hp` field, `Rebuild Relay` cost/rule, HUD indication of brownout) — real but bounded scope. D is nearly free to build (reuses collapse) but D-023's `brownout_fraction` balance value would stay permanently unused/dead code, and the relay's own HP pool would need to actually just be "collapse the ring" in disguise.

**My recommendation**
Option A for targeting (preserves wall/funneling relevance against Sapper) and Option C for the consequence (brownout + Rebuild Relay gives D-023's already-built brownout math a real trigger, and gives relay loss its own distinct, recoverable identity rather than reusing collapse). Numeric values (relay HP, Sapper stats, Rebuild Relay cost) are first-pass under D-033.

**Blocking:** Phase 9 elite work; the single largest remaining engine addition of the four elites.

**Resolution - 2026-09-07**
Kevin approved Option A (relay-hp attack target, normal wall/funneling behavior otherwise) and Option C (brownout + a new Rebuild Relay purchase, not full collapse) as recommended. This resolves D-104's deferred "independent relay targeting/destruction" follow-up. Relay HP, Sapper stats, and Rebuild Relay cost are first-pass under D-033.

---
### D-109 — Breacher elite rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A
**Source:** §§9.2, 10.2; D-066-068

**What this is about**
"Smashes deflector walls rather than pathing around them. Counter: Wall redundancy, area denial." Today's wall rule (D-066-068) is the opposite: a standard machine always detours around a wall to any reachable open surface, and only attacks a wall at a reduced (25%) rate when the ring is fully sealed with no detour available. Breacher needs to invert this specifically for itself.

**The options**
- **Option A:** Breacher's routing always prefers the nearest wall-bearing cell over any open detour, even when one exists — it treats a wall as its objective rather than an obstacle. Once in contact, it damages the wall at full rate (no 25% sealed-only penalty, since smashing walls is its entire purpose, not a fallback).
- **Option B:** Same routing override, but keep the 25% multiplier (walls are still meaningfully tougher against it than raw HP would suggest, just always accessible rather than only when sealed).
- **Option C:** Do not change routing at all; instead, only remove the "sealed-only" restriction — Breacher can choose to attack any wall it's adjacent to on its normal route, at the existing 25% rate, without requiring a fully sealed ring.

**What we get**
A makes Breacher a genuine, distinct threat to any wall anywhere (matching "smashes walls rather than pathing around them" literally) and gives "wall redundancy" real teeth as a counter (one wall isn't enough; several in depth are needed). B keeps some of the wall's toughness relevant. C is the cheapest to build (no new routing logic, just a conditional bypass on the existing sealed-check) but is a much smaller behavior change than the spec text implies — it still mostly paths around walls unless one happens to be directly in its way.

**What it costs us**
A and B both need a genuinely new per-machine routing preference (today's `WallNavigation`/route field is shared and funnels every standard machine identically; Breacher needs its own "shortest path to nearest wall, ignoring detour cost" query) — comparable in scope to Tunneler's dedicated path, though simpler since it stays on the surface. C needs no new routing at all, at the cost of a much weaker match to the spec's description.

**What happens if we're wrong**
A/B are reversible to C by disabling the routing override without discarding it; going from C up to A/B later means building the routing work anyway, just after already shipping something that undersells the elite.

**My recommendation**
Option A. "Smashes rather than pathing around" is specific, deliberate spec language contrasting Breacher directly with standard-machine behavior; a version that still mostly detours (Option C) doesn't deliver that contrast. Full damage (not the 25% sealed rate, which exists to make wall-breaking a last resort for ordinary machines) reflects that wall-breaking is Breacher's actual specialty, not an emergency fallback.

**Blocking:** Phase 9 elite work; needs new per-machine routing, similar magnitude to Tunneler.

**Resolution - 2026-09-07**
Kevin approved Option A as recommended: Breacher's routing always prefers the nearest wall over any detour, and deals full (unpenalized) damage to it. Numeric values (damage, speed, HP) are first-pass under D-033.

---
### D-110 — Assembler boss rule shape
**Date:** 2026-09-07
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved - Option A + C
**Source:** §10.3

**What this is about**
"Large, slow, ignores walls, and grows measurably stronger as it consumes structure. An Assembler that gets into a built-up ring becomes a run-ending problem." This is a boss, not a regular elite — it needs an interval-based spawn (not a continuous arrival stream) and a concrete rule for "grows stronger as it consumes structure."

**The options for spawn cadence**
- **Option A:** A dedicated `assembler.first_arrival_seconds`/`interval_seconds` schedule (same shape as Tunneler/Foundry's admission), producing one Assembler per interval regardless of run state — "punctuates the continuous ramp at intervals" reads as a fixed cadence, not a reactive/scaling trigger.
- **Option B:** Cadence scales with elapsed time or ring count (Assemblers arrive more often the longer/bigger the run gets), layering onto the existing `pressure.stat_increase_per_minute` escalation.

**What we get**
A is simple, predictable, and easy to balance/test in isolation. B ties boss frequency to run progress, which could feel more dramatic but compounds with the existing escalation curve in ways that are harder to reason about without dedicated tuning passes.

**What it costs us**
A may feel same-paced late in a run when the player is much stronger; B risks boss-fatigue (too frequent) or spike difficulty if it compounds badly with `stat_increase_per_minute`.

**What options for "grows stronger as it consumes structure"**
- **Option C:** Every wedge, wall, or occupant the Assembler personally destroys grants it a permanent stat buff for the rest of its own lifetime only (damage and/or HP), similar in spirit to D-021 assimilation but scoped to this one machine rather than the whole active swarm, and not decaying (a boss fight is meant to escalate, not recover).
- **Option D:** Reuse D-021 assimilation directly — the Assembler benefits from the same global stacking buff every machine gets from any destruction anywhere, with no Assembler-specific bonus.

**What we get**
C makes the "grows stronger as it consumes structure" language literal and personal to the Assembler (it specifically gets scarier the longer it's allowed to grind), which is what makes it "a run-ending problem" if left unchecked — matching the spec's own warning. D is simpler (zero new code, it already happens) but is indistinguishable from any other machine's assimilation benefit, undermining the boss's stated identity.

**What it costs us**
C needs new per-machine stacking state independent of D-021's existing global mechanism (a second, similar-but-distinct system) and a decision on whether its bonus decays (recommend: no, unlike D-021 — a boss fight should not offer a "wait it out" strategy the way ordinary assimilation does for the general swarm).

**What happens if we're wrong**
Numeric tuning (how much per kill, cap if any) is adjustable under D-033 regardless of which option is chosen; C vs. D is a real identity choice for the boss and not cheaply reversible once players have formed expectations.

**My recommendation**
Option A for cadence (simplest, matches the literal "punctuates... at intervals" wording) and Option C for growth (gives the Assembler its own escalating identity, matching "an Assembler that gets into a built-up ring becomes a run-ending problem" — that warning only makes sense if leaving it alone specifically makes *it* more dangerous, not just the swarm generally). "Ignores walls" reuses Tunneler-style wall-immunity (walk through/past walls without needing to burrow) rather than Breacher's smash-them mechanic, since the spec lists it as a separate trait from Breacher's.

**Blocking:** Phase 9 boss work; recommend building last, after all four elites, since it's the largest single item and its "grows stronger" mechanic benefits from the same status-effect/stacking patterns the elites establish.

**Resolution - 2026-09-07**
Kevin approved Option A (fixed-interval spawn) and Option C (own permanent, non-decaying per-kill growth, separate from D-021 assimilation) as recommended. Numeric values (interval, growth per destruction, any cap) are first-pass under D-033.



## Delegated continuation — 2026-09-08

These entries implement Kevin's explicit request: continue to feature complete, decide independently excluding art, and identify choices for later confirmation. They supersede historical pending gates only within that authorized scope. Detailed costs/values: docs/contracts/feature-completion-2026-09-08.md. Review table: docs/reviews/delegated-decisions-2026-09-08.md.

### D-111 — Authority through feature completion
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Kevin
**Status:** Approved scope and delegation

Kevin authorizes Phases10-13 and necessary audit corrections without further non-art approval stops. Art assets/final animation remain excluded. Original specification stays untouched. The benefit is completing the actual game loop; the cost is reviewing delegated choices afterward. Decisions remain data/configuration where possible for affordable revision.

### D-112 — Initial complete variety roster
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Astra under D-111
**Status:** Decided provisionally; later Kevin confirmation
**Source:** §§7,14; D-029

Use three contrasting doctrines from the spec examples, three starting loadouts and three stackable mutators. Exact modifiers/access are in the shared contract. This provides functional variety without a large untested roster. It may not be sufficient variety for release; adjusting modifiers is cheap, restructuring purchased unlocks needs migration.

### D-113 — Capped progression and reward policy
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Astra under D-111
**Status:** Decided provisionally; later Kevin confirmation
**Source:** §14; D-028

Use finite tool/loadout unlocks, three capped stat tracks and rewards for survival, all kills, expansion and three per-run challenges. Abandoned/error/practice runs earn zero. Reward details and costs are editable campaign data. This completes earn/spend/relaunch; balance and grind remain playtest questions. Changes to saved purchases require explicit migration rather than silent loss.

### D-114 — Funded opening and replayable tutorial
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Astra under D-111
**Status:** Decided provisionally; later Kevin confirmation
**Source:** §§6,7,12; D-042

Retain ring1, starter weapon and funded opening. Provide isolated guided practice with explicit teaching fixtures, no campaign rewards, replay and full reference. This avoids a clean-slate income deadlock and makes recovery learnable. Final pacing/instruction order remain reviewable; tutorial fixtures must never enter a normal run.

### D-115 — Industrial UI and widescreen execution
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Kevin (direction), Luna/Astra (implementation within brief)
**Status:** Direction approved; implementation for visual review

Use the authorized gritty industrial sci-fi direction with legible transport-style typography, compact instrument panels and non-color-only status cues. Base1440x810, minimum1280x720 and1920x1080 support; preserve16:9 at other window shapes. Details in T-064 plan; final game art remains undecided. Font licensing and native-size captures are required. Styling can be revised through shared theme resources.

### D-116 — Persistence and private candidate boundary
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Astra under D-111
**Status:** Decided provisionally; later Kevin confirmation
**Source:** §14; D-032

Persist settings/progression and exactly-once reward receipts, with backup recovery. No mid-run save/resume; a crash before durable result settlement abandons that run. Prepare a local Windows executable when installed matching tools permit, without publishing/distribution. This makes multi-run testing independent of the editor while keeping save scope bounded. Later resume requires a separate simulation schema.

### D-117 — Phase9 audit edge-case rules
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Astra under D-111
**Status:** Decided provisionally; later Kevin confirmation
**Source:** §10; D-107,D-110

Transfer gets a private finite-speed path along the skipped ring's inner boundary after its one hop, respecting inner walls/debris; sealed targetless interiors wait for a path. Other machines cannot use this corridor. Preserve current Assembler final-wedge-plus-destroyed-contents collapse growth attribution and reject overflow atomically. This closes rule bypasses without adding hop depth. Shared corridor caching and mixed tests must verify scale/correctness; waiting behavior is a later gameplay review.
### D-120 — Final art direction
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §15; resolves D-030; supersedes D-098's exploratory toggle

**What this is about**
D-030 left final art direction open with four candidates (schematic, industrial, painterly, CRT). D-098 authorized T-049 to build two of them playably for comparison. Kevin's direction was "a combination of industrial-gritty and painterly-awe," which needed turning into concrete, buildable rules — including the value structure the two references actually disagree on.

**Resolution - 2026-09-08**
Worked through in a structured Q&A pass. Full detail in `docs/art-direction-style-guide.md`; production method in `docs/art-asset-pipeline.md`. The decided direction:

**Identity:** *Lit industrial hardware, painterly light, mostly void.* Structure is the lit figure; space is near-black ground (the industrial reference's value relationship, not the painterly one's — never inverted). The painterly half is delivered as light and atmosphere, not as painted surfaces.

**Rings:** thin structural bands at each ring's outer radius, with radial truss spokes on wedge boundary lines, shared between adjacent wedges. Most of the annulus is open void — that is where turrets project and machines travel. This replaces T-049's wide opaque plates, which are the direct cause of its flat grey strategic view. Turrets mount on the band facing outward. A destroyed wedge's band segment disappears (reappears on repair); a shared spoke is lost only when both adjacent wedges are destroyed. Ring index carries a material/temperature gradient (inner hot/scorched → outer cold/pale). Battle damage persists through repair as patch welds.

**Damage read:** local working lights fail progressively (steady → flicker/amber → dark) as wedge HP falls; exact values come from the Alt overlay (D-122), not the world.

**Star:** one canonical star per run whose corona is a live status display (power draw, brownout, solar cast), drawn from a pool of skins (red giant/yellow/white and variations) randomized on a fresh run and persistent within a continuous run. Consequence: no other colour may depend on a particular star skin. Star dominance shrinks as the player expands outward.

**Void:** corona bleeds outward through the gaps and tapers into a mostly dark starfield.

**Buildings:** one shared generated mount reused under all thirteen buildings; identity lives in distinct heads that telegraph mechanism.

**Horde:** purpose-built harvester-drone species, deliberately simplified (a swarm at heart). Emissive is rank, and cold: standard machines are pure dark silhouettes, elites and the Assembler carry cold cyan/white accents. Elite silhouettes telegraph their mechanic. Scale follows the *They Are Billions* model — an indistinguishable mass at strategic zoom, individuals when zoomed in.

**Colour:** warm belongs to the star and the player; cold belongs to the horde; terrain is desaturated neutral; amber warns, red is critical.

**Lighting:** star key on inward faces, local industrial lamps on outward faces (which is also what makes the damage read free).

**VFX:** distinct per-weapon firing language, drawn procedurally at no image cost — this also settles the approach for the queued T-056. Machine kills are deliberately restrained; wedge and ring loss are loud.

**Terrain:** physical by default, exact zones on the Alt overlay.

**Production:** ~35–45 AI-generated source images, processed to game-ready, with four mandatory consistency mechanisms (style anchor first, fixed prompt templates, post-process normalisation, in-game review gate).

**What this does NOT settle:** final branding/title (D-034), audio, world assets beyond this first pass, and numeric tuning of tier boundaries/salvage/light thresholds (first-pass under D-033).

---
### D-121 — Wedge destruction destroys its occupants, with salvage refund
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§11-12; raised by the D-120 art pass

**What this is about**
Weapons on a destroyed wedge currently keep firing at full effect — `WeaponRules._step_owned` never checks wedge HP, and occupants are only cleared on full ring collapse. The art pass surfaced this: if a destroyed wedge's band segment disappears, its turrets would be left firing over open space. That is a depiction problem, but the underlying rule was never deliberately decided.

**The options**
- **Option A:** Keep the rule; depict turrets clinging to surviving spokes.
- **Option B:** Destroying a wedge destroys everything on it, no refund.
- **Option C:** Destroying a wedge destroys everything on it, with a partial salvage refund.
- **Option D:** Weapons die, passive structures and terrain survive.

**Resolution - 2026-09-08**
Kevin approved **Option C**. A destroyed wedge loses *all* occupants — the five weapon types, Armor Plating, Repair Nodes, and the three terrain items — and returns a fraction of the energy spent on them as salvage.

**What this changes:** a breach now compounds rather than merely opening a hole, making defence in depth substantially more valuable and repair more urgent. The salvage refund keeps it recoverable and hands the player funds exactly when they need to rebuild. The salvage fraction is a new first-pass tuning value under D-033, adjusted by Kevin's play.

**Blocking:** implementation and a balance retune pass; the art direction assumes it (no floating hardware to depict).

---
### D-122 — Alt-held tactical overlay
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§8-9; D-115, D-119; raised by the D-120 art pass

**What this is about**
Several rules are invisible in the world: continuous wedge HP, terrain effect zones and their exact edges, tractor lane direction, weapon range. The art direction commits to a clean, physical battlefield, which makes "always-on markings" the wrong answer — and T-071 had just finished removing clutter from that same screen space.

**Resolution - 2026-09-08**
Kevin requested wedge HP bars on a held Alt key; this is adopted as the general pattern. **Holding Alt reveals one tactical layer** carrying every rule the world hides — wedge HP bars, terrain effect zones with exact edges, tractor direction arrows, and weapon range arcs. Normal play stays clean and physical; all hidden numbers are one key away, learned once.

This is the standing pattern going forward: any future invisible rule belongs on the Alt layer rather than becoming permanent world clutter. Complements D-115's UI skin and D-119's strategic-zoom marker suppression rather than replacing either.

**Blocking:** new presentation/input work (does not exist yet); terrain zone legibility in the art guide assumes it.

### D-123 — Camera tilt: 20 degrees from vertical
**Date:** 2026-09-08
**Tier:** 2
**Decided by:** Kevin
**Status:** 🟢 Approved
**Source:** §§1, 15; refines D-008; affects D-120

**What this is about**
The view has been true top-down (straight down the star's pole) since D-008. Kevin asked to tilt it slightly toward isometric while keeping orientation fixed (no map rotation), and asked for honest feedback on the idea.

**The analysis**
Implementation is cheap: picking already routes through `get_canvas_transform().affine_inverse()`, so applying the tilt as a Y-scale on the world transform makes rendering, input, ability aiming and slot selection all transform consistently with no math changes.

The honest caveat is what the angle actually buys. Ground-plane foreshortening is `cos(tilt)` and visible object height is `sin(tilt)` per unit:

| Tilt from vertical | Ground squash | Height visible | Sprite-rotation error |
|---|---|---|---|
| 15° | 3.4% | 0.26× | negligible |
| 20° | 6.0% | 0.34× | small |
| 30° | 13.4% | 0.50× | noticeable |
| 45° | 29.3% | 0.71× | severe |

At 15-20° the ground plane barely changes — a 3-6% ellipse is imperceptible. Essentially all of the effect comes from objects having visible height, which makes this fundamentally an art change that the camera tilt makes *honest*: faked height in a true top-down view points one way on screen and therefore fights the requirement that sprites rotate to face outward at twelve different bearings.

The cost is that a tilt breaks radial symmetry. In true top-down, one sprite rotated twelve ways is exactly correct; with tilt it becomes an approximation whose error grows with angle. Keeping the angle small is precisely what keeps one-sprite-per-building affordable, protects unbounded-zoom ring readability, and preserves the near-circular mandala silhouette that is the game's signature image.

**Resolution - 2026-09-08**
**Tilt is 20° from vertical**, orientation stays fixed (no rotation), and the polar grid, coordinates and rules are all unchanged. Compatible with the spec's "2.5D view from above the star's pole" and with D-008's fixed north-up requirement — this refines the projection rather than contradicting it.

- **Buildings use one sprite each, rotated** — the small lean error at 20° is accepted, keeping the D-120 asset budget intact. If it reads badly in engine, the fix is to reduce the angle, not to add art; T-078's review gate catches it on the very first weapon head.
- **Ring bands and spokes get real depth** — beams and girders with visible side faces, not flat lines. Procedural geometry, so no image cost, and it is where most of the industrial weight comes from. Thickness also gives the damage read somewhere to live: buckling and shearing become visible in profile.

**Implementation notes that follow from the tilt:**
- The squash applies to the **ground plane only**. The star is a sphere and spheres project as circles from any angle; squashing it globally would make it subtly and incorrectly elliptical. Same for the corona.
- Draw order becomes painter's algorithm by screen Y so height overlaps resolve correctly.
- Sprites anchor at their **ground point**, so a building's footprint sits on its true slot position and clicking still matches what the player sees.
- World-space text — building labels and the D-122 Alt HP bars — must not inherit the squash or the height offset.
- **Generation specs split by asset type:** flat surface art (band strips, decals, damage) is still generated *flat top-down* because the engine applies the foreshortening; objects (building mount, heads, machines, elites, Assembler) are generated *at 20° from vertical* to match the camera.

**Timing:** raised before T-078 generates anything, so the change costs nothing. After ~40 images existed it would have cost the entire art budget.

**Blocking:** T-074 (ring geometry gains depth), T-080 (camera tilt), and the D-120 pipeline's generation specs.
