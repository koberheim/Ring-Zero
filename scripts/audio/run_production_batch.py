"""Explicit bounded queue; one request by default, stops on every first failure.

No scheduler, quota waiting, retries, credentials, download, or asset admission.
Requires a freshly checked source/session record; timestamps alone prove no quota.
"""
import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'docs/reviews/presentation-v3/T-085'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--client-directory', required=True)
    parser.add_argument('--session-review', required=True)
    parser.add_argument('--request', action='append', required=True)
    parser.add_argument('--max-requests', type=int, choices=range(1, 4), default=1)
    args = parser.parse_args()
    review_path = Path(args.session_review).resolve()
    review = json.loads(review_path.read_text(encoding='utf-8'))
    for field in ('current_model_verified', 'current_schema_verified',
                  'commercial_use_verified', 'free_session_verified',
                  'legitimate_quota_available', 'no_paid_credits'):
        if review.get(field) is not True:
            raise ValueError(f'Submission blocked: {field} is not verified')
    if review.get('spend_usd') != 0 or review.get('model') != 'acestep-v15-turbo':
        raise ValueError('Review must match approved zero-cost original-turbo recipe')
    checked = datetime.fromisoformat(review['checked_utc'])
    age = (datetime.now(timezone.utc) - checked).total_seconds()
    if not 0 <= age <= 3600 or not review.get('evidence_paths'):
        raise ValueError('A current, evidence-backed review within one hour is required')
    for item in review['evidence_paths']:
        evidence = (ROOT / item).resolve()
        if not evidence.is_relative_to(ROOT) or not evidence.is_file():
            raise ValueError('Each reviewed evidence file must exist within the repository')
    if len(args.request) > args.max_requests:
        raise ValueError('Queue exceeds the explicit bounded request count')
    requests = [Path(p).resolve() for p in args.request]
    for path in requests:
        if not path.is_relative_to(EVIDENCE) or not path.is_file():
            raise ValueError('Requests must be preserved in T-085 evidence')
        values = json.loads(path.read_text(encoding='utf-8'))['data']
        if len(values) != 49 or values[0] != review['model']:
            raise ValueError('Model/schema mismatch; refresh reviewed request template')
        if (values[16] != 1 or values[48] is not False or values[30] != 'flac'
                or not 0 < values[15] <= 30 or values[14] is not None or values[17] is not None):
            raise ValueError('Only one short instrumental FLAC with no input audio is approved')
    for path in requests:
        result = path.with_name(path.stem + '-result.json')
        if result.exists():
            raise ValueError('Existing attempt evidence is immutable; prepare a new request')
        command = [sys.executable, str(ROOT / 'scripts/audio/probe_ace_step.py'),
                   '--client-directory', args.client_directory, '--request', str(path),
                   '--result', str(result)]
        try:
            subprocess.run(command, check=True, timeout=120)
        except (subprocess.SubprocessError, OSError) as exc:
            print(f'STOP: client process error; do not retry automatically: {exc}')
            return 1
        record = json.loads(result.read_text(encoding='utf-8'))
        record['session_review'] = str(review_path.relative_to(ROOT))
        result.write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
        if record.get('status') != 'completed' or not record.get('output'):
            print('STOP: generation failed or returned no output; preserve result and review')
            return 1
        # One completed API response can contain an application-level error or no audio.
        # Human inspection is required before another request; never batch past uncertainty.
        print('STOP: inspect returned source metadata/download before another request')
        return 0
    return 0


if __name__ == '__main__':
    sys.exit(main())
