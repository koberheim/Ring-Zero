# T-024 - Reduce repeated polar motion reconstruction

Owner Sol. Start only when assigned. Own src/core/polar_motion.gd, tests/core/test_polar_motion.gd and docs/reviews/T-024.md. No gameplay, presentation, balance, or clock edits; no delegation. Read owned files and this brief only.

Your T-020 scalar PolarMotion API is accepted and integrated. A sustained1,000-machine angular simulation profile spends about4.116ms per tick inside PolarMotion.advance, within18.579ms total. T-023 is reducing gameplay overhead separately. All public motion inputs still require full validation and documented numerical guards.

Measure the current helper on representative1000 legal angular and radial partial segments, then test axis-specific reconstruction as suggested in your read-only review: preserve unchanged radial coordinates during angular motion, and unchanged angular coordinates during radial motion. Do not weaken representability validation, numerical failure behavior, radial/angle tolerances, endpoint cloning, shortest-arc half-turn rule, physical speed, or input isolation. No Cartesian authority, new gameplay tolerance or trusted-input bypass.

Retain public advance(current,target,speed,delta)->{ok,position,time_used,reached,errors}. Current tolerance-close endpoints validly return exact cloned target/reachedtrue/time0. Core gameplay consumes such endpoints within a finite loop. Failure results remain nonmutating. Stable exact target output on arrival and deterministic wedge/band boundary ownership remain essential.

Verify all prior T-020 tests, plus meaningful equivalence to the prior helper across partial radial/angular motion, seams, arbitrary fractions, split travel, endpoint tolerances, overflow/underflow and unrepresentable progress. Ordinary coordinates should retain or improve documented roundoff limits. Explain any numerical output change and prove it cannot alter legal-cell ownership or target timing beyond existing tolerances. Do not keep an optimization that changes accepted failure semantics.

Use a frozen prior helper only in test instrumentation for before/after comparison, no second production implementation. Report1000-call median/p90 with identical samples and warmup, and allocation/validation limitations. Coordinate the exclusive Godot measurement window through Astra. Pinned Godot4.7.2, workspace caches, hidden tracked processes and bounded waits.

Done when a measured improvement passes the motion tests and Astra reviews it, then Terra/Astra run gameplay consumers and Luna reruns the rendered wall trial. If specialization produces no safe gain, report that and stop; do not expand into gameplay, relax validation or change the simulation cadence.
