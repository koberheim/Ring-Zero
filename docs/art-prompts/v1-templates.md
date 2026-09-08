# RING ZERO — Production Prompt Templates, v1

**Status:** Locked for T-078 (pipeline vertical slice). Per `docs/art-asset-pipeline.md` §3.2 — versioned alongside the assets they produce. Do not edit in place once assets exist against this version; copy to v2 instead, so regenerating an old asset later still matches what shipped.

**Correction (2026-09-08, before any asset accepted):** the original object-camera phrasing — "20° from vertical" — was too abstract and produced five anchor candidates all rendered at roughly a 40–60° hero-shot elevation instead of the intended near-overhead view. None had been locked in yet, so this is edited in place rather than bumped to v2; the object-camera block below replaces the old phrasing everywhere it appeared. Candidate #4's *design* (wear level, panel density, intake-port depth, hazard striping) was approved on its merits — only the angle needs a redo.

**Anchor approved (D-125):** `assets/art/anchor/anchor_approved.png` (regenerated candidate #4 at the corrected angle). The correction above got the mounting base to read as a genuine flat top-down shape; the barrels still show somewhat more length than the ratio rule below calls for (an estimated ~30–35° apparent angle), accepted as this asset's shape rather than pushed further — a long-projecting weapon inherently shows more length than a squat object at any angle. Treat the approved anchor's angle, not the ratio rule's theoretical ideal, as the practical target for every later object-category asset.
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
- **Object categories** (mount, building head, machine) → the **locked object-camera block** below, matching the in-game camera. Every object in this version must use the *same* angle and the *same* nominal facing — they will be rotated in-engine to face outward at twelve bearings, and inconsistent facing between assets will show.

**Locked object-camera block** (referenced as `[OBJECT CAMERA]` in every object template below):

```
CAMERA     bird's-eye drone shot from nearly directly overhead, tilted
           only slightly off straight-down — NOT a hero shot, NOT a
           three-quarter view, NOT eye-level, NOT an oblique angle
FRAMING    you are looking down at the TOP of the object. Roughly 80-90%
           of the visible surface is the top face; only a thin strip of
           front-facing geometry is visible at the near edge, like the
           lip of a manhole cover or a turret cupola seen from a
           quadcopter almost directly above it
RATIO      visible front-face height should be no more than 1/4 of the
           visible top-face depth — if the front face dominates the
           image the angle is wrong, regenerate
FACING     object's front points toward the bottom of frame
NEGATIVE   no hero angle, no product-shot angle, no eye-level camera,
           no three-quarter perspective, no view that shows the object's
           full front face or side elevation
```

This was tightened after the first anchor pass produced a much steeper hero-shot angle across all five candidates — the abstract phrase "20° from vertical" alone did not reliably constrain the generator. If a generated image still comes back closer to a hero shot than to a drone-overhead shot, reject and regenerate rather than accepting it as close enough.

---

## 1. Style anchor

**Generate 5 variations of this one prompt.** Nothing else is generated until one is picked — it fixes wear level, panel detail density, and exact metal tone for every prompt after it.

```
[COMMON BLOCK]
[OBJECT CAMERA]
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
[OBJECT CAMERA]
SUBJECT   a bare armoured turret mounting base — no weapon or head
          attached — with a rotating ring collar, cable runs, anchor
          bolts, and a socket/interface where a head assembly would
          attach on top. Ground contact point clearly at the base
NEGATIVE  [common block negatives] plus: no weapon, no barrel, no dish,
          no head assembly of any kind — base only
```

Output: `assets/art/source/building_mount_01.png`.

## 5. Building head — Mass Driver

Same subject as the approved anchor, generated as a standalone head (no base) sized to sit on the mount from #4. The approved anchor is a fused turret (head + mount as one integrated design) — generate this as a fresh asset referencing the anchor's wear level, palette and angle, not a crop of it.

```
[COMMON BLOCK]
[OBJECT CAMERA] — identical angle and facing to the building mount
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
[OBJECT CAMERA]
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

---

# T-079 — remaining production assets

Corrected manifest (see `docs/art-asset-pipeline.md` §2 correction note): **8** mount-mounted building heads (5 weapons + Relay + Armor Plating + Repair Node), **1** Wall (ring-attached, NOT mount-mounted), **3** terrain objects (NOT mount-mounted), **2** remaining band tiers, **1** damage sheet, **5** elites, **1** Assembler. Flak/EMP Node/Lance Emitter/Point Defense/Relay/Repair Node/Armor Plating all use `[OBJECT CAMERA]` and reference `anchor_approved.png` for wear/palette/angle exactly like the Mass Driver head did.

## 7. Ring band strip — hot tier

```
[COMMON BLOCK]
CAMERA    flat, direct top-down, orthographic — no tilt
SUBJECT   a seamless horizontal strip of industrial deck plating and
          exposed truss structure, HOT tier: darker scorched metal,
          heavier wear, visible heat-discolouration (blue-grey to
          bronze temper marks), amber running lights along the seam —
          reads as inner-ring, sun-worn structure
TILING    must tile perfectly left-edge to right-edge
NEGATIVE  [common block negatives] plus: no vertical curvature, no
          radial distortion, no visible seam mismatch at the edges
```

Output: `assets/art/source/band_hot_01.png`.

## 8. Ring band strip — cold tier

```
[COMMON BLOCK]
CAMERA    flat, direct top-down, orthographic — no tilt
SUBJECT   a seamless horizontal strip of industrial deck plating and
          exposed truss structure, COLD tier: pale grey-white metal,
          sparse and lightly worn, minimal heat discolouration, frost-
          pale amber running lights — reads as outer-ring, frontier
          structure, less battle-worn than the working/hot tiers
TILING    must tile perfectly left-edge to right-edge
NEGATIVE  [common block negatives] plus: no vertical curvature, no
          radial distortion, no visible seam mismatch at the edges
```

Output: `assets/art/source/band_cold_01.png`.

## 9. Damage sheet

```
[COMMON BLOCK]
CAMERA    flat, direct top-down, orthographic — no tilt
SUBJECT   a sheet of 6-8 isolated battle-damage elements on a
          transparent/black ground, each independently readable:
          a scorch mark, a jagged tear in plating, a bullet/impact
          pit cluster, a patch weld (mismatched replacement plate
          over an old wound), a buckled panel section, a burnt/dead
          light fixture
NEGATIVE  [common block negatives] plus: no single dominant element,
          no elements touching or overlapping each other
```

Output: `assets/art/source/damage_sheet_01.png`.

## 10. Building head — Flak Emplacement

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a short multi-barrel flak cluster — 4-6 short stubby barrels
          in a rotary or clustered arrangement, reads unmistakably as
          "close-range burst weapon" by silhouette alone, compact and
          wide rather than long
SCALE     sized to sit on the turret mount base — head assembly only
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry, no long rails
```

Output: `assets/art/source/head_flak_01.png`.

## 11. Building head — EMP Node

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a coil-and-dish emitter assembly — concentric coil rings or
          a small dish/emitter array, reads as "area pulse/energy
          weapon" rather than a projectile weapon, no visible barrels
SCALE     sized to sit on the turret mount base — head assembly only
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry, no barrels of any kind
```

Output: `assets/art/source/head_emp_node_01.png`.

## 12. Building head — Lance Emitter

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a focusing-array emitter — a single elongated emitter housing
          with visible focusing rings/lens elements along its length,
          reads as "sustained beam weapon", slender and precise rather
          than heavy like the Mass Driver
SCALE     sized to sit on the turret mount base — head assembly only
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry, not a twin-barrel design
```

Output: `assets/art/source/head_lance_emitter_01.png`.

## 13. Building head — Point Defense

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a small fast twin-mount autocannon — compact, lightweight,
          minimal bulk, reads as "fast-tracking anti-swarm weapon" by
          its small size relative to the other heads
SCALE     sized to sit on the turret mount base — head assembly only,
          noticeably SMALLER/lighter than Flak or Mass Driver
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry, not bulky or heavy
```

Output: `assets/art/source/head_point_defense_01.png`.

## 14. Building head — Relay

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a communications mast and dish — a raised mast with a small
          angled dish/antenna array, no weapon barrels of any kind,
          reads as "infrastructure", not a weapon
SCALE     sized to sit on the turret mount base — head assembly only
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry, no barrels, no weapon
          silhouette of any kind
```

Output: `assets/art/source/head_relay_01.png`.

## 15. Building head — Repair Node

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a crane/manipulator arm assembly — an articulated repair
          arm with a welding/manipulator head, reads as "maintenance
          equipment", not a weapon
SCALE     sized to sit on the turret mount base — head assembly only
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no ground contact geometry, no barrels or weapon
          silhouette of any kind
```

Output: `assets/art/source/head_repair_node_01.png`.

## 16. Building head — Armor Plating

Per the style guide: "applied slabs, no head." This is deliberately NOT a raised turret head — it should read as a low, flat, bolted-on reinforcement rather than a mounted mechanism.

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   applied armor slabs — flat, low-profile bolted reinforcement
          plates layered onto a surface, hazard-striped edge bolts,
          NO raised mechanism, NO turret-like silhouette — reads as
          added protection, not equipment
SCALE     sized to sit on the turret mount base as a flush overlay,
          not a raised assembly
NEGATIVE  [common block negatives] plus: no mounting base, no ring
          collar, no barrels, no dish, no raised mechanism of any kind
```

Output: `assets/art/source/head_armor_plating_01.png`.

## 17. Wall (Deflector Wall) — NOT mount-mounted, revised per D-127

**T-079 finding, confirmed by direct image review:** the first attempt came back as the same octagonal turret-mount pedestal every building head uses, just with hazard stripes — it read as another turret base, not a barrier. Referencing the anchor for style pulled its literal mount geometry along, not just its material. This revision adds an explicit negative naming that exact shape.

**D-127:** Wall is a barrier on the **outside edge of the wedge, facing radially outward** — a flush-mounted plate along the band's outer face, not a free-standing turret-like object with its own base plinth.

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a flat, elongated armoured barrier plate that runs along a
          band segment's OUTER edge, facing radially outward — bracing
          struts along its back, hazard-striped leading face, a low
          wide profile (wider than it is tall). Reads as a wall
          section, not a piece of equipment sitting on the wedge
NEGATIVE  [common block negatives] plus: NO octagonal plinth, NO
          circular/polygonal turret base of any kind, NO ring collar,
          NO radial symmetry (this is a linear barrier, not a turret),
          no weapon silhouette, no barrels or dish
```

Output: `assets/art/source/wall_deflector_01.png`.

**Open, not yet scoped (D-127):** whether Wall should only ever exist on the outermost owned ring (migrating or requiring repurchase when a new ring is bought) is a separate rule question, explicitly TBD — does not block this art rework.

## 18. Terrain — Debris Field (NOT mount-mounted)

Physical, inert wreckage — must never read as attackable structure (it has no HP and cannot be targeted).

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a scattered field of inert wreckage and dead scrap — jagged
          broken hull fragments, dead machine parts, no lights, no
          function, reads unmistakably as DEAD debris, not a building
          or a wall. Loose and irregular, not a solid mass
NEGATIVE  [common block negatives] plus: no turret mount, no intact
          machinery, no lights of any kind, nothing that reads as a
          functional structure or an attackable wall
```

Output: `assets/art/source/terrain_debris_field_01.png`.

## 19. Terrain — Tractor Lane (NOT mount-mounted)

A directional ground effect, not an object with height — should read as a marking/track, not equipment.

```
[COMMON BLOCK]
CAMERA    flat, direct top-down, orthographic — no tilt (this is a
          ground marking, not a raised object)
SUBJECT   an industrial directional guide track — a rail or channel
          segment embedded in the surface with clear directional
          chevrons/arrows, reads as "this marks a direction of travel"
NEGATIVE  [common block negatives] plus: no raised structure, no
          turret mount, no weapon silhouette of any kind
```

Output: `assets/art/source/terrain_tractor_lane_01.png`.

## 20. Terrain — Occlusion Screen (NOT mount-mounted)

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a standing industrial screen/radiator panel structure, flat
          and broad rather than tall, reads as something that would
          cast a shadow — no weapon silhouette, no barrels, no dish
NEGATIVE  [common block negatives] plus: no turret mount, no weapon
          silhouette, no barrels or dish of any kind
```

Output: `assets/art/source/terrain_occlusion_screen_01.png`.

## 21-25. Elites — shared constraints, then per-elite subject (revised per D-128)

**T-079 finding, confirmed by direct image review:** Tunneler, Transfer and Breacher converged on the same silhouette family — rectangular central hull, paired side masses — and are hard to tell apart even at full close-up size, before any minification. Sapper and Foundry are genuinely distinct and prove the silhouette approach works; leave their subject descriptions as-is. Tunneler/Transfer/Breacher's subject descriptions below have been strengthened with explicit mutual-differentiation language.

**D-128 supersedes the single-shared-accent rule.** Emissive is still rank (a standard machine, §6, stays zero-emissive — any glow at all still means "not standard"), but each elite now carries its OWN accent colour, all staying cold (never warm, never confusable with player-structure amber):

| Elite | Accent colour |
|---|---|
| Tunneler | cyan |
| Transfer | blue |
| Foundry | teal-green |
| Sapper | violet |
| Breacher | icy white |

```
[COMMON BLOCK]
[OBJECT CAMERA]
MATERIAL  matte dark hull, same family as the standard machine, PLUS
          exactly one small emissive accent in THIS ELITE'S ASSIGNED
          COLOUR (see table) — never warm, never absent, never a
          different elite's colour
NEGATIVE  [common block negatives] plus: no warm-coloured accents, no
          multiple competing accent colours, no other elite's assigned
          colour, not fully emissive (the hull stays matte dark — only
          ONE small accent glows)
```

**21. Tunneler** (cyan accent) — `SUBJECT: a low, elongated burrowing rig on the ground plane, with a prominent conical drill head projecting forward — the ONLY elite with a pointed drill nose. Built for going under structure rather than over it`. Output: `assets/art/source/elite_tunneler_01.png`.

**22. Transfer** (blue accent) — `SUBJECT: a compact machine dominated by two large flared booster nozzles at its rear and short swept launch fins — the ONLY elite with visible rocket/booster nozzles. Built for a single powerful orbital hop rather than sustained ground movement. Must NOT share Tunneler's drill nose or Breacher's ram prow`. Output: `assets/art/source/elite_transfer_01.png`.

**23. Foundry** — unchanged — `SUBJECT: a huge, heavily anchored grinding press, wider and more massive than any other elite, built to park in place and grind rather than move`. Output: `assets/art/source/elite_foundry_01.png`.

**24. Sapper** — unchanged — `SUBJECT: a machine with fine seeking probes and a raised sensor mast, slender and precise, built for finding a specific target rather than brute force`. Output: `assets/art/source/elite_sapper_01.png`.

**25. Breacher** (icy white accent) — `SUBJECT: a machine almost entirely occupied by a single massive angular wedge-shaped ram prow at its front, blunt and triangular from above — the ONLY elite where the front prow is wider than the rest of the hull. Built for smashing straight through barriers. Must NOT share Tunneler's conical drill or Transfer's booster nozzles`. Output: `assets/art/source/elite_breacher_01.png`.

**Review requirement added by D-128:** each of the 5 accent colours (plus the Assembler's icy-white below) must pass the same yellow/white/red-giant star-skin legibility check the single shared cyan accent already passed in the mockup review — this hasn't been re-verified per-colour yet.

## 26. Assembler (boss)

Largest and most distinct silhouette in the game — must be unmistakable even at strategic zoom. Its growth-over-time is procedural (D-110); this is the base, unaugmented form. Per D-128, Assembler is NOT a sixth elite colour — it keeps a larger, more intense version of icy white so it reads as boss-tier rather than "one more elite."

```
[COMMON BLOCK]
[OBJECT CAMERA]
SUBJECT   a vast, heavily-built accreting-hull machine — visibly larger
          and more massive than every elite, hull made of layered
          plating that looks like it has consumed and incorporated
          structure into itself, reads immediately as "boss", not
          "elite"
MATERIAL  matte dark hull, same family as the standard machine and
          elites, PLUS a larger/more prominent ICY WHITE emissive
          accent than any elite carries (not one of the 5 elite hues)
          — this is the largest, most dangerous machine in the game
SCALE     noticeably larger in composition/proportion than the elite
          templates above — this is a boss, not another elite
NEGATIVE  [common block negatives] plus: no warm-coloured accents, not
          fully emissive (hull stays matte dark, accent stays
          localized), not one of the 5 elite accent colours, not
          multiple separate glowing areas (T-079's first attempt was
          rejected for exactly this — a lit disk plus separate lit
          ring sectors both counted as separate glowing areas)
```

Output: `assets/art/source/assembler_01.png`.
