# T-021 gameplay acceptance

Astra reviewed the navigation graph, staged movement and combat, profile validation, and independent connectivity tests against D-065 through D-071. Gameplay is accepted for T-022 presentation integration. This is not acceptance of final crowd performance.

Independent Godot 4.7.2 reruns passed 476 navigation, 325 balance, and 290 live checks (1,091 total). Terra's additional consumer reruns passed 508 building, weapon, spawning, and placement checks. Logs: `.godot/t-021-astra-*.log`; delivery details in T-021.md.

Review corrections consume tolerance-close endpoints within the bounded movement loop and reuse the preflight target copies for staged movement. Position isolation, ordered admissions, same-tick route updates, and rollback remain tested.

Independent 1,000-machine timings: sealed contact median 14.654 ms, p90 15.312 ms; active angular funnel median 17.279 ms, p90 17.476 ms. Three warmups and ten samples, no measured volleys or rebuilds, one initial route build. The movement case exceeds one 60 Hz tick before rendering. T-022 must measure the rendered loop and report the bottleneck; no final cap, reduced density, or cadence change is authorized by this acceptance.
