# T-012 — Astra acceptance

**Date:** 2026-09-06. **Status:** Accepted as an engine foundation and measurement result.

Reviewed pool/clock source, focused tests, benchmark fixture, measured logs, and report. Reusable record identity, stale-ID rejection, count consistency, equal/unequal time partitions, and pause behavior match the contract. Requested callback-triggered pause handling; Sol corrected it and verified that no remaining paused time catches up on resume. Final focused suite passes.

The 500/1,000/5,000 benchmark used the same eleven-Flak, durable band-2 target fixture with three warmups and ten samples, rendering absent. Ready-volley medians were 8.862, 18.784, and 106.597 ms. Pool operation costs were much lower. CPU inventory was unavailable; prior renderer identified RTX 4080, which does not make this a GPU benchmark.

Accepted the modules and the reported performance concern. T-013 addresses repeated targeting computation under the unchanged behavior/API. No live capacity, complete-game FPS, or completed Phase 2 loop is established by T-012.
