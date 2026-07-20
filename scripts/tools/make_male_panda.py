# Derives a male panda sprite sheet from the female one:
# bow removed (mirror + dome rebuild), dress -> navy suit, collar + tie,
# thin glasses. Blush cheeks protected by geometry (above the dress top),
# so the dress's light heart pattern still gets recolored.

from PIL import Image, ImageDraw

SRC = r"C:\Users\VietHung.Ly\Loveable_Pandas\assets\sprites\panda\panda_female_sheet.png"
OUT = r"C:\Users\VietHung.Ly\Loveable_Pandas\assets\sprites\panda\panda_male_sheet.png"
PREVIEW = r"C:\Users\VietHung.Ly\AppData\Local\Temp\claude\C--Users-VietHung-Ly-Loveable-Pandas\f8b9ff6d-ca42-412c-85c1-47712ca7af5b\scratchpad\male_preview.png"

FRAMES = {
    "idle": [(130, 43, 81, 85), (223, 43, 71, 85), (306, 42, 67, 86), (387, 44, 72, 84)],
    "run": [(101, 168, 78, 87), (178, 169, 67, 85), (247, 168, 77, 88), (323, 168, 67, 85), (392, 168, 74, 88), (471, 168, 65, 88)],
    "jump": [(101, 314, 73, 73), (182, 297, 61, 80), (254, 297, 62, 80), (326, 297, 70, 80), (399, 298, 59, 83), (468, 297, 63, 82)],
}

SUIT_DARK = (24, 30, 52)
SUIT_LIGHT = (88, 104, 148)
TIE = (168, 34, 58)
TIE_DARK = (120, 22, 42)
COLLAR = (242, 242, 246)
GLASS = (10, 10, 20)
FUR_LIGHT = (236, 234, 240, 255)
FUR_DARK = (30, 28, 52, 255)
HAIR_DARK = (14, 14, 36)
HAIR_LIGHT = (66, 70, 104)


def is_blush(px):
    r, g, b, a = px
    return a >= 128 and r >= 195 and 95 <= g <= 210 and 30 <= r - g <= 135


def seed_pink(px):
    r, g, b, a = px
    return a >= 128 and r >= 170 and r - g >= 130 and r - b >= 40


def reddish(px):
    """Any warm pink/red/maroon shade incl. dark outlines & soft edges."""
    r, g, b, a = px
    if a < 40:
        return False
    if r > 225 and g > 200 and b > 200:
        return False
    return r - g >= 18 and r - b >= -25


def is_dark(px):
    r, g, b, a = px
    return a >= 128 and (0.299 * r + 0.587 * g + 0.114 * b) < 70


def is_white(px):
    r, g, b, a = px
    return a >= 128 and r > 180 and g > 180 and b > 180


def lum(px):
    return 0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]


def flood(pix, w, h, seeds, pred):
    mask = set(seeds)
    frontier = list(seeds)
    while frontier:
        nxt = []
        for (x, y) in frontier:
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in mask:
                        continue
                    nx, ny = n
                    if 0 <= nx < w and 0 <= ny < h and pred(pix[nx, ny], nx, ny):
                        mask.add(n)
                        nxt.append(n)
        frontier = nxt
    return mask


def process_frame(frame):
    w, h = frame.size
    pix = frame.load()

    seeds = [(x, y) for y in range(h) for x in range(w) if seed_pink(pix[x, y])]
    if seeds:
        ys = sorted({y for _, y in seeds})
        split = int(0.45 * h)
        best_gap = 0
        for a, b in zip(ys, ys[1:]):
            if b - a > best_gap:
                best_gap = b - a
                split = (a + b) // 2
        if best_gap < 3:
            split = int(0.42 * h)

        bow_seeds = {(x, y) for (x, y) in seeds if y <= split}
        dress_seeds = {(x, y) for (x, y) in seeds if y > split}
        dress_top = min((y for (_, y) in dress_seeds), default=int(0.55 * h))

        # blush lives above the dress; the dress's own light-pink pattern
        # is below dress_top and must NOT be protected
        def grow(px, x, y):
            if is_blush(px) and y < dress_top - 2:
                return False
            return reddish(px)

        bow = flood(pix, w, h, bow_seeds, grow)
        dress = flood(pix, w, h, dress_seeds, grow) - bow

        # mirror-fill the bow area from the clean head side
        head_rows = int(0.55 * h)
        xs = [x for y in range(head_rows) for x in range(w)
              if pix[x, y][3] >= 128 and (x, y) not in bow]
        cx = sum(xs) / len(xs) if xs else w / 2

        # Recolor the bow into dark fur (a fluffy hair tuft) instead of
        # trying to remove it: keeps silhouette, outline and shading
        # intact in every pose -- reads as his own head floof.
        if bow:
            blums = [lum(pix[x, y]) for (x, y) in bow]
            lo, hi = min(blums), max(blums)
            span = max(hi - lo, 1)
            for (x, y) in bow:
                t = (lum(pix[x, y]) - lo) / span
                r = int(HAIR_DARK[0] + (HAIR_LIGHT[0] - HAIR_DARK[0]) * t)
                g = int(HAIR_DARK[1] + (HAIR_LIGHT[1] - HAIR_DARK[1]) * t)
                b = int(HAIR_DARK[2] + (HAIR_LIGHT[2] - HAIR_DARK[2]) * t)
                pix[x, y] = (r, g, b, pix[x, y][3])

        if dress:
            _recolor_dress(pix, dress)
            _add_collar_and_tie(pix, dress)

    # zero out faint leftovers
    for y in range(h):
        for x in range(w):
            if 0 < pix[x, y][3] < 40:
                pix[x, y] = (0, 0, 0, 0)

    # scrub remaining pinkish edge pixels on the hair (above the face,
    # where no blush lives) into the hair ramp
    for y in range(int(0.32 * h)):
        for x in range(w):
            p = pix[x, y]
            if p[3] >= 40 and p[0] >= 130 and p[0] - p[1] >= 12:
                t = min(max(lum(p) / 255.0, 0.0), 1.0)
                r = int(HAIR_DARK[0] + (HAIR_LIGHT[0] - HAIR_DARK[0]) * t)
                g = int(HAIR_DARK[1] + (HAIR_LIGHT[1] - HAIR_DARK[1]) * t)
                b = int(HAIR_DARK[2] + (HAIR_LIGHT[2] - HAIR_DARK[2]) * t)
                pix[x, y] = (r, g, b, p[3])

    boxes = _find_eye_boxes(pix, w, h)
    draw = ImageDraw.Draw(frame)
    if boxes:
        boxes = sorted(boxes, key=lambda b: b[0])
        for box in boxes:
            draw.ellipse(box, outline=GLASS, width=1)
        if len(boxes) == 2:
            lb, rb = boxes
            by = (lb[1] + lb[3] + rb[1] + rb[3]) // 4
            if rb[0] > lb[2]:
                draw.line((lb[2], by, rb[0], by), fill=GLASS, width=1)
    return frame


def _recolor_dress(pix, dress):
    lums = [lum(pix[x, y]) for (x, y) in dress]
    lo, hi = min(lums), max(lums)
    span = max(hi - lo, 1)
    for (x, y) in dress:
        t = (lum(pix[x, y]) - lo) / span
        r = int(SUIT_DARK[0] + (SUIT_LIGHT[0] - SUIT_DARK[0]) * t)
        g = int(SUIT_DARK[1] + (SUIT_LIGHT[1] - SUIT_DARK[1]) * t)
        b = int(SUIT_DARK[2] + (SUIT_LIGHT[2] - SUIT_DARK[2]) * t)
        pix[x, y] = (r, g, b, pix[x, y][3])


def _add_collar_and_tie(pix, dress):
    top = min(y for (_, y) in dress)
    top_xs = sorted(x for (x, y) in dress if y <= top + 1)
    scx = top_xs[len(top_xs) // 2]
    for dy, half in ((0, 4), (1, 3), (2, 2)):
        for dx in range(-half, half + 1):
            if (scx + dx, top + dy) in dress:
                pix[scx + dx, top + dy] = (*COLLAR, 255)
    tie_rows = ((0, 1, TIE), (1, 1, TIE), (2, 1, TIE), (3, 1, TIE_DARK), (4, 0, TIE_DARK))
    for dy, half, col in tie_rows:
        for dx in range(-half, half + 1):
            if (scx + dx, top + dy) in dress:
                pix[scx + dx, top + dy] = (*col, 255)


def _remove_floating_debris(pix, w, h):
    seen = set()
    comps = []
    for y in range(h):
        for x in range(w):
            if (x, y) in seen or pix[x, y][3] < 40:
                continue
            stack, comp = [(x, y)], []
            seen.add((x, y))
            while stack:
                px_, py_ = stack.pop()
                comp.append((px_, py_))
                for nx, ny in ((px_+1, py_), (px_-1, py_), (px_, py_+1), (px_, py_-1),
                               (px_+1, py_+1), (px_-1, py_-1), (px_+1, py_-1), (px_-1, py_+1)):
                    if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in seen and pix[nx, ny][3] >= 40:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            comps.append(comp)
    if not comps:
        return
    comps.sort(key=len, reverse=True)
    for comp in comps[1:]:
        if max(p[1] for p in comp) < 0.55 * h:
            for (x, y) in comp:
                pix[x, y] = (0, 0, 0, 0)


def _rebuild_head_dome(pix, w, h, bow):
    """Closes the remaining notch by interpolating the silhouette between
    trusted columns (columns outside the hole, plus dark tops inside it:
    rebuilt ears / outline). Fills with one uniform fur color per frame
    so no leftover bow tints bleed in as stripes."""
    if not bow:
        return
    hole_cols = sorted({x for (x, _) in bow})
    hole_set = set(hole_cols)
    x0, x1 = hole_cols[0], hole_cols[-1]

    def ytop(x):
        for y in range(h):
            if pix[x, y][3] >= 128:
                return y
        return None

    # uniform light fur color: median of bright neutral head pixels
    lights = []
    for y in range(int(0.5 * h)):
        for x in range(w):
            p = pix[x, y]
            if p[3] >= 200 and lum(p) >= 195 and abs(p[0] - p[1]) <= 18 and abs(p[1] - p[2]) <= 18:
                lights.append(p)
    if lights:
        lights.sort(key=lum)
        lp = lights[len(lights) // 2]
        fur_light = (lp[0], lp[1], lp[2], 255)
    else:
        fur_light = FUR_LIGHT

    # trusted silhouette nodes
    nodes = {}
    for x in range(max(0, x0 - 12), min(w, x1 + 13)):
        t = ytop(x)
        if t is None:
            continue
        if x not in hole_set or lum(pix[x, t]) < 140:
            nodes[x] = t
    if not nodes:
        return
    known = sorted(nodes)

    for x in hole_cols:
        y0 = ytop(x)
        if y0 is None or lum(pix[x, y0]) < 140:
            continue
        left = max((k for k in known if k < x), default=None)
        right = min((k for k in known if k > x), default=None)
        if left is not None and right is not None:
            f = (x - left) / (right - left)
            target = int(round(nodes[left] * (1 - f) + nodes[right] * f))
        elif left is not None:
            target = nodes[left]
        elif right is not None:
            target = nodes[right]
        else:
            continue
        if y0 <= target or y0 - target > 22:
            continue
        for y in range(target, y0):
            pix[x, y] = FUR_DARK if y - target <= 1 else fur_light

    # scrub leftover pink tints in the rebuilt head-top area
    for x in hole_cols:
        for y in range(0, int(0.35 * h)):
            p = pix[x, y]
            if p[3] >= 40 and reddish(p):
                pix[x, y] = fur_light


def _find_eye_boxes(pix, w, h):
    band_top, band_bot = int(0.24 * h), int(0.60 * h)
    seen = set()
    comps = []
    for y in range(band_top, band_bot):
        for x in range(int(0.08 * w), int(0.92 * w)):
            if (x, y) in seen or not is_dark(pix[x, y]):
                continue
            stack, comp = [(x, y)], []
            seen.add((x, y))
            while stack:
                px_, py_ = stack.pop()
                comp.append((px_, py_))
                for nx, ny in ((px_+1, py_), (px_-1, py_), (px_, py_+1), (px_, py_-1)):
                    if (int(0.08 * w) <= nx < int(0.92 * w) and band_top <= ny < band_bot
                            and (nx, ny) not in seen and is_dark(pix[nx, ny])):
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            if len(comp) < 8:
                continue
            xs_ = [p[0] for p in comp]
            ys_ = [p[1] for p in comp]
            if max(xs_) - min(xs_) + 1 > 0.42 * w or max(ys_) - min(ys_) + 1 > 0.34 * h:
                continue
            white_touch = sum(
                1 for (px_, py_) in comp
                for nx, ny in ((px_+1, py_), (px_-1, py_), (px_, py_+1), (px_, py_-1))
                if 0 <= nx < w and 0 <= ny < h and is_white(pix[nx, ny]))
            if white_touch < 3:
                continue
            comps.append((comp, len(comp)))
    comps.sort(key=lambda c: c[1], reverse=True)
    boxes = []
    for comp, _ in comps[:2]:
        xs_ = [p[0] for p in comp]
        ys_ = [p[1] for p in comp]
        boxes.append((min(xs_) - 2, min(ys_) - 2, max(xs_) + 2, max(ys_) + 2))
    return boxes


def main():
    sheet = Image.open(SRC).convert("RGBA")
    out = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
    previews = []
    for anim, rects in FRAMES.items():
        for (x, y, w, h) in rects:
            frame = sheet.crop((x, y, x + w, y + h))
            done = process_frame(frame)
            out.paste(done, (x, y))
            previews.append((sheet.crop((x, y, x + w, y + h)), done))
    out.save(OUT)

    scale = 3
    max_h = max(f.height for f, _ in previews) * scale
    total_w = sum((f.width + 2) for f, _ in previews) * scale
    strip = Image.new("RGBA", (total_w, max_h * 2 + 10), (250, 240, 245, 255))
    ox = 0
    for orig, done in previews:
        strip.paste(orig.resize((orig.width * scale, orig.height * scale), Image.NEAREST), (ox, 0))
        strip.paste(done.resize((done.width * scale, done.height * scale), Image.NEAREST), (ox, max_h + 10))
        ox += (orig.width + 2) * scale
    strip.save(PREVIEW)
    print("done")


main()
