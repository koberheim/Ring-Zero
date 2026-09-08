"""Small regression checks for destructive normalization failure modes."""
import tempfile
import unittest
from pathlib import Path
import numpy as np
from PIL import Image
from normalize_asset import isolate, normalize, resize


class NormalizationTests(unittest.TestCase):
    def test_black_extraction_keeps_enclosed_dark_material(self):
        a = np.zeros((20, 20, 3), dtype=np.uint8)
        a[4:16, 4:16] = 60
        a[8:12, 8:12] = 0
        result, _ = isolate(Image.fromarray(a), 8)
        self.assertEqual(result.getchannel('A').getbbox(), (4, 4, 16, 16))
        self.assertEqual(result.getpixel((9, 9))[3], 255)
        self.assertEqual(result.getpixel((0, 0))[3], 0)

    def test_existing_partial_alpha_is_preserved(self):
        im = Image.new('RGBA', (4, 4), (30, 30, 30, 128))
        result, _ = isolate(im, 8)
        self.assertEqual(result.tobytes(), im.tobytes())

    def test_premultiplied_filter_ignores_hidden_colour(self):
        im = Image.new('RGBA', (16, 16), (255, 0, 0, 0))
        for y in range(4, 12):
            for x in range(4, 12):
                im.putpixel((x, y), (90, 90, 90, 255))
        a = np.asarray(resize(im, (8, 8)))
        visible = a[a[:, :, 3] > 0, :3]
        self.assertTrue(np.all(visible[:, 0] == visible[:, 1]))

    def test_pivot_export_is_not_clipped(self):
        with tempfile.TemporaryDirectory() as directory:
            source, output = Path(directory) / 'in.png', Path(directory) / 'out.png'
            im = Image.new('RGBA', (80, 120))
            im.paste((80, 80, 80, 255), (10, 10, 70, 110))
            im.save(source)
            info = normalize(source, output, 'object', (64, 64), (40, 40))
            result = Image.open(output)
            self.assertEqual(result.size, (64, 64))
            self.assertEqual(info['pivot'], [32, 32])
            x0, y0, x1, y1 = result.getchannel('A').getbbox()
            self.assertTrue(0 < x0 < x1 < 64 and 0 < y0 < y1 < 64)


if __name__ == '__main__':
    unittest.main()
