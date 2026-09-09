"""Instrument an isolated 67a49cb archive only. No current source edits or engine run."""
from pathlib import Path
import hashlib
import json
import sys
import subprocess

task = Path(__file__).resolve().parent
workspace = task.parents[4]
isolated = (workspace / '.godot/release-qa/t083-profile-base').resolve()
dry = len(sys.argv) == 2 and sys.argv[1] == '--check'
if not dry and (len(sys.argv) != 2 or Path(sys.argv[1]).resolve() != isolated):
    raise SystemExit('Pass the exact authorized isolated project path')
if not dry and (not isolated.is_relative_to(workspace.resolve()) or not (isolated / 'project.godot').is_file()):
    raise SystemExit('Missing authorized archive')
marker = isolated / 't083-instrumentation.json'
if not dry and marker.exists():
    raise SystemExit('Instrumentation already installed; reuse it, do not double patch')

def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f'Expected one source anchor: {old[:90]!r}; got {text.count(old)}')
    return text.replace(old, new, 1)

view_path = isolated / 'src/presentation/release_view.gd'
view = subprocess.check_output(['git','show','67a49cb:src/presentation/release_view.gd'],cwd=workspace,text=True) if dry else view_path.read_text()
original_view = view
view = replace_once(view, 'var collapse_simulation: LiveSimulation', '''var collapse_simulation: LiveSimulation
# Isolated diagnostic counters, not production APIs.
var t083_mode := "normal"
var t083_cache_hold := false
var t083_hook_usec := 0
var t083_effect_draw_usec := 0
var t083_cache_check_usec := 0
var t083_albedo_usec := 0
var t083_material_usec := 0
var t083_albedo_calls := 0
var t083_material_calls := 0''')
view = replace_once(view, 'func _ready() -> void:\n\tsuper._ready()', '''func _ready() -> void:
\tfor arg in OS.get_cmdline_user_args():
\t\tif arg.begins_with("--profile-mode="): t083_mode = arg.trim_prefix("--profile-mode=")
\tsuper._ready()''')
view = replace_once(view, 'func _presentation_committed_tick(before: Dictionary, events: Dictionary, tick: int) -> void:', '''func _presentation_committed_tick(before: Dictionary, events: Dictionary, tick: int) -> void:
\tvar started := Time.get_ticks_usec()
\t_t083_original_committed_tick(before,events,tick)
\tt083_hook_usec += Time.get_ticks_usec()-started

func _t083_original_committed_tick(before: Dictionary, events: Dictionary, tick: int) -> void:''')
view = replace_once(view, '\tvar cues := collapse_feedback.admit(before,events,tick)', '\tvar cues: Array = [] if t083_mode == "admission-off" else collapse_feedback.admit(before,events,tick)')
view = replace_once(view, 'func _refresh_board_cache() -> void:', '''func _refresh_board_cache() -> void:
\tif t083_cache_hold: return # Deliberately stale board diagnostic; never an acceptance capture.
\tvar started := Time.get_ticks_usec()
\t_t083_original_refresh_board_cache()
\tt083_cache_check_usec += Time.get_ticks_usec()-started

func _t083_original_refresh_board_cache() -> void:''')
view = replace_once(view, 'func _render_board() -> void:', '''func _render_board() -> void:
\tvar is_material := board_canvas == material_canvas
\tvar started := Time.get_ticks_usec()
\t_t083_original_render_board()
\tif is_material:
\t\tt083_material_usec += Time.get_ticks_usec()-started
\t\tt083_material_calls += 1
\telse:
\t\tt083_albedo_usec += Time.get_ticks_usec()-started
\t\tt083_albedo_calls += 1

func _t083_original_render_board() -> void:''')
old_draw = '\tif interface_settings.effects: collapse_feedback.draw(self,zoom,interface_settings.reduced_motion,{"heads":heads,"mount":mount,"bands":band_textures,"wall":wall_texture,"terrain":terrain_textures})'
new_draw = '''\tif interface_settings.effects and t083_mode != "draw-off":
\t\tvar effect_started := Time.get_ticks_usec()
\t\tcollapse_feedback.draw(self,zoom,interface_settings.reduced_motion,{"heads":heads,"mount":mount,"bands":band_textures,"wall":wall_texture,"terrain":terrain_textures})
\t\tt083_effect_draw_usec += Time.get_ticks_usec()-effect_started'''
view = replace_once(view, old_draw, new_draw)

sim_path = isolated / 'src/gameplay/live_simulation.gd'
sim = subprocess.check_output(['git','show','67a49cb:src/gameplay/live_simulation.gd'],cwd=workspace,text=True) if dry else sim_path.read_text()
original_sim = sim
sim = replace_once(sim, 'var _ticks := 0', 'var _ticks := 0\nvar t083_state_copy_usec := 0\nvar t083_repair_usec := 0')
sim = replace_once(sim, '\tvar staged_state := state.duplicate(true)', '\tvar t083_copy_started := Time.get_ticks_usec()\n\tvar staged_state := state.duplicate(true)\n\tt083_state_copy_usec += Time.get_ticks_usec()-t083_copy_started')
sim = replace_once(sim, '\t\t_apply_repair_nodes(staged_state)', '\t\tvar t083_repair_started := Time.get_ticks_usec()\n\t\t_apply_repair_nodes(staged_state)\n\t\tt083_repair_usec += Time.get_ticks_usec()-t083_repair_started')

# Validate every anchor before making any write.
if dry:
    print('Every isolated instrumentation anchor validated against 67a49cb; no files or engine touched')
    raise SystemExit(0)
originals = task / 'archive-originals'
originals.mkdir(exist_ok=True)
(originals / 'release_view.gd.txt').write_text(original_view)
(originals / 'live_simulation.gd.txt').write_text(original_sim)
view_path.write_text(view)
sim_path.write_text(sim)
(isolated / 'tests/performance/profile_t083_dense.gd').write_text((task / 'profile_t083_dense.gd.txt').read_text())
manifest = {'base_commit': '67a49cb', 'instrumentation_only': True, 'root_source_edited': False,
            'files': {str(p.relative_to(isolated)): hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in [view_path, sim_path, isolated / 'tests/performance/profile_t083_dense.gd']}}
marker.write_text(json.dumps(manifest, indent=2)+'\n')
print(json.dumps(manifest, indent=2))
