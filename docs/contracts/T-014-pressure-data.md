# T-014 - Editable testing pressure data

Owner: Terra. Implement only the approved data foundation; live spawning and growth formulas await a separate handoff. No delegation.

Own data/balance/testing.json, src/gameplay/balance_profile.gd, tests/gameplay/test_balance_profile.gd, docs/balance-data.md, and docs/reviews/T-014.md. Read only these files; existing profile API remains unchanged.

Add required `pressure` object to the profile schema and JSON with these numeric fields: `spawn_per_second: 2.0` (nonnegative), `speed_ring_widths_per_second: 1.0` (positive), `spawn_offset_ring_widths: 2.0` (positive), `stat_increase_per_minute: 0.1` (nonnegative). These are Kevin's approved D-017 TESTING values, not final density. Growth timing/formula and application to existing enemies are deliberately not implemented here. No cap or additional settings. Keep schema_version 1: this is an internal prototype schema expansion without shipped saves. No implicit defaults or fallback numbers in code.

Preserve strict validation, copy isolation, JSON normalization, and override behavior. Document units, temporary status, and the fact that final gameplay targets hundreds/thousands of enemies. Explain that the growth coefficient alone does not define the future formula. Update any hand-authored profile fixture in your owned test as needed.

Done: approved values load, overrides work, negative/nonfinite/type-invalid/missing pressure fields fail clearly, zero spawn rate and zero escalation are valid test overrides, speed and offset require positive values, previous tests pass. Run focused balance tests with pinned E:/Godot/Godot_v4.7.2-stable_win64.exe, workspace APPDATA/LOCALAPPDATA and --log-file. Record results in docs/reviews/T-014.md. Astra reviews source and reruns balance/purchase/weapon consumers before acceptance. Return any dependent fixture issue outside your files rather than editing it.
