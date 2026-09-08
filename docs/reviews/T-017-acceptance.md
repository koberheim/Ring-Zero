# T-017 acceptance

Astra accepted the first wall-free live simulation on 2026-09-06 after source, state-validation, and integrated-test review. An independent pinned-Godot rerun passed all **820 checks** (297 balance, 45 building, 219 weapon, 147 spawn, 112 live), with tracked processes exiting 0. Logs: .godot/t-017-astra-<suite>.log.

Review verified due-time movement, remaining-time surface DPS, radial intact-ring blocking, same-tick break visibility, seven-break total loss without destroying outer rings, stable destroyed-ring records, core-loss short circuit, once-only kill energy and pool release, occupied candidate-band rejection, cap skipping without backlog, result isolation, and rollback of tentative admissions on errors.

Astra's 1,000-machine full-step rerun measured 10.678 ms median / 11.188 ms p90 in normal cooldown steps (zero measured hits), and 12.858 ms median / 13.159 ms p90 in forced-ready steps (55 hits each). Same durable-contact fixture, three warmups/ten samples. These remain headless CPU timings, not rendered FPS or final capacity. The known certificate-store diagnostic did not affect offline checks.

The approved interface is ready for T-018 presentation. Walls, angular funneling/route-field integration, Tunneler and the remaining slice tasks are not delivered by this acceptance.

## Natural default-profile verification

Terra ran a fresh unmodified testing profile with no purchases or fixture interventions until core loss. The run ended at19.9667 simulated seconds; ring1 collapsed at18.6833 seconds. Three kills awarded3 energy (final23), peak/final active machines36, skipped arrivals0, simulation errors0. Tracked PID39828 exited0, wall time512ms. Evidence: .godot/t-017-natural-review.gd and .godot/t-017-natural-review.log. This verifies the natural lifecycle, not balanced survival duration; no tuning was changed. The short hands-off lifetime must be disclosed in the first live-test review.
