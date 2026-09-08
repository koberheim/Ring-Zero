# Playable art comparison

Open `scenes/art_preview.tscn` in the pinned Godot editor and press **F6**. The normal main scene is `scenes/application.tscn`; this preview is a separate experiment, not a final art choice.

Open the initially collapsed **Art settings [F2]** drawer on the right. Click **Art** to cycle **Industrial / Painterly**, and **Sun** to cycle **Red giant / Yellow / White**. **Sun motion** toggles animation. These preferences change only presentation, preserving the current game, energy, buildings, cooldowns and selection. Sun motion also pauses with Menu. Red giant changes the visual palette, not the core radius or rules.

**Close core** centers the sun and reveals panel/building detail. **Strategic view** frames the currently displayed rings and removes small decoration and excess labels. Existing middle-drag pan, mouse-wheel zoom and HUD focus remain available. Select a building to see its name even at strategic scale. Building, Repair/Reclaim and Retry use the shared live game.

The preview starts with normal testing funds and pressure. Report captures use explicitly funded, quiet fixtures; the editor scene does not.

The **Terrain** tab offers Debris Field, Tractor Lane and Occlusion Screen. Use **Tractor: Clockwise / Counterclockwise** before placement. Select terrain to inspect its name; Tractor direction and Screen's outward ring span/speed appear in the top status line. Broken support disables effects until repaired.

**Focused Flare** and **EMP Burst** sit below the build tabs with ready/remaining cooldown text. Choose an ability, aim its plain outline, then click the world to cast; right click cancels. Flare aims a sector from the core; EMP aims a circle anywhere representable, including beyond displayed build rings. Casting does not pause the game and ability kills grant no energy. Menu, Retry and switching back to a build option clear targeting. Terrain and solar integration evidence is in `docs/reviews/T-051.md`.

The shared [control guide](CONTROLS.md) lists direct weapon, structure, terrain and solar shortcuts. **Tab** hides the catalogue while leaving the chosen build tool active; repeated deliberate clicks make separately validated purchases. Solar buttons stay at the lower left and casts remain one-shot. **F1** opens help. Escape closes help, then cancels a tool, then opens Menu.

Review evidence and limitations are recorded in `docs/reviews/T-049.md`; the compact layout and keyboard verification are in `docs/reviews/T-053.md`.
