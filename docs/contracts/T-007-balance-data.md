# T-007 — Editable approved balance data

**Owner:** Terra. **Coordinator:** Astra. **Date:** 2026-09-06.
Kevin approved D-010–D-015 Option A, with whole-ring expansion including a relay in D-011, and explicitly requires easy economy/combat tuning during testing, polish, and after release. He subsequently approved a ring price equal to all 12 wedge prices (120 × ring index at current tuning), including a relay structure, with power behavior deferred. This task implements data and validation only.

## Files and boundaries

Own data/balance/testing.json, src/gameplay/balance_profile.gd, tests/gameplay/test_balance_profile.gd, docs/balance-data.md, and docs/reviews/T-007.md. Generated adjacent .uid files are allowed. Read this brief only, then your own files. Do not read the full spec, edit root logs, change existing core/presentation/project files, implement gameplay, or delegate.

Use installed E:/Godot/Godot_v4.7.2-stable_win64.exe. Redirect APPDATA and LOCALAPPDATA in each process to workspace .godot/appdata and .godot/localappdata; logs go under .godot/. No package installation.

## Authoritative testing JSON shape

All keys below are required; reject unknown keys. schema_version is the file format version, not a game-balance version. Values are the approved starting tuning values:
- schema_version: 1
- economy: { kill_energy: 1, ring_plate_base_cost: 10, wall_cost: 5, flak_cost: 20, mass_driver_cost: 40 }
- scaling: { slots_per_wedge_per_ring: 1, claim_cost_ring_exponent: 1.0, wedge_hp_ring_exponent: 1.0, power_ring_exponent: -1.0 }
- flak: { damage: 2.0, cycle_seconds: 0.25, range_ring_widths: 2.0, arc_degrees: 90.0, max_targets: 5 }
- mass_driver: { damage: 20.0, cycle_seconds: 2.0, range_ring_widths: 4.0, max_targets: 1 }
- health: { wedge_base_hp: 100.0, core_hp: 200.0, wall_hp: 50.0, standard_machine_hp: 10.0 }
- standard_machine: { damage_per_second: 5.0 }
- starting_test_setup: { owned_ring_count: 1, flak_count: 1, energy_in_flak_purchases: 1, flak_wedge: 12, relay_wedge: 6, relay_count: 1 }
- structure: { collapse_broken_wedges: 7 }

Scaling formulas express approved linear baseline without hard-coding linear growth into consumers: ring factor is pow(ring_index, exponent); slots equal ring_index * slots_per_wedge_per_ring. Consumers will receive these approved contracts in later tasks. Do not implement costs/slots/gameplay calculations in this task. Power's relative falloff is approved, but base power and working power behavior are not; this coefficient is dormant data, not authority to enable power.

ring_plate_base_cost is the approved per-wedge price unit. Later consumers calculate a full ring as WEDGE_COUNT × ring_plate_base_cost × pow(ring_index, claim_cost_ring_exponent), using the fixed 12-wedge grid count. At current tuning ring 2 costs 240 and ring 3 costs 360, relay included. Do not implement purchases in this data task. Starting grant is expressed as a count of Flak purchases, so later startup derives it from current Flak cost (currently 20); never duplicate 20 as a separate starting-energy literal. Kevin approved starting Flak wedge 12, relay wedge 6, relay occupying one normal slot. Later relay slot is selected with the purchase. Expansion requires all inner wedges intact; this is a later purchase rule, not implemented here.

No friendly-fire, arc for Mass Driver, aiming, attack eligibility, relay health/cost, machine speed/spawn rate, cap, repair, or final starting layout may be invented.

## Public API and errors

BalanceProfile extends RefCounted; use a private-by-convention _data: Dictionary.
- static func from_dict(raw: Dictionary) -> Dictionary
- static func load_json(path: String) -> Dictionary
- func with_overrides(overrides: Dictionary) -> Dictionary
- func snapshot() -> Dictionary
- func value(path: String) -> Variant

Factory/override results always have { "ok": bool, "profile": BalanceProfile or null, "errors": PackedStringArray }. Failures provide actionable paths and reasons and never return a partially valid profile. load_json accepts an explicit Godot resource or filesystem path, uses FileAccess/JSON, reports unreadable/malformed files or non-object roots, and delegates validation. Do not silently fall back to the testing profile.

from_dict validates a complete input and deep-copies it. with_overrides merges a partial nested object onto a deep copy, validates the full result, and returns a NEW profile; an invalid update leaves the original untouched. Reject unknown keys, non-object section replacements, wrong types including bool-as-number, missing required fields, and unsupported schema versions. No silent coercion/clamping. JSON whole numbers may parse as floats; accept finite integer-valued numbers where an integer is required and normalize them.

snapshot returns a deep copy, not writable internal data. value uses dot paths, e.g. economy.flak_cost. Return a copy for object values; unknown paths return null. Default tuning numbers live ONLY in testing.json, not repeated as fallback constants in code. The schema may repeat key names and validation constraints.

Validation constraints: economy values are integer >= 0. slots_per_wedge_per_ring is integer >= 1. Ring exponents are finite numbers (no artificial tuning bounds). Damage values are finite >= 0; cycles/ranges/HP are finite > 0; arc is finite in (0,360]; max_targets is integer >= 1. Starting counts are integer >= 0; starting wedge identifiers are integer 1–12; collapse_broken_wedges is integer 1–12. Version is integer exactly 1.
Do not enforce today's relation between prices, weapon roles, or scaling slopes in validation; these must remain adjustable.

## Done and review

Write concise docs/balance-data.md for Kevin: where numbers live, units, changing a value, passing an alternate profile path, applying in-memory overrides, and limitations. This is a loader/data foundation; no running gameplay consumes it yet. Post-release tuning means edited data can ship in a later build, not an implemented remote update system, hot reload, or save migration.

Meaningful headless tests extend SceneTree and exit nonzero on failure. Load the shipped JSON; test changed economy/HP values via alternate data/overrides without implementation edits; verify omitted/unknown keys, malformed/unreadable/non-object JSON, invalid numeric types/ranges/nonfinite values and unsupported versions. Test deep-copy isolation both from original input and snapshots, partial nested overrides, invalid-update atomicity, and preserved starting grant dependency. Use workspace-local .godot temporary fixtures. Do not create hundreds of tests that merely repeat the JSON field list.

Run editor import and the focused data test. No need to rerun unchanged core or presentation suites. Report commands, counts, limitations, and changed files in docs/reviews/T-007.md. Astra reviews your code/data against this brief and returns deviations to you. Stop at delivery; no consumer integration.
