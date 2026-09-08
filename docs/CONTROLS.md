# Controls

These shortcuts use physical key positions and work in both the normal game and art preview. Most shortcuts select a tool without spending. Q and the Ring Plate button are the exception: each deliberate press purchases the next complete ring immediately at its displayed price; holding Q does not repeat.

| Keys | Tools |
|---|---|
| 1 / 2 / 3 / 4 / 5 | Flak / Mass Driver / EMP Node / Lance Emitter / Point Defense |
| Q / W / E / R / T / Y | Ring Plate / Wall / Armor Plating / Repair Node / Repair Wedge / Reclaim Ring |
| G | Rebuild Relay: select, then click the affected ring |
| A / S / D | Debris Field / Tractor Lane / Occlusion Screen |
| F | Toggle Tractor clockwise / counterclockwise |
| Z / X | Focused Flare / EMP Burst targeting |
| Tab | Hide/show build catalogue; retain selected tool |
| F1 | Shortcuts and help |
| F2 | Art settings drawer in art preview |
| Escape | Close help first, otherwise cancel a selected tool, otherwise open/close Menu |

Left click selects or uses the active tool at that wedge/slot. Build tools stay selected after success: each additional deliberate click validates and pays for one purchase. Holding or dragging does not paint. Failures keep the tool and explain the rejection. Right click or Escape cancels, including over controls.

Solar abilities cast once per selection. Select Z/X or their buttons, aim the outline and click the world. Cooldown must finish before another cast. Solar buttons remain reachable when the catalogue is hidden. Debris blocks the outer boundary; Tractor direction is chosen before placement; a selected Screen reports its outward range and movement percentage. Repair/Reclaim show authoritative target costs in the selection status when pointing at a valid target.

Middle drag pans; mouse wheel zooms; clicking the minimap focuses the core or a ring/wedge. Menu pauses and clears tools; Retry starts a fresh run. Help and the art drawer do not pause. Gameplay shortcuts ignore repeated key events, releases, Ctrl/Alt/Meta combinations, text-editing focus, paused games and ended runs. Escape can close an open Menu.

The catalogue retains Weapons, Structure and Terrain tabs. Prices and shortcuts appear on its compact rows. This is an interim usability layout, not a final art decision.

The application opens on run configuration. Choose a doctrine, an unlocked loadout and optional challenges, then Start. Locked catalogue tools show their status and are unlocked through the between-run Shop. The main menu offers a full practice tutorial, counter reference, and settings for fullscreen, 100/115/130% interface scale, reduced motion and weapon feedback. Settings and progression persist locally.

Pause offers Resume, Restart, Settings and Abandon. Results show authoritative survival/kills/expansion and earned credits; a failed save must be retried before continuing. Practice awards no campaign credits. The viewport keeps a 16:9 aspect ratio with letterboxing in other window shapes.

Runs write local diagnostic traces under `user://runs` (Godot user-data directory), containing fixed-tick commands and run configuration. They are diagnostic files, not resumable saves. A trace write error is shown without stopping gameplay; preserve the trace alongside a bug report.
