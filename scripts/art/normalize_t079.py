"""Normalize T-079 candidates with the unchanged T-078 pipeline.

Failures remain review candidates. Pivots are inspected source-pixel estimates.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image
from normalize_asset import ROOT, normalize

PIVOTS = {10: (627,430), 11: (627,617), 12: (627,380), 13: (627,500),
          14: (627,650), 15: (265,290), 16: (627,617), 17: (627,640),
          18: (627,627), 19: (627,627), 20: (627,650), 21: (627,580),
          22: (627,627), 23: (627,627), 24: (627,650), 25: (627,600), 26: (627,627)}
NAMES = ['Hot band','Cold band','Damage sheet','Flak','EMP Node','Lance Emitter',
         'Point Defense','Relay','Repair Node','Armor Plating','Deflector Wall',
         'Debris Field','Tractor Lane','Occlusion Screen','Tunneler','Transfer',
         'Foundry','Sapper','Breacher','Assembler']
WORLD = [256,256,128,43,38,43,28,38,56,32,48,64,48,48,16,16,24,16,16,48]

def main():
    manifest = json.loads((ROOT/'scripts/art/t079_generation_manifest.json').read_text(encoding='utf-8'))
    results = []
    for row in manifest['generations']:
        s = row['section']
        source = ROOT/row['source']
        filename = source.name
        directory = 'bands' if s<9 else 'decals' if s==9 else 'buildings' if s<17 else 'walls' if s==17 else 'terrain' if s<21 else 'machines'
        if 10<=s<=16 or s>=21:
            filename = filename.replace('_01.png','.png')
        size = (1024,128) if s<9 else (1024,1024) if s==9 else (128,128) if 21<=s<=25 else (256,256)
        kind = 'band' if s<9 else 'sheet' if s==9 else 'object'
        r = normalize(source, ROOT/'assets/art'/directory/filename, kind, size, PIVOTS.get(s))
        r.update(section=s,name=NAMES[s-7],world_width=WORLD[s-7],acceptance='review candidate',mount_mounted=10<=s<=16)
        r['source'] = Path(r['source']).as_posix()
        r['output'] = Path(r['output']).as_posix()
        r['pivot_note'] = 'Reviewed attachment axis' if 10<=s<=15 else 'Reviewed footprint/surface centre'
        a = np.asarray(Image.open(ROOT/r['output'])).astype(int)
        if s<9:
            r['edge_rgba_max_absolute_error'] = int(np.abs(a[:,0]-a[:,-1]).max())
        if s>=21:
            cold = (a[:,:,3]>128)&(a[:,:,1]>120)&(a[:,:,2]>a[:,:,0]+12)
            warm = (a[:,:,3]>128)&(a[:,:,0]>120)&(a[:,:,0]>a[:,:,2]+20)
            r['bright_cold_pixels'] = int(cold.sum())
            r['bright_warm_pixels'] = int(warm.sum())
            r['emissive_note'] = 'Threshold counts support visual inspection; do not define glowing areas.'
        results.append(r)
    (ROOT/'scripts/art/t079_normalization_manifest.json').write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps([{k:r[k] for k in ['section','output','size']} for r in results],indent=2))

if __name__=='__main__':
    main()
