# T-086 continuation: instrument theme preparation

Stream D / Luna, 2026-09-09. Read-only preparation against base `c76a45c` and audio delivery `5308bd7`; approved scope additions recorded by Astra in `f8411ff`. No source/assets, Godot, or existing evidence changed. Implementation waits for B's reviewed early collapse adapter. This is an implementation plan within D-135, not another creative approval request.

Applied `frontend-design/SKILL.md`: the characteristic subject is a star held inside engineered concentric hardware. Spend visual emphasis on that star/fortress and on the decisions that preserve it. The interface reads as the surrounding control instrument. Keep existing Barlow/metal/amber vocabulary; eliminate decorative frames that do not enclose useful information. UI remains outside A's world glow.

## Compact tokens

Six core colors preserve the approved family:

| Token | Hex | Role |
|---|---|---|
| Housing | `#111b25` | Main instrument housing / panel backing |
| Recess | `#172631` | Inset choices, tracks, editable fields |
| Steel | `#839ba8` | Explanatory copy, inactive structure, secondary emphasis |
| Ink | `#f2e6cc` | Primary readable text and keyboard focus |
| Amber | `#d5ac6e` | Deliberate action, selected tool, energy |
| Cyan | `#91cfdf` | Informational feedback and existing core instrument |

Retain `#f58b72` only as the existing fault semantic, not a new world palette. Disabled text uses the early slice's `#94a2a9`; disabled state also changes geometry/interaction. No color alone communicates selected, locked, broken or focused state.

Barlow Regular serves body and explanation; Barlow SemiBold serves actions and instrument values; Barlow SemiCondensed SemiBold serves headings and wordmark. Numeric roles use the same family with tabular-number font features where supported; stable right-aligned value columns remain required. No monospace label substitute. Named roles replace scattered overrides. Drawn shipping world labels use shared font access, including measurement and drawing together.

Provisional size function: `density = clamp(viewport_height / 1080.0, 0.85, 1.50)`; physical font size is rounded `role_px * density * saved_text_scale`. Density depends on height, never ultrawide width. Saved text scale remains 1.0 / 1.15 / 1.3. Layout uses the same density for base spacing, but grows/wraps from actual text minimums rather than multiplying an entire 1440p surface.

| Role | Native 1080p, 100% | Native 1080p, 130% | Use |
|---|---:|---:|---|
| Caption | 18 px | 23 px | Explanations, metric labels, descriptive copy |
| Body / control | 22 px | 29 px | Choices, build tools, settings, controls |
| Heading | 32 px | 42 px | Section/page grouping |
| Title | 48 px | 62 px | Page and outcome heading |
| Value | 36 px | 47 px | Primary run instrumentation |
| Display | 112 px | 146 px | Start wordmark, bounded by measured available hero width |
| World annotation | 18 px | 23 px | Screen-oriented tactical/warning text, compensated for zoom |

At 1440p density is 1.333, so body is 29/38 physical px; at 720p density bottoms at .85, so body is 19/24 and caption 15/20. Round caption upward to a 16 px physical minimum. At 4K density caps at 1.5 and gives additional map space; there is no 4K performance promise. Headline fitting may reduce display type to a title role; body never shrinks to rescue a clipped layout. Test actual Barlow glyph bounds before fixing these provisional values.

Spacing scale: 4/8/12/16/24/32/48 density-adjusted pixels. Controls have at least 44 physical px pointer targets, plus measured text height and vertical padding; regular action row target 48*density at 100%. Focus is a 2 physical px minimum keyline, 3 at normal density. Accepted selector SVGs retain a minimum 78×27 physical footprint; at native1080 make their theme dimensions match that accepted appearance rather than accidentally enlarge them by removing the old 0.75 fit. Arrow remains the accepted engraved-bar form.

## Material hierarchy and complete widget inventory

Production construction was audited through application -> release -> live -> build -> grid, plus all seven `.tscn` scenes. Scene node types are only Control, Node2D and CanvasLayer; they contain no hidden serialized Tree/ItemList/LineEdit widgets. Source construction sites below identify factories, not runtime instance counts (many run in loops).

| Control family | Actual current use / construction | Required state treatment |
|---|---|---|
| Button | `application._action`, `build_view._button`: actions, build tools, pause/help, shop, rebinding, tutorial | Raised actions with short bevel; primary amber only for main action. Normal/hover/pressed/disabled/focus, selected-tool non-color indicator, remapped key text |
| CheckButton | `application.show_start` challenges, `show_settings` three toggles | Preserve accepted four state assets, recessed rows, hover/pressed/focus keylines, disabled wording/position |
| OptionButton + implicit PopupMenu | Start doctrine/loadout, settings text scale; locked loadout items | Accepted custom arrow; dropdown is a recessed choice. Popup surface, item selection/hover/disabled text, separators, scroll arrows/check/radio icons if exposed, keyboard focus |
| TabContainer + implicit TabBar | Build Weapons/Structure/Terrain; controls Keyboard/Mouse/Controller | Selected tab joined to content well and underline; disabled text; hover/focus. Overflow arrows and menu icon supplied if engine exposes them |
| ScrollContainer + implicit V/HScrollBar | Every generic page body; help text; planned compact catalogue/settings/controls | Visible non-default track/thumb, normal/hover/pressed/focus; grips distinguish moving thumb. Scroll arrows/icons themed even if currently suppressed. 12 px minimum track, larger interaction area |
| HSlider | Existing Master/Music/Effects; planned UI/Ambience | Recessed track, filled segment, gripped thumb, hover/pressed/disabled/focus. Numeric percentage alongside label; exact zero shown as muted |
| PanelContainer | Generic pages, notices, tutorial; build/pause/help | Housing encloses related functions. Thin bevel only around actual housing. No drop shadow on every list row/track |
| ProgressBar | Live core integrity | Instrument well with flat fill; no raised action shadow. Label/value remain separate and readable |
| Label + HSeparator | All screens and HUD; generic page separator | Shared font roles; separator denotes an actual section boundary. Remove decorative repeated rules where spacing already groups content |
| TooltipPanel / TooltipLabel (implicit) | Challenge descriptions, locked tools, radar legend, build instructions | Opaque readable backing, bounded text width, caption font minimum, padding; inspect at all edges and scales |
| CheckBox / LineEdit / VSlider | No production construction found | Explicit contract-requested theme variants supplied and tested in gallery; do not introduce new controls into flows just to use them |
| Tree / ItemList / RichTextLabel / TextEdit | No production construction found (TextEdit/LineEdit appear in focus guards only) | Tree/ItemList omitted per contract; no unnecessary widget system. Existing focus guards preserved |
| TextureRect / ColorRect / custom Control drawing | Records icons, star/background/shades, instrument strip, command frame, radar | Not engine widget chrome; check texture scaling, mouse filters and semantic drawing separately |

Theme state galleries cover direct types AND implicit PopupMenu/TabBar/scrollbars/tooltips. Inventory does not claim default icons are eliminated until native inspection confirms every exposed state. Start/action labels retain plain sentence case; industrial context is carried by material and typography, not extra uppercase metadata labels.

## Plan critique before code

The first tempting treatment was one framed box per metric and equal-width cards for every action. That reproduces RC2's generic card hierarchy. Revised plan uses one shared telemetry housing with dividers determined by real bays, a distinct recessed catalogue, and unboxed explanatory text. The hero is the star/fortress itself; no additional decorative dashboard, invented threat gauge, or unrelated hero image.

The existing start wordmark's three left edges and fixed orphan tick rule do not express different functions. Revised start uses one left-aligned lockup and a single operation well; bottom navigation gains actionable control treatment without looking equally primary to Start. Layout plan is in `../T-087/preparation.md`.

## Independent audio controls

Astra authorized later scope for `src/core/pc_settings.gd`, `src/presentation/game_audio.gd`, and `src/presentation/controller_pointer.gd`. Add machine-local `[audio] ui` and `ambience` floats, using existing finite [0,1] validation. If absent in an old valid config, inherit the loaded Effects/Music values respectively, preserving current audible balance. Keep `INPUT_SCHEMA=2`, all input maps/migration, cloud profile shape, rewards, and gameplay untouched.

Update `game_audio.apply_levels` to map Master/Music/SFX/UI/Ambience independently at startup and every change. Settings labels: Master, Music, Effects, Interface, Ambience; saved keys remain `master/music/effects/ui/ambience`. Save failure restores previous local variable, slider display and bus gain and displays visible error text. This repairs the current audio handler's memory/disk disagreement on failed save without touching durable progression. Exact-zero tests assert bus mute; 100% on one category must not overwrite another category. No admitted source bank or human listening pass is inferred from these controls.

Preparation result: source audit PASS; approved-style plan READY; source implementation/native control-state proof PENDING the next lease. No additional user decision is required by this preparation.
