# Free online AI audio production plan

**Date:** 2026-09-09. **Owner:** Workstream C / Luna. **Status:** Approved execution plan under D-130/D-135. Generation follows T-085 assignment and source-admission checks; no paid spending is authorized.

Kevin chose free AI audio generation through online tools. Budget is **$0**: no paid subscription, credit purchase, commission, paid API usage or automatic top-up. Generators produce source material; selection, editing, layering, loop preparation and game mixing provide the sound design.

## Verified shortlist and source gate

**Recovery source check - 2026-09-08 local / 2026-09-09 UTC:** [T-085 preparation evidence](reviews/presentation-v3/T-085/source-admission-preparation.md) confirms the official demo pages still report Running on Zero. ACE-Step's source now defaults to XL turbo; its exact model card explicitly permits commercial music. The official Stable Audio SFX choice resolves to `stabilityai/stable-audio-3-small-sfx`, whose attached Community license and additional Gemma terms were inspected. Revenue eligibility, registration/hosted-use applicability, actual loaded revisions and a successful free pilot download remain pending. The Open Zero fallback's current source could not be retrieved, so it is not yet a verified substitute. No generation, asset admission or spending occurred in this preparation pass.

**Live ACE-Step pilot follow-up:** [Attempt evidence](reviews/presentation-v3/T-085/ace-pilot-attempt.md) records one anonymous 20-second FLAC generation request. The live API confirmed initialized XL turbo and accepted an event, but returned `event: error` / `data: null` without audio or an explanation. No download or asset admission occurred; spending remained $0. Current model identity and full terms snapshots are retained; loaded weight revision and successful free download remain pending. Browser control exposed no connected browser. Stable Audio's source gate is unchanged.

| Role | Online tool | Why it is shortlisted | Admission condition |
|---|---|---|---|
| Main music source | [Official ACE-Step v1.5 demo](https://huggingface.co/spaces/ACE-Step/Ace-Step-v1.5) | The page was reachable and reported Running on Zero. The [official model card](https://huggingface.co/ACE-Step/Ace-Step1.5) labels the model MIT and explicitly permits commercial generated music. | Capture the actual model/revision used, host terms, output download format and license at production time; successfully generate/download one pilot at no charge before scheduling the music batch. |
| Main SFX source; alternative music texture source | [Official Stable Audio 3 demo](https://huggingface.co/spaces/stabilityai/stable-audio-3) | Reachable and Running on Zero at planning time; the host exposes music and SFX model choices. | Pin the actual selected model and its output terms. Stability's [Community License](https://stability.ai/license) has an annual-revenue eligibility condition for free commercial use; eligibility must be established before admitting these assets. Do not infer eligibility or assume the hosted service and downloaded weights have identical terms. |
| SFX fallback | [Stable Audio Open Zero](https://huggingface.co/spaces/artificialguybr/Stable-Audio-Open-Zero) | Reachable community-hosted demo using the Stable Audio Open family; suitable for short mechanical source material. | Inspect host source/model selection and terms, then apply the exact underlying model's license. Its host's code license alone does not license generated outputs. The [official model card](https://huggingface.co/stabilityai/stable-audio-open-1.0) documents 44.1 kHz stereo clips up to 47 s and its license. Same eligibility caveat; no assumed rights. |

[Hugging Face's ZeroGPU documentation](https://huggingface.co/docs/hub/spaces-zerogpu) confirms free use of existing Spaces with daily quotas. These are available routes, **not a completed generation test or guaranteed free capacity**. Free queue/quota availability is checked after sign-off. Use available free sessions; record resets/queues and batch over time. Do not buy capacity, evade quotas or create throwaway accounts.

Do not use the commercial Stable Audio website's free tier merely because an open model permits a use; those are different offers. Do not admit ElevenLabs free generations: its [official licensing guidance](https://help.elevenlabs.io/hc/en-us/articles/13313564601361-Can-I-publish-the-content-I-generate-on-the-platform) denies commercial use on the free plan, despite inconsistent marketing copy. Noncommercial-only music outputs likewise cannot become shipping assets.

If the selected free host is unavailable, try the documented free alternative within its terms. If downloads, access or license eligibility cannot be established, report the precise source gate failure to Kevin. That is a source/access decision, not permission to purchase. A paid trial is not the fallback. Existing audio may remain during development but cannot pass final audio acceptance.

## Proposed sonic direction for D-135 approval

The sound should suggest a maintenance intelligence operating enormous tired machinery around a star: low mechanical weight, dry metal contact, electrical strain and an evolving instrumental bed. It should leave room for decisions. No vocals, borrowed melodies, recognizable artist imitation or constant alarm wall.

Music plan: generate 6–8 short candidate passages (roughly 45–120 seconds as the host permits), select a common tonal/tempo family, and edit a coherent 60–120 second menu loop plus a run bed with low-pressure, rising-pressure and last-watch/climax variants. Create a contrasting Assembler layer/treatment and short victory/defeat resolutions. These are musical states tied to existing run/threat facts, not new scripted waves. If separately generated layers cannot align cleanly, use complete crossfaded variants instead of claiming they are synchronized stems.

SFX plan: first generate a small pilot bank for Flak, Mass Driver, metal hit, ring fracture, relay warning and UI confirmation. Review the audible character before generating the rest. Target 3–5 usable variations for each high-frequency family and 1–3 for rare events, with local layering reusing clearly documented source components. Cover all five weapon fire/impact families, standard/elite/boss destruction, elite/Assembler arrivals and mechanic tells, construction/repair/reclaim, denied actions, solar abilities, low core HP, relay loss/restoration, brownout, ring collapse and UI transitions. Distinct mechanism sounds may share raw metal/electrical layers; they must not all reuse one finished shot.

Example source prompts, revised from the pilot results:

- “Isolated heavy industrial electromagnetic launcher, brief capacitor snap, solid steel recoil, short low mechanical tail, one shot, dry recording, no music, no speech.”
- “Large orbital steel ring tearing at several load-bearing joints, sharp initial shear, cascading heavy metal fragments, falling energy hum, four-second cinematic mechanical event, no voices, no background score.”
- “Instrumental science-fiction maintenance station ambience, slow restrained harmonic movement, deep machinery resonance, sparse metallic pulse, tension without a dominant melody, no vocals, seamless passage.”
- “Small physical control latch and warm confirmation tone, precise and quiet, one tactile action, clean transient, no reverb wash, no music.”

These generic prompts contain no repository files or private recordings. They do not request covers or cloning.

## Production and integration

1. At source admission, retain the page/model identity, applicable terms URL/text/date, host, account tier, free quota and evidence of a successful free download. Record any obligations or eligibility limitation. A model being described as open is insufficient.
2. Save raw downloads unchanged under the audio source archive; retain prompt, negative prompt, seed if exposed, duration, model/revision, timestamp and SHA-256. Record rejected candidates and why.
3. Edit locally: trim silence, remove clicks/DC offset, fade ends, isolate transients, layer/select variations and align loops. Keep source sample rate; resample only for a documented engine/export need. Retain lossless masters and compact game files; never claim an upsampled MP3 is original high-resolution WAV.
4. Start with a provisional mix ceiling of -1 dB true peak, conservative SFX gain, and music around -22 LUFS integrated before game-bus adjustment. Measure rather than normalize all cues to the same loudness. Tune ducking, per-family cooldowns, voice limits and pitch ranges under D-134; critical warning priority is tested.
5. C implements buses and event playback in its allowed files. B supplies hit/collapse events; E supplies truthful threat bearings; D exposes settings and current screen state. Cosmetic variation uses a separate RNG from the simulation. Fixed event priority protects collapse/relay/core cues under crowded fire.
6. Preserve offline playback: all accepted files are packaged; the released game never calls an audio generator or needs an online service.
7. Deliver the native cue reel and five/fifteen-minute loopback mixes specified in T-085. Astra reviews; Kevin/designated listener records the required subjective result. Generation success alone is not acceptance.

## Exit

All required events have admitted downloadable assets, provenance and an audible identity; $0 spending is recorded; commercial-use conditions are satisfied; the mix and source acceptance checks pass. Free-tier limits can affect schedule, but they do not lower the listening bar or authorize paid substitutions.
