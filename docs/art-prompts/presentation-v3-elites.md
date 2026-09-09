# T-092 elite silhouette brief v1

Approved scope: D-131/D-135 and `docs/contracts/T-092-elite-art.md`. This replaces the old one-accent elite template only within the approved Phase 14 scope. Standard drones retain D-120 restraint.

The first deliverable is an identification trial, not finished art. All six classes must be recognizable as black shapes on white at 16 physical pixels after a reference demonstration. Kevin or his designated reviewer must score at least 11/12 correct, with no recurrent Tunneler/Transfer/Breacher confusion. Detailed asset production waits for that recorded result. The author cannot pass this gate by self-review.

| Class | Approved dominant form | v1 blockout construction | Preserve in later production |
|---|---|---|---|
| Tunneler | Long drill/worm-like cutting axis | Narrow segmented body with tapered forward cutter | Long axis and small width; do not widen into a ram |
| Transfer | Open horseshoe/paired launch form | Two thick parallel rails joined behind a large open gap | Void between paired rails; do not fill the horseshoe |
| Foundry | Broad anchored processing body | Wide raised press, front jaw, four projecting feet | Squat broad body and planted corner anchors |
| Sapper | Radial reaching probes | Six thick probes around a small central hub | Radial reach and intervening void; probes must survive scale |
| Breacher | Solid asymmetric wedge ram | Offset solid prow and one raised shoulder | Solid unequal wedge; no narrow drill neck or twin rails |
| Assembler | Accreted broken-ring/hull mass | Uneven rectangular hull fragments around a permanently open center | Broken-ring void, accretion asymmetry and separate hull masses |

No new mechanic, class, heading rule or motion behavior is implied by these forms. Forward in source geometry is +Y; ground is XY; Z is real height. The fixed orthographic camera is 20 degrees from vertical, located on the -Y side. Every model has its ground pivot at (0, 0, 0). The clay sheet documents real blockout side depth only; no albedo, emission, normals or animation has been authored yet.

Source: `scripts/art/t092_silhouettes_blender.py`, executed through the open Blender MCP instance into the separate `T092_Silhouette_v1` scene and `T092_Silhouette_Blockouts_v1` collection. The initial Untitled `Scene` with Cube/Light/Camera was inspected and preserved. The isolated library is `assets/art/source/presentation-v3-elites/t092_silhouette_blockouts_v1.blend`; Kevin's current file was not saved or overwritten. Live lease released after source render work.

Review tiles come from the alpha of native 256x256 transparent Workbench renders. Crop nonzero alpha bounds, scale longest extent to 16 with Lanczos, threshold at 128, center on a 16x16 white canvas. This deliberately discards surface lighting, hue, glow and detail. Two exact sprite orientations (0 and 180 degrees) per class are shuffled into twelve trials. Full twelve-bearing live acceptance is a later separate check. Trial re-centering is for recognition only and is not a shipping pivot recipe.

After a passing human result, retain the approved cold-family elite accents under D-128 as supporting identity; produce actual albedo/normal/emission/alpha and mechanical motion under the task contract. Document tangent/image axis and green-channel conventions against A's actual lighting interface before export. Do not invent a normal format here. Provisional in-engine physical floors remain elites 16 px, Assembler 28 px; the stricter isolated human trial shows even Assembler at 16 px. Do not substitute the trial for star-palette, mixed-crowd, native strategic scale, all-bearing seating, motion/pivot or performance acceptance.
