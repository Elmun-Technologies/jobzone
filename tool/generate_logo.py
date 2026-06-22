#!/usr/bin/env python3
"""Render the Jobzone brand logo (magnifying glass + location pin + person)
into the launcher-icon / splash PNG sources consumed by flutter_launcher_icons
and flutter_native_splash. Drawn at high resolution and downsampled with
LANCZOS for crisp anti-aliased edges. Re-run with: python3 tool/generate_logo.py
"""
import math
from PIL import Image, ImageDraw, ImageChops

# ---- Brand palette (sampled from the provided logo) ----
NAVY = (44, 90, 160, 255)      # magnifying-glass frame + handle
LAV = (221, 228, 245, 255)     # location-pin teardrop + halo ring
AZ = (13, 128, 242, 255)       # person silhouette
GROUND = (44, 62, 80, 255)     # ground ellipse outline
WHITE = (255, 255, 255, 255)

# ---- Master sprite (high-res, transparent) ----
W = H = 3000
cx, cy = 1500, 1190             # lens center


def _disc(draw, x, y, r, fill):
    draw.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def build_sprite():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # White base under the lens so the inner gap stays white even on a
    # transparent canvas (matters for the adaptive foreground).
    _disc(d, cx, cy, 700, WHITE)

    # Lavender location-pin: round head + downward teardrop tail.
    rp = 655
    _disc(d, cx, cy, rp, LAV)
    ang = math.radians(33)
    lx, ly = cx - rp * math.sin(ang), cy + rp * math.cos(ang)
    rx, ry = cx + rp * math.sin(ang), cy + rp * math.cos(ang)
    d.polygon([(lx, ly), (rx, ry), (cx, 2570)], fill=LAV)

    # White interior leaves a lavender halo ring (590..655).
    _disc(d, cx, cy, 590, WHITE)

    # Person (head + bust), clipped to the lens interior so the body bottom
    # follows the lens curve.
    person = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(person)
    hr, hcy = 172, cy - 210
    pd.ellipse([cx - hr, hcy - hr, cx + hr, hcy + hr], fill=AZ)
    br, bcy = 388, cy + 372
    pd.ellipse([cx - br, bcy - br, cx + br, bcy + br], fill=AZ)
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse([cx - 575, cy - 575, cx + 575, cy + 575], fill=255)
    person.putalpha(ImageChops.multiply(person.split()[3], mask))
    img.alpha_composite(person)

    # Magnifying-glass frame (thick ring): inner 677, outer 735.
    rr, rw = 706, 58
    d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=NAVY, width=rw)

    # Handle to the lower-right with rounded caps.
    a1 = math.radians(47)
    p1 = (cx + rr * math.cos(a1), cy + rr * math.sin(a1))
    p2 = (cx + 1080 * math.cos(a1), cy + 1080 * math.sin(a1))
    hw = 72
    d.line([p1, p2], fill=NAVY, width=hw)
    for p in (p1, p2):
        d.ellipse([p[0] - hw / 2, p[1] - hw / 2, p[0] + hw / 2, p[1] + hw / 2], fill=NAVY)

    # Ground ellipse (thin outline).
    gcy = 2585
    d.ellipse([cx - 620, gcy - 95, cx + 620, gcy + 95], outline=GROUND, width=12)

    return img.crop(img.getbbox())


def place(sprite, size, frac, bg):
    canvas = Image.new("RGBA", (size, size), bg)
    maxd = int(size * frac)
    sw, sh = sprite.size
    scale = min(maxd / sw, maxd / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    rs = sprite.resize((nw, nh), Image.LANCZOS)
    canvas.alpha_composite(rs, ((size - nw) // 2, (size - nh) // 2))
    return canvas


def main():
    sprite = build_sprite()

    # Legacy / iOS / web icon — logo on white, fills the canvas.
    place(sprite, 1024, 0.90, WHITE).convert("RGB").save("assets/icon/icon.png")

    # Android adaptive foreground — logo within the ~66% safe zone, transparent.
    place(sprite, 1024, 0.62, (0, 0, 0, 0)).save("assets/icon/icon_foreground.png")

    # Splash — white badge holding the logo, reads on the indigo splash bg.
    splash = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    ImageDraw.Draw(splash).ellipse([512 - 472, 512 - 472, 512 + 472, 512 + 472], fill=WHITE)
    logo = place(sprite, 1024, 0.60, (0, 0, 0, 0))
    splash.alpha_composite(logo)
    splash.save("assets/icon/splash_logo.png")

    # Web / PWA icons + favicon (white bg; maskable variants keep the logo in
    # the ~62% safe zone so launcher masking never clips it).
    place(sprite, 64, 0.92, WHITE).convert("RGB").save("web/favicon.png")
    place(sprite, 192, 0.90, WHITE).convert("RGB").save("web/icons/Icon-192.png")
    place(sprite, 512, 0.90, WHITE).convert("RGB").save("web/icons/Icon-512.png")
    place(sprite, 192, 0.62, WHITE).convert("RGB").save("web/icons/Icon-maskable-192.png")
    place(sprite, 512, 0.62, WHITE).convert("RGB").save("web/icons/Icon-maskable-512.png")

    # Side-by-side preview for review (not shipped).
    prev = Image.new("RGB", (1100, 360), (235, 236, 240))
    prev.paste(Image.open("assets/icon/icon.png").resize((320, 320)), (20, 20))
    fg = Image.new("RGBA", (1024, 1024), (255, 255, 255, 255))
    fg.alpha_composite(place(sprite, 1024, 0.62, (0, 0, 0, 0)))
    prev.paste(fg.convert("RGB").resize((320, 320)), (390, 20))
    ind = Image.new("RGBA", (1024, 1024), (58, 54, 219, 255))
    ind.alpha_composite(Image.open("assets/icon/splash_logo.png"))
    prev.paste(ind.convert("RGB").resize((320, 320)), (760, 20))
    prev.save("tool/logo_preview.png")
    print("Wrote icon.png, icon_foreground.png, splash_logo.png + tool/logo_preview.png")


if __name__ == "__main__":
    main()
