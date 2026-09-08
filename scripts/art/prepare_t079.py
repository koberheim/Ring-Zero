"""Expand locked v1 prompts verbatim for the T-079 generation audit."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
text = (ROOT / 'docs/art-prompts/v1-templates.md').read_text(encoding='utf-8')
blocks = re.findall(r'```\n(.*?)```', text, re.S)
common, camera = blocks[:2]
negatives = ' '.join(common.split('NEGATIVE   ', 1)[1].split())
records = []
for section in range(7, 27):
    if section < 21 or section == 26:
        chunk = re.search(r'## ' + str(section) + r'\. .*?(?=\n## |\Z)', text, re.S).group()
        prompt = re.search(r'```\n(.*?)```', chunk, re.S).group(1)
        source = re.search(r'Output: `(.*?)`', chunk).group(1)
    else:
        shared = text.split('## 21-25.', 1)[1].split('## 26.', 1)[0]
        prompt = re.search(r'```\n(.*?)```', shared, re.S).group(1)
        item = re.search(r'\*\*' + str(section) + r'\. .*', shared).group()
        prompt += re.search(r'`(SUBJECT:.*?)`', item).group(1) + '\n'
        source = re.search(r'Output: `(.*?)`', item).group(1)
    prompt = prompt.replace('[COMMON BLOCK]', common.rstrip()).replace('[OBJECT CAMERA]', camera.rstrip()).replace('[common block negatives]', negatives)
    prompt += '\nREFERENCE: approved anchor is a style reference, never an edit target or source to crop. Generate a fresh asset matching its wear, material detail and achieved near-overhead camera for objects. Flat categories must remain direct top-down. Use uniform pure black RGB 0,0,0 for empty background, no gradient. '
    if section in (7, 8):
        prompt += 'Wide horizontal strip. Ends must extend to left/right canvas edges with matching repeat, no end caps; vertical margins only. Intended normalized size 1024 x 128.'
    else:
        prompt += 'Square canvas with generous margins. '
    if section >= 21:
        prompt += 'Machine MATERIAL and NEGATIVE override the common player palette: matte dark neutral hull, exactly ONE contiguous localized cold cyan/white glowing area, never zero, never two, NO amber/warm lights or hazard colours. All other surfaces unlit. '
        if section == 26:
            prompt += 'The single boss accent is larger than elite accents but remains one localized area.'
    records.append(dict(section=section, source=source, prompt=prompt, status='pending'))
manifest = dict(tool='built-in image_gen.imagegen', templates='docs/art-prompts/v1-templates.md', reference='assets/art/anchor/anchor_approved.png', generations=records)
(ROOT / 'scripts/art/t079_expanded_templates.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(json.dumps(records))
