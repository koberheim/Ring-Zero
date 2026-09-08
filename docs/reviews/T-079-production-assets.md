# T-079 remaining production assets — review required

All **20 requested subjects were generated, normalized, imported and reviewed** in the existing Godot art-preview scene. There are **23 raw outputs**, including three retained rejected attempts, **20 normalized review candidates**, and **32 GPU evidence captures**. **The production acceptance gate does not pass.** All six final elite/Assembler assets pass the specific one-cold-accent check, but the elite set fails strategic identification and reliable separation in a mixed swarm. Several structure/terrain sources also fail their requested physical read.

Repository pull: already up to date on 2026-09-08. T-078's review, every v1 template section 1–26, and the pipeline were read in full before generation. The style guide was also read. T-078 actually reports a failed production gate, rather than an approved slice; this pass proceeds under the user's explicit instruction to generate and review the remaining subjects. It does not retroactively approve T-078.

Generation used the built-in image tool, one call per asset/attempt. [Exact expanded prompts and rejected-attempt history](../../scripts/art/t079_generation_manifest.json) preserve the unchanged common/camera blocks, section-specific subjects, and appended reference/correction notes. The approved anchor was referenced throughout. The six horde assets also reference the existing standard-machine source for its matte hull family, with an explicit override requiring one cold accent.

## 1. Generated and normalized files

These are **review candidates, not production-approved files**. Normalization of a failed source is retained to make its failure inspectable in context; it is not an acceptance decision.

| Asset | Raw output | Normalized output | Size |
|---|---|---|---|
| §7 Hot band | [assets/art/source/band_hot_01.png](../../assets/art/source/band_hot_01.png) | [assets/art/bands/band_hot_01.png](../../assets/art/bands/band_hot_01.png) | 1024×128 |
| §8 Cold band | [assets/art/source/band_cold_01.png](../../assets/art/source/band_cold_01.png) | [assets/art/bands/band_cold_01.png](../../assets/art/bands/band_cold_01.png) | 1024×128 |
| §9 Damage sheet | [assets/art/source/damage_sheet_01.png](../../assets/art/source/damage_sheet_01.png) | [assets/art/decals/damage_sheet_01.png](../../assets/art/decals/damage_sheet_01.png) | 1024×1024 |
| §10 Flak | [assets/art/source/head_flak_01.png](../../assets/art/source/head_flak_01.png) | [assets/art/buildings/head_flak.png](../../assets/art/buildings/head_flak.png) | 256×256 |
| §11 EMP Node | [assets/art/source/head_emp_node_01.png](../../assets/art/source/head_emp_node_01.png) | [assets/art/buildings/head_emp_node.png](../../assets/art/buildings/head_emp_node.png) | 256×256 |
| §12 Lance Emitter | [assets/art/source/head_lance_emitter_01.png](../../assets/art/source/head_lance_emitter_01.png) | [assets/art/buildings/head_lance_emitter.png](../../assets/art/buildings/head_lance_emitter.png) | 256×256 |
| §13 Point Defense | [assets/art/source/head_point_defense_01.png](../../assets/art/source/head_point_defense_01.png) | [assets/art/buildings/head_point_defense.png](../../assets/art/buildings/head_point_defense.png) | 256×256 |
| §14 Relay | [assets/art/source/head_relay_01.png](../../assets/art/source/head_relay_01.png) | [assets/art/buildings/head_relay.png](../../assets/art/buildings/head_relay.png) | 256×256 |
| §15 Repair Node | [assets/art/source/head_repair_node_01.png](../../assets/art/source/head_repair_node_01.png) | [assets/art/buildings/head_repair_node.png](../../assets/art/buildings/head_repair_node.png) | 256×256 |
| §16 Armor Plating | [assets/art/source/head_armor_plating_01.png](../../assets/art/source/head_armor_plating_01.png) | [assets/art/buildings/head_armor_plating.png](../../assets/art/buildings/head_armor_plating.png) | 256×256 |
| §17 Deflector Wall | [assets/art/source/wall_deflector_01.png](../../assets/art/source/wall_deflector_01.png) | [assets/art/walls/wall_deflector_01.png](../../assets/art/walls/wall_deflector_01.png) | 256×256 |
| §18 Debris Field | [assets/art/source/terrain_debris_field_01.png](../../assets/art/source/terrain_debris_field_01.png) | [assets/art/terrain/terrain_debris_field_01.png](../../assets/art/terrain/terrain_debris_field_01.png) | 256×256 |
| §19 Tractor Lane | [assets/art/source/terrain_tractor_lane_01.png](../../assets/art/source/terrain_tractor_lane_01.png) | [assets/art/terrain/terrain_tractor_lane_01.png](../../assets/art/terrain/terrain_tractor_lane_01.png) | 256×256 |
| §20 Occlusion Screen | [assets/art/source/terrain_occlusion_screen_01.png](../../assets/art/source/terrain_occlusion_screen_01.png) | [assets/art/terrain/terrain_occlusion_screen_01.png](../../assets/art/terrain/terrain_occlusion_screen_01.png) | 256×256 |
| §21 Tunneler | [assets/art/source/elite_tunneler_01.png](../../assets/art/source/elite_tunneler_01.png) | [assets/art/machines/elite_tunneler.png](../../assets/art/machines/elite_tunneler.png) | 128×128 |
| §22 Transfer | [assets/art/source/elite_transfer_01.png](../../assets/art/source/elite_transfer_01.png) | [assets/art/machines/elite_transfer.png](../../assets/art/machines/elite_transfer.png) | 128×128 |
| §23 Foundry | [assets/art/source/elite_foundry_01.png](../../assets/art/source/elite_foundry_01.png) | [assets/art/machines/elite_foundry.png](../../assets/art/machines/elite_foundry.png) | 128×128 |
| §24 Sapper | [assets/art/source/elite_sapper_01.png](../../assets/art/source/elite_sapper_01.png) | [assets/art/machines/elite_sapper.png](../../assets/art/machines/elite_sapper.png) | 128×128 |
| §25 Breacher | [assets/art/source/elite_breacher_01.png](../../assets/art/source/elite_breacher_01.png) | [assets/art/machines/elite_breacher.png](../../assets/art/machines/elite_breacher.png) | 128×128 |
| §26 Assembler | [assets/art/source/assembler_01.png](../../assets/art/source/assembler_01.png) | [assets/art/machines/assembler.png](../../assets/art/machines/assembler.png) | 256×256 |

Three rejected outputs are retained, and no other assets were regenerated:

- [Flak attempt 1](../../assets/art/source/head_flak_01_rejected_attempt_01.png): four five-barrel clusters, about 20 barrels total, instead of one 4–6-barrel assembly. Attempt 2 has six front-facing barrels; the housing remains bulky.
- [Relay attempt 1](../../assets/art/source/head_relay_01_rejected_attempt_01.png): long mast shafts shown largely in side elevation. Attempt 2 foreshortens the mast, but still carries more visible height than the kit's flatter objects; bearing acceptance remains failed.
- [Assembler attempt 1](../../assets/art/source/assembler_01_rejected_attempt_01.png): a luminous central disk plus separate illuminated ring sectors. This was rejected under the strict one-glowing-area rule. Attempt 2 uses one solid localized panel; its surrounding hull is unlit.

The approved anchor and all five T-078 normalized/source assets remain unchanged. No shared mount was added beneath Wall or any terrain asset. The four are stored in new `walls/` and `terrain/` directories because the existing layout had no appropriate category. Armor remains in `buildings/` as a flat applied overlay.

## 2. Review scope and evidence

The review runs in a new **F4** overlay inside `scenes/art_preview.tscn`; T-078's F3 overlay is retained. Keys **1–5** choose checks and **Left/Right** select pages. Captures are actual **1440×810 GPU renders, Godot 4.7.2 Compatibility, RTX 4080**, not generated mockups.

**PASS** below means the stated property was observed in this diagnostic fixture. **FAIL (blocked)** means a required production property cannot be established without the missing live renderer. No flat-dial observation is promoted to a live tilted-ground seating pass. **N/A** applies to excluded flat-surface/crowd categories only.

- Close evidence: [bands](artifacts/T-079-close-01.png), [damage](artifacts/T-079-close-02.png), [heads and existing Mass Driver](artifacts/T-079-close-03.png), [Wall/terrain and Armor overlay](artifacts/T-079-close-04.png), [elites, standard and boss](artifacts/T-079-close-05.png).
- Strategic evidence: [bands/damage/heads](artifacts/T-079-strategic-01.png), [Wall/terrain/horde](artifacts/T-079-strategic-02.png).
- Yellow-star evidence: [page 1](artifacts/T-079-yellow-01.png), [page 2](artifacts/T-079-yellow-02.png), [page 3](artifacts/T-079-yellow-03.png), [page 4](artifacts/T-079-yellow-04.png), [page 5](artifacts/T-079-yellow-05.png).
- Mixed-swarm evidence: [zoom 3.2](artifacts/T-079-crowd-01.png), [close zoom 1.55](artifacts/T-079-crowd-02.png), [strategic zoom 0.273](artifacts/T-079-crowd-03.png).
- All twelve bearings for every object/overlay: [Flak](artifacts/T-079-rotations-01.png), [EMP Node](artifacts/T-079-rotations-02.png), [Lance Emitter](artifacts/T-079-rotations-03.png), [Point Defense](artifacts/T-079-rotations-04.png), [Relay](artifacts/T-079-rotations-05.png), [Repair Node](artifacts/T-079-rotations-06.png), [Armor Plating](artifacts/T-079-rotations-07.png), [Deflector Wall](artifacts/T-079-rotations-08.png), [Debris Field](artifacts/T-079-rotations-09.png), [Tractor Lane](artifacts/T-079-rotations-10.png), [Occlusion Screen](artifacts/T-079-rotations-11.png), [Tunneler](artifacts/T-079-rotations-12.png), [Transfer](artifacts/T-079-rotations-13.png), [Foundry](artifacts/T-079-rotations-14.png), [Sapper](artifacts/T-079-rotations-15.png), [Breacher](artifacts/T-079-rotations-16.png), [Assembler](artifacts/T-079-rotations-17.png).

Provisional complete-canvas world widths are recorded in the [normalization manifest](../../scripts/art/t079_normalization_manifest.json): bands 256; heads 28–56; Armor 32; Wall 48; terrain 48–64; ordinary elites 16, Foundry 24, Assembler 48; the unchanged standard is 8. Point Defense is deliberately smaller than Flak/Mass Driver, and Foundry/boss are deliberately larger than the other elites. Export resolution alone is not a world-size contract. Damage is tested as six individual atlas motifs at 32 world units each.

Strategic zoom uses T-078's formula, `810 × 0.42 / 1248 = 0.273`. Thus elite canvases become approximately **4.4 px**, Foundry **6.5 px**, and Assembler **13.1 px**. No minimum-size floor, tint, outline, extra glow, contrast boost or relighting was used to rescue visibility.

Each crowd page renders the same **1,000 standard machines + six of each of five elites + one Assembler**. A seeded six-world-unit grid with jitter produces actual overlap; all items are sorted together by screen Y so standards can obscure elites and the boss. All twelve facings occur. Zoom changes both spacing and sprite size. These are diagnostic textured draw calls, not the live MultiMesh implementation and not a throughput benchmark.

The star check uses the actual `sun.gdshader`, yellow palette 1, phase 0, with neutral texture modulation. This pass checks the requested canonical yellow star only; red/white-skin acceptance is not claimed.

## 3. Five checks per asset

Strategic results distinguish visibility of a generic mark from survival of the intended identity. A surviving blob does not pass a mechanism-identification requirement.

| Asset | Close | Strategic | Yellow star | Mixed swarm | Twelve bearings / seating |
|---|---|---|---|---|---|
| Hot band | **PASS** — scorched deck/truss reads | **PASS** — darker tier strip survives | **PASS** — bronze/amber stays subordinate | N/A | N/A |
| Cold band | **PASS** — pale deck/truss reads | **PASS** — pale tier strip survives | **PASS** — pale steel does not overpower star | N/A | N/A |
| Damage sheet | **FAIL** — all six motifs read, but scorch/pits carry underlying plating, violating surface-free damage | **FAIL** — pits, patch weld and dead-light identity collapse into small marks | **PASS** — neutral damage palette is subordinate | N/A | N/A |
| Flak | **PASS** — six short barrels form a wide burst-weapon cluster | **FAIL** — barrels merge into an anonymous compact block | **PASS** — restrained amber/steel | N/A | **FAIL (blocked)** — coherent outward rotation; live mount seating absent |
| EMP Node | **PASS** — concentric coils read as pulse equipment | **FAIL** — coil identity disappears into a small round mark | **PASS** — copper/amber remains player-coloured | N/A | **FAIL (blocked)** — radial head remains centred; live seating absent |
| Lance Emitter | **PASS** — slender single focusing array differs from twin rails | **FAIL** — narrow emitter reduces to a faint line | **PASS** — warm lens/steel does not rival corona | N/A | **FAIL (blocked)** — consistent outward axis; live seating absent |
| Point Defense | **FAIL** — twin guns read, but housing is too heavy for lightweight fast-tracking equipment | **FAIL** — twin-gun distinction disappears at its smaller trial size | **PASS** — warm accent family matches kit | N/A | **FAIL (blocked)** — coherent outward rotation; live seating absent |
| Relay | **PASS** — mast/dish clearly communicates infrastructure | **FAIL** — mast/dish become an ambiguous lopsided speck | **PASS** — amber remains subordinate | N/A | **FAIL** — raised mast/dish projection rotates into a conspicuous inward lean at far bearings; live seating also absent |
| Repair Node | **PASS** — articulated arm and tool read as maintenance | **FAIL** — claw and joints collapse into a thin bent stroke | **PASS** — warm neutral machinery | N/A | **FAIL** — diagonal arm reaches off the nominal outward axis at every bearing; no corrective rotation hidden |
| Armor Plating | **PASS** — flat bolted slabs; no raised mechanism | **PASS** — solid reinforcement plate mark survives, fine bolts do not | **PASS** — subdued grey/hazard edge | N/A | **FAIL (blocked)** — flat overlay rotates coherently; flush live placement unverified |
| Deflector Wall | **FAIL** — reads as reinforced floor plate more than standing barrier | **PASS** — broad reinforced-panel mark remains visible; this does not cure close identity failure | **PASS** — grey/amber is subordinate | N/A | **FAIL (blocked)** — no gross dial lean, but band attachment and raised profile cannot be validated |
| Debris Field | **PASS** — separate dead scraps, no lamps or functional intact structure | **PASS** — irregular scattered patch survives | **PASS** — inert scrap stays subordinate | N/A | **FAIL (blocked)** — irregular footprint stable; live ground seating absent |
| Tractor Lane | **FAIL** — chevrons read, but thick enclosed rail housings look like equipment rather than a flush marking | **FAIL** — arrows disappear; only a plate-like mark remains | **PASS** — warm markings do not compete | N/A | **FAIL** — arrows are source −Y, so the common +Y rotation convention points them inward; flat marking has no object-camera lean test |
| Occlusion Screen | **FAIL** — floor-like twin radiator panel, not a standing shadow-casting screen | **FAIL** — radiator/screen identity becomes a generic plate mark | **PASS** — neutral radiator palette | N/A | **FAIL (blocked)** — flat-looking source rotates stably, but screen height/shadow and seating remain unverified |
| Tunneler | **PASS** — forward drill reads at 128 px | **FAIL** — drill and rank lamp vanish at 4.4 px | **PASS** — one cold accent contrasts without competing | **FAIL** — drill is lost under overlap; elongated hull confuses with Transfer/Breacher | **FAIL (blocked)** — drill points outward at all twelve; live seating absent |
| Transfer | **PASS** — twin boosters and long launch rails read | **FAIL** — booster/rail distinction vanishes at 4.4 px | **PASS** — one cold accent, no warmth | **FAIL** — boosters merge into the same elongated dark hull family | **FAIL (blocked)** — stable rotation, but nozzle end makes forward-facing interpretation ambiguous; live placement absent |
| Foundry | **PASS** — wide anchored grinding press reads | **FAIL** — grinder and anchors disappear at 6.5 px | **PASS** — one cold lamp stays subordinate | **FAIL** — strongest elite at close zoom, but not reliably identified at strategic crowd scale | **FAIL (blocked)** — broad footprint stable; live seating absent |
| Sapper | **PASS** — seeking probes and sensor mast read at export size | **FAIL** — fine probes and tiny lamp vanish at 4.4 px | **PASS** — localized cold sensor, no competing glow | **FAIL** — probes merge with swarm detail, leaving a near-standard-sized central body | **FAIL** — mast's baked projection turns inward at far bearings; live seating also absent |
| Breacher | **PASS** — broad wedge ram clearly reads | **FAIL** — prow identity disappears at 4.4 px | **PASS** — one cold lamp stays distinct in colour | **FAIL** — wedge outline is obscured and confuses with other heavy elongated hulls | **FAIL (blocked)** — ram faces outward coherently; live seating absent |
| Assembler | **PASS** — large layered hull and larger single accent read as boss | **FAIL** — survives as a larger dim mark, but is not unmistakably boss at 13.1 px | **PASS** — cold panel remains localized; yellow star still dominates | **FAIL** — clearly identifiable in both close crowd trials, but not unambiguous in strategic overlap | **FAIL (blocked)** — stable broad outline at twelve bearings; live seating absent |

The bands additionally **fail exact seamless repeat**: hot left/right RGBA mean absolute error **9.6504**, maximum **110**; cold mean **17.2637**, maximum **169** (byte values). Both are visibly repeatable strips in the fixture, but neither is accepted as perfectly seamless. No seam blend or edge replacement was applied.

## 4. Elite / Assembler emissive audit

Each final normalized PNG was opened directly and inspected, then inspected again in the close, yellow-star and bearing captures. **All six pass the requested source/export emissive rule**: one localized cold cyan/white accent, no warm glow, no second independent glowing area, matte dark surrounding hull. This is separate from the failed strategic visibility test.

| Asset | Final result | Visual observation | Bright cold pixels | Bright warm pixels | Attempts |
|---|---|---|---|---|---|
| Tunneler | **PASS** | One small cyan-white hull lamp; rest of hull matte | 12 | 0 | 1 |
| Transfer | **PASS** | One small cyan-white hull lamp; rest of hull matte | 10 | 0 | 1 |
| Foundry | **PASS** | One small cyan-white hull lamp; rest of hull matte | 12 | 0 | 1 |
| Sapper | **PASS** | One small cyan-white sensor face; rest of hull matte | 6 | 0 | 1 |
| Breacher | **PASS** | One small cyan-white hull lamp; rest of hull matte | 16 | 0 | 1 |
| Assembler | **PASS** | One larger solid cyan-white central panel; rest of hull matte | 418 | 0 | 2; first rejected for disk plus lit ring sectors |

Counts use opaque-enough pixels (alpha >128), G >120 and B >R+12 for cold; R >120 and R >B+20 for warm. They are supporting measurements, not a definition of emissive or a substitute for visual inspection. A sensor's internal lines are inspected as one localized face; separate luminous areas elsewhere would fail. The Assembler's first disk-plus-ring treatment was deliberately rejected rather than interpreted generously.

At the current export sizes, the boss has 418 bright cold pixels versus 6–16 for an elite. Its single panel is also proportionally larger, not merely higher-resolution. No emissive cleanup, hue removal, lamp painting or machine-specific darkening was used. The standard machine retains its T-078 zero-emissive treatment unchanged.

## 5. Honest silhouette assessment

**As a close-up lineup, this is a useful differentiated starting set. As a gameplay identification system, it is not yet successful.**

Foundry is the strongest elite: width, anchoring feet and the open central grinder jointly announce a stationary processor. Sapper has the most different outline, but that identity lives in thin probes that minification and overlap erase first. Tunneler's pointed drill and Breacher's wide ram distinguish them when unobscured. Transfer's booster/rail mechanism reads up close, but most of it is internal detail within a familiar long hull.

The weakest grouping is **Tunneler / Transfer / Breacher**. They share a central rectangular body and paired side masses; under overlap their different front mechanisms are exactly what is hidden. The common small lamp says “elite” at generous close scale, but does not identify which elite, and it becomes subpixel well before the strategic view. Merely increasing PNG resolution would not change that world-space loss.

Assembler is easy to find in both close crowd trials. Its broad layered outline and much larger single light establish rank successfully there. At the trial strategic size, even that advantage is too small and partially occluded to call unmistakable. The accreted construction is also fairly symmetric and manufactured-looking; it suggests a heavier machine more strongly than structure visibly consumed into a hull. That is a content weakness worth preserving in the review.

These judgments are visual inspection, not a timed blind identification study. No claim is made that the names in a labelled lineup prove at-a-glance recognition.

## 6. Pipeline findings beyond the five-asset slice

**Reference transfer copied subject geometry as well as style.** This became much more apparent across twenty different subjects. The anchor successfully holds wear, steel tone and panel detail together, but repeatedly pulls objects toward a broad armored deck footprint. Wall, Tractor Lane and Occlusion Screen all suffer from this. Head-only prompts also tend toward heavier housings, particularly Point Defense. The four non-mounted assets were never composited onto the shared mount; their problematic slab-like geometry is in the generated sources themselves.

**One accent requires a dedicated review.** Five elite first attempts satisfied the visual rule. The first boss did not: its central disk and separate lit sectors demonstrate that “localized accent” can still produce multiple luminous surfaces. The logged correction worked. Quantitative hue checks alone would have missed this failure because every illuminated sector was correctly cold.

**Fixed canvas size is not consistent physical size or useful silhouette coverage.** A pivot-centred long Repair arm spends much of its 256×256 budget on empty canvas; a compact EMP fills most of its canvas. The same issue affects thin Sapper probes. The new manifest therefore records explicit source pivots and provisional world widths rather than assuming every 256-pixel head should be drawn at identical width. No final gameplay scale contract was invented.

**The existing normalizer needed no category-specific algorithm change.** Its object handling covers Wall, terrain and flat overlays using explicit footprint/surface pivots; its sheet path covers damage. [normalize_t079.py](../../scripts/art/normalize_t079.py) supplies category sizes, destinations and reviewed pivot estimates to the unchanged [normalize_asset.py](../../scripts/art/normalize_asset.py). Black-background extraction, straight-alpha export and premultiplied filtering follow T-078. The band handler repeats hot three times and cold twice before resizing. These are mechanical normalizations, not hidden content corrections.

**Albedo remains unresolved.** The inherited bounded illumination suppression (strength 0.35, gain capped at 0.85–1.15) cannot separate AO, metal highlights and baked lamps into physically flat albedo and emissive maps. Damage is especially substrate-dependent; a dead fixture is a static picture, not a switchable lamp state. Dynamic relighting/brownout acceptance is not established.

**Review tooling had to become paginated and class-comparative.** T-078's single fixed sheet was insufficient. The new fixture has 32 pages of evidence, including 17 bearing pages and three scales of genuinely overlapping mixed swarms. Early fixture captures exposed incorrect atlas-region crops, labels colliding with the footer, and insufficient overlap. Those fixture issues were corrected and recaptured; no art was changed to improve those results. Final evidence uses the corrected fixture.

**Orchestration/import issues:** writing the entire expanded twenty-asset prompt audit as a single Windows shell command exceeded the process command-length limit; it was saved through file patches instead. Initial Godot import hit sandbox-denied editor cache/settings writes; the authorized retry completed. Godot's graphical executable can return before its child finishes, so completion was checked against all saved capture messages, not the shell return alone. Auto-created import sidecars for unrelated anchor/mockup/T-078 evidence files were removed from this change.

**Import settings:** all 20 normalized assets use lossless compression, mipmaps, alpha-border fixing and straight alpha; the fixture uses linear mipmap filtering. As in T-078, these small strips remain lossless for review. Live angular repeat configuration is not implemented. Raw sources retain the existing `.gdignore` and export exclusion.

**Verification:** normalization regression tests **4/4 passed**; existing [art-preview tests](artifacts/T-079-preview-tests.txt) **59/59 passed**; final [GPU capture log](artifacts/T-079-capture.txt) records **all 32 saves with no script/render errors**. The headless test emitted the pre-existing root-certificate warning. All 20 raw/output hashes, dimensions, RGBA modes, import settings and report links were checked; all five T-078 output hashes still match their original manifest. These checks validate file/fixture mechanics, not art acceptance.

The live engineering blockers documented in T-078 remain: authored band UV/placement, production mount/head composition, textured machine class rendering and minimum screen-size behavior, tilted-ground seating/depth, and material/emissive relighting. No T-074/T-075 work, gameplay integration, template edits, pipeline-document edits, or planning-log edits were performed.

**Decision:** retain the candidates and evidence for review; do not mark the twenty-asset set production-approved. Content failures and the missing live rendering prerequisites remain explicit.

## Reproduce

1. Run `python scripts/art/normalize_t079.py` with Pillow and numpy installed. It only normalizes the 20 T-079 candidates and writes their manifest. Run `python scripts/art/test_normalize_asset.py` for the inherited regression checks. The checked-in generation manifest is the executed prompt audit; `prepare_t079.py` only creates a separate baseline expansion file and does not overwrite that audit.
2. Import in Godot 4.7.2. Open `scenes/art_preview.tscn`, press **F4**, then **1–5** and **Left/Right**. This is a source-project diagnostic fixture; its manifest is under the existing non-exported `scripts/` directory.
3. Capture with `Godot_v4.7.2-stable_win64.exe --path . --resolution 1440x810 --script tests/presentation/capture_production_review.gd --quit-after 240 --log-file .godot/t079-capture.log`. Use a graphical renderer. Expected output: 5 close, 2 strategic, 5 yellow, 3 crowd and 17 bearing PNGs under `docs/reviews/artifacts/`.
