import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
project = root.parents[3]
sources = [
    'src/presentation/live_view.gd', 'src/presentation/release_view.gd',
    'src/presentation/effects/collapse_feedback.gd',
    'src/presentation/effects/collapse_feedback.gd.uid',
    'tests/presentation/capture_t083_collapse.gd',
    'tests/presentation/capture_t083_collapse.gd.uid',
    'tests/presentation/test_t083_collapse.gd',
    'tests/presentation/test_t083_collapse.gd.uid',
    'tests/performance/measure_t083_collapse.gd',
    'tests/performance/measure_t083_collapse.gd.uid',
]
def record(path):
    data = path.read_bytes()
    return {'path': path.relative_to(project).as_posix(), 'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest()}
artifacts = [record(p) for p in sorted(root.rglob('*'))
             if p.is_file() and p.name != 'delivery-manifest.json']
manifest = {'scope': 'T083 early delivery snapshot; downstream review additions are separate',
            'head_at_manifest': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=project, text=True).strip(),
            'source_files': [record(project / p) for p in sources if (project / p).exists()],
            'artifacts': artifacts,
            'status': 'partial; dense load failure and human/audio/final flow acceptance pending'}
(root / 'delivery-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(f'{len(manifest["source_files"])} source hashes, {len(artifacts)} artifact hashes')
