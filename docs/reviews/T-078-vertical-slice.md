# T-078 vertical slice — review required

The file pipeline runs, but the production acceptance gate does **not pass**. Five generated assets have been normalized, imported, and rendered in Godot. The standard machine fails strategic visibility and dense-crowd separation. Exact band tiling and physical albedo are also unresolved. Live rendering integration is absent, so the diagnostic fixture cannot establish production placement or relighting acceptance. No later production assets were generated.

Repository pull: already up to date on 2026-09-08. The two requested briefs were read in full before generation. Locked v1 templates were left unchanged. Generation used the built-in image tool, one call per asset/attempt, with the approved anchor as a reference. Exact expanded prompts plus appended reference/correction notes are in [generation_manifest.json](../../scripts/art/generation_manifest.json).

## 1. Generated and normalized files

All paths below are repository relative. These are review candidates, not production-approved assets.

| Asset | Raw output | Normalized output | Size |
|---|---|---|---|
| Working band | [assets/art/source/band_working_01.png](../../assets/art/source/band_working_01.png) | [assets/art/bands/band_working_01.png](../../assets/art/bands/band_working_01.png) | 1024×128 |
| Decal sheet | [assets/art/source/decal_sheet_01.png](../../assets/art/source/decal_sheet_01.png) | [assets/art/decals/decal_sheet_01.png](../../assets/art/decals/decal_sheet_01.png) | 1024×1024 |
| Mount | [assets/art/source/building_mount_01.png](../../assets/art/source/building_mount_01.png) | [assets/art/buildings/mount_01.png](../../assets/art/buildings/mount_01.png) | 256×256 |
| Mass Driver head | [assets/art/source/head_mass_driver_01.png](../../assets/art/source/head_mass_driver_01.png) | [assets/art/buildings/head_mass_driver.png](../../assets/art/buildings/head_mass_driver.png) | 256×256 |
| Standard machine | [assets/art/source/machine_standard_01.png](../../assets/art/source/machine_standard_01.png) | [assets/art/machines/machine_standard.png](../../assets/art/machines/machine_standard.png) | 64×64 |

Two additional generated decal attempts are retained:

- [assets/art/source/decal_sheet_01_rejected_attempt_01.png](../../assets/art/source/decal_sheet_01_rejected_attempt_01.png): sensor was rendered obliquely. The tool preview appeared to have a shaded backdrop; later pixel inspection established that the empty-space alpha was zero. It was **not** actually rejected for an opaque background.
- [assets/art/source/decal_sheet_01_rejected_attempt_02.png](../../assets/art/source/decal_sheet_01_rejected_attempt_02.png): sensor still oblique and pipe had only one elbow. Third attempt supplies an end-on sensor and two-elbow U-pipe.

Reusable tooling: [scripts/art/normalize_asset.py](../../scripts/art/normalize_asset.py), [normalization_manifest.json](../../scripts/art/normalization_manifest.json), and [test_normalize_asset.py](../../scripts/art/test_normalize_asset.py). Raw sources have `.gdignore` and are explicitly excluded from export.

## 2. Anchor

Used the already-approved [assets/art/anchor/anchor_approved.png](../../assets/art/anchor/anchor_approved.png), unchanged. D-125 identifies this as `anchor_v2_02.png`: candidate #4's approved design regenerated at the corrected angle, chosen for its flattest, most shadowless lighting. Wear, panel density and palette follow that reference; its achieved camera is the practical target. The mount and head were generated independently, never cropped from the fused anchor.

## 3. Five review checks per asset

**Scope:** these are observed outcomes in the labelled T-078 diagnostic overlay inside `scenes/art_preview.tscn`, not passes for the missing live gameplay paths. PASS means the stated property was visible in that fixture. FAIL (blocked) means the required contextual check cannot be established. N/A is used only for categories excluded by the brief.

| Asset | Close | Strategic | Yellow star | Crowd | Rotations / seating |
|---|---|---|---|---|---|
| Working band | **PASS** — deck, truss and seam lights read | **PASS** — strip remains visible | **PASS** — neutral steel/amber complements corona | N/A | N/A |
| Decal sheet | **PASS** — eight separate industrial details | **FAIL** — individual motifs become indistinct specks | **PASS** — small warm accents remain subordinate | N/A | N/A |
| Mount | **PASS** — bare socket/collar and armoured base read | **PASS** — circular mount mark survives; detail does not | **PASS** — grey hull and sparse amber stay distinct | N/A | **FAIL (blocked)** — no live tilted ground placement/depth to validate seating |
| Mass Driver head | **PASS** — twin rails read as heavy weapon; composite fits provisionally | **PASS** — paired-rail mark survives; fine detail does not | **PASS** — no competing cold colour | N/A | **FAIL (blocked)** — no live mount/head attachment and tilted-plane rendering |
| Standard machine | **PASS** — maw, blunt hull and vanes read at 64 px | **FAIL** — approximately 2.2 px at trial strategic scale, effectively vanishes | **PASS** — matte dark silhouette contrasts with the bright limb | **FAIL** — vanes and hull outlines merge in dense overlap on grey decking | **FAIL (blocked)** — no live sprite transforms or tilted-ground placement |

Evidence: [close](artifacts/T-078-close.png), [strategic](artifacts/T-078-strategic.png), [yellow star](artifacts/T-078-yellow.png), [crowd](artifacts/T-078-crowd.png), [all twelve bearings](artifacts/T-078-rotations.png). These are actual 1440×810 GPU captures from Godot 4.7.2, Compatibility renderer, RTX 4080.

The close page shows export pixels (the machine also has an explicitly labelled 3× enlargement). The minification page uses provisional world widths: band 256, whole sheet 128, mount 32, head 43, machine 8. It compares close zoom 1.55 with the existing 12-ring strategic formula, `810 * 0.42 / 1248 = 0.273`. These are diagnostic sizes, not an approved gameplay scale contract; individual decal sizes/placement and machine minimum-screen-size handling remain unresolved.

The star page reuses the actual `sun.gdshader`, palette 1, frozen phase 0. It includes a segmented polar-UV band sample, the sheet and eight individual decal regions, plus all objects. No artificial relighting is used. The crowd contains 1,000 textured quads in one MultiMesh: 500 spaced copies and 500 genuinely overlapping copies on working-tier grey. This establishes a visual crowd failure, not a throughput benchmark.

The rotation page renders all three object assets at 12 outward bearings using `bearing - PI/2` because their front is source +Y. In this flat fixture, none shows a gross hero-shot lean; all face outward coherently. However, a flat screen-space dial cannot prove correct seating on the missing tilted ground plane. The blocked failures above deliberately do not turn that observation into a production pass.

## 4. Standard-machine emissive check

**Passed on the first generated attempt; no machine regeneration.** Immediately after normalization, `assets/art/machines/machine_standard.png` itself was opened and visually inspected. It was inspected again after fixing background alpha extraction. There are no windows, running lights, glowing seams or coloured accents; only matte dark hull variation. No hue removal, light painting or machine-specific darkening was used to conceal an emissive failure. Opaque normalized pixels have maximum RGB channel 109/255 and maximum channel spread 6/255; these figures support, but do not replace, the visual inspection.

The earlier mockup failure in D-124 is historical and is not counted as an attempt in this slice. The two regenerations in this task were both decal-sheet attempts.

## 5. Where the pipeline works and breaks

**Prompt → generate:** works with iteration. The anchor gives coherent materials and facing, and independent modular sources were produced. Flat decals required two corrections. The band misses the template's exact seamless-repeat condition: its normalized left/right boundary differs by mean 3.01 and maximum 85 byte values across RGBA. It looks repetitive at normal preview size, but is **not accepted as perfectly seamless**. Normalization repeats the source three times to reach the 8:1 target without crushing each panel horizontally; it does not hide or repair the boundary mismatch.

**Normalize:** fixed dimensions, explicit pivots, alpha extraction/preservation, resampling and reproducibility work. The script applies bounded, alpha-weighted low-frequency illumination suppression (strength 0.35, gain limited to 0.85–1.15). It **does not recover physical flat albedo**: recessed AO, bevel highlights and baked amber light remain in the building/decal sources. Full dynamic relighting/brownout acceptance therefore fails at this boundary until there is better flat source material or a reviewed material/emissive separation workflow. It would be inaccurate to call these clean albedo maps.

Pivots are reviewed estimates in source pixels: mount projected ground centre `(627,617)`, machine ground/support centre `(627,650)`, head attachment axis `(627,440)`. They map to each export's canvas centre. Ground contact in this near-overhead view means the footprint's projected centre, not the bottommost silhouette pixel. The fixture's composite puts the head on the mount socket, offset about 100 source pixels upward from the ground centre. The manifest records scales and offsets for later integration; the estimates still require production seating review.

PNGs use straight alpha for Godot's default CanvasItem blend. Resizing is internally premultiplied to avoid black fringes. This intentionally resolves the older pipeline document's premultiplied-PNG instruction in favour of correct default engine blending; no premultiplied material path exists. All five imports use lossless compression, mipmaps and alpha-border fixing; the fixture uses linear mipmap filtering. The small band is also lossless for this review. Live angular repeat configuration remains part of the missing band renderer.

**Import → diagnostic review:** works. All five normalized files are referenced from a review fixture in the existing scene, rendered on the GPU, and captured. Four normalization regression checks pass. Existing art-preview tests pass **59/59** after the final fixture edits. Final capture log contains all five saves and no script errors. Headless Godot emitted an unrelated root-certificate-store warning; it did not prevent import or the tests.

**Import → live production review:** blocked at these precise paths:

- `art_preview.gd::_draw_board()` still renders wide procedural plates and panels; it has no authored working-band angular UV/repeat path, thin-band/spoke integration, or individual atlas-decal placement.
- `art_preview.gd::_draw_occupant()` still draws procedural shapes and strategic circles; it has no shared mount plus head sprite composite, attachment transform, authored outward-facing placement, or production size/LOD contract.
- `live_view.gd::_create_machine_markers()` builds circle/triangle ArrayMeshes; `_update_machine_markers()` supplies fixed-size marker transforms. It has no textured-quad machine class path, sprite-facing transform, or sprite visibility treatment at strategic zoom. The preview additionally tints those old markers red. The new crowd fixture does not replace this system.
- The live board's tilted-plane/depth placement and dynamic material/emissive relighting needed to validate source camera lean, shadows and brownout behaviour are absent.

TASKS.md explicitly places the sprite prerequisites inside T-074/T-075; T-080 governs the camera, and T-079 remains dependent on T-078 passing. These engineering tasks were not implemented as part of this art slice. No planning logs or locked templates were changed.

**Decision:** do not advance to the remaining production assets. The generation/normalization/import mechanics are reusable, but the band boundary, albedo limitation, machine visibility/crowd failures and missing live renderer prevent an end-to-end production pass.

## Reproduce

1. Install Pillow and numpy in the Python environment, then run `python scripts/art/normalize_asset.py --slice` (works from any working directory). Run `python scripts/art/test_normalize_asset.py` for the four regression checks.
2. Import the project in Godot 4.7.2. Run `scenes/art_preview.tscn`; press **F3**, then **1–5** for the five review pages. The overlay is authored at 1440×810. F3 returns to the unchanged live renderer.
3. GPU capture command: `Godot_v4.7.2-stable_win64.exe --path . --resolution 1440x810 --script tests/presentation/capture_vertical_slice.gd --quit-after 120`. This must use a graphical renderer, not headless mode. It writes the five evidence PNGs listed above.
