#!/usr/bin/env python3
"""Deterministic T-078 normalization (Python 3, Pillow, numpy).

Run `python scripts/art/normalize_asset.py --slice` from any directory.
For later assets: input output --kind object|band|sheet --size W H
    --pivot X Y [--delight 0.35] [--black-threshold 8]
Pivot is a reviewed SOURCE pixel coordinate, not the image's bottom edge:
for near-overhead objects it is the projected ground/attachment centre.

This is bounded low-frequency illumination suppression, NOT recovery of
physical albedo from a photograph. AO, speculars and emissive colours cannot
be separated reliably from one RGB image; inspect and reject bad sources.
PNG uses straight alpha for Godot's default CanvasItem blend mode. Pillow's
RGBa resize performs premultiplied filtering before straight-alpha export.
"""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SLICE = [
    ('band_working_01.png', 'bands/band_working_01.png', 'band', (1024, 128), None),
    ('decal_sheet_01.png', 'decals/decal_sheet_01.png', 'sheet', (1024, 1024), None),
    ('building_mount_01.png', 'buildings/mount_01.png', 'object', (256, 256), (627, 617)),
    ('head_mass_driver_01.png', 'buildings/head_mass_driver.png', 'object', (256, 256), (627, 440)),
    ('machine_standard_01.png', 'machines/machine_standard.png', 'object', (64, 64), (627, 650)),
]


def isolate(im, threshold):
    """Preserve supplied alpha. For opaque black-ground input remove only
    border-connected near-black, retaining enclosed dark hull/recess pixels.
    Reject nonblack opaque backdrops rather than guessing a subject mask.
    """
    rgba = im.convert('RGBA')
    if rgba.getchannel('A').getextrema()[0] < 255:
        return rgba, 'source alpha preserved'
    a = np.asarray(rgba).copy()
    candidate = np.max(a[:, :, :3], axis=2) <= threshold
    if not all(candidate[y, x] for y, x in [(0, 0), (0, -1), (-1, 0), (-1, -1)]):
        raise ValueError('Opaque backdrop is not black; regenerate or supply a reviewed alpha mask.')
    # A padded eligible border connects all edge-entry background regions.
    # fromarray can expose a read-only buffer; floodfill silently catches its
    # write error. Copy explicitly so black extraction cannot become a no-op.
    mask = Image.fromarray(np.pad(candidate.astype(np.uint8) * 255, 1, constant_values=255)).copy()
    ImageDraw.floodfill(mask, (0, 0), 128)
    outside = np.asarray(mask)[1:-1, 1:-1] == 128
    a[outside, 3] = 0
    return Image.fromarray(a), 'border-connected black removed'


def delight(im, strength):
    """Alpha-weighted broad luminance estimate, gain bounded to +/- 15%.
    Relative material values, colour and small details stay intact. No
    machine-specific hue/light cleanup: that must not conceal a failed source.
    """
    a = np.asarray(im).astype(np.float32) / 255
    rgb, alpha = a[:, :, :3], a[:, :, 3]
    lum = rgb @ np.array([0.2126, 0.7152, 0.0722])
    radius = max(im.size) / 12
    def blur(v):
        return np.asarray(Image.fromarray(np.uint8(np.clip(v, 0, 1) * 255)).filter(
            ImageFilter.GaussianBlur(radius))).astype(np.float32) / 255
    field = blur(lum * alpha) / np.maximum(blur(alpha), 0.01)
    visible = alpha > 0.9
    target = float(np.median(field[visible]))
    gain = np.clip((target / np.maximum(field, 0.02)) ** strength, 0.85, 1.15)
    a[:, :, :3] = np.clip(rgb * gain[:, :, None], 0, 1)
    a[alpha == 0, :3] = 0
    return Image.fromarray(np.uint8(np.round(a * 255)))


def resize(im, size):
    return im.convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')


def normalize(source, destination, kind, size, pivot=None, strength=0.35, threshold=8):
    original = Image.open(source)
    im, alpha_method = isolate(original, threshold)
    im = delight(im, strength)
    bounds = im.getchannel('A').getbbox()
    if bounds is None:
        raise ValueError('Empty asset')
    content = im.crop(bounds)
    w, h = size
    output = Image.new('RGBA', size)
    info = dict(source=str(source.relative_to(ROOT) if source.is_relative_to(ROOT) else source),
                source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                size=size, content_bounds=bounds, alpha_method=alpha_method,
                delight_strength=strength, alpha_encoding='straight', kind=kind)
    if kind == 'sheet':
        # Keep complete sheet layout and gutters; no single pivot or cropping.
        scale = min(w / im.width, h / im.height)
        tile = resize(im, (round(im.width * scale), round(im.height * scale)))
        output.paste(tile, ((w - tile.width) // 2, (h - tile.height) // 2))
        info['pivot'] = None
    elif kind == 'band':
        # Preserve motif aspect approximately by repeating the source an integer
        # number of times. No hidden seam repair: report the real boundary error.
        repeats = max(1, round((w / h) / (content.width / content.height)))
        tiled = Image.new('RGBA', (content.width * repeats, content.height))
        for i in range(repeats):
            tiled.paste(content, (i * content.width, 0))
        output = resize(tiled, size)
        info.update(pivot=[0, h / 2], repeats=repeats)
        values = np.asarray(output).astype(float)
        info['edge_rgba_mean_absolute_error'] = float(np.abs(values[:, 0] - values[:, -1]).mean())
    else:
        if pivot is None:
            raise ValueError('Object requires a reviewed --pivot X Y in source pixels.')
        px, py = pivot[0] - bounds[0], pivot[1] - bounds[1]
        if not (0 < px < content.width and 0 < py < content.height):
            raise ValueError('Pivot must lie inside content bounds.')
        margin = max(2, round(min(size) * 0.025))
        scale = min((w / 2 - margin) / px, (w / 2 - margin) / (content.width - px),
                    (h / 2 - margin) / py, (h / 2 - margin) / (content.height - py))
        tile = resize(content, (max(1, round(content.width * scale)), max(1, round(content.height * scale))))
        offset = (round(w / 2 - px * scale), round(h / 2 - py * scale))
        output.paste(tile, offset)
        info.update(source_pivot=pivot, pivot=[w / 2, h / 2], scale=scale, paste_offset=offset,
                    pivot_note='Reviewed projected ground centre; head uses attachment axis.')
    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination)
    info['output_sha256'] = hashlib.sha256(destination.read_bytes()).hexdigest()
    info['output'] = str(destination.relative_to(ROOT) if destination.is_relative_to(ROOT) else destination)
    return info


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', nargs='?', type=Path)
    parser.add_argument('output', nargs='?', type=Path)
    parser.add_argument('--slice', action='store_true')
    parser.add_argument('--kind', choices=['object', 'band', 'sheet'], default='object')
    parser.add_argument('--size', nargs=2, type=int, default=[256, 256])
    parser.add_argument('--pivot', nargs=2, type=float)
    parser.add_argument('--delight', type=float, default=0.35)
    parser.add_argument('--black-threshold', type=int, default=8)
    args = parser.parse_args()
    if not 0 <= args.delight <= 1 or min(args.size) < 1 or not 0 <= args.black_threshold <= 32:
        parser.error('Invalid strength, dimensions or black threshold.')
    if args.slice:
        records = [normalize(ROOT / 'assets/art/source' / src, ROOT / 'assets/art' / dst,
                   kind, size, pivot, args.delight, args.black_threshold)
                   for src, dst, kind, size, pivot in SLICE]
        (ROOT / 'scripts/art/normalization_manifest.json').write_text(
            json.dumps(records, indent=2) + '\n', encoding='utf-8')
    elif args.input and args.output:
        records = [normalize(args.input.resolve(), args.output.resolve(), args.kind, tuple(args.size),
                   args.pivot, args.delight, args.black_threshold)]
    else:
        parser.error('Use --slice or input output.')
    print(json.dumps(records, indent=2))


if __name__ == '__main__':
    main()
