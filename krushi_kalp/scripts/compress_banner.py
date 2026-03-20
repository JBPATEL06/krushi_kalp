"""
Second-pass compression for homeBanner.png.
Resizes to 50% dimensions + quantizes to 128 colors to reach <300KB.
"""
from PIL import Image
import os

path = r'f:\Krushi_kalp1\krushi_kalp\assets\images\homeBanner.png'
before_kb = os.path.getsize(path) / 1024

img = Image.open(path)
w, h = img.size
print(f'Mode: {img.mode}, Size: {w}x{h}')

# Resize to 50% — banner doesn't need full resolution on mobile (~400px logical width)
new_w = int(w * 0.5)
new_h = int(h * 0.5)
img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

# Quantize with fewer colors
if img_resized.mode not in ('RGB', 'L'):
    img_resized = img_resized.convert('RGB')
quantized = img_resized.quantize(colors=128, dither=Image.Dither.FLOYDSTEINBERG)
quantized.save(path, format='PNG', optimize=True)

after_kb = os.path.getsize(path) / 1024
print(f'Before: {before_kb:.1f} KB')
print(f'After : {after_kb:.1f} KB')
result = 'PASS' if after_kb < 300 else 'NEEDS MORE'
print(f'Result: {result} (target <300 KB)')
print(f'New dimensions: {new_w}x{new_h}')
