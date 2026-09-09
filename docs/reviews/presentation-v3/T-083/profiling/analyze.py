"""Summarize retained native timelines; does not run or alter the game."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
results = []
for path in sorted(root.glob('*-0[12]/trial-*.json')):
    trial = json.loads(path.read_text())
    rows = trial['timeline']
    worst = max(rows, key=lambda row: row['wall_ms'])
    results.append({
        'source': str(path.relative_to(root)).replace('\\','/'),
        'mode': trial['mode'], 'repetition': trial['repetition'],
        'valid_runtime': trial['valid'],
        'median_ms': trial['median_frame_ms'], 'p95_ms': trial['p95_frame_ms'],
        'max_ms': trial['max_frame_ms'], 'simulation_wall_ratio': trial['simulation_wall_ratio'],
        'initial_state_sha256': trial['initial_state_sha256'],
        'initial_targets_sha256': trial['initial_targets_sha256'],
        'numeric_target_hash': path.parent.name not in ('normal-01', 'draw-off-01'),
        'first_measured_tick': rows[0]['tick'], 'last_measured_tick': rows[-1]['tick'],
        'albedo_rebuilds': sum(row['albedo_calls'] for row in rows),
        'material_rebuilds': sum(row['material_calls'] for row in rows),
        'max_hook_us': max(row['hook_us'] for row in rows),
        'max_effect_draw_us': max(row['effect_draw_us'] for row in rows),
        'max_repair_us': max(row['repair_us'] for row in rows),
        'max_state_copy_us': max(row['state_copy_us'] for row in rows),
        'worst_frame': worst,
    })
(root / 'summary.json').write_text(json.dumps(results, indent=2)+'\n')
artifacts = []
for path in sorted(root.rglob('*')):
    if path.is_file() and path.name != 'profiling-manifest.json':
        data = path.read_bytes()
        artifacts.append({'path': str(path.relative_to(root)).replace('\\','/'),
                          'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
(root / 'profiling-manifest.json').write_text(json.dumps({'base':'67a49cb','artifacts':artifacts}, indent=2)+'\n')
print(f'{len(results)} retained trials; {len(artifacts)} artifact hashes')
