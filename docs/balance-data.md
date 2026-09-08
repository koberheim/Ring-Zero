# Editing RING ZERO balance data

All starting tuning numbers live in `data/balance/testing.json`. The loader in `src/gameplay/balance_profile.gd` checks data and gives callers independent, validated profiles. Purchase, weapon, spawn, and live-simulation rules consume these profiles; scene presentation is a separate integration.

To tune a value, edit the JSON number and run the focused test below. Keep the existing key names and sections. `schema_version` describes the file format and must remain `1`; it is not a balance revision number. Missing fields, extra keys, invalid types, unsupported versions, and out-of-range values produce errors naming the affected fields. The loader never silently substitutes defaults or clamps values.

| Section | Meaning and units |
| --- | --- |
| `pressure` | Testing spawn rate in enemies/second (nonnegative), speed in ring widths/second (positive), spawn offset in ring widths (positive), nonnegative stat-increase coefficient per minute, and positive whole `max_active_machines`. |
| `economy` | Nonnegative whole energy amounts: kill reward, per-wedge ring plate price unit, and building prices. |
| `scaling` | Slots per wedge per ring index is a positive whole count. Ring exponents are finite numbers; the intended later ring factor is `pow(ring_index, exponent)`. Power's exponent is dormant data. |
| `flak`, `mass_driver` | Damage is HP per attack, cycle is seconds, range is ring widths, and max targets is a positive whole count. Both weapons require arc_degrees greater than zero through 360; the testing Mass Driver arc is 360.0 degrees. |
| `health` | Positive HP amounts for wedges, core, walls, standard machines, and Tunnelers. |
| `tunneler` | Positive finite first arrival, arrival interval, and burrow duration, all in seconds. Pure scheduling data; runtime integration is separate. |
| `standard_machine` | Nonnegative damage in HP per second; required `wall_damage_multiplier` is a finite fraction from 0 through 1 inclusive, testing value 0.25. |
| `structure` | `collapse_broken_wedges` is the whole broken-wedge threshold, from 1 through 12. |
| `starting_test_setup` | Nonnegative whole counts of owned rings, Flak, relay, and Flak purchases granted as energy. `flak_wedge` and `relay_wedge` are whole wedge numbers from 1 through 12. |

The required `pressure` section holds Kevin's approved D-017 **TESTING** values: `spawn_per_second: 2.0`, `speed_ring_widths_per_second: 1.0`, `spawn_offset_ring_widths: 2.0`, and `stat_increase_per_minute: 0.1`. These temporary values do not define final density; final gameplay targets hundreds or thousands of enemies. Zero spawn rate and zero escalation are valid test overrides. Speed and spawn offset must remain positive; every pressure value must be finite. Missing fields have no implicit defaults.

Approved D-053 testing growth adds the configured fraction of original HP and DPS for each completed minute, applied only to new spawns: `factor = 1 + floor(elapsed_seconds / 60) * stat_increase_per_minute`. At 0.1, minute two gives 1.2 times the original stats. Existing enemies retain their spawn stats. This additive curve is testing only.

Approved D-076 Tunneler testing data adds `health.tunneler_hp: 20`, `tunneler.first_arrival_seconds: 60`, `tunneler.arrival_interval_seconds: 30`, and `tunneler.burrow_seconds: 2`. The pure `TunnelerRules` helper schedules `(start, end]` arrivals, using the scheduled time for the same additive HP/DPS growth and normal speed. Thus the first default arrival has 22 HP. Each scheduled bearing bypasses one intact wedge to the next intact wedge inward; broken or collapsed gaps do not count. Without two intact wedges it is skipped, with no backlog. Returned underground descriptors are untargetable and own a locked destination. These fields are data and pure descriptors only: live admission, burrowing, emergence, shared-cap enforcement, and warning presentation await their separate integration. The intended cap and kill reward remain shared with normal machines; no Tunneler-specific cap or reward is introduced. All four new values are required finite positive numbers and support existing profile overrides.

Approved D-067/D-068 use `standard_machine.wall_damage_multiplier: 0.25` on each machine's spawn-scaled DPS only when walls seal its reachable region from all exposed wedge/core surfaces. Otherwise normals route to a reachable exposed surface. Walls protect underlying wedges until destroyed; destroying a wall erases its record and gives no reward or refund. A multiplier of zero is valid and prevents wall damage; one permits full machine DPS under the same sealed-region condition. Closure uses shared graph reachability, including mixed-ring perimeters, rather than a count of walls on one ring.

Approved D-059 adds required `pressure.max_active_machines: 1000` as a positive whole testing capacity. The live simulation admits earliest due arrivals up to available slots and permanently skips the remainder; freeing slots never causes a deferred burst. This is not a final density claim. Spawn offset is measured beyond the outer boundary of the highest noncollapsed ring, with even repeating wedge-center bearings. `schema_version` remains 1 because this is an internal prototype expansion with no shipped saves.

Cycles, ranges, and health must be positive. Damage can be zero. Whole numbers parsed from JSON as floats are accepted and normalized to Godot integers, provided they fit its signed 64-bit integer representation. Booleans and numeric strings are rejected. Price relationships and exponent slopes are deliberately adjustable.

Load the testing file or pass a complete alternate profile using an explicit resource or filesystem path:

```gdscript
const Profile = preload("res://src/gameplay/balance_profile.gd")

var result = Profile.load_json("res://data/balance/testing.json")
# Alternatively: Profile.load_json("E:/MyBalance/alternate.json")
if not result.ok:
    push_error("\n".join(result.errors))
    return
var profile = result.profile
var flak_cost = profile.value("economy.flak_cost")
```

Apply partial nested overrides without changing a file:

```gdscript
var changed = profile.with_overrides({
    "economy": {"flak_cost": 37},
    "health": {"core_hp": 321.5},
})
if changed.ok:
    var test_profile = changed.profile
else:
    push_error("\n".join(changed.errors))
```

Every factory or override returns `ok`, `profile`, and `errors`. Failed operations return a null profile. Successful overrides create a new profile; both successful and failed updates leave the original alone. `from_dict(raw)` accepts a complete dictionary. Input data, snapshots, and object values returned by `value()` are copied. Unknown dot paths return null. Callers should use these APIs instead of accessing the private-by-convention `_data` field.

The starting energy grant remains a count of Flak purchases, so startup derives energy from the current Flak price. There is no separate starting-energy number to keep synchronized. Full-ring purchases cost all 12 wedge prices combined, using the ring-cost exponent, and include a relay. The approved starting Flak is on wedge 12 and relay on wedge 6; the relay occupies one normal building slot. Relay placement is chosen during a full-ring purchase. Expansion requires all immediately inward wedges unbroken, sufficient energy, and no living machine in the proposed new polar band.

The balance loader itself validates data; gameplay services implement purchases, damage, placement, collapse, startup, and the approved testing pressure schedule. Shared wall funneling and conditional wall attacks now run in the simulation. Power, manual repair, Reclaim and solar abilities are now implemented by their gameplay services; terrain presentation is a separate handoff. Post-release tuning means edited data can ship in a later build; there is no remote update system, hot reload, or save migration.

Run the focused test from the project directory in PowerShell:

```powershell
$env:APPDATA = Join-Path (Get-Location) '.godot/appdata'
$env:LOCALAPPDATA = Join-Path (Get-Location) '.godot/localappdata'
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
& 'E:/Godot/Godot_v4.7.2-stable_win64.exe' --headless --path . --editor --import --log-file .godot/t-007-import.log
& 'E:/Godot/Godot_v4.7.2-stable_win64.exe' --headless --path . --script tests/gameplay/test_balance_profile.gd --log-file .godot/t-007-tests.log
```




T-043 moves the unchanged assimilation testing constants into the required `assimilation` section: `bonus_per_stack: 0.05` (finite nonnegative damage fraction), `max_stacks: 10` (positive whole count), and `stack_seconds: 15.0` (finite positive seconds). Each stack retains an independent expiry; only currently active machines receive grants. Overrides now control both granted expiry/cap and actual attack damage. Zero bonus is valid for isolated comparisons. Computed multiplier/expiry overflow fails a live tick before admissions. This correction does not change the outstanding wedge-break versus retained-occupant trigger interaction.

EMP Node and Lance Emitter keep `max_targets` in the strict legacy profile schema, but ignore it during selection: their approved pulses/bursts hit every living targetable eligible machine. EMP is restricted to its own ring and distance radius; Lance to its exact wedge column outward from its firing radius within range. Other weapon caps are unchanged.


T-048 introduces cooldown-only solar testing profiles under D-026/D-097 and D-033 numeric tuning authority. `focused_flare` defaults to damage 60 HP, cooldown 30 seconds, range 8 ring widths measured from the core, and a 60-degree sector centered on the clicked nonzero bearing. `emp_burst` defaults to damage 2 HP, cooldown 10 seconds, radius 1.5 ring widths around the clicked point, and stun 2 seconds. These are provisional values; existing weapons/enemies/economy are unchanged. Damage is finite nonnegative, cooldown/range/radius/stun finite positive, and Flare arc greater than zero through 360 degrees. The complete sections are required; missing/extra/type-invalid fields are rejected. No EMP aim-distance limit is imposed.

Both abilities affect living targetable machines only, and ability kills award zero energy. Empty valid casts start cooldown; invalid casts and UI cancellation do not. New runs begin ready. Successful fixed ticks decrement independent ability cooldowns; pause, ended ticks and failed ticks do not. EMP refreshes stun with the maximum of old/new durations. Cast commands return separate hit/kill events and do not replace fixed-tick events. Ability hits use `{ability_id: StringName, target_id: int, damage: float}`; consumers must count command kills exactly once rather than expecting them on the next tick.

T-050 adds the approved terrain catalogue as slot-occupying, energy-only structures. Provisional D-033 costs are `economy.debris_field_cost: 30`, `tractor_lane_cost: 25`, and `occlusion_screen_cost: 30`; costs are finite nonnegative integers. `tractor_lane.path_cost_multiplier: 0.5` discounts only its preferred outgoing angular route arc, never physical movement time. `occlusion_screen.shadow_rings: 3` is a positive integer; `speed_multiplier: 0.5` slows surface movement in the same column over those outward rings. Both multipliers must be finite and greater than zero through one. Required sections/fields and strict unknown-field/type rejection remain in force.

Debris hides its protected outer surface from both exposed and wall goals. Tractor direction is exactly integer -1 (counterclockwise) or +1 (clockwise), one lane per wedge. Screens overlap by strongest slow once. All three effects require positive supporting-wedge HP; broken support retains inactive occupants, repair reactivates them, and whole-ring collapse removes them. Terrain placement and ground restoration reject a fully sealed outer frontier; live commands additionally reject trapping an existing surface machine. Underground Tunnelers and inside-wedge attackers are excluded from open-cell route requirements. Shadow slows only physical surface travel, including roaming Tunnelers; attacks, weapon/ability cooldowns, assimilation and underground travel retain their existing rates. Numeric profiles are fixed for a simulation; this adds no runtime balance editor.

