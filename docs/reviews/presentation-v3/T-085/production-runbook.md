# Prepared production workflow — no source admitted

The 12 source prompts in `production-recipes.json` are ready for the next legitimate free session. They are candidates, not generated assets or promises that a music model can isolate convincing effects. Six cover the shared D-minor score; six cover mechanical/percussive source material. Use an auditioned passage, not its prompt label, to decide which event it can support. Stable Audio stays gated by exact eligibility/host terms.

The last official ACE-Step attempt exhausted anonymous ZeroGPU quota. Do not run submission now. Recheck actual current model, API schema, output terms and free quota after legitimate reset; retain that evidence in a new review copied from `session-review-template.json`. Its false fields intentionally block the runner. The approximate reset timestamp in the handoff is an estimate, not proof of renewed quota. No account, proxy, alternate identity or paid credits are part of this workflow.

## Commands

Run from repository root with Python and the official Gradio client 2.6.1 directory already prepared during this task. Preparation is offline:

```powershell
python scripts/audio/prepare_production.py --recipe menu --out docs/reviews/presentation-v3/T-085/menu-request-01.json
python scripts/audio/run_production_batch.py --client-directory "$env:TEMP/ringzero-t085-gradio-client" --session-review docs/reviews/presentation-v3/T-085/session-review-NEW.json --request docs/reviews/presentation-v3/T-085/menu-request-01.json
```

The runner verifies review fields before constructing a client. It submits one request, stops on the first timeout/quota/error, and also stops after a completed response so the actual output can be inspected. No repeated attempts, automatic reset wait or automatic source downloads occur. Prepared queue order is menu, run_low, run_pressure, run_climax, assembler, outcomes, dry_metal, heavy_mass, electrical, fracture, servo, warning. Each source costs scarce free quota; inspect usefulness before advancing. The retained first pilot shows that shorter requested music duration did not reduce the host's requested 180 GPU seconds.

Preserve successful response metadata, exact host-returned download URL and original lossless file under `assets/audio/source/t085-production/`. Verify that URL belongs to the expected host/download service before retrieval, retain generation time/prompt/seed/model/exposed revision, file SHA-256, sample rate/channels/duration and exact license snapshots. A Space revision is not a model-weight hash. Never mark commercial or download verification from a successful response alone.

Copy `mix-recipe-template.json`, replace its missing source and false checks with actual evidence, and choose trim boundaries after audition. The template deliberately fails while no original exists. FFmpeg and FFprobe were found at `E:/FFmpeg/`. The helper uses trim, reset timestamps, highpass, gain, fades, delay, summed layers and EBU R128 true-peak measurement, according to the installed FFmpeg filter help and [official filters documentation](https://ffmpeg.org/ffmpeg-filters.html). Gain/fades are explicit in the recipe; there is no hidden normalization or limiter.

```powershell
python scripts/audio/prepare_mix.py --recipe docs/reviews/presentation-v3/T-085/mix-recipe-NEW.json
python scripts/audio/prepare_mix.py --recipe docs/reviews/presentation-v3/T-085/mix-recipe-NEW.json --render
```

Default prints commands after verifying preserved sources and terms files. `--render` creates a new **unadmitted float WAV** in evidence, never overwrites originals or modifies the runtime bank. Float export retains overload for measurement; lower recipe gains and render a new candidate if true peak exceeds the provisional -1 dBTP ceiling. Inspect the EBU measurement log in the adjacent provenance JSON. Music target begins at approximately -22 LUFS integrated; short effect LUFS can be unstable and must not be blindly normalized. Measure full mixed gameplay separately. After peak/listening approval, export SFX/UI to PCM WAV and music/ambience to suitable looping WAV/OGG, retaining export command and final hash. 48 kHz delivery does not increase original fidelity.

## Coverage and editing direction

| Event families | Source/edit direction |
|---|---|
| Flak fire/hit | Short dry crack clusters / scattered gravel tail; 3–5 separate cuts each |
| Mass driver fire/hit | Capacitor snap plus heavy recoil / dense low metal impact |
| EMP fire/hit | Rounded electrical pulse / descending ionized texture |
| Lance fire/hit | Narrow bright cut / brief hot hiss with a short hard contact |
| Point defense fire/hit | Small precise ticks / tiny sparks; quieter and shorter than flak |
| Standard/elite/boss destruction | Increasing distinct debris mass; no reused structural-collapse identity |
| Wedge fracture / ring collapse | Short stressed break / long multi-layer cascade with low mass; separate motifs |
| Tunneler/transfer/foundry/breacher/sapper arrivals and mechanics | Individual servo, displacement, press, fracture and electrical motifs; mechanics shorter and clearer than arrival |
| Assembler arrival/mechanic | Three-stroke heavy assembly motif / concise press-and-lock response |
| Relay/power/core warnings | Distinct rising/falling and repeated mechanical warning contours, center pan for global state |
| Build/repair/reclaim/denied and UI | Small latch/tool contacts; restrained confirm/back separation; no threat-like hover |
| Solar flare/EMP/reverse | Electrical source with separate broad sweep, abrupt pulse and reversed gesture |
| Victory/defeat | Restrained tonal recovery / machine shutdown; separate from collapse |
| Five music states and machinery ambience | Shared tonal identity; audition long passages and manually author seam-safe loops |

Final event definitions, provisional gains, priorities and cooldowns remain in `data/audio/cues.json`; every variant list is still empty. Cutting different regions is preferred to five trivially pitch-shifted copies. Different weapon fire and hit sources must remain recognizable at gameplay mix levels.

## Admission checklist still pending

1. Successful lawful free generation and original download with exact provenance; verify and hash every source before edits.
2. Audition, trim, layer, master and export; retain edit recipes, candidate measurements and final file hashes. Manually verify loops and avoid clipping or unintended vocal/melodic content.
3. Fill runtime source records and variant entries only under a newly coordinated source-write slot; publish admitted/missing counts. Current runtime is frozen for A's aggregate suite.
4. B/D wire actual event facts, transformed screen bearing, music states, pause and independent persisted five-bus controls. Do not equate adapter readiness with complete application wiring.
5. Indexed audition reel, matched native before/after traces, voice/bus/peak evidence, five-minute headphone and fifteen-minute mixed-game review; human blind bearing and weapon identity each at least 9/10. Record failures and named listener results.
6. Integrated 42+ regression suites and native performance. T-085 remains partial until these and all contract gates pass.

Validation of production tooling is limited to Python syntax, offline request preparation and rejection of the intentionally incomplete review/mix templates. No source render, successful generation, native audio or listening pass is claimed.
