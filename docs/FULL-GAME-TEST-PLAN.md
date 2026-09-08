Complete-candidate update, 2026-09-08: all named gameplay/application features are implemented; final39-suite aggregate and private packaged lifecycle pass. Human pacing/variety/recovery evaluation, real-time large-swarm capacity, physical desktop input and clean-machine portability remain explicit reviews. This is feature implementation completion, not full acceptance of every historical Phase13 evaluation criterion. See reviews/feature-completion-briefing-2026-09-08.md.


> 2026-09-08 update: Kevin authorizes completing this roadmap and delegates non-art decisions for later confirmation. Historical permission gates below are superseded by D-111 through D-117 and docs/contracts/feature-completion-2026-09-08.md. The human evaluation matrix remains a later review; automated feature completion must not be described as Kevin's playtest acceptance.
# RING ZERO: from accepted slice to fully testable game

2026-09-07. Plan prepared by Astra and approved through D-085. Phases 1-7 are accepted, with explicit D-086/D-087 exceptions. Phase 8 is implemented and verified, awaiting Kevin review under D-101; all 24 suites pass after source freeze. The current session is editor-only under D-032; command recording, independent relay damage/rebuild and recovery-payback verification remain named follow-ups. T-047 now verifies playable expansion through ring 12, closing the three-ring view restriction. The future phase descriptions below remain integration targets, not claims of completed work. BUILD-PLAN.md and TASKS.md carry current assignments.

## The destination

**A private, gameplay-complete test build:** Kevin can launch it without the editor, learn the controls, choose a loadout/doctrine, play an evolving run, expand beyond three rings, use the full named tactical catalogue and enemy roster, survive and recover from setbacks, lose, receive persistent progression, and start another meaningfully different run. Runs target the spec's 15-25-minute experience without imposing a timed victory on an endless game. Testers can report a reproducible problem with build/profile/run identifiers.

Planning assumption: “fully testable game” includes every named gameplay system in the specification, using approved functional placeholders. It does not mean only extending the existing slice. Counts of doctrines, upgrades and mutators below are **proposed test coverage**, not launch promises or already-approved content. Kevin can amend this scope before implementation.

Not required for this endpoint: final art direction, final title/branding, production audio, store pages, achievements/platform services, installers/signing, localization completeness, marketing, monetization, public servers, publishing or broad compatibility certification. Functional feedback and usable controls still matter. A private Windows export is proposed because that is the current development platform; this requires D-032 confirmation. No deployment, distribution or invitation is implied.

## Working rules

1. Preserve the polar coordinate and shared-route foundations. Extend the existing transaction/commit boundaries; no engine rewrite is justified by this audit.
2. Keep every economy, health, damage, timing, growth and power value in versioned balance data. Keep old accepted testing profiles identifiable; do not silently turn provisional numbers into final rules.
3. Bring Kevin **one cohesive system briefing** before each design gate: behavior, exact provisional parameter sheet, interactions, alternatives, recommendation and what it blocks. D-033 can instead grant explicitly bounded tuning authority. It is not granted today.
4. Assign concrete task IDs only when a phase is authorized and a bounded contract is ready. Sol owns engine, persistence and performance; Terra owns game rules/data; Luna owns presentation/input; Astra owns contracts, review and integration.
5. Each system includes its UI, feedback and integration checks before human review. Pure helpers alone are not a completed playable feature.
6. Repeat full-run and performance checks at meaningful integration gates. Keep correctness, simulation timing and rendered timing separate; retain failed evidence honestly. No cap reductions, dropped ticks or skipped actors to manufacture a pass.

## Phase overview and dependencies

| Phase | Playable outcome | Prerequisites / decisions | Exit review |
|---|---|---|---|
| 6. Reliable test baseline and repeatable sessions | Identifiable build, corrected HUD evidence, start/loss/retry, reproducible tests and scenario capture | D-085, D-032 session/export scope, D-033 tuning process | A fresh copy runs tests and a private game session can be restarted cleanly. |
| 7. Expansion, power and recovery | Play beyond ring 3; repair/reclaim ground; relay interruption and restoration; decaying loss pressure | Phase 6; D-022/D-023, repair/armor portion of D-027, D-021 | Demonstrate expansion, break, repair/reclaim, brownout and restoration without fixture-only game actions. |
| 8. Complete tactical tools | Full building/terrain catalogue plus two solar abilities | Core mutation/status contracts from 6; Phase 7 power/recovery; D-027/D-026 | Every tool can be purchased/used and has a verified role, counterexample and understandable feedback. |
| 9. Complete enemy roster and run pressure | All named elites and Assembler integrated into continuous swarm pressure | Phase 8 counters; Phase 7 relay/assimilation rules; D-019 and pressure sheet | Mixed enemies exercise their distinct threats over a full run, including recovery opportunities. |
| 10. Meaningful run variety | Doctrine/loadout/mutator choices alter how a run is played | Variety contract discussed in 6; Phases 7-9 core systems; D-029 | Repeated runs demonstrate contrasting viable strategies, not just scalar difficulty changes. |
| 11. Persistent progression | Results, earned meta currency, upgrades/unlocks, saved settings/progress | State boundary in 6; content IDs and variety from 8-10; D-028/D-032 | Lose, bank once, close/reopen, spend/unlock, start again with the correct state. |
| 12. Learnable, legible whole-game experience | Tutorial, chosen opening, reference help, settings and full-game feedback | Finalized test mechanics from 7-11; D-042/D-035; large-ring HUD follow-up | A complete unfamiliar-player workflow is executable without coaching or editor intervention. |
| 13. Integrated private test candidate | Reproducible full-duration, multi-run, scale and recovery evaluation | All prior exits; approved test population and performance envelope | Kevin accepts the private test build against the checklist below, with known limitations attached. |

Phases are integration gates, not a ban on useful parallel work. The doctrine/loadout data contract and prototype comparisons should begin early enough to influence tool design. Private build tooling starts in Phase 6, not at the end. Tutorials and tooltips grow with each feature; Phase 12 verifies the complete learning experience. Repeated performance samples start in Phase 6 and expand with the game.

## Phase 6 — reliable baseline and repeatable sessions

**Deliverables**
- Correct audit A1/A3 and add discriminating regressions (A4). Preserve the dated Phase 5 correction and approvals. Turn the A2 probe into an integrated multi-ring test when the view/world contract is extended in Phase 7.
- Establish a recoverable source baseline, pinned engine instructions, a one-command correctness runner and separate opt-in performance commands. Preserve historical digest baselines outside `.godot`, with provenance and explicit update review.
- Introduce a session lifecycle: new run, pause/resume, core defeat, basic result summary, retry and return to start. Reset clock, pause state, commands, cooldowns, pool IDs, UI selections, counters and events correctly. No meta rewards until their rules are approved.
- Define stable content IDs and one authoritative command/tick/commit interface for later builds, abilities, status effects and restoration. Preserve rollback and immutable public snapshots; keep efficient internal ownership.
- Add run/profile/build identifiers, tick-indexed command recording and seed recording when randomization is introduced. Provide isolated scenario loading for development, never hidden grants in a normal game.
- Produce a private local Windows test export after D-032 platform approval. Check a fresh launch outside the editor; document logs and reproduction steps. No public hosting.

**Ownership:** Sol for runner/state/recording/export; Terra for run accounting and commands; Luna for lifecycle screens; Astra defines the interface before assignments.

**Exit:** existing regression suites still pass; start → play → loss → retry works repeatedly without state leakage; a clean project copy can reproduce correctness checks and a recorded scenario; every error is reported as failure rather than swallowed. Test timing data includes engine, hardware, scene, profile and source identifiers.

**Decision package first:** D-085 continuation scope, D-032 private Windows build/session persistence, D-033 parameter approval versus bounded tuning. Recommendation: persist settings and meta when implemented; mid-run suspend/resume is a separate optional feature, not a prerequisite for complete-game testing. If selected, its schema is designed here and delivered in Phase 11.

## Phase 7 — expansion, power and genuine recovery

Implement these as separate reviewed handoffs in dependency order, then combine them:

1. **Growing world.** Replace the playable three-ring ceiling with incremental expansion and geometry/input synchronization. Keep the configured slice as a regression fixture. Test focus → world selection → purchase/build beyond ring 3, through ring 12 and beyond; do not confuse a twelve-band HUD with a twelve-ring playable scene. Profile/map size must not force a fixed design cap.
2. **Destruction and restoration contract.** Define intact/damaged/broken/collapsed/reclaimed states, historical ring IDs, occupants, walls, relays and exactly-once destruction events. Settle partial-wedge recovery versus complete-ring reclaim, occupancy blocking, relay placement, restored HP/buildings and expansion prerequisites (D-022). No free restoration/refund is inferred.
3. **Armor and repair.** Implement Armor Plating and Repair Node after price, capacity, repair range/rate, stacking and broken-wedge rules are approved. HUD health reads authoritative maximums. Clearly separate repair of surviving structure from reclaiming destroyed territory.
4. **Relay power.** Implement strictly outward ring-level transmission, decreasing outer throughput, relay vulnerability/rebuilding, minimal brownout output and restoration (D-023). Resolve the important interaction: an inner ring can collapse while outer rings survive, but its missing power path must be visible and recoverable under approved rules. Power is output capacity, not a second spendable currency or passive energy income.
5. **Assimilation.** Add destruction-driven buffs to existing machines with approved decay, stacking, recipients and effect types (D-021). No extra spawns. Decide whether incidental wedge loss, individual structures and total collapse each contribute; avoid double counting. Define how later spawns and Assemblers interact with buffs.

**Ownership:** Terra for rules, Sol for dynamic geometry/state/routing support, Luna for restoration controls and power/loss feedback.

**Exit:** matched scenarios show a loss, a costly recovery attempt and a viable restored defense. Tests verify no duplicate charges/destruction buffs, no ghost occupancy, correct path rebuilding, and clear downstream brownout/restoration. Record recovery costs against the income and useful coverage restored; do not declare comeback quality from arithmetic alone.

**Gate:** if Kevin judges total ring loss arbitrary or recovery consistently futile, stop feature expansion and brief a rule/tuning revision. Do not silently soften the seven-break collapse rule.

## Phase 8 — full tactical catalogue and abilities

**Shared rules first:** damage sources and kill attribution; stun/slow stacking and duration; armor/piercing; target eligibility; power modifiers; terrain occupancy and navigation costs. Every building remains automatic; solar attacks use player targeting.

**Tools to add**
- EMP Node: periodic crowd control; Lance Emitter: radial piercing; Point Defense: local anti-penetration defense. Existing Flak and Mass Driver remain regression anchors.
- Debris Field: impassable purchased terrain; Tractor Lane: directional rerouting; Occlusion Screen: slowdown. Define edge cases for completely sealed layouts, placement around existing enemies, shadow extent, overlapping effects and interactions with wall attacks/Tunnelers. Do not allow generic navigation defaults to choose these rules.
- Complete Ring Plate/Relay/Armor/Repair/Wall interactions, selection, affordability, invalid-placement reasons and power effects.
- Focused Flare and EMP Burst: cooldown-only player actions with targeting preview, cancel/invalid-target behavior and readable cooldowns. Resolve ability-kill energy credit explicitly: the spec's kill-income rule and prohibition on abilities granting energy need D-026's answer. No cooldown ability claims territory or constructs buildings.

**Exit:** every named catalogue item has one working full UI path, editable values and an isolated behavioral test plus a mixed encounter. Compare usefulness against its cost and alternatives; no decorative buttons or unimplemented tabs in the test candidate. Test pause, loss, reload if supported, and destruction during ongoing effects.

## Phase 9 — full horde and continuous escalation

- Transfer: approved hop depth, landing eligibility, warnings, vulnerability and interception/counter rules.
- Foundry: armor/HP, contact behavior and grinding pressure; test Mass Driver/Lance tradeoffs.
- Sapper: reachable relay targeting and fallback when a relay is absent; depends on actual relay vulnerability.
- Breacher: deliberate wall attacks, breach transition and target priority; preserve normal-machine sealed-route rules.
- Assembler: timing, movement, wall bypass and consumption growth with exact interaction against global assimilation. No double reward or duplicate destruction consumption.
- Integrate all with normals and Tunnelers through the shared pool, chronological admission, target/state lifecycle, death accounting and cap policy. Resolve new exact-time priority conflicts rather than assuming D-079 covers every elite.
- Tune pressure toward Kevin's preference for hundreds/thousands of weaker enemies. The accepted two/second and additive growth are test settings, not the final ramp. Keep arrivals continuous, without wave/build pauses.

**Exit:** each enemy presents its intended threat and has an available counter; long-run mixed scenarios include overlapping effects, multiple elites, purchased terrain, relay disruption and collapse. Record cap saturation/skipped admissions so a hidden cap does not flatten late-run difficulty unnoticed.

## Phase 10 — variety before progression hides balance

D-029 defines the actual doctrines, loadout constraints and mutators. The spec's Conservator, Prospector and Interdictor are illustrative, not automatically approved content.

**Proposed test breadth:** at least three materially different doctrine configurations, multiple useful loadouts per configuration, and several independently testable stackable mutators. Exact names/counts/modifiers require approval. Use temporary equal-access test profiles first so grind does not conceal whether tools or strategies work.

Doctrine differences should exercise recovery/armor, aggressive expansion/economy and terrain control where approved. Loadouts affect starting access/state and ability sets under an explicit contract. Mutators alter rules/difficulty and their reward multipliers must be compatible with Phase 11 accounting. No in-run card draft, research tree or boss loot is added.

**Exit:** Kevin can complete repeated attempts with meaningfully different build sequences and choices. Identify dominant strategies and dead choices; record observed variety separately from the number of menu options. Run sameness is the spec's highest-priority risk and must no longer remain excluded from evaluation.

## Phase 11 — persistence and a complete between-run loop

- Results derive survival time, kills and approved milestones/challenges from authoritative run accounting. Award meta currency exactly once, including after reload/retry/error. Resolve abandoned-run rewards, reset policy, upgrades and unlock costs under D-028.
- Add persistent upgrade/unlock state, loadout availability and settings. Stable IDs and a versioned format support renamed/rebalanced content without relying on UI labels.
- Use atomic writes, a recoverable backup and clear handling of missing, corrupt or incompatible files. Distinguish test resets from normal user progress and ask before destructive resets outside an explicit test fixture.
- If D-032 includes mid-run resume, save at a defined tick boundary. Preserve pool lifetime-ID high-water mark, tick/cooldowns, pending effects, arrival counters, power/recovery states, Tunneler phases and in-flight route waypoints (or demonstrate exact reconstruction). Define what happens when a balance profile changes. Visible positions alone are not a sufficient snapshot.

**Exit:** lose → reward → spend/unlock → exit → relaunch → new run works without duplicate credit or lost progress. Corruption/migration tests are meaningful and isolated. If resume is included, uninterrupted and save/load continuations agree at angular seams, burrows, destruction and shared-cap ties.

## Phase 12 — onboarding, legibility and usable controls

- D-042 selects the actual opening. Do not switch to a clean slate merely because it was suggested. An empty opening must have an approved way to bootstrap kill-only income.
- Build a replayable tutorial and in-game reference for placement, income, expansion, seven-break collapse, power, repair/reclaim, enemy counters, solar targeting and HUD symbols. Separate guided learning from a normal unpaused run; tutorial pause/grants require explicit rules.
- Add enough feedback to show attacks/hits, effect duration, range/coverage, target eligibility, power loss and restoration, elite warnings, results and failure reasons. Retain functional placeholders until art/audio choices are approved.
- Address the accepted small-Tunneler-marker overlap and twelve-ring HUD density against actual full-game use. Review a concrete scalable HUD treatment before implementing it; prior acceptance is not authority to invent filtering, aggregation or colors.
- Define private-test resolutions/window sizes, text scaling, non-color cues, input options and any audio/flash/motion controls under D-035. Final sound production is deferred, but important information must be perceptible without relying on an unimplemented sound cue.

**Exit:** the intended test user can launch, learn, play, understand a loss and retry without editor access or verbal rescue. UI remains usable at supported sizes and at representative outer radii. Kevin approves the observed experience; external participants remain separately authorized.

## Phase 13 — integrated validation and private test handoff

Prepare an evidence packet and execute this matrix on an identifiable private build:

| Area | Required evidence |
|---|---|
| Session completeness | Fresh launch, tutorial/reference, selection, full run, results, retry, quit/relaunch and saved progression; no debug grants in the normal path. |
| Run pacing | Multiple actual 15-25-minute target sessions plus long-run stress beyond that range; times to useful purchases, maximum radius, idle intervals, deaths and player input history. An endless run need not terminate at minute 25. |
| Economy/scaling | Radius-dependent cost, total HP, slots, actual coverage, kill throughput, delivered power, repair/reclaim payback and several viable build strategies. |
| Death spiral | Matched no-loss/loss/recovery runs with assimilation decay and power cascades; player explanation of why loss occurred and whether recovery was worthwhile. |
| Variety | Repeat-run observations across approved doctrines/loadouts/mutators, with equal-access experiments separated from progression-paced play. |
| Scale | Crowd × rings × weapons × enemy kinds × terrain/status effects; simultaneous volleys, topology-changing destruction, pause/resume and sustained rendered progress. Measure whole frames, tick cost, input response and memory; report missed criteria. |
| Persistence | Correct rewards, settings/progress retention, corrupt-file recovery and version policy; optional resume equivalence if included. |
| Readability | Find an off-screen failing bearing, diagnose a brownout, notice underground threats, select/build at outer radii and understand collapse. Record observations, not just screenshots. |
| Reproducibility | Build/profile/seed/command identifiers and local logs reproduce a reported issue; a clean Windows environment runs the private build without Godot installed. |

Agree hardware, representative density, acceptable frame/input budgets, run sample counts and usability criteria before executing acceptance trials. Keep the current 1,000 trial acceptance intact; qualifying the full game with additional systems is a new measurement, not retroactive rejection. No final crowd-cap claim follows from targeting-only or quiet scenes.

**Done means:** all named gameplay systems work through the normal interface; required correctness/integration checks pass; the approved test matrix is complete; no known blocker prevents ordinary multi-run testing; saved progress is trustworthy; Kevin accepts the candidate with a concise known-issues list. Final assets, release balancing and publication work remain outside this milestone.

## Decision roadmap and immediate next step

| When | Brief Kevin on | Existing record |
|---|---|---|
| Before Phase 6 assignment | Approve this full-game private-test scope/sequence; choose session/export/persistence expectations and tuning authority | D-085 (new plan), D-032, D-033 |
| Before Phase 7 rules | Recovery/repair/reclaim boundaries, power and relay failure, assimilation decay; include exact provisional parameter sheet and competing rules | D-022, D-023, D-021, D-027 subset |
| Before Phase 8 | Remaining tool/terrain/status rules, solar targeting and energy credit | D-027, D-026 |
| Before Phase 9 | Elite/Assembler behavior, pressure schedule and admission policies | D-019 and provisional pressure follow-ups |
| Discuss in 6; settle before 10-11 | Doctrine/loadout/mutator test breadth, rewards/upgrades/unlocks and persistence details | D-029, D-028, D-032 |
| Before final onboarding/usability gate | Opening/tutorial, functional feedback and accessibility | D-042, D-035; D-024 scaling follow-up |
| Before integrated acceptance | Private-test hardware/density criteria and participant scope | D-007 follow-up; new full-game evaluation briefing (D-031's slice review remains closed) |
| Later, not a blocker here | Final art and naming | D-030, D-034 |

**Recommended first authorization:** approve Phase 6 as the next implementation phase within this roadmap. Start with the reproduced HUD defect, regression/evidence cleanup and reproducible session/test foundation; settle D-032/D-033 in one briefing before their dependent implementation. Do not approve every future number or mechanic merely by approving the roadmap.


