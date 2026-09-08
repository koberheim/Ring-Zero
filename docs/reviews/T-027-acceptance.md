# T-027 runtime acceptance

Astra accepts the runtime against D-018, D-075, D-076 and D-079. Source review covered chronological admissions and eligible Tunneler tie priority, locked underground travel, emergence vulnerability, inside damage, retained inactive walls on broken supports, normal routing, snapshot isolation and failed-tick rollback. Independent pinned Godot 4.7.2 runs passed 404 live and 357 weapon checks with exit 0; logs are `.godot/t-027-astra-live_simulation.log` and `.godot/t-027-astra-weapon_rules.log`.

Terra's consumer suites and all 246 original normal-state digests passed without baseline changes. Independent long-suite timing again reproduced the documented inflated measurements; this does not establish rendered performance. The existing 1,000-machine angular frame-budget issue remains open.

The optional runtime flag defaults false, preserving legacy consumers. T-028 may now enable it in the main view and implement the approved destination warning/countdown and surfaced triangle. Gameplay acceptance does not imply final balance, art or crowd-cap acceptance. The exclusive Godot window is released to Luna for presentation verification.
