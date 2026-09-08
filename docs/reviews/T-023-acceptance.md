# T-023 acceptance of measured gameplay corrections

Astra reviewed the route cache, read-only private staging, pool membership cleanup and regression coverage. The corrections preserve public snapshot/result isolation, waypoint lifetime rules, same-tick topology updates and failed-tick rollback. They are accepted; rendered performance remains open.

Independent pinned Godot reruns passed480 navigation and293 live checks. The sustained cost mode passed785 checks, including all246 exact baseline state/event/waypoint digests. Consumer checks reported by Terra also pass. Root logs are `.godot/t-023-astra-*.log`.

Independent short median/p90: sealed12.589/13.181ms; angular16.176/16.487ms. Independent sustained sealed12.374/13.988ms, but angular showed a large all-phase timing increase to41.564/44.918ms. This anomaly also appeared in Terra's runs and is retained in the evidence.

Follow-up isolated diagnostics show prior sealed work is not necessary for a slow tail. A fresh angular run retaining exact outside-timed digest verification measured17.489/42.734ms; a diagnostic omitting that verification measured18.018/19.427ms. The latter does not replace correctness tests and does not prove a cause. It suggests sensitivity to the surrounding review workload. See T-023.md for sample counts, fixtures and limitations.

The three corrections have repeatable small gains, especially in sealed contact, but do not yet establish60Hz rendered capacity. Sol receives T-024 to reduce measured PolarMotion work while retaining numerical validation. Luna must then rerun both rendered wall fixtures. No crowd, balance, speed or clock-policy change is approved here.
