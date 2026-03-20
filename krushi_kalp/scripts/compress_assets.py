"""
Compress PNG images in assets/images/ while keeping filenames, dimensions, and PNG format.
Strategy: Quantize to palette mode for dramatic size reduction.
"""
import os
from PIL import Image

assets_dir = r"f:\Krushi_kalp1\krushi_kalp\assets\images"

targets = [
    {
        "file": "notification_logo.png",
        "target_kb": 100,
        "colors": 128,
    },
    {
        "file": "playstore.png",
        "target_kb": 100,
        "colors": 128,
    },
    {
        "file": "homeBanner.png",
        "target_kb": 300,
        "colors": 192,
    },
]

for t in targets:
    path = os.path.join(assets_dir, t["file"])
    original_size = os.path.getsize(path)
    original_kb = original_size / 1024

    img = Image.open(path)
    original_mode = img.mode
    original_size_px = img.size
    print(f"\n{'='*60}")
    print(f"File    : {t['file']}")
    print(f"Before  : {original_kb:.1f} KB  |  Mode: {original_mode}  |  Size: {original_size_px}")

    if original_mode in ("RGBA", "LA"):
        quantized = img.quantize(colors=t["colors"], dither=Image.Dither.FLOYDSTEINBERG)
    else:
        if original_mode != "RGB":
            img = img.convert("RGB")
        quantized = img.quantize(colors=t["colors"], dither=Image.Dither.FLOYDSTEINBERG)

    quantized.save(path, format="PNG", optimize=True)

    result_img = Image.open(path)
    new_size = os.path.getsize(path)
    new_kb = new_size / 1024
    print(f"After   : {new_kb:.1f} KB  |  Mode: {result_img.mode}  |  Size: {result_img.size}")
    reduction = (1 - new_size / original_size) * 100
    status = "PASS" if new_kb < t['target_kb'] else "NEEDS MORE"
    print(f"Reduction: {reduction:.1f}%  |  Target: <{t['target_kb']} KB  |  {status}")

print("\nDone.")
