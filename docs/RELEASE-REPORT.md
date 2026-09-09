# RING ZERO — autonomous release-candidate report

> Superseded presentation: Kevin rejected this first candidate's visual quality.
> The current `1.0.0-rc2` overhaul, screenshots and verification are documented in
> [PRESENTATION-OVERHAUL.md](PRESENTATION-OVERHAUL.md). This report preserves the
> earlier gameplay, architecture and release-scope history.

September 8, 2026. Branch: `release/v1.0-candidate`. Application version: `1.0.0-rc1`.

## Executive decision

The project now has a built, locally tested Windows release candidate with a finite winning objective, a live industrial battlefield, original sound, configurable PC input, controller pointer interaction, durable service records, and substantially improved rendering performance. The work is recorded in logical Git commits. The original design specification and historical art sources were preserved.

This is **not a certified, published, bug-free AA Steam release**. Steam service activation, physical-controller and lower-spec hardware testing, comprehensive human balance testing, store assets and commercial acceptance remain outstanding. I cannot honestly certify a $9.99 value proposition from automated checks. The distinction matters: the executable and the evidence are concrete deliverables, while those claims require work outside the available local development environment.

Launch `exports/windows/RingZero.exe`. Keep its PCK, build identity and licenses beside it. The source can also be opened in the pinned Godot 4.7.2 installation. Nothing was pushed to a remote, uploaded to Steam, or published.

## What the audit found

This was already a substantial game. It contained seven enemy families, five automatic weapons, expansion, walls, armor, repair, relays and brownouts, three terrain tools, two solar abilities, doctrines, loadouts, progression, a tutorial, saved profiles and Windows export tooling. The initial 39-suite correctness run passed. I retained that investment instead of replacing the game with a smaller unrelated prototype.

The important gaps were elsewhere. The main application still used the neutral graybox battlefield. The prior production-asset review had failed, particularly on mixed-swarm identification and some physical terrain reads. A thousand-machine battle was too slow. Controls were hard-coded physical keys. There was no production audio or victory outcome. Steam Cloud and achievements were not connected to Steam services.

Your autonomous-development instruction superseded the older approval stops. I recorded that authority in the planning, task and decision logs and created a separate current scope document. I did not rewrite the fixed original specification or retroactively describe the earlier failed art reviews as passes.

## The game and its scope

The release mode is a **15-minute containment operation**. Protect the star, expand the fortress, counter the machines and survive until the operation completes. The HUD divides that time into Ignition, Fortress and Last Watch. Those are pacing labels over the existing continuous pressure curve, not three newly authored campaigns or scripted waves.

Victory has its own presentation and follows the existing durable reward path. An early victory summary is rejected. Practice, abandonment and interrupted runs remain ineligible for campaign rewards. The same run cannot credit currency twice. A victory also unlocks the Containment service record; winning with all three mutators unlocks Trial by Fire.

I retained the three doctrines, three loadouts, seven purchasable unlocks, three capped upgrade tracks and three combinable mutators. They supply the replay variation. I did not add multiplayer, a campaign map, extra enemy types, workshop support, monetization, or another progression system.

The most consequential cut is the production limit: **128 simultaneous machines and 12 rings**. The old 1,000-machine tests remain available and unchanged as stress fixtures; they are not the production promise. This limit is explicit in the release profile and run creation. Normal pressure and all seven enemy streams still use the existing shared admission rules; arrivals may be skipped when the shared cap is full. The limit is not a guarantee that every stream gets a reserved slot.

There is still no mid-run save/resume. Profile progress settles between runs. A crash before durable settlement can lose that run's unsaved reward. This preserves the existing tested accounting model rather than adding a rushed world-state serializer.

## Rules and architecture

I kept the deterministic 60 Hz simulation, polar coordinates, validated purchase commands, fixed-step clock, separated rule services and persistent profile store. Presentation reads committed state; it does not invent kill counts or reward totals.

The main mechanical correction concerns destroyed support. A broken wedge now immediately loses its occupants and any supported wall, and its maximum health returns to its base value after armor is destroyed. Repairing the wedge therefore cannot resurrect a turret, wall or armor bonus. Destruction grants are counted once, including Assembler growth and ring-collapse accounting. One old test intentionally expected an inactive wall record to remain on broken support; its assertion now checks the new destruction rule. All other gameplay tests continue to pass.

Balance profiles now record successful validation at construction and cache scalar lookups. Public reads return values or copies, and overrides construct a newly validated profile. This avoids repeatedly copying and validating the complete balance document inside routine rule calls while preserving validation at the input boundary. An empty directly constructed profile is still rejected.

I also removed unnecessary full target snapshots from hit-feedback position collection. That path now reads only the positions it needs. Public gameplay snapshots retain their copy semantics.

## Art and visual production

The governing direction remains **lit industrial hardware, painterly light, mostly void**. The battlefield uses narrow bands at ring boundaries, open trusses, visible metal depth, warm player lighting and cold enemy accents. The ground is foreshortened to the specified 20-degree view; the spherical star stays circular. Mouse picking continues through the same viewport and camera transforms as the drawn world.

The new live renderer uses existing normalized building heads and machine art from the repository. It does not alter the generated source images. Buildings sit on procedural supports and draw in screen-height order. Destroyed band segments disappear, and shared trusses remain while either adjacent wedge still supports them. Strategic zoom suppresses bolts and braces that would be too small to read.

Because the prior machine sprites were difficult to identify in a crowd, enemy families receive distinct geometric outlines at strategic scale. This is an explicit readability decision, not a claim that the sprite source defects disappeared. Debris, tractor direction and screen hardware receive procedural treatments rather than promoting misleading terrain source images wholesale. The tactical layer exposes wedge health, screen reach and selected weapon range information. It is not a complete tactical visualization for every rule or every weapon family.

The star reuses the project's shader, varies its palette per run, responds to core damage and dims during a brownout. Weapon effects distinguish pulses, beams, flak impacts and tracers. Structural breaches produce bounded fragments and restrained camera shake. Reduced-motion settings suppress that movement. Effects and sounds remain bounded so a large fight cannot create unlimited transient objects.

I authored an application icon, a procedural orbital menu background, six service-record emblems, and twelve earned/locked achievement PNG candidates. The emblems are editable SVGs in `assets/ui/achievements`; the 64-pixel PNG candidates are in `exports/steam-icons`. The conversion is reproducible through `scripts/prepare_release_assets.gd`. No new image-generation calls were required: existing authored hardware plus new code/vector assets filled this pass's needs.

These choices make the candidate cohesive and reviewable in the actual game. They do not establish final commercial art acceptance, a complete animation production pass, or parity with a staffed AA art team.

## Interface, input and accessibility

The start, shop, tutorial, pause, settings and results flows retain the industrial theme and licensed Barlow fonts. I added a visible winning objective, victory presentation, a service-record screen with named conditions and icons, and a credits screen. Current keyboard shortcuts are shown on the main gameplay buttons. Menus preserve the fixed 16:9 design area at different window sizes.

Settings now include master, ambience/music and effects levels, alongside fullscreen, interface scale, reduced motion and feedback settings. Input and audio settings use a separate local configuration file so they do not require changing the currency/progression schema. A failed settings write is reported; invalid saved input maps fall back to defaults.

Keyboard shortcuts, mouse battlefield actions and controller buttons are assignable. Duplicate assignments swap, keeping both actions reachable. Mouse menu activation remains the primary button, and wheel actions are kept separate from click/drag actions. Stick axes and trigger roles are fixed, so this is not unrestricted remapping of every analog axis.

The controller uses a visible pointer: left stick moves it, A activates, B cancels or returns, Start pauses, right stick pans, triggers zoom continuously, shoulders cycle tools, and X/Y select solar abilities. D-pad scrolling makes the long settings and reference pages reachable. Tool cycling deliberately skips immediate expansion purchases; expansion remains available through its button. The pointer follows the same root-viewport input path as a mouse, including letterboxing and GUI handling. Focus loss and controller disconnection pause an active run.

Automated controller events verify the routing and primary interaction. They do not replace hands-on Xbox, PlayStation, Steam Deck or Steam Input testing.

## Audio

The new audio layer synthesizes original interface, construction, weapon, solar, breach, defeat and victory sounds. An eight-second harmonic ambience loop provides a quiet industrial background. Eight reusable voices and event cooldowns bound simultaneous playback. This is original synthesis, not a licensed music recording or a claimed full soundtrack.

Playback stops and releases streams during teardown. Headless runs synthesize the resources but skip playback: the headless dummy audio driver left playback references at shutdown during testing. Normal rendered runs retain sound and shut down without the observed object-leak warnings. The actual mix still needs listening on speakers and headphones; waveform generation and successful playback initialization do not certify audio quality.

## Performance evidence

The initial new renderer redrew all its metal geometry each frame. The 12-ring, 128-machine GPU fixture measured approximately **55 ms median frames**, with about **25 ms spent issuing drawing commands**. That was a failure, not a result I accepted.

Caching polar directions and arc geometry, and omitting unreadable strategic detail, brought drawing to roughly 5 ms. I then moved fortress geometry into a separate retained drawing layer. It refreshes when topology, occupants, visible damage bands, selection, zoom or tools change. Moving enemies and combat effects redraw independently. The tactical layer updates continuously while requested, preserving its live inspection behavior.

The final observed test used Godot 4.7.2 Compatibility, an RTX 4080, a 1440×810 window, 12 rings, 128 mixed machines and effects enabled. Across 180 measured frames:

| Measurement | Observed result |
|---|---:|
| Median frame | 16.666 ms |
| 95th percentile frame | 16.784 ms |
| Maximum frame | 17.047 ms |
| Median dynamic drawing | 1.004 ms |
| Median synchronization/HUD work | 1.989 ms |
| Maximum simulation callback | 4.325 ms |
| Simulated time / wall time | 0.99998 |

This is approximately 60 FPS in this local bounded fixture. It is not a minimum-spec certification, a long thermal soak, or proof that every combat arrangement has the same cost. The fixture uses durable actors and explicit setup funds to sustain load; those are test conditions, not production player benefits. The old 1,000-machine case remains too slow.

## QA and observed playability

The final complete correctness run passed **40 suites**, with zero suite failures or timeouts. The new release suite adds **24 checks** covering saved rebindings, keyboard conflict swaps, mouse translation without corrupting GUI events, controller conflict swaps and start activation, focus pausing, practice reward exclusion, early-victory rejection, victory settlement, duplicate settlement, independent achievement reload, service records and credits navigation. The original lifecycle, save-recovery, numerical movement, enemy and UI suites also pass.

After the last visual-only adjustments, the release checks, GPU captures and rendered performance probe were run again and passed. Actual captures include start, opening battle, expanded fortress, tactical view, settings, controls, victory, records, credits, 1280×720 and 1920×1080. The large battle and victory screenshots are explicitly synthetic QA fixtures; the victory capture is not evidence of a natural winning playthrough.

A deterministic starter strategy, using real purchases and no extra funding or durability, survived **565.73 seconds**, destroyed **1,169 machines**, reached ring two, and then lost. It took about 39 seconds of accelerated headless execution. This supports the existence of a sustained playable loop and a working defeat, but it does not prove a complete winning strategy or balanced progression. Human playtesting and a broader strategy/balance pass remain necessary before a commercial release claim.

Successful final runs still print the environment's existing “Failed to read the root certificate store” diagnostic. Gameplay and package tests do not use networking. This is disclosed in the retained capture diagnostics; it is not being disguised as an application script failure.

Evidence is retained under `docs/reviews/release-v1/`, including the suite summary, frame metrics, strategy output and screenshots. Windows packaging and its final smoke-test outcome are recorded in the build verification section below.

## Steam boundary and remaining release work

Six service records are saved atomically with completed results. `AchievementHooks` exposes stable IDs through a signal that a Steam adapter can consume and replay after Steam user stats become ready. This is an implemented hook and offline journal, **not a shipped Steamworks transport**.

`docs/STEAM-RELEASE.md` specifies the exact profile and backup paths for Windows Auto-Cloud and excludes temporary files, locks, traces and local audio/input settings. The setup follows [Steam's Auto-Cloud documentation](https://partner.steamgames.com/doc/features/cloud). No App ID or partner configuration was available, so Cloud has not been activated or verified on Steam. Per-Steam-account local profile isolation and cross-device conflict testing are still outstanding.

Engine and third-party notices are extracted through the [installed engine's license APIs](https://docs.godotengine.org/en/stable/classes/class_engine.html), and the Windows exporter now includes those files beside the existing Barlow notices. The credits screen describes the AI-assisted asset process.

Before selling this as a finished $9.99 release, the remaining work is concrete: complete the Steamworks adapter and partner configuration; verify Cloud and account switching; test physical controllers and lower-spec hardware; complete human playtesting, winning-strategy and balance coverage; review the audio and remaining animation/art quality; prepare the store capsule, trailer and final screenshots; and complete Steam's content and release review. The price remains the requested target, not an experimentally validated market conclusion.

## Build verification

The frozen Windows export succeeded with matching Godot 4.7.2 Mono templates. Build identity: `44c8b67728dd14ca38dec43818409a23ccb0eb7662c31dc271a51f3f3df76e1e`, verified against 379 source files. Generated metadata is excluded from its own hash. Documentation and Git history are outside this source identity.

The first packaged external-headless-driver check timed out without running its assertions. The actual owned-window driver did run successfully: start, Flak placement, cancellation, pause/resume, abandonment with zero reward, Quit and independent reload all passed, and both processes exited through the interface. I changed the packaged-input entry point to use that working owned-window path. The old headless driver is retained as diagnostic source and is not counted as a pass. The corrected entry point was rerun against the final frozen export: both owned processes exited 0 through the UI and the lifecycle/reload check passed. Evidence: `docs/reviews/release-v1/package-summary.json`.

Executable SHA-256: `16e0ec3cfd398b938f514de95ff2474b532b5061ada78f92226dba3f7584d55d`. PCK SHA-256: `41105878d2e08851fb6d782d0bcbc472d4bc1cacb06549bbb30852d7647d3a97`. The executable is the unchanged engine template; game changes reside in the adjacent PCK. A clean distribution archive is `exports/RingZero-1.0.0-rc1-windows.zip`.

Git stages: scope lock; gameplay/validation and breach fixes; persistence/input foundations; integrated presentation/audio/controller/victory flow; reproducible QA/assets/build tools; package-driver correction; final report and evidence. The working branch is kept local for review.
