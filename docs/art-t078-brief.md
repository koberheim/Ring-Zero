# RING ZERO — T-078 Brief: Pipeline Vertical Slice

**Purpose:** prove the *production* art pipeline end to end on five assets before committing the remaining ~35-image budget. This is different from the earlier mockup review (`docs/art-mockup-brief.md`), which validated art *direction* using full dramatic scenes. This tests whether isolated, flat-lit, single-subject source images can actually become clean game assets.
**Self-contained:** this file plus `docs/art-prompts/v1-templates.md` is everything needed. Background/reasoning lives in `docs/art-direction-style-guide.md` and `docs/art-asset-pipeline.md` if wanted, but isn't required to execute this task.
**Task record:** T-078 in TASKS.md.

---

## What's different from last time

The mockup review produced beautiful full scenes — dramatic lighting, motion, dust — and that was correct for judging direction. **None of that belongs here.** Every image in this task must be a single isolated subject, flat-lit, on a plain background, because these images get processed (de-lit, palette-mapped, trimmed, scaled) into assets that get *relit dynamically in the running game*. Baked scene lighting on a production asset will look wrong the moment the star moves or a brownout hits.

If any generated image looks like a finished game screenshot, it's wrong for this task — it should look more like a product photo of one part.

---

## Step 1 — Style anchor (do this first, and only this, until approved)

Generate the 5 anchor candidates from `docs/art-prompts/v1-templates.md` §1. Save to `assets/art/anchor/anchor_candidate_01.png` through `_05.png`.

**Stop here and report back** with all 5 for review before continuing. The chosen anchor sets wear level, panel density and metal tone for every asset after it — nothing else should be generated until one is picked.

## Step 2 — Five-asset vertical slice

Once the anchor is approved, generate the five assets below using their templates in `docs/art-prompts/v1-templates.md` (§2–§6), matching the anchor's wear level and detail density:

1. **Ring band strip** (working tier) — §2
2. **Decal sheet** — §3
3. **Building mount** — §4
4. **Building head** (Mass Driver) — §5. If the approved anchor already reads as a clean standalone head, ask before deciding whether to reuse it or regenerate separately.
5. **Standard machine** — §6, with its hardened emissive constraint

Save raw outputs to `assets/art/source/` using the filenames given in each template section.

## Step 3 — Normalize

Per `docs/art-asset-pipeline.md` §4, apply to each of the 5 assets:

```
1. DE-LIGHT     flatten any residual lighting/shadow to even albedo
2. TRIM         crop to content bounds
3. CENTRE       align to the asset's natural pivot
                (mount/machine: ground contact point; band strip: left edge;
                 decal sheet: no single pivot, leave as a sheet)
4. SCALE        resize to the fixed size below
5. EXPORT       PNG, alpha channel preserved, no compression artifacts
```

| Asset | Export size |
|---|---|
| Ring band strip | 1024 × 128 |
| Decal sheet | 1024 × 1024 |
| Building mount | 256 × 256 |
| Building head | 256 × 256 |
| Standard machine | 64 × 64 |

Write and run a small script for this rather than doing it by hand — it will be reused for the remaining ~30 assets in later stages. Save it as `scripts/art/normalize_asset.py` (or equivalent) so it's reusable, not a one-off.

Save normalized outputs to their real locations:
- `assets/art/bands/band_working_01.png`
- `assets/art/decals/decal_sheet_01.png`
- `assets/art/buildings/mount_01.png`
- `assets/art/buildings/head_mass_driver.png`
- `assets/art/machines/machine_standard.png`

## Step 4 — Hard check on the standard machine specifically

Before anything else: open `machines/machine_standard.png` and look for any lit detail at all — a window, a seam glow, a running light, any colour that isn't the matte hull tone. **This exact asset broke the emissive-is-rank rule on the first mockup attempt (D-124).** If you find anything lit, regenerate from the template in step 2 rather than accepting it. Report explicitly whether this check passed on the first attempt or needed a regeneration.

## Step 5 — In-engine review gate

Import the 5 normalized assets into the project (`scenes/art_preview.tscn` is the existing preview scene) and check each against `docs/art-asset-pipeline.md` §6:

1. Close zoom — does it read as the thing it is?
2. Strategic zoom — does it survive minification, or vanish?
3. Against the star — does it fight the corona's colour? (Canonical star for this pass is **yellow** — see `docs/art-asset-pipeline.md`.)
4. In a crowd (standard machine only) — does the silhouette hold up tiled/duplicated many times?
5. At different rotations (mount, head, machine) — does it still sit correctly when rotated to face outward, or does it visibly lean?

If this requires engine wiring that doesn't exist yet (sprite-based building rendering, a machine sprite path), note exactly what's missing rather than skipping the check — that gap is real information for T-074/T-079, not a reason to wave the asset through.

---

## Report back

1. Path to every generated and normalized file.
2. Anchor: which candidate was chosen and why (or that you're waiting on approval before continuing).
3. For each of the 5 slice assets: pass/fail on each of the 5 review-gate checks, with a one-line reason for any fail.
4. Standard machine emissive check: passed first try, or needed a regen — and why if it needed one.
5. **The real decision this task answers:** is this pipeline (prompt → generate → normalize → import → review) producing usable game assets, or did something break down? If something broke, say exactly where — that's more valuable than a partial pass.

Do not proceed to generating the remaining ~30 production assets (pipeline stages 2–4) without this report being reviewed first.
