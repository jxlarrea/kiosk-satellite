"""Generate the synthetic JPEG workload. Requires Pillow and an output folder."""
from pathlib import Path
import hashlib
import random
import sys

from PIL import Image, ImageDraw

root = Path(sys.argv[1])
root.mkdir(parents=True, exist_ok=True)
for index in range(3):
    rng = random.Random(index)
    picture = Image.new("RGB", (3000, 4000))
    draw = ImageDraw.Draw(picture)
    for y in range(0, 4000, 4):
        draw.rectangle(
            (0, y, 3000, y + 3),
            fill=((y // 20 + index * 61) % 256, (y // 30 + 60) % 256, (y // 18 + 120) % 256),
        )
    for _ in range(1200):
        x, y, radius = rng.randrange(3000), rng.randrange(4000), rng.randrange(8, 100)
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            fill=tuple(rng.randrange(256) for _ in range(3)),
        )
    draw.text((300, 700), "PHOTO " + str(index), fill="white", stroke_width=3)
    path = root / f"{index}.jpg"
    picture.save(path, quality=93)
    print(path.name, hashlib.sha256(path.read_bytes()).hexdigest())
