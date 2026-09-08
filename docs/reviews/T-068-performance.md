# T-068 — Bounded mixed whole-step probe

**After T-069 correction, all18 unchanged fixtures complete successfully. Large-crowd whole-step costs exceed the60Hz budget in these normalized stress cases.** Initial rejected-tick evidence is preserved below. Script: `tests/performance/measure_feature_candidate.gd`; it is separate from `test_*.gd` discovery and writes no baseline/digest.

Matrix: owned rings1/6/12 × actual actors100/500/1000 × natural weapon cadence/explicit forced-ready volleys. Three warmups and20 measured complete `LiveSimulation.step(1/60)` calls per fixture. Time wraps only the complete public step; setup, diagnostics and a deliberate midpoint wall-placement command are outside. The next step includes its navigation rebuild. Median averages sorted positions9/10; p95 is nearest rank index18. Report raw microseconds, median/p95/max, per-step hit/rebuild counts, initial/final kind/status counts, admissions/skips and CPU-only simulated-seconds-per-wall-second. This rate excludes setup/render/UI and is not rendered FPS or sustained production performance.

Explicit fixture, not campaign pacing: direct LiveSimulation.create with all enemy streams enabled; capacity set exactly to requested actor count, normal60/sec and elite first0.1sec/interval1sec to expose skipped admissions while the durable pool remains full. HP/wall/core durability1e9, per-actor DPS0.01, speed1, funding1e9, power base150×ring count to support outer-ring weapon demand. Natural weapon numeric ranges/cycles/damage remain profile values. All rings bought and walls/terrain/weapons placed through real live commands. Outer walls1/3/5/7/9, Debris11, Tractor4, Screen2; five weapon kinds on outer wedges6–10 plus original starter Flak. At measured sample10, place wall2 to invalidate topology without killing actors.

Actors are explicit valid pool fixtures distributed over12 bearings and six surface kinds plus Tunneler where valid. Half surface actors start at contact, half0.2 ring widths outward. One-third carry an assimilation expiry10sec, one-fifth initial stun0.2sec; Assembler has one growth stack. Tunneler fixtures split between beginning a legal two-band burrow and completed inside surface attack. Ring1 has no legal two-band burrow, so it contains six kinds and reports that omission. Status snapshots expose what is actually present; no claim that a short durable fixture reproduces every transition, death/collapse workload or roaming phase. Transfer hops can occur through normal step behavior. Every step requires exact requested active count and a non-ended successful simulation.

No production setting, optimization, existing cost-review fixture or baseline is changed in this lane. Root/Luna separately own final rendered evidence.

## Initial failure and handoff

After the final store suite completed at2026-09-08T10:24:14Z, the pinned `E:/Godot/Godot_v4.7.2-stable_win64.exe` ran `--headless --path "E:/AI Projects/Games/Ring Zero" --script res://tests/performance/measure_feature_candidate.gd`. Hidden tracked PID31972 exited1 before its90-second bound. The first1-ring/100-actor normal-cadence fixture returned `Angular progress is too small to represent.`

Root authorized one diagnostic reproduction. Only failure-row fields were added (ring/count/mode/tick/elapsed); fixture HP, speed, statuses, actors and topology were unchanged. PID47404 exited1 within30 seconds, reproducing at zero-based `tick_index:13`, committed elapsed0.216666666666667 seconds, active100 and ended=false. This is immediately after the deliberately placed wall2 at measured sample10; the failed step did not advance simulation time. No completed fixture timing row was printed, and partial timings are not reported as successful measurements.

Logs: `.godot/t068-probe.out/.err` and `.godot/t068-probe-diagnostic.out/.err`. No script/parse errors occurred; the known certificate-store diagnostic remains. All owned children exited and runtime was handed to Terra for root-assigned T-069 correction. No fixture weakening or production edit was made in this lane. The successful unchanged matrix after correction is recorded below.

## Completed matrix after T-069

Terra ran the unchanged fixture with the narrow integration residual-time correction documented in [T-069](T-069.md). PID39880 exited0 within its60-second bound under pinned Godot4.7.2, hidden tracked launch and workspace APPDATA/LOCALAPPDATA. Log `.godot/t069-feature-probe.log` contains18 successful JSON rows and the zero-failure footer. Sol independently parsed the log: every row has20 measured samples and exact requested initial/final actor counts. Terra froze the correction after focused regressions and all246 stored behavior digests matched. Sol did not rerun the matrix just to duplicate that evidence.

| Rings | Actors | Cadence | Median ms | p95 ms | Max ms | CPU sim rate × | Wall command ms |
|---:|---:|---|---:|---:|---:|---:|---:|
|1|100|normal|3.518|4.020|5.087|4.590|0.211|
|1|100|forced ready|3.726|4.460|4.542|4.311|0.225|
|1|500|normal|11.609|13.270|14.220|1.420|0.228|
|1|500|forced ready|12.354|14.416|14.612|1.338|0.231|
|1|1000|normal|22.258|25.187|26.276|0.748|0.262|
|1|1000|forced ready|23.603|25.994|28.804|0.694|0.252|
|6|100|normal|4.000|5.375|6.756|3.937|0.356|
|6|100|forced ready|4.195|5.475|6.644|3.756|0.403|
|6|500|normal|12.260|13.745|15.221|1.330|0.400|
|6|500|forced ready|13.572|29.275|30.643|0.903|0.389|
|6|1000|normal|53.113|58.331|63.805|0.310|0.740|
|6|1000|forced ready|54.169|62.755|64.310|0.304|0.743|
|12|100|normal|9.349|11.165|15.370|1.715|1.017|
|12|100|forced ready|10.202|11.062|15.500|1.620|1.116|
|12|500|normal|28.903|35.338|36.153|0.582|1.058|
|12|500|forced ready|30.643|38.093|41.543|0.528|1.134|
|12|1000|normal|51.947|58.824|61.062|0.319|2.023|
|12|1000|forced ready|56.022|63.414|63.542|0.298|1.091|

Every fixture retained all requested actors, with zero admissions and zero kills. Full pools skipped23 normal arrivals and one arrival from each of the six special streams over23 total ticks; at one ring the Tunneler stream is also ineligible. The six-ring and12-ring1000 fixtures each have143 normal/Foundry/Transfer/Sapper/Breacher/Assembler plus142 Tunnelers (71burrowing,71surface attack). They retain334 assimilated actors; initial200 stunned actors fall to9 at six rings or0 at12. Forty-seven Transfers actually hop. No fixture contains roaming Tunnelers. All rows record a single measured shared-route rebuild at topology sample10. Hit counts span0–94 at one ring,0–82 at six and0–73 at12; per-sample arrays remain in the log. Forced-ready mode deliberately resets cooldowns before each step and is not ordinary cadence.

These are20-sample headless costs of durable normalized fixtures, only one-third simulated second after warmup. For1000 actors, even one-ring medians exceed16.667ms; six/12-ring cases consume roughly0.3× real-time in the timed step workload alone. This is an observed shortfall, not a recommended cap or a cause diagnosis. Variation is visible, including a six-ring500 forced-ready p95 of29.275ms despite13.572ms median. Root subsequently identified this same workstation from the registry as Intel Core i7-14700K, with .NET ProcessorCount28 and Windows OSVersion10.0.26200.0. Luna native GL logs identify NVIDIA RTX4080/driver610.88. CIM memory inventory was denied, so memory remains unverified. These are local workstation observations, not controlled laboratory conditions; the probe itself is headless. Rendering/UI/input/disk recording are excluded; wall command cost is separately shown and its next-step rebuild is included. Final rendered evidence belongs to Luna. No optimization, actor reduction, cadence change or new baseline was performed.


