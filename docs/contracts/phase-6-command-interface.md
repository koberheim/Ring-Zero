# Phase 6 — stable content IDs and the authoritative command/tick/commit interface

Astra, 2026-09-07. This documents the existing pattern as the authoritative interface later systems (Phase 7 repair/reclaim/power/assimilation, Phase 8 abilities/status effects) must extend, per the full-game plan's Working Rule 1 ("extend the existing transaction/commit boundaries; no engine rewrite is justified"). It is a contract, not a new implementation — nothing here required a source change beyond what T-031/032/033 already delivered.

## Stable content IDs

Building/occupant/machine kinds are already `StringName` literals, not display strings or indices: `&"flak"`, `&"mass_driver"`, `&"relay"`, `&"tunneler"`, `&"wall"`, plus structural targets `&"wedge"`/`&"core"` and phases `&"burrowing"`/`&"surface_attack"`/`&"roaming"`. This is the established convention and every new building, enemy, ability, or status effect added from Phase 7 onward must use a `StringName` kind the same way — never a raw string compared by value, never a bare integer enum (integers can't be grepped for usage or safely reordered as content grows). Add new kinds to this list as they're implemented; there is no central registry to update because Godot's `StringName` interning makes one unnecessary for correctness, only for discoverability:

`&"flak"`, `&"mass_driver"`, `&"relay"`, `&"tunneler"`, `&"wall"`, `&"wedge"`, `&"core"`, `&"burrowing"`, `&"surface_attack"`, `&"roaming"`

## The commit pattern (already implemented, to be extended not replaced)

`LiveSimulation.step()` (`src/gameplay/live_simulation.gd`) is the one authoritative per-tick entry point. Its shape is the contract:

1. Validate inputs and current state; fail closed (`_failed_tick`) before any mutation if anything is wrong.
2. Do all fallible work — admission, movement, combat — against **staged** copies (`staged_state := state.duplicate(true)`, `staged_core`, `staged_cooldowns`), never the live fields.
3. Only after every fallible call has succeeded, commit: copy results into the pool, assign `state = staged_state`, `core_hp = staged_core`, etc., in one block with no further fallible calls after it starts.
4. Public reads never see live mutable internals: `targets_snapshot()` clones positions (`_target_record(..., copy_position=true)`); the private staging path (`_step_targets()`) may skip the clone only because `PolarMotion`/`WeaponRules` are documented to never mutate their inputs — that exception is narrow and stays narrow.

**Any future system that mutates simulation state during a tick — repair/reclaim, relay power transmission, assimilation buffs, ability effects, status effects — extends this same stage-then-commit block inside `step()` (or a helper it calls before its commit point). It does not introduce a second, parallel mutation path, a second "phase" of the tick with its own commit, or a bypass that writes directly to `state` before the existing commit.** If a new system's ordering relative to movement/combat matters (e.g., does repair happen before or after combat damage in the same tick?), that ordering is a rule decision for Kevin's system briefing, not something to infer here.

## Run/profile/build identifiers

D-032 Option A (editor-only, restart-from-beginning, no export or save/resume) removes the pressure for a persisted run-identifier scheme now — there's nothing to reload against. What Phase 6 still needs, and already has by convention rather than by new code: every review/report in this repo states the exact pinned Godot version (`4.7.2.stable.official.ed1daf0bf`), the balance profile used, and any fixture overrides, in prose (see every `docs/reviews/*.md` and this session's `docs/reviews/phase-5-evidence.md`). That convention **is** the run/profile/build identifier requirement for a Kevin-only testing stage; continue it for every future report rather than building a logging subsystem with no current reader. Revisit a real recorded identifier scheme (tick-indexed command recording, seeds) if and when D-031 moves toward external participants (their bug reports need a build to point at) or Phase 11 persistence needs a save-compatible version stamp — not before, per "no engine rewrite is justified."

## What this does not do

This is a documentation contract, not a decision. It doesn't choose any Phase 7 rule (repair costs, power transmission, assimilation decay), doesn't add a save format, and doesn't create new source files. It exists so the next system briefing can say "follow the stage-then-commit pattern, use a StringName kind" instead of re-deriving it.

## Continuation audit clarification - 2026-09-07

Accepted immediate player commands (purchase/place/repair/reclaim) validate and stage their own transactions between simulation ticks, then commit on success. Passive healing, assimilation and combat effects remain within the tick transaction. The earlier description that all recovery runs inside step was too broad; no command scheduling rewrite is authorized by correcting this documentation.

Public snapshot methods promise isolation of their returned positions and mutable status arrays. The implementation still exposes state and pool by convention for internal integration and fixtures; the earlier phrase "public reads never see live mutable internals" was not accurate for every public field. T-043 repairs the accidental assimilation_stacks alias in targets_snapshot and validates new status fields before processing.

Current additional occupant IDs are armor_plating, repair_node, emp_node, lance_emitter and point_defense (StringName values like the existing kinds). Future catalogue additions must update placement validation, state validation, weapon selection, power demand and presentation mappings together; interning a name does not prevent those enumerations from drifting.

D-032 editor-only/no-resume and D-086 deferred command-recording decisions remain unchanged. Do not infer export, persistence or replay implementation authority from this clarification.
