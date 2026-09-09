# T-092 early silhouette package - human result pending

This is a partial source-art delivery under the crash-recovery lease, based on `a42b7a8fb7cf85cae7f6385b1f0f0a24d310c037` plus disjoint recovered T-086 work. Six depth blockouts and a twelve-trial monochrome review are ready. No shipping assets or application code changed. T-092 is not Done.

Open [the review page](public/index.html) on the reviewer's normal display. Learn the six labeled references, then click **Hide reference and begin twelve trials**. Identify each numbered shape and prepare/copy the answers back to Astra. The page contains no answer key and does not auto-score. It compensates `devicePixelRatio` so each trial occupies 16 physical pixels. Do not magnify the page or use OS magnification; record reviewer name and the display confirmation. If display scale changes during the trial, the result flags it and the reviewer should retake with a freshly shuffled package before scoring. The PNG [reference demonstration](public/reference-demonstration.png) and [unlabeled trial sheet](public/trials-unlabeled-16px.png) are fallbacks only when displayed at native image size, without fit-to-window scaling. Enlarged reference shapes are explicitly labeled 8x demonstrations; no enlarged image is trial evidence.

After all twelve answers are recorded, Astra may compare against `reviewer-private/answer-key.json`. Do not provide that file or the generator's shuffle sequence to the participant beforehand. Pass requires **at least 11/12 correct and no recurrent Tunneler/Transfer/Breacher confusion**, recorded by Kevin or his designated human reviewer. Repeat confusions must be described by direction/class pair. A failure returns to Kevin before detailed production. These instructions do not contact another reviewer automatically.

| Gate | State | Evidence / next action |
|---|---|---|
| Six mechanic-led silhouette candidates | Prepared | `public/reference-demonstration.png` |
| Real 20-degree depth source | Prepared | `clay-depth-blockouts.png`, isolated source `.blend` and source script |
| Twelve shuffled monochrome 16px trials, two/class | Artifact integrity PASS | `artifact-checks.json`; all twelve canvases 16x16, only black/white |
| >=11/12 human identification / confusion check | PENDING | Kevin/designated reviewer answers required |
| Original live Blender file preserved; lease released | PASS readback | Initial/final Scene has only Cube/Light/Camera; active file remained Untitled; release returned true |
| Detailed color/normal/emission/motion production | NOT STARTED | Waits for human gate |
| Native all-bearing/three-palette/mixed-crowd/strategic floor | PENDING | Requires later assets, A/D interfaces and E integration |
| 42-suite / import/export / performance / final crowd acceptance | NOT RUN FOR THIS PARTIAL DELIVERY | No Godot runtime or shipping edits; later integrated acceptance remains required |

The self-review inspected the reference and clay sheets: all six have distinct large-scale blockout form and real side faces. This is an author inspection, **not** a blind human pass. The Tunneler's narrow axis, Transfer's large open gap, solid asymmetric Breacher and broken-ring Assembler are specifically preserved at the prepared floor. Whether the 16px shapes identify reliably is still untested by a human.

Retained `before/` tiles are derived from the current shipping PNG alpha at the same normalization; original T-079 evidence and all shipping PNGs are untouched. Do not use the before tiles as the candidate reference in the new trial. The after source is under `assets/art/source/presentation-v3-elites/`; the 16px sheets are derived diagnostic fixtures, not game output. Camera/pivots, normalization, source identity, deliberate non-applicable simulation fields and outstanding limitations are in `fixture-metadata.json`. `manifest-sha256.json` hashes package/source/tooling files; its own file is excluded from its manifest.

Reproduction:

1. Inspect and claim a live Blender instance. On a new untouched namespace, execute `exec(compile(open(r'E:\AI Projects\Games\Ring Zero\scripts\art\t092_silhouettes_blender.py', encoding='utf-8').read(), 't092_silhouettes_blender.py', 'exec'))` through Blender MCP, then `build()` once. The script refuses an existing v1 scene. Do not overwrite the current file. For another iteration, use a new versioned scene and source output.
2. Re-execute the definitions in each new MCP code call (tool Python globals do not persist). Call `render_class(kind)` and `render_class(kind, clay=True)` for all six `CLASSES`, then `save_source()`. `save_source()` writes only the isolated new scene and dependencies using `bpy.data.libraries.write`, and refuses an existing source path. No active-file save operator is used. Restore/read back original active scene and release the instance. Source renders used Blender 5.2.1 LTS Workbench, 256x256 RGBA, transparent background; no lights or GPU-intensive effects were added.
3. Run `python scripts/art/t092_silhouette_review.py` from repository root. It assembles fixtures on CPU with Pillow; it does not launch Blender/Godot. Keep the private key private when sharing the public folder. A new repeat test should change the shuffle seed and candidate/version labels before generation to avoid memorized ordering.

Executed: live `get_scene_info`; `claim_blender_instance`; read-only state check; source script `build()`; six silhouette and six clay `render_class` calls; `save_source()`; final `get_scene_info`; `release_blender_instance`; `python scripts/art/t092_silhouette_review.py`. Two harmless tool retries are recorded for transparency: an unsupported 1800-second lease request was retried with the default lease; the first multi-render call found that Python globals were not retained, so it made no renders and was retried with definitions reloaded. Both completed successfully. No source model regeneration was necessary after visual inspection.

Bounded provisional values: blockout component heights 0.19-0.82 source units; orthographic camera extent 4.1 units; native render 256x256; review floor 16x16; alpha threshold 128; two trial sprite orientations at 0/180 degrees. These are reproducible silhouette-prototype values, not accepted shipping balance or atlas sizes. The later normals/emission conventions and motion timing are intentionally pending A's interface and the human result.

Changed paths: `docs/art-prompts/presentation-v3-elites.md`; `scripts/art/t092_silhouettes_blender.py`; `scripts/art/t092_silhouette_review.py`; `assets/art/source/presentation-v3-elites/`; this review directory. No commit made; narrowly scoped patch for Astra review. No planning-log edits.
