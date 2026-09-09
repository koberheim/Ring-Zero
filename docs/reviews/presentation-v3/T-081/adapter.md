# T-081 rendering adapter for B, D and E

Implementation interface frozen for review. Mobile is selected; measured backend choice and acceptance limits are in `implementation-report.md`. No gameplay APIs changed.

## Ownership and composition

`application.stage` owns its own `World3D` and uses an opaque background. This keeps its `WorldEnvironment` from also post-processing the parent/root viewport after UI composition. The main world canvas and space layer -10 are included by `Environment.BG_CANVAS`, `background_canvas_max_layer=0`. Existing HUD CanvasLayer1 and application menu CanvasLayer100 are excluded. New interface layers must remain >0. Transient world effects should draw on the main world canvas (or a CanvasLayer<=0); they then enter final world glow automatically.

The fortress has two isolated `World2D` SubViewports: `board_viewport` for albedo, `material_viewport` for normal/emission attributes. They share size, `canvas_transform`, `UPDATE_ONCE` invalidation and static draw commands. They do not share world lighting. `board_sprite` composites their textures through `core_response.gdshader`; its inverse raster transform preserves the original camera/picking alignment. A light in the main World2D is not expected to reach inside either cache. The core response is evaluated on the final composite, so changing palette/HP does not redraw static geometry.

Compatibility uses LDR caches. The Mobile comparator uses HDR2D caches because native LDR transparent-buffer readback returned alpha1/3 for opaque geometry on the tested engine/driver; HDR caches fixed this and all twelve native normal-orientation checks. Its albedo is converted from linear to sRGB explicitly for the LDR final stage. Material channels are linear data; never apply a color-space conversion to them.

## Stable methods

```gdscript
release_view.update_core_lighting(palette: int, energy: float) -> void
# palette clamped0..2 (red/yellow/white); energy clamped0..1.
# Updates shader uniforms and effects-off glow flag; no geometry invalidation.

release_view.lighting_state() -> Dictionary
# palette:int, color:Color, radius:float, height:float, enabled:bool,
# world_layer_max:int, albedo_redraws:int, material_redraws:int.
```

The existing `_refresh_board_cache()`, `_set_zoom()`, board transform, camera, drawing and hit-effect interfaces remain. D must preserve invalidation of **both** caches on size/zoom, visibility coverage, tactical mode, damage, occupants, wall/relay state and collapse. Panning a fully covered strategic fortress moves the composite without redraw. Dynamic palette/HP updates must remain outside the geometry stamp. When resizing, synchronize both raster sizes/transforms and shader `raster_size`, `raster_origin`, `raster_scale`. Do not set `UPDATE_ALWAYS` on these static caches.

## Material conventions

`FortressLighting.material_texture(albedo, family)` returns a CanvasTexture. `diffuse_texture` is source albedo; `normal_texture` is a declared authored geometric proxy (bevel/dome or band cross-section); `specular_texture` is repurposed as a separate emission mask. The proxy maps are not physical normals recovered from grayscale AI art. Families cover mount, head, band, wall and terrain. Wedge lamps retain their existing HP-dependent draw mask; dead relay tint suppresses authored emission. Fortress emission scales with core energy.

Proxy maps encode RGB=((image-right normal+1)/2,(image-down normal+1)/2,(toward-viewer normal+1)/2). The material pass explicitly samples `NORMAL_TEXTURE`, avoiding Godot's implicit green inversion, and rotates the normal with an actual UV-derivative tangent basis. The cached attribute raster packs world-normal XY in RG, emission in B, coverage in A. The composite unpremultiplies the packed channels and reconstructs positive normal Z. Native tests read back inward bevel normals at all twelve bearings; do not substitute a resource/property assertion for that proof.

## Moving hardware integration for E

`FortressLighting.moving_material()` returns a ShaderMaterial using `moving_hardware.gdshader`. Assign **one instance per moving-hardware canvas**, not one per actor. Draw different CanvasTextures on that canvas: each draw supplies its own diffuse/normal/emission channel; palette/energy are shared uniforms updated once per frame by `FortressLighting.set_core_state(material,palette,energy)`. This avoids updating a shared per-actor uniform while retaining commands from earlier actors.

T-092 Blender maps declare green=camera-up and blue=toward-viewer; the dynamic helper defaults `normal_green_up=true` and flips green exactly once. Keep identical atlas frame/pivot/UV rectangle for all three maps, no independent trim shift. Albedo is sRGB; normal/emission are raw data. No normal map should contain baked glow. Bind a black emission texture for standards that have no self-emission (the engine's absent specular texture is white). Elite self-emission is independent of core HP; only reflection uses core energy. The helper exposes the integration contract; actual moving-map drawing/native atlas orientation validation belongs to E's accepted integration, and is not falsely claimed by T-081's static hardware proof.

## Provisional values

World-unit light radius420 and height170 preserve a warm interior/cold expanding frontier. Core colors are red(1,.32,.13), yellow(1,.69,.34), white(.78,.88,1). The response uses cold ambient(.40,.54,.68), radial exponential falloff and direct coefficients(.56+1.65*NdotL). A soft shoulder starts at.82 with strength.55; fortress emission gain.70. These values are versioned in the helper/shaders under D-134 and are presentation tuning, not gameplay power rules.

Final LDR glow uses threshold.45, intensity1.0, bloom.08 and Screen composition. This intentionally admits a small amount of subthreshold light. Earlier threshold-only settings produced **no measurable world halo** in the native calibration; those failures are retained. The calibrated Compatibility world-halo sum was28.97 over the fixed black annulus while the identical UI annulus difference was exactly0.0. Mobile's glow kernel is different and stronger; final backend choice must consider that visible result and its measured cost.
