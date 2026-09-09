"""Render a reviewed local layer recipe with FFmpeg; output remains unadmitted.

Default prints the command only. --render writes new float WAV plus peak/loudness
measurement and provenance. No synthesis, source downloads or bank edits occur.
"""
import argparse
import hashlib
import json
import math
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'docs/reviews/presentation-v3/T-085'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def finite(value, lower, upper):
    value = float(value)
    if not math.isfinite(value) or not lower <= value <= upper:
        raise ValueError(f'Numeric recipe value outside [{lower}, {upper}]')
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--recipe', required=True)
    parser.add_argument('--render', action='store_true')
    args = parser.parse_args()
    recipe_path = Path(args.recipe).resolve()
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    output = (ROOT / recipe['output']).resolve()
    if not output.is_relative_to(EVIDENCE) or output.suffix.lower() != '.wav' or output.exists():
        raise ValueError('Output must be a new WAV under T-085 evidence (never runtime bank)')
    if not 1 <= len(recipe['layers']) <= 8:
        raise ValueError('One to eight checked source layers required')
    command = [shutil.which('ffmpeg') or 'ffmpeg', '-nostdin', '-n', '-hide_banner']
    filters, source_records = [], []
    for index, layer in enumerate(recipe['layers']):
        path = (ROOT / layer['path']).resolve()
        if not path.is_relative_to(ROOT / 'assets/audio/source') or not path.is_file():
            raise ValueError('Missing preserved source under assets/audio/source')
        if layer.get('commercial_use_verified') is not True or layer.get('download_verified') is not True or layer.get('spend_usd') != 0:
            raise ValueError('Unverified source rights/download/cost')
        if digest(path) != layer['sha256'].lower() or not layer.get('terms_evidence'):
            raise ValueError('Source hash/terms evidence missing or mismatched')
        for evidence in layer['terms_evidence']:
            item = (ROOT / evidence).resolve()
            if not item.is_relative_to(ROOT) or not item.is_file():
                raise ValueError('Terms evidence must exist in repository')
        start = finite(layer['start_seconds'], 0, 3600)
        duration = finite(layer['duration_seconds'], 0.02, 300)
        fade = finite(layer.get('fade_seconds', 0.01), 0, duration / 2)
        gain = finite(layer.get('gain_db', -12), -80, 12)
        delay = finite(layer.get('delay_seconds', 0), 0, 30)
        highpass = finite(layer.get('highpass_hz', 25), 5, 2000)
        command += ['-i', str(path)]
        filters.append(f'[{index}:a]atrim=start={start}:duration={duration},asetpts=PTS-STARTPTS,highpass=f={highpass},volume={gain}dB,afade=t=in:d={fade},afade=t=out:st={duration-fade}:d={fade},adelay={round(delay*1000)}:all=1[a{index}]')
        source_records.append(dict(layer, verified_sha256=digest(path)))
    labels = ''.join(f'[a{i}]' for i in range(len(filters)))
    filters.append(f'{labels}amix=inputs={len(filters)}:duration=longest:normalize=0[out]')
    command += ['-filter_complex', ';'.join(filters), '-map', '[out]', '-ar', '48000',
                '-ac', '2', '-c:a', 'pcm_f32le', str(output)]
    record = {'admitted': False, 'recipe_sha256': digest(recipe_path),
              'command': command, 'sources': source_records,
              'note': '48 kHz export is delivery format, not a claim of increased source resolution.'}
    if not args.render:
        print(json.dumps(record, indent=2))
        return
    output.parent.mkdir(parents=True, exist_ok=True)
    # Preserve float overload without integer clipping; reject or reduce gain before delivery.
    subprocess.run(command, check=True, timeout=180)
    measure = [command[0], '-nostdin', '-hide_banner', '-i', str(output), '-af',
               'ebur128=peak=true', '-f', 'null', '-']
    measured = subprocess.run(measure, capture_output=True, text=True, check=True, timeout=180)
    record.update(output_sha256=digest(output), measured_utc=datetime.now(timezone.utc).isoformat(),
                  measurement_command=measure, measurement_log=measured.stderr)
    output.with_suffix('.provenance.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
    print(f'Rendered UNADMITTED candidate: {output}; review peak/clip, listening and seam gates')


if __name__ == '__main__':
    main()
