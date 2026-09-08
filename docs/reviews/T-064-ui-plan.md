# T-064 — Industrial UI plan and presentation audit

Luna, 2026-09-08. Design/audit delivery only: no source changes, font downloads or Godot launches. Sol owns the baseline runtime window. This plan applies Kevin's new production-oriented industrial sci-fi UI direction; game-world assets may remain graybox. It does not settle the star, structures or enemy final art.

## Direction and critique

Build the interface as a maintained control station inside a heavily used orbital machine: recessed instruments, clear service labels, substantial switches and replaceable metal sections. The reference films inform material weight, lighting restraint and credible instrumentation; do not copy their logos, proprietary letterforms or screen graphics. Cloud City supplies the disciplined light/dark separation, the Falcon and Expanse supply practical hardware, and Blade Runner supplies occasional amber instrument light. Wear belongs on peripheral housing, never over numbers or instructions.

The current style guide is explicitly an unresolved outline (`docs/art-direction-style-guide.md:3`), including its UI section. Today's UI authorization is sufficient to develop this interface independently of the unresolved industrial/painterly world blend. Keep the animated star as the visual centerpiece. The HUD should explain the battle, not compete with the star through animated scanlines or glowing decoration.

Initial critique: a generic black/neon terminal would lose the worn spacecraft character and harm small-type reading. A rivet on every button would consume the space T-053 recovered. Revised approach: one restrained housing treatment around grouped controls, flat readable control interiors, a physical amber selection indicator, and a consistent family of strong numerals. No fake telemetry, decorative serial numbers, random warning stripes, animated text scrambling or grunge behind body copy. Use sentence case, short action names and aligned numeric columns.

## Tokens and typography

| Token | Initial value | Role |
|---|---|---|
| Housing | `#15191D` | Opaque panel body and modal foundation |
| Recess | `#242C32` | Input wells, unselected rows, secondary surfaces |
| Steel | `#8F9DA6` | Secondary readable labels and visible control edges |
| Instrument white | `#EDF1EF` | Essential text and key values |
| Service amber | `#F2B85B` | Selected tool, capacity warning, keyboard focus |
| Fault red | `#FF8173` | Destruction, failed action, immediate threat |

These are proposed implementation tokens, not measured contrast claims. Verify text/background contrast in the rendered theme before freezing. Use symbols and words in addition to color: critical dot, broken X, interrupted power-chain mark, explicit Ready/cooldown value. Preserve existing minimap meanings. Disabled controls retain readable names plus a reason; reduced contrast alone must not explain unavailability. A 2px focus outline and a selected-row indicator distinguish keyboard focus from an armed tool.

**Font choice:** use locally bundled Barlow Regular and SemiBold for body, buttons and numbers; Barlow Semi Condensed SemiBold for large headings and compact section titles. One related family gives a utilitarian transport/signage character while keeping ordinary words readable. Avoid condensed body paragraphs and novelty stencil glyphs. Use the proportional family for normal labels; stable-width numerals should be explicitly tested rather than assuming a monospaced fallback is required.

The upstream [Barlow project](https://github.com/jpt/barlow) supplies the family and its [SIL OFL 1.1 license](https://github.com/jpt/barlow/blob/main/OFL.txt). The license allows bundling with software while requiring the copyright/license to accompany redistributed copies. Proposed acquisition: pin an upstream revision, vendor only the unmodified static TTF weights actually used into `assets/ui/fonts/barlow/`, include OFL.txt and a provenance file with source revision and SHA-256 hashes, and expose the attribution through Credits. No OS-installed-font dependency or runtime font download. No font assets are currently present in the inspected assets tree. Static files avoid depending on experimental variable-font behavior mentioned by upstream. Use the existing fallback only during import failure, with that failure visible in developer validation.

| Role | 1440×810 design size | 1280×720 effective minimum |
|---|---:|---:|
| Screen title | 36px | 32px |
| Section heading / major stat | 24px | 21px |
| Body, essential action, error | 18px | 16px |
| Secondary label / hotkey / cost | 16px | 14px |
| Button height | 36px | 32px |
| Panel padding | 18px | 16px |

Use a 6/12/18/24px spacing rhythm at the design size. Essential text never shrinks below 16px at the minimum viewport; secondary text never below 14px. Long titles wrap in menus, while catalogue names have a reserved flexible column and costs align right. Test `1/I/l`, `0/O`, decimal cooldowns, minus signs and the longest current names. Future localization is a layout concern, not a promise of bundled script coverage.

## 16:9 layout

Treat the gameplay canvas as a 16:9 rectangle. Author at 1440×810, support 1280×720 as the minimum and 1920×1080 at the same composition. At other window aspects, letterbox/pillarbox the complete gameplay canvas and route pointer conversion through that canvas; do not stretch the world or silently expose a different aiming region. UI and world share the same content rectangle. The central star and camera target remain unchanged when only interface panels open or resize.

The first implementation should prove the aspect/input path before restyling controls. Current project settings remain 1280×900 (`project.godot:17–18`); this migration is still work to implement. At 1920×1080 the base layout scales by 4/3; at minimum by 8/9. Test physical-pixel text rendering and desktop DPI separately from this design scale.

```text
1440 × 810 content rectangle
┌─────────────────────────────────────────────────────────────────────┐
│ Energy     Core integrity     Run time     Threats     Help   Menu   │
│ Selected ring / target: integrity, power, relay or weapon status     │
│ ┌Build catalogue──────┐   Brief active tool / rejected action   ◎ HUD│
│ │Weapons Structure   │                                             │
│ │Terrain (same row)  *│           PLAYFIELD                          │
│ │key  name      cost │     no invisible blocking panels             │
│ └────────────────────┘                                             │
│                                                     Threat notice  │
│ Solar: Flare / EMP             selected-object detail when needed  │
└─────────────────────────────────────────────────────────────────────┘
* All three category labels must actually fit on one row, not wrap.
```

Concrete base allocation: outer inset 18px; top instrument strip 42px high; selection strip below it 30px high; catalogue at x18/y102, width288px, natural height for its visible category; circular minimap 180px at the upper right. These become a 256px catalogue and 160px minimap at 1280×720. Solar stays at the lower left in its own compact group, independent of catalogue visibility. The transient context area occupies the center between left catalogue and right HUD; a dedicated two-line region prevents long selection text and purchase feedback from overlapping. Lower-right notices must never cover a modal action or the minimap's hit area.

Closed catalogue leaves only the small Tab reopen button. Hidden drawers remove their actual blocking rectangles. All three tabs remain immediately visible. Preserve physical hotkeys, deliberate repeat placement, one-shot abilities, right/Escape precedence, cross-panel middle release and pan/zoom. Settings/help are ordinary UI layers, not world coordinates. Modal focus stays inside the open modal; closing it restores sensible focus without arming or buying a tool.

## Current functional gaps and evidence

These are source observations, not failed runtime repros. Existing rule completion is not being reopened.

| Finding | Current evidence | Needed presentation work |
|---|---|---|
| New elite/boss schedules are not enabled by the normal scene | `live_view.gd:111` passes only the Tunneler flag; `live_simulation.gd:78` gives Foundry/Transfer/Sapper/Breacher/Assembler flags false defaults | Enable the approved roster in the intended playable session configuration, with scheduled-arrival and Retry integration tests. Keep benchmark fixtures explicitly controlled. |
| New enemy types look identical to normal machines | `live_view.gd:186` appends every non-Tunneler to normal circle points | Add inexpensive, distinct functional markers and a short inspect legend for Foundry, Transfer, Sapper, Breacher and Assembler. Keep batching; final enemy models are unnecessary. |
| Relay rebuilding exists only in rules | `live_simulation.gd:265/269` exposes quote/rebuild; `live_view.gd:352` supported modes and `build_view.gd:28` key map contain no rebuild action | Add a selected-ring Rebuild Relay action with authoritative quote and clear damaged/destroyed/healthy states. Reserve a new key only in the next explicit control contract; do not steal R Repair Node or T Repair Wedge. |
| HUD can show a destroyed relay as present | `live_view.gd:630` derives relay_active from dictionary nonemptiness; `power_rules.gd:27` breaks the chain at relay_hp <= 0 | Read authoritative relay HP and chain status. Distinguish local relay destruction from an intact ring browned out by an inward break. Show the repairable cause. |
| Power is largely invisible until a purchase fails | `live_view.gd:559` supplies a generic power error; selected status at `live_view.gd:404` covers occupant/wall/repair but not demand/output/chain | Selected-ring demand/output and relay HP, brownout source ring, and prospective weapon demand from existing rules. Do not imply existing weapons are removed merely because demand exceeds current output. |
| Relay-loss event feedback is absent | `_simulation_tick` at `live_view.gd:149` handles core/collapse/wedge/wall; events expose relays_lost at `live_simulation.gd:76` | A brief actionable relay-loss notice plus focus/rebuild path, avoiding a continuous repeating alert every tick. |
| Approved ring-purchase simplification is incomplete | `build_view.gd:251` still selects expansion mode; world press is required at `build_view.gd:360`. T-055 contract calls for direct one-action purchase | Parent must reconcile the current live interaction with D-104 before copy/tutorial assertions are frozen. Do not accidentally restore the removed relay-slot step. Two-slot density is rule data, not UI math. |
| Hits have no visible weapon feedback | `weapon_rules.gd:187` appends weapon_id/target_id/damage; `_simulation_tick` does not consume hits; `_draw` at `live_view.gd:592` draws only board/aim/walls/Tunneler warnings | T-056 event-driven placeholder attack visuals, specified below. |
| Session flow is still a test scene | `project.godot:11` launches live_view; `live_view.gd:83` adds Retry to the simple pause panel; loss text at `live_view.gd:285` is brief feedback | Real start/configuration/results/settings/tutorial presentation, wired only to the forthcoming session/meta contracts. |

T-056 should retain instant authoritative combat. Stage each tick's event once, with source position and the target's event-time endpoint captured before killed targets disappear. A post-step snapshot alone cannot locate a killed target; a frame's last_events alone also loses earlier catch-up ticks. Resolve this with the gameplay owner if the existing event payload is insufficient, rather than guessing positions or changing damage timing. Visual lifetimes use presentation state, pause consistently, clear on Retry, and never award damage/energy. Group bounded visual buffers instead of spawning one scene per shot; any cosmetic saturation policy must be explicit and must not alter actors or simulation cadence.

Initial graybox vocabulary: Flak short burst spokes, Mass Driver thin straight trace, EMP Node pulse outline, Lance persistent-looking short-lived beam, Point Defense a compact tracer. These indicate confirmed hits; they are not physical projectile simulations. Separate solar cast events from weapon hits. Also make Transfer's consumed hop and Assembler growth inspectable, identify Sapper's relay attack and Breacher's wall focus, and keep the existing Tunneler locked-destination countdown. Avoid promises of damage-number clouds or final particles in this slice.

## Future player screens in the same system

| Screen | Composition and required behavior | Dependency boundary |
|---|---|---|
| Start | Quiet star/graybox backdrop, large title, left-aligned Start run / Continue when valid / Settings / How to play / Quit | Continue only when a real supported save exists; no inert button |
| Loadout / run setup | Available choices on the left, selected effects/costs on the right, persistent bottom Start run and Back | Only approved loadout choices and authoritative affordability/unlock data; do not invent bonuses |
| Meta progression | Grouped upgrade list, current currency, selected effect/current-to-next value, buy confirmation where required | Save/unlock/purchase rules belong to their owners; atomic failure and reload persistence must be tested |
| Results | Clear outcome and survival time first, a short stat column, actual earned progression, Retry / Setup / Main menu | Freeze final values once; do not keep counting or re-award rewards on navigation |
| Settings | Display/UI, Audio, Controls, Accessibility sections; readable preview and Apply/Back behavior | Implement only real settings; distinguish immediately applied options from display changes needing timed recovery |
| Tutorial / help | One short playable instruction at a time with visible key/action and completion; full reference remains F1 | Determine pause policy and persistence in the session contract; never cover the required target or simulate a purchase from tutorial navigation |

All screens share font resources, spacing, selection/focus states and button vocabulary. Avoid copying ad hoc absolute-position code into each new screen. A shared Theme and a small set of reusable HUD/panel/button components should serve normal and preview scenes. Keep game-world experimental art toggles in the preview drawer, separate from real gameplay settings.

## Bounded implementation sequence and acceptance

1. Theme/font and 16:9 shell: vendor licensed static fonts, establish aspect-correct canvas/input, install token resources and layout containers; capture all three required resolutions before adding new session features.
2. Gameplay visibility: roster enablement, elite markers/inspect, relay rebuild and power diagnosis, then T-056 event visuals. Keep rule/API corrections owned by gameplay and preserve baseline fixture semantics.
3. Session screens: start and real run configuration first, then results/meta/settings against frozen APIs. Extend the same component system rather than using separate skins.
4. Guided play and final usability verification: tutorial completion, restart/back/focus behavior, save failure/empty cases, full keyboard and pointer paths.

Acceptance must include real inputs at all three 16:9 sizes, non-16:9 letterbox clicks, offscreen targeting, pan/zoom with open and closed UI, readable long failure/quote strings, all three visible tabs, pause and catch-up event lifetimes, killed-target effects, each elite lifecycle, destroyed inward relay with surviving outer ring, successful and rejected rebuilds, loss/results/reward once, and repeated Retry. Measure actual frame/simulation/sync/draw costs in the existing fixed fixtures; this UI plan does not claim a resolved 1000-machine cap. Inspect screenshots at native pixel size, including grayscale/correct symbol interpretation, before calling the theme production-ready.

Immediate next recommendation: implement the 16:9/font/theme shell and relay/power/elite visibility as separately reviewable contracts. They give Kevin a legible complete battle to test while session/meta owners finish their APIs. Final world art can follow independently.
