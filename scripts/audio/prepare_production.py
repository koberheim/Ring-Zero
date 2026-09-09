"""Offline ACE-Step request preparation. Never contacts a host or admits assets."""
import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = ROOT / 'docs/reviews/presentation-v3/T-085'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--recipe', required=True)
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    recipes = json.loads((EVIDENCE / 'production-recipes.json').read_text(encoding='utf-8'))
    recipe = next(item for item in recipes['sources'] if item['id'] == args.recipe)
    request = json.loads((EVIDENCE / 'ace-original-request.json').read_text(encoding='utf-8'))
    request['data'][4] = recipe['prompt']
    request['data'][6] = recipe['bpm']
    request['data'][13] = str(recipe['seed'])
    request['data'][15] = recipe['seconds']
    request['recipe_id'] = recipe['id']
    request['admitted'] = False
    request['required_before_submission'] = recipes['submission_gate']
    out = Path(args.out).resolve()
    if not out.is_relative_to(EVIDENCE) or out.exists():
        raise ValueError('Output must be a new file under T-085 evidence')
    out.write_text(json.dumps(request, indent=2) + '\n', encoding='utf-8')
    print(f'Prepared only: {out}; no network request made')


if __name__ == '__main__':
    main()
