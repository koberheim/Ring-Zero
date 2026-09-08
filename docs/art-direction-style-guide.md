# RING ZERO — Art Direction Style Guide

**Status:** Decided. Supersedes the 2026-09-07 skeleton. Resolves D-030 (final art direction) via **D-120**; see also **D-121** (wedge destruction destroys occupants) and **D-122** (Alt tactical overlay), both raised by this pass.
**Decided by:** Kevin, 2026-09-08, in a structured Q&A pass with Astra.
**Production method:** AI-generated source art, processed to game-ready. Budget and process live in [art-asset-pipeline.md](art-asset-pipeline.md).
**Supersedes:** D-098's exploratory industrial/painterly toggle. T-049's two treatments were the *comparison*; this guide is the *answer*, and it is neither of them exactly.

---

## 1. Core visual identity

> **Lit industrial hardware, painterly light, mostly void.**
> A thin skeletal wheel of working machinery, lit by the star it cages, hanging in near-black space.

Three commitments make this concrete, and every asset is checked against them:

**Structure is the figure; space is the ground.** The fortress is the lit, detailed subject. Space is near-black. This is the industrial reference's value relationship, not the painterly reference's — we never invert to dark-silhouette-structure-on-bright-field.

**The fortress is thin, not solid.** Rings are narrow structural bands with radial spokes. Most of the area between rings is open void — that void is where turrets project, where machines travel, and where the fight happens. The T-049 build's wide opaque plates are *not* the target and are the reason its strategic view flattened to a grey disc.

**Painterly lives in the light, not in the surfaces.** The awe comes from the star's corona bleeding outward through the gaps and fading to dark starfield at the frontier — atmosphere as the medium the hardware sits in. Surfaces themselves stay industrial: metal, wear, working lights.

**Test any asset against this:** *Is it lit hardware? Does it leave the void alone? Does its light come from the star or from its own working lamps?*

### Camera and projection (D-123)

**20° from vertical, orientation fixed, no rotation.** A slight tilt off true top-down. The polar grid, coordinates and every rule are unchanged.

At this angle the ground plane is only foreshortened ~6% — imperceptible on its own. **All of the dimensional effect comes from objects having visible height** (`sin 20°` ≈ 0.34× of an object's height shows as its side). The tilt exists to make that height *honest*: faked height in a true top-down view points one direction on screen, which fights the requirement that everything rotates to face outward at twelve bearings.

Consequences that bind every asset:

- **Ring bands and spokes have real depth** — beams and girders with visible side faces, not flat lines. This is where most of the industrial weight comes from, and it is procedural, so it costs no image budget. Thickness also gives the damage read somewhere to live: buckling and shearing show in profile.
- **Buildings use one sprite each, rotated** to face outward. The small lean error at 20° is accepted deliberately; keeping the angle small is exactly what keeps this affordable. If it reads badly in engine, the fix is a smaller angle, not more art.
- **The star stays circular.** It is a sphere, and spheres project as circles from any angle — the squash applies to the ground plane only.
- **Sprites anchor at their ground point**, so a building's footprint sits on its true slot and clicking matches what the player sees.
- **World-space text** — labels and the Alt HP bars — never inherits the squash or the height offset.
- Draw order is painter's algorithm by screen Y.

---

## 2. The star

**Canonical and reactive.** One star identity per run, whose corona is a status display you never have to read:

| State | Corona |
|---|---|
| Normal | steady, slow swirl |
| High power draw | pulses with the load |
| Brownout | guttering, dimmed, unstable |
| Solar ability cast | flare toward the target arc |

**Skin pool for variety.** Red giant, yellow, white and variations. A continuous run keeps its star; starting a fresh run from zero randomises the skin from the pool. **Consequence:** every other colour in the game — emissive accents, weapon fire, status colours — must remain legible against *every* skin. Nothing may depend on the star being one particular colour.

**Dominance shrinks as you expand.** Early game the star is large and everything is backlit and close; as rings are purchased outward it becomes a hot core in a growing structure. The visual arc mirrors the run's arc: furnace → fortress.

The star sits *inside* the innermost ring, so it is never the background behind structure — it is a bright object at the centre with black space between the rings. This is what lets "big star" and "lit structure on dark void" coexist.

---

## 3. Ring structure and wedge plates

### Geometry

```
   (*)   core
    :
    :    gap — open void, kill zone
    :
  ==╤════╤════╤══  RING 1 band  (thin, at the ring's OUTER radius)
    │    │    │    radial spokes, on wedge boundary lines
    T    T    T    turrets, mounted on the band, facing OUTWARD
    :
    :    gap — open void, kill zone
    :
  ==╤════╤════╤══  RING 2 band
```

- **Band at the outer radius.** Each ring's band sits on the line machines must cross, so the barrier and the crossing line are the same object.
- **Turrets face outward.** Weapons mount on the band and project into the gap ahead of it — the annulus they defend is their field of fire.
- **Spokes are shared.** Radial truss members sit on wedge boundary lines and belong to *both* adjacent wedges.
- **Spokes render as open truss.** Machines cross wedge lines freely in the rules, so spokes must visibly be girders, not walls. *(Engineering note: this is the one depiction/rule pairing to watch — if spokes ever read as solid, players will expect angular movement to be blocked when it isn't.)*

### Destruction and repair

| Event | What happens visually |
|---|---|
| One wedge destroyed | that wedge's **band segment disappears**; flanking spokes remain |
| Two adjacent wedges destroyed | the **shared spoke between them also goes** |
| Wedge repaired | band segment reappears |
| Ring collapsed | whole ring dark and gone |

A breach is therefore a literal hole in the wheel — the most important rule in the game is legible as absence.

### Damage before destruction

**Lights failing** carries continuous HP, and comes free with the lighting model in §8:

| HP | Read |
|---|---|
| 100% | steady warm running lights, lit seams |
| ~60% | some lamps dead, occasional flicker |
| ~25% | amber, strobing, mostly dark |
| 0% | segment gone |

A failing arc is visible as a spreading dark patch from full strategic zoom. Exact numbers come from the Alt overlay (§7), not from the world.

### Ring identity by index

Material and colour temperature shift outward, so ring number is legible without reading anything, and the strategic view is a banded gradient rather than uniform grey:

| Rings | Character |
|---|---|
| Inner | scorched, hot, dense, sun-worn |
| Middle | working industrial grey, the baseline |
| Outer | pale, cold, sparse, frontier |

*(Exact tier boundaries are first-pass tuning under D-033, set in the pipeline doc's manifest.)*

### Battle history

Scorch, pitting and torn plating accumulate and **persist through repair as patch welds and mismatched plate**. A veteran ring looks veteran; a fresh purchase looks new. This is a major source of strategic-view variation at no per-asset cost beyond one decal sheet.

### Strategic-zoom legibility

T-049 proved the failure mode: lit-structure-on-dark collapses into a featureless grey disc when zoomed out. Four mitigations stack, and all four are required.

**1. Thin structure, mostly void.** The primary fix and the reason the rest are affordable. A skeletal wheel has an inherently structured wide view; a solid disc does not. This is what T-049 got wrong.

**2. Structural silhouette variation.** Spokes, pylons, antenna masts and docking spurs break the smooth ring stack so the fortress has an outline with character rather than being a set of nested circles. It should be recognisable as a shape — close to a logo — at any distance.

**3. State-coloured wide view.** As zoom increases, rings shift toward reading by state — intact / damaged / broken / powered / browned-out — so the far view becomes the information display you zoomed out to consult. This is the schematic-readout candidate borrowed as a *zoom level only*, never as the game's identity, and it must blend smoothly rather than snapping between two looks. Respects D-119's marker suppression.

**4. Ring-index banding and battle history**, per the two sections above — the disc is never uniform because temperature varies by radius and history varies by wedge.

---

## 4. Buildings and turrets

**Shared mount, distinct heads.** One generated mount/base asset is reused under all thirteen buildings, giving the fortress a coherent kit language. Identity lives entirely in the upper assembly, and every head telegraphs its mechanism:

| Building | Head reads as |
|---|---|
| Flak Emplacement | short multi-barrel cluster |
| Mass Driver | long heavy rail |
| Lance Emitter | focusing array + emitter |
| EMP Node | coil rings / dish |
| Point Defense | small fast twin mount |
| Armor Plating | applied slabs, no head |
| Repair Node | crane/manipulator arm |
| Relay | mast and dish (ring-level, not slot-attached — D-104) |

Everything mounts on the band and faces outward. Silhouette is the primary identification channel; colour is never the sole cue (D-115).

---

## 5. The horde

### The species

**Simplified harvester drones — a machine swarm at heart.** Blunt, functional mining machinery: intake maws, grinding heads, collection bays, solar vanes. They are not soldiers attacking you; they are equipment *processing* you. Detail is deliberately low — hundreds to a thousand will be on screen, and the swarm reads as a mass, not as a gallery.

They are a purpose-built species with their own design language, distinct from your salvaged-industrial fortress.

### Scale — the *They Are Billions* model

Machines have a fixed small world size; the camera does the work:

| Zoom | Read |
|---|---|
| Strategic | indistinguishable mass — a tide, a pressure front |
| Close | individual machines, readable as distinct units |

This is why standard-machine art can be simple and why elite art is worth the detail: the elites are what you can still pick out when zoomed out.

### Emissive is rank, and it is cold

| Class | Treatment |
|---|---|
| Standard machine | pure dark silhouette, no emissive |
| Elite (5 kinds) | silhouette + **cold** emissive accent (cyan / hard white) |
| Assembler (boss) | silhouette + large cold accent, growing as it consumes |

Glow is information, not decoration: **any lit shape in the swarm is not an ordinary machine.** Cold accents keep the horde legible against every warm star skin and never compete with your own warm working lights or muzzle flashes (§8).

### Elite silhouettes telegraph the mechanic

Learned once, used forever — the shape tells you what it is about to do, so you can respond before it acts:

| Elite | Silhouette | Mechanic it announces |
|---|---|---|
| Tunneler | low burrowing rig, drill head | goes under everything |
| Transfer | boosters and launch rails | one orbital hop past a ring |
| Foundry | huge, anchored, grinding press | parks and grinds a wedge down |
| Sapper | fine seeking probes, sensor mast | beelines for your relay |
| Breacher | armoured ram prow, wedge-shaped | smashes walls head-on |
| Assembler | vast accreting hull, visibly grows | eats structure and gets stronger |

---

## 6. Terrain and shadow

Terrain is **physical by default, explicit on Alt** (§7):

| Item | Physical read | On Alt |
|---|---|---|
| Debris Field | inert wreckage and drifting scrap — visibly *not* a wall, nothing to shoot | exact blocked footprint |
| Tractor Lane | visible drift/current in the void | direction arrows, exact influence area |
| Occlusion Screen | soft real shadow cast outward from the screen | exact shadow zone edges and ring span |

Debris must never read as attackable structure — it has no HP and cannot be targeted, and looking like a wall would be a lie about the rules.

---

## 7. UI, HUD and the tactical overlay

The industrial UI skin from **D-115** stands: gritty industrial sci-fi, transport-style typography, compact instrument panels, non-colour-only status cues, 16:9 at 1440×810 base. **D-119**'s strategic-zoom marker suppression also stands.

**New: hold Alt reveals the tactical layer (D-122).** One key, one mental model, for every rule the world hides:

- wedge HP bars above each wedge
- terrain effect zones with exact edges
- tractor lane direction arrows
- weapon range arcs

The battlefield stays clean and physical during normal play; all hidden numbers are one key away. This is the standing pattern — any future invisible rule belongs on the Alt layer rather than becoming permanent world clutter.

---

## 8. Colour and lighting

### Colour language

| Role | Colour |
|---|---|
| Star | warm — amber, orange, white (per skin) |
| **Your** structure lights | warm amber / warm white working lamps |
| **The horde** | cold cyan / hard white accents |
| Terrain | desaturated neutral grey-blue |
| Status | amber = warning, red = critical |

Warm belongs to the star and to you; cold is intrusion. The two never compete for the same meaning, and cold accents stay legible against a red-giant, yellow or white star alike.

### Lighting model

- **Star key light** on all inward-facing surfaces — hot rim light, strongest on inner rings.
- **Local industrial lighting** on outward-facing surfaces: strip lamps, hazard flashers, lit seams, glowing windows. This is what keeps outer rings alive when the star's key falls off, and it is what makes the fortress read as inhabited working plant rather than scenery.
- Those same local lights are the damage read (§3) — dying structure is literally going dark.

### The void

```
GAP 1–2    warm plasma haze, corona wisps
GAP 3–5    dim amber, thinning
GAP 6+     near-black, cold, dark starfield
```

Corona bleeds outward and tapers into a mostly dark starfield. This is the painterly half of the brief, delivered as light and air rather than as painted surfaces — and it gives the outer rings their cold-frontier identity for free.

---

## 9. Animation and VFX

### Weapon fire — distinct per weapon, drawn procedurally

No sprite sheets: code and shaders, so it costs nothing from the image budget, scales at any zoom, and tunes by numbers.

| Weapon | Firing language |
|---|---|
| Flak | short cone of bursting flak |
| Mass Driver | single fast slug + recoil flash |
| Lance Emitter | sustained blooming beam |
| EMP Node | expanding pulse ring |
| Point Defense | rapid tracer stream |

This closes the open T-056 requirement (no projectile visuals) with an approach, not just a task.

### Destruction — restrained kills, dramatic structure loss

| Event | Treatment |
|---|---|
| Machine kill | **minimal** — brief, small, quiet |
| Wedge breach | loud: plate shears, debris scatters, lights die along the arc |
| Ring collapse | very loud, slow, lingering — the whole ring goes dark and breaks apart |
| Core loss | everything; the star reacts |

Kills stay quiet deliberately: a thousand-machine fight must remain readable, and the dark-silhouette horde depends on nothing else competing for attention. Structure loss lands *because* nothing else is shouting.

---

## 10. Production scope

- **Budget:** ~35–45 generated source images for a first complete pass.
- **Method:** AI-generated source art, processed to game-ready assets.
- **Stays procedural (no image cost):** ring geometry, bands, spokes, damage masks, the star and corona, the void/atmosphere, all weapon VFX, all destruction VFX, the Alt overlay.
- **Gets authored art:** ring band surface strips, decal sheets, damage sheets, the shared building mount, thirteen building heads, standard machine, five elites, Assembler.
- **Four consistency mechanisms are mandatory** — style anchor first, fixed prompt templates, post-process normalisation, in-game review gate. All four are specified in [art-asset-pipeline.md](art-asset-pipeline.md).

### What this guide does not settle

- Final branding/title treatment (D-034, still Kevin's).
- Audio, music, and any world assets beyond this first pass.
- Exact numeric tuning of ring tier boundaries, salvage fraction, light-failure thresholds — all first-pass under D-033, adjusted by play.
- Whether spokes ever need a movement-cost rule to match their appearance (currently: no — they render as open truss precisely so no rule change is needed).
