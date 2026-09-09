# Astra run-memory preparation acceptance — 2026-09-09

Reviewed isolated bounded history and actual-image identity behavior. Independent headless check passed24/24, exit0, retained in reviewer-memory.txt; the full checkpoint passed47/47 including this final source. Exact old/new-run and rendered-state tickets reject mismatched pixels, reduction preserves actual endpoints/global peak, and no-data/reset/terminal outcomes remain truthful. The only diagnostic was the existing Windows certificate-store warning.

This accepts the helper only. Native capture timing, usable-map cropping, result composition and a real completed-run image/history still require D integration. The host must cache returned image/texture for display rather than copy the retained image each frame. No gameplay, rewards or source audio changes belong in this helper.
