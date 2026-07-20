# Generates three pixel-art parallax background packs (beach, frankfurt,
# alps) in the same format as the cherry blossom pack: 480x270 PNG layers
# 00 (sky, opaque) .. 04 (foreground, transparent).
# Drawn at 240x135 and upscaled 2x nearest for a chunky pixel look.
# Layers tile horizontally (motion_mirroring): edge-crossing shapes are
# avoided, gradients are horizontally uniform.
#
# Run: python scripts/tools/make_level_backgrounds.py

from PIL import Image, ImageDraw
import os, random

BASE = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites", "environment")
W, H = 240, 135


def new_layer(opaque_color=None):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0) if opaque_color is None else (*opaque_color, 255))
    return img, ImageDraw.Draw(img)


def vgradient(draw, y0, y1, c0, c1, steps=16):
    span = max(y1 - y0, 1)
    for i in range(steps):
        t0 = i / steps
        t1 = (i + 1) / steps
        c = tuple(int(c0[k] + (c1[k] - c0[k]) * (t0 + t1) / 2) for k in range(3))
        draw.rectangle([0, int(y0 + t0 * span), W, int(y0 + t1 * span)], fill=(*c, 255))


def save_pack(name, layers):
    out_dir = os.path.join(BASE, name)
    os.makedirs(out_dir, exist_ok=True)
    names = ["00 - Sky.png", "01 - Far.png", "02 - Mid.png", "03 - Near.png", "04 - Foreground.png"]
    for fname, img in zip(names, layers):
        img.resize((W * 2, H * 2), Image.NEAREST).save(os.path.join(out_dir, fname))
    print("saved", name)


# ---------------------------------------------------------------- beach ---

def make_beach():
    rng = random.Random(7)
    sky, d = new_layer((125, 190, 235))
    vgradient(d, 0, 80, (110, 175, 230), (255, 225, 190))
    vgradient(d, 80, H, (255, 225, 190), (255, 236, 210))
    # sun with halo
    d.ellipse([160, 26, 186, 52], fill=(255, 246, 214, 255))
    d.ellipse([164, 30, 182, 48], fill=(255, 252, 235, 255))
    # clouds
    for cx, cy, s in ((45, 30, 10), (120, 18, 8), (205, 42, 7)):
        for dx, dy, r in ((0, 0, s), (s, 2, s - 2), (-s + 2, 3, s - 3)):
            d.ellipse([cx + dx - r, cy + dy - r // 2, cx + dx + r, cy + dy + r // 2],
                      fill=(255, 255, 255, 235))

    sea, d = new_layer()
    vgradient(d, 76, 110, (98, 190, 190), (58, 150, 172))
    d.rectangle([0, 76, W, 78], fill=(210, 235, 230, 255))
    for _ in range(45):
        x = rng.randrange(4, W - 6)
        y = rng.randrange(80, 108)
        d.line([x, y, x + rng.randrange(2, 5), y], fill=(235, 250, 245, 190))
    # little sailboat
    d.polygon([(60, 84), (60, 74), (67, 84)], fill=(250, 250, 250, 255))
    d.line([53, 85, 69, 85], fill=(120, 80, 60, 255))

    far, d = new_layer()  # distant islands
    for ix, iw in ((30, 40), (180, 34)):
        d.ellipse([ix, 84, ix + iw, 96], fill=(52, 118, 128, 255))
        d.line([ix + iw // 2, 78, ix + iw // 2, 86], fill=(40, 95 , 105, 255))
        d.ellipse([ix + iw // 2 - 6, 74, ix + iw // 2 + 6, 82], fill=(45, 105, 115, 255))

    near, d = new_layer()  # sand + palms
    vgradient(d, 100, H, (246, 224, 174), (240, 212, 158))
    for x in range(0, W, 7):
        d.point([(x, 100), (x + 3, 101)], fill=(255, 238, 200, 255))
    for px, flip in ((38, 1), (205, -1)):
        # curved trunk
        for i in range(28):
            t = i / 28
            x = px + flip * int(10 * t * t)
            y = 104 - int(38 * t)
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=(122, 82, 58, 255))
        top_x = px + flip * 10
        top_y = 66
        for ang_dx, ang_dy in ((-14, -2), (14, -2), (-10, 6), (10, 6), (0, -8), (-16, 3), (16, 3)):
            d.ellipse([top_x + ang_dx - 8, top_y + ang_dy - 3,
                       top_x + ang_dx + 8, top_y + ang_dy + 3], fill=(66, 150, 92, 255))
        d.ellipse([top_x - 3, top_y - 3, top_x + 3, top_y + 3], fill=(96, 66, 46, 255))

    fg, d = new_layer()  # dune strip with shells
    vgradient(d, 116, H, (232, 202, 148), (222, 190, 136))
    d.line([0, 116, W, 116], fill=(246, 224, 176, 255))
    for _ in range(9):
        x = rng.randrange(8, W - 8)
        y = rng.randrange(121, 132)
        kind = rng.random()
        if kind < 0.4:
            d.ellipse([x - 2, y - 1, x + 2, y + 2], fill=(250, 240, 225, 255))
        elif kind < 0.7:
            d.polygon([(x, y - 3), (x - 3, y + 2), (x + 3, y + 2)], fill=(255, 150, 130, 255))
        else:
            for gx in (-2, 0, 2):
                d.line([x + gx, y, x + gx + (1 if gx else 0), y - 4], fill=(150, 140, 90, 255))
    save_pack("beach_parallax", [sky, sea, far, near, fg])


# ------------------------------------------------------------ frankfurt ---

def _tower(d, x, w, top, color, win_color, rng, spire=None, pyramid=False):
    d.rectangle([x, top, x + w, 108], fill=(*color, 255))
    if pyramid:
        d.polygon([(x, top), (x + w, top), (x + w // 2, top - 10)], fill=(*color, 255))
    if spire:
        d.line([x + w // 2, top - spire, x + w // 2, top], fill=(*color, 255))
    for wy in range(top + 4, 104, 5):
        for wx in range(x + 2, x + w - 2, 4):
            if rng.random() < 0.35:
                d.rectangle([wx, wy, wx + 1, wy + 1], fill=(*win_color, 255))


def make_frankfurt():
    rng = random.Random(11)
    sky, d = new_layer((40, 45, 90))
    vgradient(d, 0, 60, (34, 38, 82), (86, 70, 118))
    vgradient(d, 60, 100, (86, 70, 118), (238, 148, 108))
    vgradient(d, 100, H, (238, 148, 108), (250, 176, 128))
    for _ in range(40):
        x, y = rng.randrange(2, W - 2), rng.randrange(2, 55)
        d.point([(x, y)], fill=(255, 255, 255, rng.randrange(120, 220)))
    d.ellipse([104, 88, 136, 112], fill=(255, 200, 150, 90))
    d.ellipse([112, 94, 128, 108], fill=(255, 226, 180, 140))

    far, d = new_layer()
    c, wc = (64, 62, 104), (255, 214, 140)
    for x, w, top in ((14, 12, 66), (32, 10, 74), (52, 14, 58), (76, 10, 70),
                      (150, 12, 64), (170, 10, 72), (196, 14, 60), (218, 10, 70)):
        _tower(d, x, w, top, c, wc, rng)
    d.rectangle([0, 104, W, 108], fill=(*c, 255))

    near, d = new_layer()
    c, wc = (42, 44, 78), (255, 224, 150)
    _tower(d, 28, 18, 44, c, wc, rng, pyramid=True)            # Commerzbank-ish
    _tower(d, 60, 14, 52, c, wc, rng, spire=16)                # Messeturm-ish
    _tower(d, 96, 20, 62, c, wc, rng)
    _tower(d, 132, 16, 40, c, wc, rng, spire=22)               # antenna tower
    _tower(d, 168, 22, 56, c, wc, rng)
    _tower(d, 204, 16, 48, c, wc, rng, pyramid=True)
    d.rectangle([0, 106, W, 110], fill=(*c, 255))

    river, d = new_layer()
    vgradient(d, 108, 124, (36, 40, 72), (24, 28, 54))
    for _ in range(60):
        x = rng.randrange(3, W - 6)
        y = rng.randrange(109, 123)
        col = (255, 200, 120, 150) if rng.random() < 0.6 else (150, 170, 220, 120)
        d.line([x, y, x + rng.randrange(2, 5), y], fill=col)
    # iron footbridge arc
    d.arc([70, 96, 170, 130], 180, 360, fill=(20, 22, 40, 255), width=2)
    d.line([70, 113, 170, 113], fill=(20, 22, 40, 255), width=2)
    for bx in range(74, 168, 8):
        d.line([bx, 106 + abs(bx - 120) // 12, bx, 113], fill=(20, 22, 40, 200))
    for lx in (80, 120, 160):
        d.point([(lx, 108)], fill=(255, 230, 160, 255))

    fg, d = new_layer()
    vgradient(d, 122, H, (26, 28, 50), (18, 20, 38))
    d.line([0, 122, W, 122], fill=(48, 50, 82, 255))
    for lx in (30, 120, 210):
        d.line([lx, 122, lx, 108], fill=(30, 32, 56, 255), width=2)
        d.ellipse([lx - 2, 104, lx + 2, 109], fill=(255, 224, 150, 255))
        d.ellipse([lx - 4, 102, lx + 4, 111], fill=(255, 224, 150, 60))
    save_pack("frankfurt_parallax", [sky, far, near, river, fg])


# ----------------------------------------------------------------- alps ---

def _peak(d, cx, base_w, top_y, color, snow, base_y=110):
    d.polygon([(cx - base_w, base_y), (cx + base_w, base_y), (cx, top_y)], fill=(*color, 255))
    # snow cap
    h = base_y - top_y
    cap = int(h * 0.34)
    ratio = cap / h
    lx = cx - int(base_w * ratio)
    rx = cx + int(base_w * ratio)
    d.polygon([(lx, top_y + cap), (rx, top_y + cap), (cx, top_y)], fill=(*snow, 255))
    d.polygon([(lx, top_y + cap), (lx + 4, top_y + cap + 5), (lx + 8, top_y + cap)], fill=(*snow, 255))
    d.polygon([(rx - 8, top_y + cap), (rx - 4, top_y + cap + 4), (rx, top_y + cap)], fill=(*snow, 255))


def make_alps():
    rng = random.Random(5)
    sky, d = new_layer((150, 200, 240))
    vgradient(d, 0, 95, (132, 190, 238), (225, 240, 250))
    vgradient(d, 95, H, (225, 240, 250), (235, 245, 252))
    for cx, cy, s in ((60, 26, 11), (150, 40, 8), (215, 20, 9)):
        for dx, dy, r in ((0, 0, s), (s - 1, 2, s - 3), (-s + 2, 3, s - 4)):
            d.ellipse([cx + dx - r, cy + dy - r // 2, cx + dx + r, cy + dy + r // 2],
                      fill=(255, 255, 255, 240))

    far, d = new_layer()
    for cx, bw, ty in ((20, 46, 46), (95, 55, 34), (170, 48, 50), (232, 40, 44)):
        _peak(d, cx, bw, ty, (152, 172, 205), (232, 240, 250))
    d.rectangle([0, 108, W, 112], fill=(152, 172, 205, 255))

    mid, d = new_layer()
    for cx, bw, ty in ((-10, 60, 58), (70, 52, 48), (150, 62, 40), (235, 55, 55)):
        _peak(d, cx, bw, ty, (112, 134, 172), (240, 246, 252), base_y=114)
    d.rectangle([0, 112, W, 116], fill=(112, 134, 172, 255))

    near, d = new_layer()  # meadow hills + chalets + pines
    d.ellipse([-60, 96, 140, 160], fill=(122, 172, 108, 255))
    d.ellipse([100, 100, 300, 168], fill=(108, 160, 98, 255))
    d.rectangle([0, 122, W, H], fill=(112, 164, 102, 255))
    for hx, hy in ((52, 104), (176, 108)):
        d.rectangle([hx, hy, hx + 16, hy + 10], fill=(150, 110, 78, 255))
        d.polygon([(hx - 2, hy), (hx + 18, hy), (hx + 8, hy - 8)], fill=(120, 60, 48, 255))
        d.rectangle([hx + 3, hy + 3, hx + 5, hy + 5], fill=(255, 230, 160, 255))
        d.rectangle([hx + 10, hy + 3, hx + 12, hy + 5], fill=(255, 230, 160, 255))
    for px, py, s in ((20, 108, 9), (34, 112, 7), (120, 112, 8), (150, 108, 10), (222, 112, 8)):
        for i in range(3):
            w = s - i * 2
            y = py - i * 4
            d.polygon([(px - w, y), (px + w, y), (px, y - 6)], fill=(58, 112, 74, 255))
        d.rectangle([px - 1, py, px + 1, py + 3], fill=(96, 70, 50, 255))

    fg, d = new_layer()
    vgradient(d, 118, H, (96, 152, 92), (84, 138, 84))
    d.line([0, 118, W, 118], fill=(130, 184, 116, 255))
    for _ in range(26):
        x = rng.randrange(4, W - 4)
        y = rng.randrange(121, 133)
        col = rng.choice([(255, 255, 255), (255, 220, 120), (255, 160, 190), (180, 140, 255)])
        d.point([(x, y)], fill=(*col, 255))
        d.point([(x, y + 1)], fill=(70, 120, 70, 255))
    for _ in range(18):
        x = rng.randrange(3, W - 3)
        y = rng.randrange(120, 132)
        d.line([x, y, x, y - 3], fill=(76, 130, 76, 255))
    save_pack("alps_parallax", [sky, far, mid, near, fg])


def contact_sheet():
    packs = ["beach_parallax", "frankfurt_parallax", "alps_parallax"]
    names = ["00 - Sky.png", "01 - Far.png", "02 - Mid.png", "03 - Near.png", "04 - Foreground.png"]
    sheet = Image.new("RGBA", (480, 270 * 3 + 20), (30, 30, 30, 255))
    for i, pack in enumerate(packs):
        comp = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
        for n in names:
            layer = Image.open(os.path.join(BASE, pack, n))
            comp = Image.alpha_composite(comp, layer)
        sheet.paste(comp, (0, i * 280))
    out = os.environ.get("CONTACT_OUT", os.path.join(BASE, "bg_contact_preview.png"))
    sheet.save(out)
    print("contact sheet:", out)


make_beach()
make_frankfurt()
make_alps()
contact_sheet()
