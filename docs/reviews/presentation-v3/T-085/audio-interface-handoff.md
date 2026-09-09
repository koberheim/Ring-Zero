# T-085 offline audio interface handoff

**Status:** Adapter implemented; source bank and listening acceptance pending. Current bank contains **52 required cue families, zero admitted audio files**. The existing synthesized development sounds remain explicitly labeled by `diagnostics().legacy_development_fallback`; they do not close T-085. No shared view, application, gameplay or settings-storage file was edited.

## Frozen consumer interface

`game_audio.gd` retains `play(kind)`, `apply_levels()` and asynchronous `shutdown()` for existing callers. New calls:

```gdscript
emit_cue(event_id: StringName, screen_pan: float = 0.0, strength: float = 1.0) -> bool
set_music_state(state_id: String) -> bool
set_paused(value: bool) -> void
set_levels(values: Dictionary) -> void
diagnostics() -> Dictionary
```

`emit_cue` returns true only after an admitted cue is assigned a playback voice. It does not certify that a user heard it. Consumers supply existing event facts; C never derives gameplay damage, fires, deaths or elapsed-time state. `screen_pan` is horizontal position in the **current transformed usable map**, normalized to [-1,1]; zero centers a global cue. Inputs are clamped to +/-0.85 audible pan. North/south distinction still requires a visual cue. `strength` is a finite cosmetic gain multiplier in [0,1], with zero silent; it has no simulation consequence.

Event IDs are the keys in `data/audio/cues.json`:

- `weapon.{flak,mass_driver,emp,lance,point_defense}.{fire,hit}`
- `machine.{standard,elite,boss}.destroy`, `wedge.fracture`, `ring.collapse`
- `elite.{tunneler,transfer,foundry,breacher,sapper}.{arrive,mechanic}`
- `boss.assembler.{arrive,mechanic}`
- `relay.{lost,restored}`, `power.brownout`, `core.low`
- `action.{build,repair,reclaim,denied}`, `solar.{flare,emp,reverse}`
- `ui.{hover,confirm,back,toggle,error,transition}`, `outcome.{victory,defeat}`
- `music.{menu,run_low,run_pressure,run_climax,assembler}`, `ambience.machinery`

Music state IDs are `menu`, `run_low`, `run_pressure`, `run_climax`, `assembler`, `silent`. Consumers choose these from current screens and truthful threat/run facts. No timer-driven wave is introduced. Repeating the current state is idempotent; requesting a missing track returns false. Streams must be authored/imported as seamless loops before admission; crossfading is not proof of a seamless source.

`set_paused` stops existing gameplay SFX and preserves music position. UI cues remain available on pause. On scene transitions, stop/cancel old presentation events in the consumer; do not replay events accumulated during pause. Await `shutdown()` before application teardown as existing callers do.

## Buses and voice policy

Master contains Music, SFX, UI and Ambience. Each of 24 SFX/UI players has a private panner bus routed to its cue's category. Private bus names contain the director instance ID and are removed on teardown. Four voices are reserved for priority >=90. Higher-priority events can interrupt lower-priority voices; lower or equal priority cannot steal an occupied voice. Per-family cooldowns replace a global cross-weapon throttle in the authored path. Cosmetic RNG is isolated from simulation RNG and avoids immediate repeat when a family has multiple variants.

Provisional D-134 values: priority100 collapse/core/relay/outcomes; priority85 boss mechanics/wedge fracture; priority60-70 ordinary/elite destruction; weapon fire30/hit40; UI confirm50/hover10. The bank records gain in dB, cooldown in seconds and min/max pitch ratios per family. Critical cues duck music by 7 dB, 35 ms attack, 400 ms minimum hold and 650 ms release. Music crossfades over 1.25 s. These values need authored-source measurement and native listening; they are not final mix acceptance.

`set_levels` accepts capitalized bus keys, linear gain [0,1], with exact zero using bus mute. Existing `apply_levels` maps the saved PCSettings Master/Music/Effects to Master/Music/SFX and currently mirrors Effects to UI and Music to Ambience. **D integration still must expose/persist independent UI/Ambience controls and call the pause/music/event APIs.** C's lease did not include `src/core/pc_settings.gd` or the three shared views. Existing `play("shot")` and `play("breach")` aliases are only historical compatibility; B must replace them with actual weapon and structural event IDs before full bank acceptance.

## Source admission and asset plan

The runtime rejects variant entries without `admitted: true`, an allowed `res://assets/audio/` path, nonempty source IDs and corresponding commercial/download-verified, $0 source records with SHA-256. The asset-production manifest must independently verify hashes, license snapshots and edits; a schema field alone is not legal review. No output is fabricated to fill an empty entry.

Each variant entry will hold `path`, `source_ids` and `admitted`. Each source record will retain prompt, model, actual exposed revision, host, generation timestamp, original path/hash, exact terms evidence, free-session result, commercial-use verification and spend. Preserve raw FLAC/WAV before any edit. Produce 3-5 authored variations per repeated fire/hit family and 1-3 for rare events. Assemble menu, low/pressure/climax, Assembler and outcome music with shared tonal identity; complete crossfaded tracks are acceptable when generated passages do not form aligned stems.

The official client now provides a concrete source limit. `ace-client-original-retry.json`, observed **2026-09-09 03:57:32 UTC**, reports anonymous ZeroGPU quota exhaustion: 180 seconds requested, zero remaining, retry in 23:48:37 (approximately **2026-09-10 03:46 UTC**). No output was returned. The earlier direct call's null error and XL client's timeout remain preserved. No further generation should run before the quota resets under this identity. No account, paid credits, proxy changes or quota evasion were used. Stable Audio remains unadmitted because eligibility/host-applicability is unresolved.

## Verification and remaining work

Godot 4.7.2 headless import exposed one new `pitch` inference error during A's attempted native trial. That invalid trial was retained; the error was repaired by an explicit float type. Subsequent import had no script parse errors. The first import used default editor paths and logged sandbox cache/certificate errors, not a clean OS-environment pass; the narrow test used isolated APPDATA/LOCALAPPDATA under `.godot/t085-profile`.

The new `tests/presentation/test_audio_director.gd` passed **84/84 checks**: saturation/reserved critical voices, preemption, independent family cooldowns, pause/UI policy, pan clamping/NaN, nonrepeating selection, truthful missing-bank reporting, levels and clean headless lifecycle. `audio-test.txt` retains the result and the sandbox certificate-store warning. No native mix, listening result, full regression pass or hardware performance pass is claimed by C. Runtime was then frozen and its hashes sent to A before their retry.

| Required gate | Result |
|---|---|
| Stable event/bus adapter and 52-family asset plan | IMPLEMENTED |
| Narrow headless behavior check | PASS, 84/84 |
| Authored free downloadable sources | BLOCKED by current quota; none admitted |
| Full application event/music/pause wiring and independent saved bus controls | PENDING B/D integration lease |
| Authored master/true peak, native panning/ducking/voice recording | PENDING assets and native capture |
| Five-/fifteen-minute mix, weapon identity and blind bearing checks | PENDING; human gates not asserted |
| Complete 42+ suite regression and native performance | PENDING integrated reviewer runs |

Changed runtime/data paths: `src/presentation/game_audio.gd`, `src/audio/{audio_director,cue_policy}.gd`, `data/audio/cues.json`; narrow test and generated Godot UID sidecars; source diagnostic helper `scripts/audio/probe_ace_step.py`; T-085 evidence and factual audio-plan updates. No commit or planning-log edit was made by C.

## Prepared production handoff

`production-runbook.md` now provides twelve ordered source prompts, per-family edit direction, exact next-session commands and remaining admission gates. `scripts/audio/prepare_production.py` prepares offline requests; `run_production_batch.py` requires a current evidence-backed free-session review and stops after the first result/error for inspection; `prepare_mix.py` verifies local originals and source records before planning or rendering unadmitted float-WAV candidates with EBU true-peak/loudness logs. False review fields and missing-source examples cannot submit/render. No source generation or audio processing occurred during this preparation.

`production-tool-checks.json` records 14/14 limited checks: four Python parses, twelve unique recipe IDs, offline request preparation, rejection before network/render for missing review/source, and six installed FFmpeg filter-help checks. This is not rendered-audio validation. `delivery-manifest.json` records final scoped hashes; older pilot manifests remain historical snapshots. Runtime hashes are unchanged from the release returned to A.
