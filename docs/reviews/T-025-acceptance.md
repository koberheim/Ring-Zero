# T-025 acceptance

Astra reviewed the shared combat implementation, private scratch ownership and rollback tests. Public WeaponRules.step remains pure; the private owned path changes only exclusive target HP records. Combat never mutates positions or nested extras. LiveSimulation discards failed scratch before commit. No gameplay or validation changes are retained.

Independent342weapon,296live and785cost checks passed (1423 total), including all246 exact baseline state/event/waypoint digests. Logs: `.godot/t-025-astra-*.log`.

Matched agent timing-only measurements improved sealed12.323 to9.817ms and active angular16.677 to14.455ms median. Public pure-call median4.336 to4.362ms showed no material regression; private call2.440ms. Independent short medians sealed9.691/angular13.434ms support the gain. Root sustained digest-mode angular again showed all-phase inflation (34.556ms); this known review-workload sensitivity is retained, not interpreted as a proven cause or discarded.

Correction accepted. Luna owns the exclusive unchanged rendered fixture rerun. No final1000-enemy capacity or60Hz rendered acceptance is inferred from headless gains.
