#!/usr/bin/env python3
"""Render map-pin marker icons for Yandex MapKit placemarks (which take an image
asset, unlike flutter_map's widget markers). Teardrop pin + white dot, one per
marker kind. Drawn hi-res and downsampled (LANCZOS) for crisp edges.
Re-run: python3 tool/generate_map_pins.py
"""
import math
from PIL import Image, ImageDraw

# (name, fill) — colors match the design system / logo palette.
PINS = [
    ("pin_job", (58, 54, 219, 255)),       # indigo #3A36DB (jobs / picked)
    ("pin_applicant", (13, 128, 242, 255)),  # azure #0D80F2 (candidates)
]

SS = 4              # supersample
W, H = 96 * SS, 120 * SS
R = 40 * SS         # head radius
CX, CY = W // 2, R + 4 * SS


def build(fill):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Teardrop: head disc + tail triangle to the bottom tip.
    ang = math.radians(40)
    lx, ly = CX - R * math.sin(ang), CY + R * math.cos(ang)
    rx, ry = CX + R * math.sin(ang), CY + R * math.cos(ang)
    d.polygon([(lx, ly), (rx, ry), (CX, H - 3 * SS)], fill=fill)
    d.ellipse([CX - R, CY - R, CX + R, CY + R], fill=fill)
    # White inner dot.
    r2 = int(R * 0.42)
    d.ellipse([CX - r2, CY - r2, CX + r2, CY + r2], fill=(255, 255, 255, 255))
    return img.resize((W // SS, H // SS), Image.LANCZOS)


def main():
    for name, fill in PINS:
        build(fill).save(f"assets/icon/{name}.png")
    print("Wrote", ", ".join(f"assets/icon/{n}.png" for n, _ in PINS))


if __name__ == "__main__":
    main()
