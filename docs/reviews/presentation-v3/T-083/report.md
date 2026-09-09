# T-083 early collapse delivery — partial

The committed-event adapter and early visual slice are implemented. Whole-ring loss now separates retained thin band segments, open trusses, hardware and wall modules, with a pressure flash, depth, decaying impulse and persistent structural gap. A broken wedge remains distinct. **This is not full T-083 acceptance.** Human comprehension, authored sound, integrated final-core results and the dense performance failure remain open.

Reviewed base: A `c76a45c`, C `5308bd7`, subsequent disjoint art/docs commits through `f8411ff`. Runtime source hashes are in the final manifest. Native tool: Godot4.7.2 stable official ed1daf0bf, Forward Mobile, RTX4080/NVIDIA610.88. Capture2560×1440, UI1.0, camera origin, zoom1.3, yellow palette, seed83083; exact actual ticks and actor counts are in each sequence JSON. Profiles are isolated under `.godot`. Windows certificate-store warning and explicit missing-audio development warning persist; neither is concealed.

## Checks

| Gate | Result |
|---|---|
| Successful original tick, occupant removal, no refund, outer-ring survival, pre-state immutability | PASS narrow native |
| Failed tick rejection, duplicate event rejection, multiple ticks per draw | PASS |
| Actual slot_count/high slot and twelve clock-face bearing alignment | PASS |
| Open band/truss geometry, standing walls and hardware copies | PASS technical; native self/reviewer inspection |
| Pause/expiry/retry reset, reduced motion and effects-off persistent loss | PASS narrow; reduced/off native sequences |
| Regression suite | PASS47/47, clean import, `run-20260909-042647-168-31964` |
| T083 native behavior | PASS40/40 |
| Matched RC2/current-A/new native motion | Captured, timestamped; at least1s before and3s after actual events |
| Canonical timing after integration | Two samples PASS; final repeatability matrix remains T093 |
| Actual bounded high-ring collapse25 hardware/140 walls | Diagnostic16.684/17.419/19.361ms median/p95/max, ratio.993678 |
| Actual dense high-ring collapse120 hardware/140 walls | **FAIL: max111.127ms, p9519.821ms**; diagnosis/repair pending |
| Blind muted comprehension | PENDING human; public playback prepared |
| Authored collapse audio/native listening | PENDING C source bank (zero admitted sources) |
| Production final-core transition after world effect | PENDING T088/T084 integrated flow; diagnostic deliberately held world visible |

Native narrow command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File docs/reviews/presentation-v3/T-083/run-probe.ps1 -ProjectPath . -Label reviewer-native -Script res://tests/presentation/test_t083_collapse.gd`.

Sequence command uses `-Script res://tests/presentation/capture_t083_collapse.gd -EvidenceDirectory res://<separate-output>`; optional `-Mode reduced`, `off`, or `blind`. Do not overwrite retained owner evidence. Native sequences are diagnostic initial HP/contact/structural states followed by real unaccelerated fixed-step events, not ordinary-session playthroughs. The final-core fixture disables application `_process` only to keep three seconds of world aftermath visible; no claim is made about production results flow. Blind fixtures hide only the answer-giving feedback label and retain the actual native world/HUD. `public/index.html` plays the blind captures at their measured timestamps; no answer is submitted automatically. Machine/self inspection is not a blind human result.

`before-rc2` is literal `ebeaf72` Compatibility source from the existing untouched archive, with only this task's diagnostic capture harness copied into its test directory; its renderer was not changed. `before-a-valid` is reviewed A/Mobile plus the legacy collapse visuals. `after-corrected` is the corrected new normal sequence, and `after-reduced`, `after-off`, `blind-native` are separate native variants. Matching case/seed/state does not erase the documented RC2-vs-Mobile lighting difference.

## Failures retained and repairs

Initial capture script had two Variant inference parse errors (`before-a` log), repaired with explicit types. First runtime capture polled last_events once per frame and missed events across multiple fixed ticks (`before-a` directory, before-a-02 log); per-tick capture callback repaired this (`before-a-valid`). No passing motion claim uses that failed sequence.

Initial new geometry (`after-normal`) passed runtime checks but was visually rejected: it filled a whole annulus, used incorrect slot fallback and half-wedge angle, and did not draw retained walls. Root review returned those issues. Corrected geometry derives center from PolarGrid, uses real slot_count, preserves thin bands/open rails/textured hardware/wall modules;40 native checks include all12 bearings and high-slot positions. The rejected sequence remains intact. A narrow test's untyped snapshot parse error (`native-test-01`) was repaired before subsequent40-check pass.

Timing probes ran under root-coordinated all-owner idle/source freeze. Probe-only repairs occurred between runs while other owners remained idle; runtime source did not change. `canonical-01` =16.671/17.726/19.175ms, ratio.997916; `canonical-02` =16.694/17.435/19.108ms, ratio.998562. Both retain the original12 rings/128 actors/zoom.41/60 warmup/180 measured/vsync fixture. Limits remain18.3348/18.4360/20.3379ms and ratio>=.99.

`collapse-load-01` failed setup because all weapon placements exceeded real ring power;15 hardware were admitted. `collapse-load-02` failed setup because armor stacking is capped;25 admitted. `collapse-load-03` had valid120 hardware placements but no collapse: repair nodes heal their ring's most-damaged wedge. These are rejected diagnostics; all errors and numbers remain. `collapse-load-04` used a1.1-second stunned high-damage attacker to overcome that healing and produced a real tick67 collapse with120 hardware,6 sectors and140 wall modules: median16.633ms, p9519.821ms, max111.127ms, max simulation callback25.921ms, ratio.998043. **The spike remains unresolved; it must not be averaged away or described as fixed.** Its exact original runtime source was not snapshotted at launch; the saved probe variant reproduces the recorded fixture from the edit trail and is labeled accordingly.

At root's direction the final bounded probe uses only legal three-Flak/two-armor occupancy on each of five standing high-ring sectors, original6DPS attacker and no repair nodes. It prevalidates commands/state before timing. `collapse-load-05` passed its actual-event/count assertions, retaining25 hardware/140 walls/6 sectors at tick68. It is useful bounded evidence, not a replacement for the dense failure or a maximum-cap stress acceptance. Diagnostic output is flagged separately from the unchanged canonical fixture. The runner's inherited diagnostic sentence calls it “uncapped”; this is imprecise generic wording—the actual collapse diagnostic retains vsync and is **not** uncapped.

No screenshot, PNG save or image readback occurs inside either timed probe. Dense failure attribution still needs controlled profiling; source inspection alone does not prove it was shader compilation, cache rebuilding, geometry copy or repair-node simulation.

Collapse-load fixture overrides are explicit: release profile with pressure spawn rate0, Flak damage0 and power base_output1800; public purchases fund twelve rings from an initial1e9 energy fixture. Six ring12 wedges start broken, wedge7 starts at6.7HP, five surviving sectors receive public hardware/wall placements. There are128 externally seeded diagnostic actors with1e9HP: one boundary attacker and127 nearly stationary actors (speed.00001 ring widths/s, zeroDPS). The normal boundary attacker uses6DPS and speed1; dense04 alone used1.1s initial stun and1e7DPS to overcome95 real repair nodes. Current bounded05 uses15Flak+10armor; dense04 adds95RepairNodes. These setup overrides do not change production data or prove a natural playthrough.

`probe-variants/load04-reconstructed.gd.txt` is a rerunnable reconstruction from the recorded tool edit trail for later profiling, not a falsely claimed original launch snapshot. Copy it to a new `tests/performance/` script path under the coordinated runtime lease and run through the same wrapper. `load05-frozen.gd.txt` is an exact copy of the final bounded probe before downstream view edits. Invalid01–03 have complete logs/commands but no original source snapshots; their differences and failed constraints are enumerated above. The preparation helper regenerates the reconstructed04 variant from bounded05, with assertions around replacements.

D's isolated T088 source/tests reached their final hashes at04:26:34UTC; the47-suite runner reached D's test at04:27:35UTC. It therefore tested the final files (24/24); E's2690/2690 also passed. The diagnostic probe alone changed after full suite; every final probe parsed and executed natively. Production source remained identical to the47-suite tree.
