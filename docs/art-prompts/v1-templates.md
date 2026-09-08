# RING ZERO — Production Prompt Templates, v1

**Status:** Locked for T-078 (pipeline vertical slice). Per `docs/art-asset-pipeline.md` §3.2 — versioned alongside the assets they produce. Do not edit in place once assets exist against this version; copy to v2 instead, so regenerating an old asset later still matches what shipped.
**Differs from the mockup brief:** `docs/art-mockup-brief.md` produced full dramatic scene composites for direction review. These templates produce **isolated, flat-lit, single-subject** source images meant to become actual game assets. Do not reuse mockup-brief phrasing here — the lighting and framing rules are opposite on purpose (baked scene lighting must never end up on a production asset that has to relight dynamically in engine).

---

## Locked common block

Every template below starts with this, unmodified:

```
STYLE      gritty industrial sci-fi, working machinery, weathered metal,
           panel lines, rivets, hazard markings, functional not decorative
PALETTE    desaturated grey-steel base; warm amber working lights;
           NO cold cyan anywhere on player/structure assets
LIGHTING   flat, even, shadowless — lighting is applied later in engine
BACKGROUND pure black or transparent, isolated subject, no scene,
           no ground plane, no environment
FRAMING    subject centred, fully in frame, generous margin
NEGATIVE   no text, no logos, no UI, no characters, no scene lighting,
           no cast shadows, no perspective vanishing, no colour grading,
           no motion blur, no depth of field, no dust or atmosphere
```

## Camera split (D-123) — read this before generating anything

- **Flat surface categories** (band strip, decal sheet) → **flat, direct top-down, orthographic.** They lie on a surface the engine foreshortens; pre-tilting them bakes the squash in twice.
- **Object categories** (mount, building head, machine) → **20° from vertical**, matching the in-game camera. Every object in this version must use the *same* 20° and the *same* nominal facing (imagine the object's "front" pointing toward the bottom of frame) — they will be rotated in-engine to face outward at twelve bearings, and inconsistent facing between assets will show.

---

## 1. Style anchor

**Generate 5 variations of this one prompt.** Nothing else is generated until one is picked — it fixes wear level, panel detail density, and exact metal tone for every prompt after it.

```
[COMMON BLOCK]
CAMERA    20° from vertical, object facing toward bottom of frame
SUBJECT   a single turret head — twin-barrel mass driver rail assembly,
          heavy and mechanical — mounted on an armoured industrial base
          with visible cable runs, anchor bolts and hazard-striped edge
DETAIL    moderate wear: scuffed paint, a little rust bleed at seams,
          rivets and panel lines crisp — not pristine, not derelict
```

Output: `assets/art/anchor/anchor_candidate_01.png` … `_05.png`.

## 2. Ring band strip (working tier)

Working/middle tier only for this slice — hot and cold tiers come in pipeline stage 2, once this one is proven.

```
[COMMON BLOCK]
CAMERA    flat, direct top-down, orthographic — no tilt
SUBJECT   a seamless horizontal strip of industrial deck plating and
          exposed truss structure, working-tier: neutral grey-steel,
          moderate wear, amber running lights along the seam
TILING    must tile perfectly left-edge to right-edge; do not frame
          the ends with anything that breaks the repeat
NEGATIVE  [common block negatives] plus: no vertical curvature, no
          radial distortion, no visible seam mismatch at the edges
```

Output: `assets/art/source/band_working_01.png`.

## 3. Decal sheet

```
[COMMON BLOCK]
CAMERA    flat, direct top-down, orthographic — no tilt
SUBJECT   a sheet of 8-10 small isolated industrial details, evenly
          spaced on a transparent/black ground, each independently
          readable: an access hatch, a vent grille, a pipe run with
          two elbow joints, a hazard-stripe corner panel, a rivet
          seam strip, a cable conduit, a warning stencil panel,
          a small antenna/sensor stub
NEGATIVE  [common block negatives] plus: no single dominant element,
          no elements touching or overlapping each other
```

Output: `assets/art/source/decal_sheet_01.png`.

## 4. Building mount

```
[COMMON BLOCK]
CAMERA    20° from vertical, facing toward bottom of frame
SUBJECT   a bare armoured turret mounting base — no weapon or head
          attached — with a rotating ring collar, cable runs, anchor
          bolts, and a socket/interface where a head assembly would
          attach on top. Ground contact point clearly at the base
NEGATIVE  [common block negatives] plus: no weapon, no barrel, no dish,
          no head assembly of any kind — base only
```

Output: `assets/art/source/building_mount_01.png`.

## 5. Building head — Mass Driver

Same subject as the approved anchor, generated as a standalone head (no base) sized to sit on the mount from #4. If the anchor is approved as-is, this step can reuse it directly instead of regenerating.

```
[COMMON BLOCK]
CAMERA    20° from vertical, facing toward bottom of frame — identical
          angle and facing to the building mount
SUBJECT   a twin-barrel mass driver rail assembly, heavy and mechanical,
          reads unmistakably as "long-range heavy weapon" by silhouette
          alone — long heavy rail, minimal ornamentation
SCALE     sized to sit on a turret mount base — not a whole turret,
          the upper mechanism only
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry — head assembly only
```

Output: `assets/art/source/head_mass_driver_01.png`.

## 6. Standard machine — hardened emissive constraint

**D-124: this exact asset failed the emissive-is-rank rule on the first mockup attempt.** The constraint below is mandatory, not optional phrasing.

```
[COMMON BLOCK]
CAMERA    20° from vertical, facing toward bottom of frame
SUBJECT   a small blunt harvester drone — von Neumann machine swarm
          unit — intake maw at the front, a grinding/processing head,
          a compact collection bay, small fixed solar vanes. Simple,
          low detail — this will appear hundreds of times on screen
MATERIAL  REQUIRED: matte, unlit dark hull — near-black, non-reflective,
          zero emissive of any kind. Silhouette alone carries all
          identity. This is a STANDARD machine, not an elite.
NEGATIVE  [common block negatives] plus: NO windows, NO running lights,
          NO glow, NO light-up panels, NO coloured accents, NO cyan,
          NO warm lights, NO emissive surfaces of any kind whatsoever
```

Output: `assets/art/source/machine_standard_01.png`.

**Verification step, not optional:** before this asset is treated as acceptable, inspect it specifically for any lit detail — a window, a seam glow, a running light — and reject/regenerate if found. This is the exact failure mode from the mockup review.
