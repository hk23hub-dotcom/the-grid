#!/usr/bin/env python3
"""
THE GRID — Preview generator.
For each world in grid.json:
  - if its project folder has real images, use the best one (cover-fit 800x600)
  - otherwise render a branded HK23 placeholder card
Writes previews/<id>.jpg and rewrites grid.json preview paths.

Usage: python3 scripts/make-previews.py "/path/to/Projects"
"""
import os, sys, json, glob
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT_GRID = os.path.join(HERE, "..")
GRID = os.path.join(ROOT_GRID, "grid.json")
PREV = os.path.join(ROOT_GRID, "previews")
PROJECTS = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT_GRID, "..")
W, H = 800, 600

os.makedirs(PREV, exist_ok=True)

def font(sz, bold=True):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def find_dir(name):
    # match a world id back to its folder (case/spacing-insensitive)
    target = name.replace("-", "").replace(" ", "").lower()
    for d in os.listdir(PROJECTS):
        if d.replace("-", "").replace("_", "").replace(" ", "").lower() == target:
            return os.path.join(PROJECTS, d)
    return None

def best_image(folder):
    if not folder:
        return None
    exts = ("*.png", "*.jpg", "*.jpeg", "*.webp")
    found = []
    for e in exts:
        found += glob.glob(os.path.join(folder, "**", e), recursive=True)
    found = [f for f in found if "node_modules" not in f]
    if not found:
        return None
    # prefer the largest file (usually the hero/screenshot)
    found.sort(key=lambda f: os.path.getsize(f), reverse=True)
    return found[0]

def cover_fit(img, w, h):
    src = img.width / img.height
    dst = w / h
    if src > dst:
        nh = h; nw = int(h * src)
    else:
        nw = w; nh = int(w / src)
    img = img.resize((nw, nh), Image.LANCZOS)
    x = (nw - w) // 2; y = (nh - h) // 2
    return img.crop((x, y, x + w, y + h))

def wrap(draw, text, fnt, maxw):
    words, lines, cur = text.split(), [], ""
    for word in words:
        t = (cur + " " + word).strip()
        if draw.textlength(t, font=fnt) <= maxw:
            cur = t
        else:
            if cur: lines.append(cur)
            cur = word
    if cur: lines.append(cur)
    return lines

def from_photo(path):
    base = cover_fit(Image.open(path).convert("RGB"), W, H)
    # darken bottom for legibility
    overlay = Image.new("RGB", (W, H), (0, 0, 0))
    mask = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mask)
    for y in range(H):
        md.line([(0, y), (W, y)], fill=int(150 * (y / H) ** 2))
    return Image.composite(overlay, base, mask)

def card(name, accent=(212, 175, 55)):
    # dark gradient bg
    img = Image.new("RGB", (W, H), (10, 10, 12))
    d = ImageDraw.Draw(img)
    for y in range(H):
        v = int(8 + 18 * (y / H))
        d.line([(0, y), (W, y)], fill=(v, v, v + 3))
    # subtle accent glow top-left
    glow = Image.new("RGB", (W, H), (10, 10, 12))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-200, -240, 360, 240], fill=(accent[0]//4, accent[1]//4, accent[2]//5))
    img = Image.blend(img, glow.filter(ImageFilter.GaussianBlur(120)), 0.6)
    d = ImageDraw.Draw(img)
    # accent bar
    d.rectangle([60, 250, 120, 258], fill=accent)
    # name (wrapped)
    fnt = font(58)
    lines = wrap(d, name, fnt, W - 140)
    if len(lines) > 2:
        fnt = font(44); lines = wrap(d, name, fnt, W - 140)
    y = 278
    for ln in lines:
        d.text((60, y), ln, font=fnt, fill=(245, 245, 245))
        y += fnt.size + 8
    # footer
    ff = font(20, bold=False)
    d.text((60, H - 60), "NOT GIVEN.  TAKEN.", font=ff, fill=accent)
    d.text((W - 150, H - 60), "HK23 · GRID", font=ff, fill=(120, 120, 120))
    return img

def main():
    grid = json.load(open(GRID))
    for w in grid["worlds"]:
        folder = find_dir(w["id"]) or find_dir(w["name"])
        photo = best_image(folder)
        out = os.path.join(PREV, w["id"] + ".jpg")
        if photo:
            from_photo(photo).save(out, "JPEG", quality=86)
            src = "photo:" + os.path.basename(photo)
        else:
            card(w["name"]).save(out, "JPEG", quality=90)
            src = "card"
        w["preview"] = "./previews/" + w["id"] + ".jpg"
        print(f"  {w['id']:<26} <- {src}")
    json.dump(grid, open(GRID, "w"), indent=2, ensure_ascii=False)
    open(GRID, "a").write("\n")
    print(f"Done. {len(grid['worlds'])} previews -> previews/")

main()
