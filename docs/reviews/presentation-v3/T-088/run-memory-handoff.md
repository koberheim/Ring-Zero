# T-088 isolated run-memory helper

Stream D / Luna, 2026-09-09. Implements the isolated preparation lease only. No existing view/source, simulation, reward, profile, audio or asset file changed. Native capture and result-screen integration remain pending the full D lease.

## Consumer interface

`src/presentation/ui/run_memory.gd` extends RefCounted and has no tree, filesystem or gameplay dependencies. Create one instance per application and reset it explicitly on each actual run/practice start.

```gdscript
reset(run_id: String, practice: bool = false) -> bool
observe(seconds: float, radius: int, state_id: String) -> bool
capture_ticket() -> Dictionary
supply_capture(ticket: Dictionary, captured_state: Dictionary, pixels: Image) -> bool
finish(outcome: String) -> bool
snapshot() -> Dictionary
peak_image() -> Image # null when the actual peak has no accepted image
```

`reset` requires a nonempty run ID of at most256 characters; invalid resets preserve the current run. It increments the local capture epoch and clears prior history/image/result state. `observe` accepts finite nonnegative actual elapsed seconds, nonnegative integer actual radius and nonempty state identity of at most256 characters. Time can stay equal for same-tick commands, but cannot move backward. Invalid observations do not mutate the memory. State identity should fingerprint the exact visual fortress state including simulation tick and topology/occupants; it is supplied by the future host, not inferred here.

Each accepted observation gets `{epoch:int, sequence:int, seconds:float, radius:int, state_id:String}`. `capture_ticket()` returns an isolated copy of the latest observation only while it is at the observed maximum radius and no peak image has been accepted. It returns `{}` when a peak image is unavailable and the current fortress has already shrunk; it never relabels a lower-radius view as peak.

The host must retain the ticket, await the actual rendered viewport frame, then supply both actual frame pixels AND the observation identity of the state that frame rendered. `supply_capture` requires the ticket, actual rendered-state dictionary and latest observation to be identical, including epoch/sequence. A changed tick/state, new peak or reset rejects the delayed capture. Rejection leaves an honest image-unavailable state. The host can request again at a current peak, but must never copy the request identity into `captured_state` without checking the rendered state. Helper tests establish identity policy; only the later native host evidence can establish that pixels match the identity.

When a higher radius is actually observed, the older lower-peak image is discarded. If the same highest radius occurs later, a valid capture then still depicts a genuine peak-radius fortress; `image_identity` stores its exact time/state separately from `peak`, which records the first observed global maximum. This makes later equal-height captures honest without claiming they occurred at the first peak moment.

`finish` accepts the existing outcome vocabulary victory/defeat/abandoned/error/practice, is idempotent for the same result and rejects conflicting results. Subsequent observations are rejected. The host supplies its actual terminal observation before finish; finish never manufactures a900-second endpoint or reward. A terminal after-draw capture may still be accepted when its actual identity matches the final observation. Empty runs stay `has_data=false` even after finish.

`snapshot` returns isolated metadata and samples: run_id, practice, outcome, has_data, samples, latest, peak, has_peak_image, image_identity, history_reduced. It does not embed pixels or retain an outcome/reward dictionary. `peak_image` returns an independent Image copy so neither incoming nor outgoing pixel mutation alters retained memory.

## Bounded truthful history and image

Provisional D-134 presentation values: sample ordinary unchanged-radius history at most once per1.0 seconds, always record a changed radius immediately, retain at most256 chart samples including the actual latest endpoint. Online reduction removes the smallest-area interior sample while protecting the first sample, latest retained sample and exact observed global maximum. All retained samples are actual observations with their original identities. The chart is reduced and `history_reduced` exposes that fact: it does not guarantee retention of every minor local excursion. Do not present reduced line segments as exact per-tick trajectories. The current final endpoint is appended from the actual latest observation even between regular sample times.

Retain at most one RGB8/RGBA8 image, with no mipmaps, dimensions at most4096 each and area at most3840×2160. This bounds retained pixel bytes to33,177,600 (31.64MiB) for RGBA8. Copies temporarily used by the caller are outside retained helper storage; the host should request the result image once and release it when leaving results. The limit admits native1920/2560/3440 captures and3840×2160, and rejects oversized/HDR/mipmap images without resizing them. Native capture may convert the actual viewport readback to RGBA8 before supplying it; it must not upscale evidence.

## Verification status

`tests/presentation/test_t088_run_memory.gd` covers empty history, invalid/oversized IDs and time/radius, exact capture identity mismatch, stale/new-peak/reset tickets, pixel copy isolation, mipmap rejection, bounded changing-radius history, actual endpoint/global-peak preservation, actual sample identities, snapshot isolation, immutable finish and practice reset. Samples and red/blue test images are explicitly diagnostic inputs, not natural-run evidence. B's coordinated full-suite checkpoint will import/run the new suite; D has not launched Godot in this preparation lease.

| Gate | Status |
|---|---|
| Isolated helper and focused behavioral suite implemented | READY for engine execution/review |
| Source/control lease isolation | PASS; new helper/test/docs only |
| Godot parse/runtime test | PENDING coordinated B suite |
| Actual after-frame image/state verification | PENDING full D native hook |
| Results composition, real-run graph/peak and human acceptance | PENDING later T-088/T-093 |

Frozen source SHA-256: helper `46c58e6f80834635a38dbf24cc67b9524b662f53ce3b1d1c898b664d993fa800`; test `92fd26cf7abdf97c424aad0845e14123391149132c9900535704c9909ac77e1d`. No commit or planning-log edits by this owner.
