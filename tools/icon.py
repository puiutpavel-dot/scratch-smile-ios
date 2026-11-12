import math, random
from PIL import Image, ImageDraw, ImageFilter
S = 2048
random.seed(7)

def vgrad(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img

# --- fundal: noapte violet + lumină în centru + raze
bg = vgrad((S, S), (74, 26, 130), (22, 10, 56)).convert("RGBA")
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
g = ImageDraw.Draw(glow)
g.ellipse([S*0.12, S*0.10, S*0.88, S*0.86], fill=(255, 90, 170, 120))
glow = glow.filter(ImageFilter.GaussianBlur(S * 0.11))
bg.alpha_composite(glow)
rays = Image.new("RGBA", (S, S), (0, 0, 0, 0))
r = ImageDraw.Draw(rays)
cx = cy = S / 2
n = 18
for i in range(n):
    a0 = i * 2 * math.pi / n
    a1 = a0 + math.pi / n
    R = S * 0.9
    r.polygon([(cx, cy), (cx + math.cos(a0) * R, cy + math.sin(a0) * R),
               (cx + math.cos(a1) * R, cy + math.sin(a1) * R)], fill=(255, 255, 255, 26))
bg.alpha_composite(rays)

# --- lozul, desenat drept pe un strat separat, apoi rotit
TW, TH = 1380, 960
pad = 200
layer = Image.new("RGBA", (TW + pad * 2, TH + pad * 2), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)
x0, y0 = pad, pad
gold = vgrad((TW, TH), (255, 236, 150), (226, 160, 40)).convert("RGBA")
mask = Image.new("L", (TW, TH), 0)
m = ImageDraw.Draw(mask)
m.rounded_rectangle([0, 0, TW - 1, TH - 1], radius=110, fill=255)
notch = 78
ny = int(TH * 0.30)
for nx in (0, TW):
    m.ellipse([nx - notch, ny - notch, nx + notch, ny + notch], fill=0)
layer.paste(gold, (x0, y0), mask)
# contur auriu închis
edge = mask.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.MaxFilter(13))
layer.paste(Image.new("RGBA", (TW, TH), (150, 100, 14, 255)), (x0, y0), edge)
# linia punctată de rupere
for xx in range(x0 + 120, x0 + TW - 120, 64):
    d.rounded_rectangle([xx, y0 + ny - 7, xx + 36, y0 + ny + 7], radius=7, fill=(150, 100, 14, 200))
# antet: trei stele
def star(draw, c, R, r, fill, points=5, rot=-math.pi / 2):
    pts = []
    for i in range(points * 2):
        a = rot + i * math.pi / points
        rad = R if i % 2 == 0 else r
        pts.append((c[0] + rad * math.cos(a), c[1] + rad * math.sin(a)))
    draw.polygon(pts, fill=fill)
for i, sx in enumerate((-260, 0, 260)):
    star(d, (x0 + TW / 2 + sx, y0 + ny / 2 + 6), 92 if i == 1 else 70, 40 if i == 1 else 30, (255, 255, 255, 235))
# zona de joc
px0, py0, px1, py1 = x0 + 110, y0 + ny + 70, x0 + TW - 110, y0 + TH - 90
d.rounded_rectangle([px0 - 14, py0 - 14, px1 + 14, py1 + 14], radius=74, fill=(150, 100, 14, 255))
d.rounded_rectangle([px0, py0, px1, py1], radius=60, fill=(255, 248, 226, 255))
# zâmbetul descoperit
fc = (px0 + (px1 - px0) * 0.30, (py0 + py1) / 2)
fr = (py1 - py0) * 0.40
d.ellipse([fc[0] - fr, fc[1] - fr, fc[0] + fr, fc[1] + fr], fill=(255, 205, 40, 255), outline=(190, 120, 10, 255), width=14)
for ex in (-0.36, 0.36):
    d.ellipse([fc[0] + ex * fr - 26, fc[1] - fr * 0.30 - 40, fc[0] + ex * fr + 26, fc[1] - fr * 0.30 + 40], fill=(70, 40, 10, 255))
d.arc([fc[0] - fr * 0.58, fc[1] - fr * 0.55, fc[0] + fr * 0.58, fc[1] + fr * 0.62], start=20, end=160, fill=(70, 40, 10, 255), width=30)
# folia argintie, cu margine zimțată spre zâmbet
fx = px0 + (px1 - px0) * 0.52
foil = Image.new("RGBA", layer.size, (0, 0, 0, 0))
f = ImageDraw.Draw(foil)
pts = [(px1, py0), (fx + 40, py0)]
steps = 9
for i in range(steps + 1):
    yy = py0 + (py1 - py0) * i / steps
    pts.append((fx + (random.uniform(-70, 10) if i % 2 == 0 else random.uniform(30, 110)), yy))
pts += [(px1, py1)]
f.polygon(pts, fill=(255, 255, 255, 255))
silver = vgrad(layer.size, (232, 236, 240), (150, 158, 168)).convert("RGBA")
play_mask = Image.new("L", layer.size, 0)
ImageDraw.Draw(play_mask).rounded_rectangle([px0, py0, px1, py1], radius=60, fill=255)
from PIL import ImageChops
fmask = ImageChops.multiply(foil.split()[3], play_mask)
layer.paste(silver, (0, 0), fmask)
# dungi pe folie
stripes = Image.new("RGBA", layer.size, (0, 0, 0, 0))
sd = ImageDraw.Draw(stripes)
for k in range(-TH, TW * 2, 70):
    sd.line([(px0 + k, py1), (px0 + k + (py1 - py0), py0)], fill=(255, 255, 255, 90), width=16)
layer.paste(stripes, (0, 0), ImageChops.multiply(stripes.split()[3], fmask))
# firimituri de folie
for _ in range(26):
    cxx = fx + random.uniform(-150, 20); cyy = random.uniform(py0 + 30, py1 - 30); rr = random.uniform(6, 16)
    d.ellipse([cxx - rr, cyy - rr, cxx + rr, cyy + rr], fill=(178, 186, 196, 255))

rot = layer.rotate(11, resample=Image.BICUBIC, expand=True)
shadow = Image.new("RGBA", rot.size, (0, 0, 0, 0))
shadow.paste(Image.new("RGBA", rot.size, (10, 0, 30, 170)), (0, 0), rot.split()[3])
shadow = shadow.filter(ImageFilter.GaussianBlur(40))
ox, oy = (S - rot.size[0]) // 2, (S - rot.size[1]) // 2 - 10
bg.alpha_composite(shadow, (ox + 10, oy + 50))
bg.alpha_composite(rot, (ox, oy))

# --- moneda care răzuiește, în colțul din dreapta-jos
d2 = ImageDraw.Draw(bg)
cc = (S * 0.775, S * 0.745); cr = 250
coin_shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(coin_shadow).ellipse([cc[0] - cr + 14, cc[1] - cr + 40, cc[0] + cr + 14, cc[1] + cr + 40], fill=(10, 0, 30, 160))
bg.alpha_composite(coin_shadow.filter(ImageFilter.GaussianBlur(30)))
d2.ellipse([cc[0] - cr, cc[1] - cr, cc[0] + cr, cc[1] + cr], fill=(170, 110, 10, 255))
d2.ellipse([cc[0] - cr + 16, cc[1] - cr + 16, cc[0] + cr - 16, cc[1] + cr - 16], fill=(255, 205, 60, 255))
d2.ellipse([cc[0] - cr + 56, cc[1] - cr + 56, cc[0] + cr - 56, cc[1] + cr - 56], outline=(200, 135, 20, 255), width=14)
star(d2, cc, 130, 56, (255, 248, 200, 255))
d2.arc([cc[0] - cr + 34, cc[1] - cr + 34, cc[0] + cr - 34, cc[1] + cr - 34], start=200, end=260, fill=(255, 250, 215, 255), width=22)

# --- scântei
def sparkle(c, R):
    star(d2, c, R, R * 0.18, (255, 255, 255, 255), points=4, rot=0)
for c, R in [((S * 0.17, S * 0.20), 90), ((S * 0.86, S * 0.17), 64), ((S * 0.13, S * 0.80), 56), ((S * 0.60, S * 0.93), 40), ((S * 0.93, S * 0.45), 36)]:
    sparkle(c, R)

out = bg.convert("RGB").resize((1024, 1024), Image.LANCZOS)
out.save("icon.png")
out.resize((360, 360), Image.LANCZOS).save("icon_preview.png")
print(out.size, out.mode)
