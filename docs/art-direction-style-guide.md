# RING ZERO — Art Direction Style Guide (outline)

**Status:** Skeleton only. Sections are headers and open questions, not decisions or content. Kevin and Astra work through this together in a separate pass. Nothing here supersedes or resolves D-030 (final art direction remains open) — see `docs/reviews/phase8-effort-briefing.md` and the D-098 art experiments (`docs/ART-PREVIEW.md`, captures in `docs/reviews/artifacts/T-049-*`) for what's already been playably tested.

**Starting point:** Kevin's direction is a combination of industrial-gritty and painterly-awe — the two treatments T-049 already built and captured, rather than picking one exclusively or exploring the third candidate (schematic readout, §15 of the design spec). This guide exists to turn "a combination of both" into concrete, buildable rules.

---

## 1. Core visual identity statement
One or two sentences that describe the game's look so any future asset can be checked against it. What does "industrial + painterly" mean together, not as two separate modes?

**Q&A to work through:**
- Is this a blend applied uniformly to everything, or a *split by subject*: e.g., structure/hardware rendered industrial, the star/space/atmosphere rendered painterly?
- Does the ratio change with zoom (industrial detail up close, painterly wash at strategic range), echoing T-049's own "detail simplifies at wide zoom" finding?
- One signature image that captures the whole game's identity — do we have one yet, or does it come out of this process?

## 2. The star
The design spec calls the star "both your economy and your artillery" and flags it as deserving spectacle (§15). T-049 already built red giant/yellow/white palettes with animated corona and swirl.

**Q&A:**
- Which palette(s) survive — one canonical star, or does star type vary by run/seed/meta-unlock?
- How much of the painterly treatment's atmospheric drama is kept when the rest of the game leans industrial?
- Does the star's visual state ever reflect gameplay (health, power draw, brownout) or is it purely cosmetic?

## 3. Ring structure and wedge plates
The concentric rings are the game's core silhouette and the thing that must stay legible at unbounded zoom (§15's stated hard constraint).

**Q&A:**
- Intact / damaged / broken / collapsed wedge states — what reads each state at a glance, at both close and strategic zoom?
- How "industrial" do plates get up close (panels, rivets, grime, wear) before that detail has to disappear at range, and what's the simplification rule?
- Does ring material/finish change with ring index (inner = dense/hot/industrial, outer = sparse/cold/painterly) as a way to blend both styles spatially rather than uniformly?

## 4. Buildings and turrets
Five weapons, five structure items, three terrain items, all currently placeholder geometry.

**Q&A:**
- Silhouette-first or detail-first identification — can a player tell Flak from Mass Driver from Point Defense by shape alone at typical play zoom?
- How much individual "character" per building (worn industrial hardware) versus a unified kit language?
- Does this block or follow the projectile/VFX work (item 3 from Kevin's list) — do turret art and their firing effects get designed together?

## 5. The horde (machines and elites)
Von Neumann harvesters, solar-powered, "shadow is a weapon" per §2/§10 of the spec. Currently placeholder markers only.

**Q&A:**
- Do machines read as mechanical/industrial (matching the player's own aesthetic, since the spec frames them as a corrupted mirror of the player) or as something visually distinct?
- How do the five elites (Tunneler, Transfer, Foundry, Sapper, Breacher) read as silhouettes distinct from standard machines and from each other, at a glance, mid-swarm?
- Assemblers (bosses) — how much bigger/more distinct do they need to be to register as a real event?

## 6. Terrain and shadow
Debris Field, Tractor Lane, Occlusion Screen — the newest category, already rule-complete (T-050/T-051) but placeholder-rendered.

**Q&A:**
- Occlusion Screen's shadow is a gameplay-legible zone (it slows machines) — how visually loud does the shadow need to be to read as "this area is different," independent of final art style?
- Does Debris Field read as "dead"/inert industrial wreckage, or something else — it's explicitly not a wall (no HP, can't be attacked)?

## 7. UI and HUD
T-053 is actively reworking layout/compactness; this guide is about *visual skin*, not layout, but the two will eventually meet.

**Q&A:**
- Does the HUD stay in a clean "schematic readout" style (per §15's third candidate) even if the game world itself is industrial/painterly? Many games mix a diegetic-feeling world with a clean non-diegetic HUD.
- Color language for status (intact/damaged/broken/collapsed, powered/brownout, cooldown-ready) — does this get fixed here or in a separate UI-specific pass?

## 8. Color and lighting language
**Q&A:**
- Palette: what's the "home" color (player structure) versus "threat" color (horde) versus "neutral" (terrain, background)?
- How does lighting direction work when the sole light source is a central star the camera looks down on from above its pole — is it a top-down key light, a rim-light-only treatment, or something else?

## 9. Animation and VFX language
Overlaps with Kevin's item 3 (no projectiles yet) and the star's swirl/corona work already done in T-049.

**Q&A:**
- What's the visual vocabulary for a hit, a kill, a wedge breaking, a ring collapsing, an ability cast — is there a consistent "impact" language across all of these?
- Weapon-specific: does each of the five weapons get a distinct projectile/beam/pulse treatment (Flak flak-burst, Mass Driver rail-like shot, EMP Node pulse ring, Lance Emitter beam, Point Defense rapid tracer), or a shared minimal treatment for cost reasons?

## 10. Production scope and constraints
**Q&A:**
- Solo/small-team budget reality: which of the above are hand-authored assets versus procedural/shader-driven (the spec already commits to procedural ring geometry regardless of style, §15)?
- What's genuinely needed for the next playable milestone versus deferred to a later art pass?
- Does anything here block Phase 9 (enemy roster) engineering work, or can rules/engineering keep proceeding on placeholders while this guide is worked out?

---

## Suggested working order
Once we sit down to fill this in, doing it in roughly this order avoids rework: (1) core identity statement → (2) star → (3) rings/plates → (8) color/lighting, since these four constrain everything else. Buildings, horde, terrain, UI, and VFX can follow in any order Kevin prefers. Production scope is a final pass over whatever the earlier sections commit to.
