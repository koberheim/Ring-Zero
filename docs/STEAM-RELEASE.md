# Steam release setup

This candidate runs offline. No Steam App ID, Steamworks SDK/extension, partner account session, or published Cloud configuration is present in this repository. Nothing has been uploaded or published. The following is the concrete setup for the release owner, not a claim of live integration.

## Cloud progress

Configure Steam Auto-Cloud for Windows using root **WinAppDataRoaming**, subdirectory **Godot/app_userdata/RING ZERO**, and two exact file patterns: **profile.json** and **profile.json.bak**. Set a modest quota such as 1 MiB and 4 files. Exclude `*.tmp`, lock directories, `runs/`, and `pc_settings.cfg`. Audio levels and input bindings are machine-local; the older interface preferences are still part of the progress profile.

The game already writes progress atomically, keeps a last-valid backup, rejects incompatible schemas, and detects concurrent local revisions. Auto-Cloud synchronizes these files around game sessions. It is not a mid-run resume system and does not merge two independently advanced profiles. Verify conflict selection, offline/online transitions, account switching on one PC, a clean second-PC download, and recovery from backup in Steam before advertising Cloud support. Per-Steam-account local profile isolation remains an integration task; the current offline profile is per Windows account.

Source: [Steam Cloud documentation](https://partner.steamgames.com/doc/features/cloud).

## Achievement adapter contract

`AchievementHooks.earned(summary, mutators)` returns stable achievement IDs only for eligible completed campaign runs. The application adds these IDs to the same atomic profile settlement as the currency reward, then calls `achievement_hooks.replay_saved(progress.achievements)`. The signal `achievement_requested(id)` is the integration boundary. A Steam adapter should connect after user stats are ready, then call `replay_saved` at startup so previously earned offline records are submitted. Each hook instance emits an ID once per session. Platform failures must be retried by the adapter and must never roll back local progress.

Create these six achievements in Steamworks. Original earned/locked PNG candidates are prepared in `exports/steam-icons`; review and upload them before submission:

| API ID | Name | Condition |
|---|---|---|
| FIRST_WATCH | First Watch | Survive five minutes |
| MACHINE_BREAKER | Machine Breaker | Destroy 250 machines in one run |
| OUTER_FRONTIER | Outer Frontier | Reach ring six |
| POWER_RESTORED | Power Restored | Rebuild a relay |
| CONTAINMENT | Containment | Complete a 15-minute operation |
| TRIAL_BY_FIRE | Trial by Fire | Win with all three mutators |

The current executable includes hooks and durable offline service records. It does not include a Steamworks achievement transport. Registering the IDs alone does not activate achievements.

## Input and package

The native Godot gamepad path uses standard buttons and axes and supports Steam Input's gamepad emulation. A virtual pointer drives the same GUI and world input path as a mouse. Keyboard shortcuts, mouse battlefield actions, and gamepad buttons can be reassigned in Settings > Controls; button collisions swap. Stick axes and trigger roles are fixed. Provide a recommended Steam Input layout and verify physical Xbox, PlayStation, Steam Deck and disconnect/reconnect behavior. Automated injected events are not hardware certification.

Ship the entire `exports/windows/` game set (`RingZero.exe`, `RingZero.pck`, build identity and license notices), excluding export diagnostic logs. The existing script name/preset remains “private” for compatibility; output is a local release candidate. Steam depot configuration, store capsule/screenshots/trailer, achievement icons, store description, pricing, age/content questionnaire, executable signing where desired, and Steam review are outstanding release-owner work. There is no external publication in the automation.
