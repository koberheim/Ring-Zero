# RING ZERO — Art Asset Pipeline

**Status:** Specified 2026-09-08 under D-120. Companion to [art-direction-style-guide.md](art-direction-style-guide.md) — that document decides *what it looks like*, this one decides *how it gets made, checked and shipped*.
**Method:** Kevin generates source images; they are processed to game-ready assets and reviewed in the running game before acceptance.
**Budget:** ~35–45 source images for a first complete pass.

---

## 1. What is authored vs. what stays procedural

The budget only survives because most of the game is drawn by code. Anything in the right column costs **zero** images.

| Authored (generated art) | Procedural (code + shaders) |
|---|---|
| Ring band surface strips | Ring/spoke geometry, layout, damage masks |
| Decal sheet (vents, hatches, stripes, pipes) | Star, corona, all reactive states |
| Damage sheet (scorch, tears, patch welds) | Void atmosphere, corona bleed, starfield |
| Shared building mount | All weapon fire VFX |
| 13 building heads | All destruction VFX |
| Standard machine | Alt tactical overlay |
| 5 elites + Assembler | Lighting, ring-tier tinting, state colouring |

**Rule of thumb:** if it must scale to unbounded zoom, deform, or respond to game state, it is procedural. If it is a fixed object a player identifies by shape, it is authored.

---

## 2. Asset manifest — the ~40

| # | Asset | Count | Notes |
|---|---|---|---|
| 1 | **Style anchor** candidates | ~5 | one subject, several looks; Kevin picks one. Sets lighting, palette, wear, detail density for everything after |
| 2 | Ring band strips | 3 | hot / working / cold tiers (§3 of the guide) |
| 3 | Decal sheet | 2 | isolated elements on transparent ground |
| 4 | Damage sheet | 1 | scorch, pitting, tears, patch welds |
| 5 | Shared building mount | 1 | reused under all 13 buildings |
| 6 | Building heads | 13 | 5 weapons, 5 structures, 3 terrain |
| 7 | Standard machine | 1 | deliberately simple — swarm-first |
| 8 | Elites | 5 | Tunneler, Transfer, Foundry, Sapper, Breacher |
| 9 | Assembler | 1 | boss; growth is procedural on top |
| | **Subtotal** | **32** | |
| | Iteration / rejects headroom | ~8–13 | |
| | **Total** | **~40–45** | |

---

## 3. Generation specs

### 3.1 The style anchor comes first

**Nothing else is generated until the anchor is chosen.** Generate ~5 candidates of a single subject — recommended: *a Mass Driver head on its mount, three-quarter top-down, lit from below by a warm star* — and pick one. That image then defines lighting, palette, wear level and detail density, and is referenced by every prompt after it.

This is the cheapest defence against the failure mode that kills AI-assisted art pipelines: forty individually-good images that don't belong to the same game.

### 3.2 Fixed prompt templates

One locked, versioned template per category; only the `SUBJECT` line changes. Templates live in `docs/art-prompts/` and are versioned alongside the assets they produced, so regenerating one asset in six months still matches.

**Common block — in every template:**

```
STYLE     gritty industrial sci-fi, working machinery, weathered metal,
          panel lines, rivets, hazard markings, functional not decorative
PALETTE   desaturated grey-steel base; warm amber working lights;
          NO cold cyan on player structures
LIGHTING  flat, even, shadowless — lighting is applied in engine
BACKGROUND pure black, isolated subject, no scene, no ground plane
FRAMING   subject centred, fully in frame, generous margin
NEGATIVE  no text, no logos, no UI, no characters, no scene lighting,
          no cast shadows, no perspective vanishing, no colour grading
```

**Camera angle splits by asset type (D-123).** The game view is tilted 20° from vertical, but that does *not* mean everything is generated at 20°:

- **Flat surface art** — band strips, decals, damage — is generated **flat, direct top-down**. It lies on surfaces, and the engine applies the foreshortening. Generating it pre-tilted would bake the squash in twice.
- **Objects** — mount, heads, machines, elites, Assembler — is generated **at 20° from vertical**, matching the game camera, so their visible height is correct.

**Per-category `SUBJECT` and camera:**

| Category | Camera | Subject guidance |
|---|---|---|
| Ring band strip | **Flat top-down, orthographic** | Seamless horizontal strip of industrial deck plating and truss; must tile left↔right; tier character per §3. Band *depth* is procedural geometry, not painted into the strip |
| Decals | **Flat top-down, orthographic** | Single isolated element on transparent/black: vent, hatch, pipe run, hazard stripe, access panel |
| Damage | **Flat top-down, orthographic** | Isolated scorch mark / tear / patch weld, no underlying surface |
| Building mount | **20° from vertical** | Bare armoured mounting base with cable runs and anchor bolts; no weapon. Ground point clearly at the base |
| Building heads | **20° from vertical** | The mechanism only, sized to sit on the shared mount; must telegraph function per §4; enough visible side to read as solid |
| Machines | **20° from vertical** | Blunt harvester drone; intake maw, grinder, collection bay, solar vanes; simple, low detail |
| Elites | **20° from vertical** | As above, plus the one feature that announces its mechanic per §5 |

**Consistency requirement:** every object asset must be generated at the *same* 20° and the same nominal facing, or they will not sit together once rotated to their bearings. This belongs in the locked common block.

**Machine colour note:** machines carry **cold** cyan/white accents; player structures carry **warm** amber. This inversion is load-bearing (§8) and belongs in the negative prompt for both sides.

### 3.3 The polar-distortion constraint

Wedge plates are trapezoids that stretch toward the rim. This is why the manifest has no per-wedge plate art:

- **Decals** are small enough that polar stretch is negligible — placed and rotated procedurally.
- **Band strips** tile *angularly* (around the ring), where stretch is uniform and correctable.
- **Buildings and machines** are individually framed sprites, rotated to face outward — no distortion at all.

Never generate a whole pre-distorted wedge plate; it cannot be reused across radii.

---

## 4. Post-process normalisation

Every accepted image goes through the same mechanical steps, regardless of how it came out. This absorbs a great deal of variance without regenerating anything.

```
1. DE-LIGHT       flatten baked lighting/shadow to even albedo
2. PALETTE MAP    clamp to the project palette; strip stray hues
3. TRIM           crop to content bounds
4. CENTRE         align to the asset's pivot (mount point / centre of mass)
5. SCALE          normalise to the category's fixed pixel budget
6. EXPORT         PNG, premultiplied alpha, power-of-two where atlased
```

**Fixed sizes per category** (first-pass, tunable):

| Category | Export size |
|---|---|
| Ring band strip | 1024 × 128, tiling on X |
| Decal / damage sheet | 1024 × 1024 atlas |
| Building mount + heads | 256 × 256 each |
| Standard machine | 64 × 64 |
| Elites | 128 × 128 |
| Assembler | 256 × 256 |

Machine sizes follow the *They Are Billions* scale model (§5): small in world space, but detailed enough to hold up when the camera is close.

---

## 5. Godot import and repo conventions

### Directory layout

```
assets/art/
  anchor/              the chosen style anchor + rejected candidates
  bands/               ring band strips by tier
  decals/              decal and damage atlases
  buildings/           mount + 13 heads
  machines/            standard, elites, assembler
  source/              unprocessed generated originals (never shipped)
docs/art-prompts/      versioned prompt templates
```

`source/` is retained for regeneration and diffing but excluded from export presets.

### Naming

`<category>_<subject>_<variant>.png` — lowercase, underscore-separated.
Examples: `band_hot_01.png`, `head_mass_driver.png`, `elite_breacher.png`, `decal_hazard_sheet_01.png`.

### Import presets

| Setting | Value | Why |
|---|---|---|
| Filter | Linear | camera zooms continuously; nearest would crawl |
| Mipmaps | **On** | required — strategic zoom minifies heavily |
| Compression | Lossless for atlases, VRAM for large strips | atlases suffer from block artifacts |
| Fix alpha border | On | prevents dark fringing on transparent decals |
| Repeat | On for band strips only | they tile angularly |

### Rendering

Machines already render through `MultiMesh` instancing; authored machine sprites must stay a **single quad with one shared material** per class or the thousand-machine budget breaks. Elites may use a second material; the Assembler may be individual.

---

## 6. Review gate

**No asset is accepted from a generated image alone.** It has to be seen in the running game, via the existing art preview scene (`scenes/art_preview.tscn`), at:

1. **Close zoom** — does it read as the thing it is?
2. **Strategic zoom** — does it survive minification, or vanish?
3. **Against the star** — does it fight the corona's colour, on *every* star skin?
4. **In a crowd** (machines only) — does the silhouette survive a thousand overlapping copies?

5. **At all twelve bearings** (objects only) — does the rotated sprite still sit correctly at the top of the screen, where the 20° lean error is worst?

Typical rejections at this gate: reads fine alone but vanishes at range; wrong apparent scale beside its neighbours; competes with the star; silhouette collapses in a swarm; leans visibly when rotated to the far bearings. These fail only in context, which is exactly why the gate exists.

**The bearing check is the tilt's escape hatch.** D-123 accepts a small lean error to keep one sprite per building. If the very first weapon head fails check 5, the correct response is to reduce the camera angle — not to start generating multiple aspects per building, which would break the budget.

---

## 7. Production order

Deliberately a vertical slice first — prove the whole pipeline end-to-end on a handful of assets before committing the budget.

| Stage | Work | Exit condition |
|---|---|---|
| **0. Anchor** | ~5 candidates, Kevin picks one | anchor approved and in `assets/art/anchor/` |
| **1. Vertical slice** | one band strip + one decal sheet + the mount + **one** weapon head + the standard machine | all five pass the review gate together, in one scene |
| **2. Structure** | remaining band tiers, damage sheet | rings read correctly at every zoom, damage progression legible |
| **3. Buildings** | remaining 12 heads | all thirteen identifiable by silhouette at play zoom |
| **4. Horde** | 5 elites + Assembler | each elite identifiable mid-swarm at strategic zoom |
| **5. Integration** | VFX (procedural), Alt overlay, ring-tier tinting | full guide compliance pass |

Stage 1 is the real decision point: if the pipeline produces a coherent, in-engine-verified slice of five assets, the remaining thirty-odd are mechanical. If it doesn't, the templates change before any budget is spent.

---

## 8. Engineering work this pipeline depends on

These are code tasks, not art tasks, and several are prerequisites:

| Need | Blocks |
|---|---|
| Thin band + spoke geometry replacing wide plates | everything structural |
| Ring-tier tinting and state colouring at strategic zoom | stage 2 |
| Per-wedge damage state driving light failure + decals | stage 2 |
| Sprite-based building rendering (mount + head composite) | stage 3 |
| MultiMesh sprite path for machines, elite/boss variants | stage 4 |
| Alt tactical overlay (D-122) | stage 5 |
| Wedge destruction destroys occupants + salvage (D-121) | stage 5 |
| Corona bleed / void atmosphere shader | stage 5 |

Tracked in TASKS.md from T-072.
