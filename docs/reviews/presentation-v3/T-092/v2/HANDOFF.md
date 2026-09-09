# T-092 v2 asset handoff for E/A

**Status: provisional implementation ready; human and native acceptance pending.** Latest explicit user continuation, recorded in the T-092/shared contracts, permits this production without treating the untested silhouette gate as passed. The original v1 package remains historical and unchanged.

Read `assets/art/machines/presentation_v3_v2/metadata.json` (`ring-zero-elite-art/2`). It is the exact machine-readable interface. No shared view or shipping texture replacement is included in this delivery.

| Class | Frame / atlas px | Pivot px | World canvas units | Occupied physical floor | Loop seconds |
|---|---|---|---|---|---|
| Tunneler | 128 / 512x256 | 64,64 | 15 | 16 px | 0.8 |
| Transfer | 128 / 512x256 | 64,64 | 15 | 16 px | 1.0 |
| Foundry | 128 / 512x256 | 64,64 | 21 | 16 px | 1.2 |
| Sapper | 128 / 512x256 | 64,64 | 15 | 16 px | 1.6 |
| Breacher | 128 / 512x256 | 64,64 | 15 | 16 px | 0.8 |
| Assembler | 256 / 1024x512 | 128,128 | 34 | 28 px | 2.0 |

Every class has **8 frames in a 4-column, 2-row atlas**. Frame `f` uses `Rect2((f % 4) * size, floor(f / 4) * size, size, size)`. Paths are `res://assets/art/machines/presentation_v3_v2/<kind>_<channel>.png`, where channels are `albedo`, `normal`, `emission`, `alpha`. There are 24 PNG atlases. Metadata includes exact frame rectangles, timestamps, alpha bounds and projected visible extents in world units. These are artwork extents, not collision/rule footprints.

The model origin `(0,0,0)` is the ground pivot, fixed at frame center. Model forward is **+Y**, which projects **up** in the image. Ground is XY; height is Z. Camera is orthographic, **20 degrees from vertical**, on the negative-Y side, looking at the origin. Projection is already baked into artwork. Preserve the pivot through rotation and verify any parent Y squash in the live bearing check. The current release's `point.angle() - PI/2` rotates an up-facing sprite inward; retain authoritative heading rather than introducing a new facing rule.

Physical floors apply to the **occupied shape**, not transparent canvas size. Metadata's `min_occupied_extent_fraction` conservatively takes the smallest longest alpha extent over all eight poses and all twelve 30-degree sprite bearings. E can use:

`canvas_world_size = max(world_canvas_size, physical_floor_px / (world_to_physical_pixel_scale * min_occupied_extent_fraction))`

The scale must include actual window/viewport scaling. The supplied world sizes preserve the existing release's provisional 15/21/34-unit canvases. Test floors after all transforms at 1080p/1440p; this formula is not itself native evidence.

Albedo is **unlit sRGB straight RGBA**: material colors and actual geometry boundaries, without beauty-reference light or glow. Normals are **linear data**, obtained from the modeled surface Geometry Normal, transformed WORLD to CAMERA, with Blender camera Z explicitly inverted to point toward the viewer. Encoding is `RGB = (right X, up Y, toward-viewer Z) * .5 + .5`; neutral is approximately `(128,128,255)`. Green remains camera-up. A known horizontal roof validates approximately `(128,171,247)`, reflecting the 20-degree tilt. Final opaque normal vectors are renormalized after reduction and have quantization error below 0.0063 in length.

Emission is **linear RGB cold color/mask with matching alpha**, without bloom or baked lighting. Omit an extra sRGB/source-color decode when sampling it as data; runtime supplies intensity and glow. D-128 hues remain cyan, blue, teal-green, violet and icy white; boss is icy white. Normal and emission share each albedo frame's exact region/pivot. A confirmed the right/up/viewer convention. The Godot 2D adapter must perform its required conversion exactly once and rotate normal XY with the sprite; see [CanvasItem NORMAL_MAP conversion](https://docs.godotengine.org/en/4.4/tutorials/shaders/shader_reference/canvas_item_shader.html) and [CanvasTexture coordinate convention](https://docs.godotengine.org/en/4.0/classes/class_canvastexture.html). Do not infer normals from grayscale albedo.

Use lossless texture import, mipmaps on and repeat off. The normal texture is data, not sRGB color. No green flip has been applied during export. Albedo reduction uses linear-light alpha weighting and exact area averaging; normals use alpha weighting then vector renormalization. RGB extends four texels beyond coverage while alpha stays unchanged, and no black albedo RGB remains immediately outside coverage. This supplies edge colors for linear filtering; retain the importer’s border protection. The grayscale alpha atlas equals every RGBA channel's coverage.

Local mechanical phases: drill rotation, paired launch compression, processing jaw, radial probe reach, ram recoil, feeding clamps on the accreted ring. `frame = floor(presentation_phase_seconds / period_seconds * 8) % 8`. These loops are **presentation poses**, not attack/hop/growth events. Event-gate action phases from existing authoritative state/events. Do not move simulation positions to animate a part. Assembler's actual growth still follows real accumulated-growth state; the local feed loop does not grant growth. Reduced motion freezes frame 0. All periods are provisional presentation values; the source action timeline stores eight phase samples, while this table defines class-specific runtime timing.

E integration must still prove occupied floors, mixed crowd (128 production and separate 800/1000 stress), original 1031-sprite diagnostic, three star palettes, normal orientation at all bearings, pivots, reduced motion, motion/heading, and timing. Human v2 recognition remains pending; use `public/index.html`, keep `reviewer-private/answer-key.json` private, and record >=11/12 with no recurrent Tunneler/Transfer/Breacher confusion. No production acceptance or T-079 closure follows from this file.
