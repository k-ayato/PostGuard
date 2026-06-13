"""PostGuard アプリアイコン レンダラ（Pillow / numpy不要）
AppIcon.svg と同じデザインを 1024x1024 の不透明PNGに描画する。"""
from PIL import Image, ImageDraw
import math

S = 2048            # スーパーサンプリング用キャンバス
F = S / 1024.0      # 1024座標 -> S 座標の倍率


def sc(v):
    return v * F


def lerp(a, b, t):
    return a + (b - a) * t


def vgrad_column(h, top, bottom):
    img = Image.new("RGB", (1, max(1, h)))
    px = img.load()
    for y in range(img.height):
        t = y / max(1, img.height - 1)
        px[0, y] = (int(lerp(top[0], bottom[0], t)),
                    int(lerp(top[1], bottom[1], t)),
                    int(lerp(top[2], bottom[2], t)))
    return img


def radial_glow(size, cx, cy, r, color, max_alpha, res=256):
    small = Image.new("L", (res, res), 0)
    px = small.load()
    step = size / res
    for j in range(res):
        for i in range(res):
            x = (i + 0.5) * step
            y = (j + 0.5) * step
            d = math.hypot(x - cx, y - cy) / r
            a = 0 if d >= 1 else max_alpha * (1 - d) ** 2
            px[i, j] = int(a * 255)
    layer = Image.new("RGBA", (size, size), color + (0,))
    layer.putalpha(small.resize((size, size)))
    return layer


def cubic(p0, c1, c2, p3, n=72):
    pts = []
    for k in range(n + 1):
        t = k / n
        m = 1 - t
        x = m**3*p0[0] + 3*m**2*t*c1[0] + 3*m*t**2*c2[0] + t**3*p3[0]
        y = m**3*p0[1] + 3*m**2*t*c1[1] + 3*m*t**2*c2[1] + t**3*p3[1]
        pts.append((x, y))
    return pts


# 盾の輪郭（1024座標）
segs = [
    ((512, 296), (612, 350), (690, 360), (760, 360)),
    ((760, 360), (760, 540), (740, 660), (512, 772)),
    ((512, 772), (284, 660), (264, 540), (264, 360)),
    ((264, 360), (334, 360), (412, 350), (512, 296)),
]
shield_pts = []
for seg in segs:
    shield_pts.extend(cubic(*seg)[:-1])
shield_pts = [(sc(x), sc(y)) for (x, y) in shield_pts]

# 背景グラデーション
base = vgrad_column(S, (0x16, 0x16, 0x1F), (0x09, 0x09, 0x0E)).resize((S, S)).convert("RGBA")

# パープルグロー
base = Image.alpha_composite(base, radial_glow(S, sc(512), sc(470), sc(400), (0x6C, 0x63, 0xFF), 0.55))

# 盾マスク
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).polygon(shield_pts, fill=255)

# 盾グラデーション
top_y, bot_y = int(sc(296)), int(sc(772))
sg_col = vgrad_column(bot_y - top_y, (0x91, 0x89, 0xFF), (0x5A, 0x50, 0xE2)).resize((S, bot_y - top_y))
sg_full = Image.new("RGB", (S, S), (0x5A, 0x50, 0xE2))
sg_full.paste(sg_col, (0, top_y))
base.paste(sg_full, (0, 0), mask)

# 上部ハイライト
y0, y1 = int(sc(300)), int(sc(540))
hcol = vgrad_column(y1 - y0, (1, 1, 1), (0, 0, 0))  # placeholder, rebuild as alpha below
hi_col = Image.new("L", (1, y1 - y0))
hp = hi_col.load()
for y in range(hi_col.height):
    t = y / max(1, hi_col.height - 1)
    hp[0, y] = int(0.28 * 255 * (1 - t))
hcol_full = Image.new("L", (S, S), 0)
hcol_full.paste(hi_col.resize((S, y1 - y0)), (0, y0))
hi_alpha = Image.composite(hcol_full, Image.new("L", (S, S), 0), mask)
white = Image.new("RGBA", (S, S), (255, 255, 255, 255))
white.putalpha(hi_alpha)
base = Image.alpha_composite(base, white)

# 盾の縁取り
border = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(border).line(shield_pts + [shield_pts[0]], fill=(0xB5, 0xAE, 0xFF, 140),
                            width=int(sc(4)), joint="curve")
base = Image.alpha_composite(base, border)

draw = ImageDraw.Draw(base)

# 吹き出し（白）
draw.rounded_rectangle([sc(384), sc(402), sc(640), sc(574)], radius=sc(44), fill=(255, 255, 255, 255))
draw.polygon([(sc(452), sc(560)), (sc(452), sc(632)), (sc(520), sc(566))], fill=(255, 255, 255, 255))

# チェック（パープル、丸キャップ）
chk = [(sc(454), sc(492)), (sc(498), sc(536)), (sc(582), sc(446))]
draw.line(chk, fill=(0x6C, 0x63, 0xFF, 255), width=int(sc(30)), joint="curve")
rr = sc(15)
for (x, y) in chk:
    draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(0x6C, 0x63, 0xFF, 255))

# 書き出し（不透明RGB / sRGB）
final = base.convert("RGB").resize((1024, 1024), Image.LANCZOS)
final.save("AppIcon-1024.png")
print("saved", final.size, final.mode)
