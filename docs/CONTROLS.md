# Controls

These defaults use physical key positions. Settings > Controls lists the active bindings and lets you remap keyboard actions, mouse battlefield buttons and gamepad buttons. Map movement is available during the normal game and tutorial. Most shortcuts select a tool without spending. Q and the Ring Plate button are the exception: each deliberate press purchases the next complete ring immediately at its displayed price; holding Q does not repeat.

| Keys | Action |
|---|---|
| W / A / S / D | Hold to move the map up / left / down / right |
| Arrow keys | Alternate map movement, unless assigned to another action |
| 1 / 2 / 3 / 4 / 5 | Flak / Mass Driver / EMP Node / Lance Emitter / Point Defense |
| Q / H / E / R / T / Y | Ring Plate / Wall / Armor Plating / Repair Node / Repair Wedge / Reclaim Ring |
| G | Rebuild Relay: select, then click the affected ring |
| C / V / B | Debris Field / Tractor Lane / Occlusion Screen |
| F | Toggle Tractor clockwise / counterclockwise |
| Z / X | Focused Flare / EMP Burst targeting |
| Tab | Hide/show build catalogue; retain selected tool |
| F1 | Shortcuts and help |
| F2 | Art settings drawer in art preview |
| Escape | Close help first, otherwise cancel a selected tool, otherwise open/close Menu |

Left click selects or uses the active tool at that wedge/slot. Build tools stay selected after success: each additional deliberate click validates and pays for one purchase. Holding or dragging does not paint. Failures keep the tool and explain the rejection. Right click or Escape cancels, including over controls.

Solar abilities cast once per selection. Select Z/X or their buttons, aim the outline and click the world. Cooldown must finish before another cast. Solar buttons remain reachable when the catalogue is hidden. Debris blocks the outer boundary; Tractor direction is chosen before placement; a selected Screen reports its outward range and movement percentage. Repair/Reclaim show authoritative target costs in the selection status when pointing at a valid target.

Hold WASD to pan the map, or use middle drag. Diagonal movement has the same speed as straight movement, and zoom does not change the apparent panning speed. Mouse wheel zooms; clicking the minimap focuses the core or a ring/wedge. Menu pauses and clears tools; Retry starts a fresh run. Help and the art drawer do not pause. Gameplay shortcuts ignore repeated key events, releases, Ctrl/Alt/Meta combinations, text-editing focus, paused games and ended runs. Escape can close an open Menu.

The build catalogue groups Weapons, Structure and Terrain. Each available tool shows its cost and current shortcut. H selects Wall, C selects Debris, V selects Tractor and B selects Occlusion; WASD is reserved for map movement by default.

The application opens on run configuration. Choose a doctrine, an unlocked loadout and optional challenges, then Start. Locked catalogue tools show their status and are unlocked through the between-run Shop. The main menu offers a full practice tutorial, counter reference, and settings for fullscreen, 100/115/130% interface scale, reduced motion and weapon feedback. Settings and progression persist locally.

Pause offers Resume, Restart, Settings and Abandon. Results show authoritative survival/kills/expansion and earned credits; a failed save must be retried before continuing. Practice awards no campaign credits. The game renders the world and interface at 2560x1440. The default window is 1920x1080, with the native image downsampled to fit; a 2560x1440 display can show it at full resolution. Other window shapes retain the 16:9 composition with letterboxing. Fullscreen is available in Settings.

Runs write local diagnostic traces under `user://runs` (Godot user-data directory), containing fixed-tick commands and run configuration. They are diagnostic files, not resumable saves. A trace write error is shown without stopping gameplay; preserve the trace alongside a bug report.
## Remapping and controller

Settings > Controls is authoritative for current bindings. Keyboard shortcuts, mouse battlefield buttons and gamepad buttons are saved locally and can be reassigned; collisions swap. The reference above lists defaults. Mouse menu activation retains the primary button. Wheel directions can be exchanged; dragging/placement require non-wheel buttons. Modifier-only keyboard assignments are restricted to keep shortcuts usable. If moving the tactical overlay off Alt would swap Alt into another action, first choose an unused key or move the other action. Older control files migrate to WASD movement automatically: custom bindings are retained where they do not conflict, and displaced actions receive available keys shown in Controls.

Controller defaults: left stick moves the pointer; south/A activates the pointed control or world position; east/B cancels/back; Start pauses; right stick pans; triggers zoom; shoulders cycle available tool positions (skipping the immediately purchasing expansion action); west/X selects EMP Burst; north/Y selects Flare; D-pad up/down scrolls menus; Back toggles the catalogue. Expansion remains available through its visible button. Stick axes and trigger roles are fixed. The same pointer can reach every menu and building action. Focus loss and controller disconnection pause an active run and clear held controller motion. Keyboard movement stops on focus loss, while paused, in menus and during text input or rebinding. Both input methods remain available without switching a mode.

Hold the tactical-overlay binding (Alt by default) for wedge integrity and terrain detail. The operation objective is to protect the star for 15 minutes. Defeat and victory settle earned campaign credits; practice and abandonment do not.
