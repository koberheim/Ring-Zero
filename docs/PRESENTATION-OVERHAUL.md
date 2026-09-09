# RING ZERO — presentation replacement

September 8, 2026. Branch `release/v1.0-candidate`. Version `1.0.0-rc2`.

## Why this pass was necessary

Kevin rejected the first candidate's interface, structure art, flat sun and low
apparent resolution. That feedback was justified by the actual game captures.
Passing gameplay tests had not established acceptable visual quality. This pass
therefore replaced the presentation and reviewed it through rendered game images.

Three agents worked on separate areas: application/HUD design, world rendering,
and input. Astra established the shared resolution and visual contract, reviewed
the first deliveries, requested further corrections, integrated the work and
ran the application and package checks. The input agent also supplied a separate
visual review and rebuilt the integrity instrument after its first capture failed
the visual review.

## Resolution and composition

The application previously rendered to 1440 × 810 and enlarged that image for
larger displays. The new stage renders world art, shaders and text at **2560 ×
1440**. The desktop window initially opens at **1920 × 1080**. Smaller and wider
windows retain their proportions by fitting that native image inside the window.
At 1080p the game downsamples the larger render; at 1440p it uses it directly.

The native stage is shared by the application, battlefield, mouse coordinates
and controller pointer. The frame is the only outer scaling step. This preserves
world picking when the game is letterboxed and avoids separate, drifting input
coordinate systems. The opening camera now frames the owned fortress, rather
than fitting the unused inspection grid; this makes the hardware visible from
the first playable frame. Later expansion and state refreshes preserve player
camera control.

The higher resolution initially exposed a rendering bottleneck: thousands of
individual detail draws were resubmitted every frame. A native-resolution
transparent fortress cache now combines unchanged geometry into one image.
Changes to the structure, selection, tactical state or view refresh that image.
Moving machines, weapon feedback and the star remain independently animated.
This optimization retains the resolution and authored detail.

The visual direction is industrial spacecraft instrumentation: deep navy housings,
warm ivory type, burnished brass details, amber player lights and cold machine
accents. The title screen now has a large Barlow display title and stellar hero
composition, with a separate operation console and restrained bottom navigation.
The launch action has clear visual priority. Settings, controls, pause, records
and results use the same typography, surfaces and spacing.

The in-game HUD separates energy, core integrity, active machines and elapsed
time into instrument bays. A core-integrity bar makes damage immediately visible.
Weapon controls include the actual hardware icons. The former filled gold minimap
is now a dark segmented integrity instrument with bearing marks, relay indicators,
and distinct broken, critical and brownout symbols. Its existing click-to-focus
geometry remains intact.

## World art and asset production

The audit found good 1024-pixel hull strips and existing 256-pixel building heads
that the release renderer had not been using. The replacement maps those hull
textures onto cached curved meshes. Inner bands are 28 world units wide, outer
bands 25; undersides extend seven units down-screen. Layered edges, pipes, lamps,
directionally lit trusses and physical mount surfaces give the fortress more
material detail and depth while preserving open movement space.

Building heads are larger and rotate outward. Wall slabs use the authored barrier
texture rather than plain white polylines. Terrain uses its authored textures.
Detailed runtime texture imports already had mipmaps enabled; the renderer uses
them while zooming out. The original source assets and mockups were preserved.

The star uses a new shader that samples animated turbulence on a rotating sphere.
Projected surface detail, limb compression and darkening, active regions, sunspots,
a warm halo and irregular prominences replace the flat noise disc. Red, yellow
and white stellar palettes remain available. The matching space shader follows
the star's screen position as the camera moves. Reduced-motion settings stop the
world's surface animation and camera shake, and slow the menu presentation.

This remains a Godot 2D game with dimensional drawing and spherical shader
lighting; it is not a conversion of the simulation to a 3D physics world. Blender
was available, but no Blender scene changes were needed: the existing authored
assets supplied the missing material detail. This pass created original shader
and mesh code instead of generating another batch of replacement bitmap art.

## Controls and compatibility

**WASD pans the map.** Wall moves to **H**, Debris to **C**, Tractor Lane to **V**,
and Occlusion Screen to **B**. The number-row weapons, Q expansion and other
familiar actions remain. Unassigned arrow keys also pan. Movement is continuous,
diagonal-normalized and adjusted for zoom. Releasing a key stops movement;
pausing, opening other pages, rebinding or losing focus clears held navigation.

Physical bindings are now separate from the game's stable internal command
identifiers. Old settings migrate to reserve WASD, retaining custom bindings
where possible and relocating conflicts deterministically. New settings include
the four remappable map actions. Validation rejects an invalid modifier swap
instead of saving an unusable binding map.

The controller pointer derives its bounds from the actual native stage. Focus
loss and controller disconnect clear held stick, trigger and scrolling state.
All existing profile settlement, tutorial, reward and unlock behavior was retained.

## Review corrections

The first deliveries were reviewed and revised before acceptance. Corrections
included flower-like corona loops, plain white battlefield warnings and walls,
too-small opening framing, the flat integrity disc, inconsistent HUD font sizes
after refresh, crowded configuration content, decimal-heavy result readouts and
the redundant save-result control after settlement.

Automated interaction also caught a new pause-screen bug that screenshots could
not show: the dimming layer intercepted clicks on the visible menu. Reordering
the controls in the scene tree fixed the hit testing. Draw order alone was not
sufficient. Popup tests were updated to target the themed menu's actual item area
instead of the old bottom-margin coordinates.

An actual audio-driver teardown probe found that immediate Quit could leave
playback objects pending on the audio thread. Quit and window-close now stop
sound immediately, allow a short asynchronous cleanup interval, and then exit.
The capture tooling uses the same cleanup path.

## Verification and package

The new Windows package is [RingZero-1.0.0-rc2-windows.zip](../exports/RingZero-1.0.0-rc2-windows.zip).
The directly runnable build is [RingZero.exe](../exports/windows/RingZero.exe).
Keep the adjacent PCK, build information and licenses with the executable.

- **42 regression suites passed.** This includes the 77-check application flow,
  31 navigation/settings checks, 28 native-resolution integration checks and
  24 release-candidate checks. [Full suite results](reviews/presentation-v2/test-summary.json).
- The final cache received **10 rendered invalidation/coordinate checks** and
  **11 independent checks** covering walls, occupants, relays, collapse,
  close-view coverage and tactical extents. The rendered WASD/picking integration
  also passed all 28 checks after the cache change.
- Actual captures cover native 1440p, 1080p output, enlarged 130% UI, all three
  stellar palettes, opening play, a crowded fortress, close inspection, tactical
  view, pause, settings, controls and results. The final verbose capture exited
  cleanly without leaked-object or shader/script warnings. The machine's existing
  certificate-store message remains in engine logs.
- The **actual exported application** passed launch, world purchase, cancel,
  pause/resume, abandonment, Quit and independent reload. The trace records
  153 simulation ticks, one accepted command and three pause/resume markers;
  abandonment settled with zero reward. Both launches exited through the UI with
  code 0. [Package verification](reviews/presentation-v2/package-verification.json).
- The archive passed integrity checks and exact byte comparison against the
  exported executable, PCK, metadata, README and all four license/provenance files.
  [Archive verification](reviews/presentation-v2/archive-verification.json).

The final canonical rendered sample used **2560 × 1440, 12 rings, 128 machines,
effects enabled and an NVIDIA RTX 4080**. Over 180 measured frames after warmup,
median frame time was **16.668 ms**, the 95th percentile **16.760 ms**, and the
maximum **18.489 ms**. Simulation/wall-clock ratio was **0.99998**.
[Native performance evidence](reviews/presentation-v2/native-performance.txt).

Separate 90-frame samples measured continuous panning at 16.662 ms median,
held tactical view at 16.666 ms, and combined panning/tactical view at 16.661 ms.
Their 95th percentiles stayed below 16.92 ms.
[Panning and tactical evidence](reviews/presentation-v2/pan-tactical-performance.txt).
These are local samples, not a guarantee for every machine or every destruction
burst. Actual structural changes and newly exposed close-view geometry still
redraw the cache immediately.

Frozen build identity: `40cc70a1bb11f5edcb689168bc45a9014c5c02b39c401ecb1b5a1c763510bf7f`
(399 source files). ZIP size: 56,624,478 bytes.
ZIP SHA-256: `b7dea95b230d13fdb602d5b70d678c5327c510feac5d454db88ab19c7680856b`.

## Actual game images

[Main menu](reviews/presentation-v2/release-start.png) ·
[Opening fortress](reviews/presentation-v2/release-opening.png) ·
[Crowded fortress](reviews/presentation-v2/release-fortress.png) ·
[Hardware close-up](reviews/presentation-v2/release-detail.png) ·
[Settings](reviews/presentation-v2/release-settings.png) ·
[Enlarged HUD](reviews/presentation-v2/release-opening-130.png) ·
[Victory](reviews/presentation-v2/release-victory.png).

The crowded, close-up and victory images use the isolated QA fixture; its large
energy/health reserves and forced result are test data, not claims of a naturally
completed operation. The opening image uses a normal fresh operation and the
yellow stellar palette.

## Scope retained

This is a presentation and PC-input correction. It does not add a campaign,
change combat balance, activate Steam services or establish commercial quality
through an automated score. The earlier report's outstanding Steam activation,
physical-device, wider-hardware and human balance work still applies. The new
screenshots and executable are the concrete result to assess visually.
