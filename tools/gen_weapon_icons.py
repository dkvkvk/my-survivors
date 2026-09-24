
# -*- coding: utf-8 -*-
"""P6 新增法宝的图标生成（回风梭 / 地火符阵）。

项目里"图标缺失时用代码画"的先例（weapon_drop 的菱形占位、电弧/刀光纯代码绘制）延续到这里：
超采样 + 覆盖率阈值降采样 + 1px 暗描边，产出与既有 AI 图标同规格的像素图。

    python tools/gen_weapon_icons.py

产出：assets/ui/icon_fa_boomerang.png (32x32)、assets/ui/icon_fa_mine.png (32x32)、
      assets/ui/skill_boomerang.png (64x64)、assets/ui/skill_mine.png (64x64)
想换成 AI 生图：见 XIANXIA_ART_PROMPTS.md 的"P6 补充图标"提示词，覆盖同名文件即可。
"""
import math
import os

from PIL import Image, ImageDraw

S = 8  # 超采样倍数
OUTLINE = (20, 26, 36, 255)
CYAN_L = (198, 253, 246, 255)
CYAN = (111, 227, 216, 255)
CYAN_D = (46, 158, 156, 255)
GOLD_L = (255, 236, 186, 255)
GOLD = (255, 196, 92, 255)
ORANGE = (255, 122, 47, 255)
RED = (206, 62, 52, 255)
STEEL_L = (128, 146, 166, 255)
STEEL = (78, 92, 110, 255)
STEEL_D = (38, 46, 58, 255)
WHITE = (242, 253, 255, 255)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, "assets", "ui")


def canvas(size):
    return Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))


def px(v):
    return v * S


def thick_line(d, pts, width, color):
    d.line([(px(x), px(y)) for x, y in pts], fill=color, width=int(round(px(width))), joint="curve")
    r = px(width) / 2.0
    for x, y in (pts[0], pts[-1]):
        d.ellipse([px(x) - r, px(y) - r, px(x) + r, px(y) + r], fill=color)


def disc(d, cx, cy, r, color):
    d.ellipse([px(cx - r), px(cy - r), px(cx + r), px(cy + r)], fill=color)


def poly(d, pts, color):
    d.polygon([(px(x), px(y)) for x, y in pts], fill=color)


def bezier(p0, p1, p2, n=10):
    out = []
    for i in range(n + 1):
        t = i / float(n)
        u = 1.0 - t
        out.append((u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0],
                    u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]))
    return out


def shift(mask, dx, dy):
    out = Image.new("L", mask.size, 0)
    out.paste(mask, (dx, dy))
    return out


def finish(img, size):
    """超采样 -> 覆盖率阈值降采样 -> 1px 暗描边。颜色取最近邻，保持纯色不糊边。"""
    cover = img.split()[3].resize((size, size), Image.BOX)
    mask = cover.point(lambda v: 255 if v >= 128 else 0)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    body = img.resize((size, size), Image.NEAREST)
    body.putalpha(mask)
    out.alpha_composite(body)

    dil = mask.copy()
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
        dil = Image.composite(Image.new("L", mask.size, 255), dil, shift(mask, dx, dy))
    ring = Image.composite(Image.new("L", mask.size, 255), Image.new("L", mask.size, 0), dil)
    ring = Image.composite(Image.new("L", mask.size, 0), ring, mask)
    out.paste(OUTLINE, (0, 0), ring)
    return out, mask


def dark_rim(out, mask, color):
    br = Image.composite(Image.new("L", mask.size, 0), mask, shift(mask, -1, -1))
    out.paste(color, (0, 0), br)


# ---------------------------------------------------------------- 法宝图标 32x32

# 回风梭的局部中轴（以肘部为原点）：两头尖、肘部厚，靠锥形带出"飞梭"轮廓
BOOM_PATH_LOCAL = (bezier((-12.5, -8.5), (-5.5, 4.0), (0.0, 8.0), 16)
                   + bezier((0.0, 8.0), (5.5, 4.0), (12.5, -9.5), 16)[1:])


def _half_width(t):
    return 0.45 + 3.05 * (1.0 - abs(2.0 * t - 1.0) ** 1.5)


def tapered_ribbon(d, path, w_at, color):
    """沿中轴生成"中间厚两头尖"的多边形（回风梭的形体）。"""
    n = len(path)
    up, dn = [], []
    for i, (x, y) in enumerate(path):
        if i == 0:
            tx, ty = path[1][0] - x, path[1][1] - y
        elif i == n - 1:
            tx, ty = x - path[i - 1][0], y - path[i - 1][1]
        else:
            tx, ty = path[i + 1][0] - path[i - 1][0], path[i + 1][1] - path[i - 1][1]
        ln = math.hypot(tx, ty) or 1.0
        nx, ny = -ty / ln, tx / ln
        w = w_at(i / float(n - 1))
        up.append((x + nx * w, y + ny * w))
        dn.append((x - nx * w, y - ny * w))
    poly(d, up + dn[::-1], color)


def boomerang_shape(d, cx, cy, scale, color):
    path = [(cx + x * scale, cy + y * scale) for x, y in BOOM_PATH_LOCAL]
    tapered_ribbon(d, path, lambda t: _half_width(t) * scale, color)
    return path


def icon_boomerang(size=32):
    """回风梭：两头尖的弯梭，左下两道回转气流。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    d.line([(px(5.0), px(25.5)), (px(12.0), px(25.5))], fill=CYAN_D, width=int(round(px(1.8))))
    d.line([(px(8.5), px(28.6)), (px(15.0), px(28.6))], fill=CYAN_D, width=int(round(px(1.8))))
    path = boomerang_shape(d, 16.0, 15.0, 1.0, CYAN)
    out, mask = finish(img, size)
    dark_rim(out, mask, CYAN_D)
    d2 = ImageDraw.Draw(out)
    # 上缘反光：沿中轴往上挪 1.8px 画一条 1px 亮线
    d2.line([(px(x), px(y - 1.8)) for x, y in path], fill=CYAN_L, width=1)
    return out


def icon_mine(size=32):
    """地火符阵：铁符匣（六角俯视）+ 符面雷纹。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    hex_pts = [(16, 3.5), (28, 10.5), (28, 22.5), (16, 29.5), (4, 22.5), (4, 10.5)]
    poly(d, hex_pts, STEEL)
    inner = [(16, 7.0), (24.5, 12.0), (24.5, 21.0), (16, 26.0), (7.5, 21.0), (7.5, 12.0)]
    poly(d, inner, STEEL_D)
    # 符面：亮符纸 + 深色雷纹（高对比，32px 下才读得出是"符"）
    disc(d, 16.0, 16.5, 8.6, GOLD)
    disc(d, 16.0, 16.5, 7.2, GOLD_L)
    poly(d, [(18.6, 8.6), (11.6, 17.4), (15.6, 17.4), (13.4, 24.4),
             (20.8, 15.4), (16.6, 15.4)], RED)
    out, mask = finish(img, size)
    dark_rim(out, mask, (22, 28, 40, 255))
    d2 = ImageDraw.Draw(out)
    for x, y in ((6.5, 8.5), (25.5, 11.0), (24.0, 24.5)):
        d2.point((px(x), px(y)), fill=GOLD_L)
    return out


# ---------------------------------------------------------------- 技能图标 64x64

def skill_boomerang(size=64):
    """风卷残云：一枚大飞梭居中，两侧拖出回转风迹。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    # 回转风迹：左右各三道，画在飞梭之外，不与本体粘连
    for i, (x0, x1, y) in enumerate(((5.0, 12.0, 26.0), (2.5, 9.0, 32.0), (6.0, 12.5, 38.0))):
        d.line([(px(x0), px(y)), (px(x1), px(y))], fill=CYAN, width=int(round(px(2.4))))
    for i, (x0, x1, y) in enumerate(((52.0, 59.0, 24.0), (55.0, 61.5, 30.0), (51.5, 58.0, 36.0))):
        d.line([(px(x0), px(y)), (px(x1), px(y))], fill=CYAN, width=int(round(px(2.4))))
    path = boomerang_shape(d, 32.0, 30.0, 1.5, CYAN)
    out, mask = finish(img, size)
    dark_rim(out, mask, CYAN_D)
    d2 = ImageDraw.Draw(out)
    d2.line([(px(x), px(y - 2.6)) for x, y in path], fill=CYAN_L, width=1)
    return out


def skill_mine(size=64):
    """十方雷网：六枚符雷围成一圈，符间连雷，中心雷核。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    cx = cy = 32.0
    pts = []
    for i in range(6):
        a = math.radians(-90 + i * 60)
        pts.append((cx + 23.0 * math.cos(a), cy + 23.0 * math.sin(a)))
    # 符间连雷：折线（先画，符压在上面）
    for i in range(6):
        x0, y0 = pts[i]
        x1, y1 = pts[(i + 1) % 6]
        mx, my = (x0 + x1) / 2.0, (y0 + y1) / 2.0
        nx, ny = -(y1 - y0), (x1 - x0)
        nl = math.hypot(nx, ny) or 1.0
        ox, oy = mx + nx / nl * 7.0, my + ny / nl * 7.0
        d.line([(px(x0), px(y0)), (px(ox), px(oy)), (px(x1), px(y1))], fill=CYAN_D, width=int(round(px(4.0))))
        d.line([(px(x0), px(y0)), (px(ox), px(oy)), (px(x1), px(y1))], fill=CYAN_L, width=int(round(px(1.8))))
    # 符雷：小六角铁匣 + 亮符面
    for x, y in pts:
        poly(d, [(x, y - 7.5), (x + 7.0, y - 3.5), (x + 7.0, y + 3.5),
                 (x, y + 7.5), (x - 7.0, y + 3.5), (x - 7.0, y - 3.5)], STEEL)
        disc(d, x, y, 4.6, GOLD)
        disc(d, x, y, 3.4, GOLD_L)
        poly(d, [(x + 1.4, y - 4.0), (x - 3.0, y + 0.4), (x - 0.4, y + 0.4),
                 (x - 1.6, y + 4.2), (x + 2.6, y - 0.2), (x + 0.2, y - 0.2)], RED)
    # 中心雷核
    disc(d, cx, cy, 9.5, STEEL)
    disc(d, cx, cy, 7.5, GOLD)
    poly(d, [(cx + 2.6, cy - 8.6), (cx - 5.0, cy - 0.4), (cx - 0.8, cy - 0.4),
             (cx - 3.2, cy + 8.4), (cx + 5.6, cy - 1.0), (cx + 1.0, cy - 1.0)], RED)
    out, mask = finish(img, size)
    dark_rim(out, mask, (22, 28, 40, 255))
    return out


def main():
    jobs = [
        ("icon_fa_boomerang.png", icon_boomerang(32)),
        ("icon_fa_mine.png", icon_mine(32)),
        ("skill_boomerang.png", skill_boomerang(64)),
        ("skill_mine.png", skill_mine(64)),
    ]
    for name, im in jobs:
        path = os.path.join(UI, name)
        im.save(path)
        print("wrote %s %s" % (path, im.size))

    ref = ["icon_fa_sword.png", "icon_fa_ring.png", "icon_fa_fire.png", "icon_fa_talisman.png",
           "icon_fa_boomerang.png", "icon_fa_mine.png"]
    sk = ["skill_shuriken.png", "skill_orbit_blade.png", "skill_aura.png", "skill_chain_lightning.png",
          "skill_boomerang.png", "skill_mine.png"]
    cell = 192
    sheet = Image.new("RGBA", (cell * 6, cell * 2), (24, 28, 36, 255))
    for row, names in enumerate((ref, sk)):
        for i, n in enumerate(names):
            im = Image.open(os.path.join(UI, n)).convert("RGBA").resize((cell, cell), Image.NEAREST)
            sheet.alpha_composite(im, (i * cell, row * cell))
    sheet.save(os.path.join(ROOT, "_shots", "icon_style_ref.png"))
    print("contact sheet -> _shots/icon_style_ref.png")


if __name__ == "__main__":
    main()
