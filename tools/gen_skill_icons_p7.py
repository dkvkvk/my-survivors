
# -*- coding: utf-8 -*-
"""P7 新增神通的占位图标（8 张 64x64）。

风格与 tools/gen_weapon_icons.py 一致：超采样 -> 覆盖率阈值降采样 -> 1px 暗描边。
AI 生图提示词见 XIANXIA_ART_PROMPTS.md 的「八、A 组」，生成后覆盖同名文件即可。
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_weapon_icons import (S, px, canvas, disc, poly, thick_line, finish,
                              dark_rim, shift, UI,
                              CYAN, CYAN_L, CYAN_D, GOLD, GOLD_L, ORANGE, RED,
                              STEEL, STEEL_D, STEEL_L, WHITE)
from PIL import Image, ImageDraw


def _bolt(d, cx, cy, h, col):
    """一道小闪电。"""
    w = h * 0.34
    poly(d, [(cx + w * 0.5, cy - h / 2), (cx - w, cy + h * 0.06), (cx - w * 0.1, cy + h * 0.06),
             (cx - w * 0.6, cy + h / 2), (cx + w, cy - h * 0.12), (cx + w * 0.1, cy - h * 0.12)], col)


def _flame(d, cx, cy, r, col):
    """一簇火苗（三角 + 圆底）。"""
    poly(d, [(cx, cy - r * 1.7), (cx + r * 0.7, cy), (cx - r * 0.7, cy)], col)
    disc(d, cx, cy, r * 0.75, col)


def _sword(d, cx, cy, ln, ang, col, hilt):
    """一把指向 ang 方向的剑（剑身 + 护手）。"""
    ex, ey = cx + math.cos(ang) * ln, cy + math.sin(ang) * ln
    d.line([(px(cx), px(cy)), (px(ex), px(ey))], fill=col, width=int(round(px(ln * 0.16))))
    nx, ny = -math.sin(ang), math.cos(ang)
    hx, hy = cx + math.cos(ang) * ln * 0.22, cy + math.sin(ang) * ln * 0.22
    d.line([(px(hx - nx * 2.6), px(hy - ny * 2.6)), (px(hx + nx * 2.6), px(hy + ny * 2.6))],
           fill=hilt, width=int(round(px(1.8))))


def icon_dash_blade(size=64):
    """御剑疾影：一把剑 + 三道残影。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    for i, a in enumerate((0.30, 0.46, 0.62)):
        col = (198, 253, 246, int(90 - i * 22))
        _sword(d, 12.0 + i * 7.0, 46.0 - i * 7.0, 12.0, -0.8, col, col)
    _sword(d, 30.0, 30.0, 21.0, -0.8, CYAN, GOLD)
    d.line([(px(8), px(52)), (px(26), px(40))], fill=CYAN_D, width=int(round(px(2.2))))
    out, mask = finish(img, size)
    return out


def icon_ring_release(size=64):
    """剑环外放：一圈向外的剑 + 断裂的环。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    cx = cy = 32.0
    d.arc([px(cx - 19), px(cy - 19), px(cx + 19), px(cy + 19)], 20, 160, fill=CYAN_D,
          width=int(round(px(2.4))))
    for i in range(5):
        a = math.radians(-90 + i * 72)
        _sword(d, cx + math.cos(a) * 10.0, cy + math.sin(a) * 10.0, 15.0, a, CYAN, GOLD)
    disc(d, cx, cy, 4.0, WHITE)
    out, mask = finish(img, size)
    return out


def icon_fire_field(size=64):
    """焚地火域：俯视火海（椭圆 + 火苗）。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    d.ellipse([px(8), px(30), px(56), px(54)], fill=ORANGE)
    d.ellipse([px(15), px(35), px(49), px(51)], fill=GOLD)
    d.ellipse([px(23), px(38), px(41), px(48)], fill=GOLD_L)
    for x, h in ((16, 9), (25, 14), (33, 17), (41, 13), (49, 8)):
        _flame(d, x, 32 - h * 0.2, h * 0.45, ORANGE)
        _flame(d, x, 33 - h * 0.3, h * 0.3, GOLD)
    out, mask = finish(img, size)
    return out


def icon_charge_storm(size=64):
    """蓄雷引弧：符箓居中，四道雷向内汇聚。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    poly(d, [(24, 12), (40, 12), (42, 52), (22, 52)], GOLD)
    poly(d, [(27, 16), (37, 16), (39, 48), (25, 48)], GOLD_L)
    _bolt(d, 32.0, 32.0, 22.0, RED)
    for (x0, y0, x1, y1) in ((4, 6, 17, 19), (60, 6, 47, 19), (4, 58, 17, 45), (60, 58, 47, 45)):
        d.line([(px(x0), px(y0)), (px(x1), px(y1))], fill=CYAN, width=int(round(px(2.6))))
        disc(d, x1, y1, 1.8, WHITE)
    out, mask = finish(img, size)
    return out


def icon_pierce_shuttle(size=64):
    """穿云巨梭：一枚大飞梭 + 直线上三个被穿过的影子。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    d.line([(px(4), px(32)), (px(58), px(32))], fill=WHITE, width=int(round(px(2.0))))
    for x in (14, 24, 34):
        poly(d, [(x, 24), (x + 6, 32), (x, 40), (x - 6, 32)], STEEL_D)
    poly(d, [(58, 32), (36, 46), (26, 32), (36, 18)], CYAN)
    poly(d, [(54, 32), (38, 41), (31, 32), (38, 23)], CYAN_L)
    out, mask = finish(img, size)
    dark_rim(out, mask, CYAN_D)
    return out


def icon_detonate_all(size=64):
    """符阵合围：六枚符雷围成圈同时炸开。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    cx = cy = 32.0
    pts = []
    for i in range(6):
        a = math.radians(-90 + i * 60)
        pts.append((cx + 20.0 * math.cos(a), cy + 20.0 * math.sin(a)))
    for i in range(6):
        x0, y0 = pts[i]
        x1, y1 = pts[(i + 1) % 6]
        d.line([(px(x0), px(y0)), (px(x1), px(y1))], fill=CYAN_D, width=int(round(px(2.2))))
    for x, y in pts:
        poly(d, [(x, y - 6), (x + 5.5, y - 2.5), (x + 5.5, y + 3.5), (x, y + 6.5),
                 (x - 5.5, y + 3.5), (x - 5.5, y - 2.5)], STEEL)
        disc(d, x, y, 3.4, GOLD)
        for k in range(4):
            a = math.radians(45 + k * 90)
            d.line([(px(x + math.cos(a) * 4), px(y + math.sin(a) * 4)),
                    (px(x + math.cos(a) * 10), px(y + math.sin(a) * 10))],
                   fill=ORANGE, width=int(round(px(2.0))))
    disc(d, cx, cy, 5.0, GOLD_L)
    out, mask = finish(img, size)
    return out


def icon_inferno_ring(size=64):
    """焚天剑轮：六把带火的剑围成轮。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    cx = cy = 32.0
    d.arc([px(cx - 22), px(cy - 22), px(cx + 22), px(cy + 22)], 0, 360, fill=ORANGE,
          width=int(round(px(3.4))))
    for i in range(6):
        a = math.radians(i * 60)
        _sword(d, cx + math.cos(a) * 8.0, cy + math.sin(a) * 8.0, 16.0, a, CYAN, GOLD)
        _flame(d, cx + math.cos(a) * 21.0, cy + math.sin(a) * 21.0, 4.0, ORANGE)
    disc(d, cx, cy, 6.0, GOLD_L)
    disc(d, cx, cy, 3.5, WHITE)
    out, mask = finish(img, size)
    return out


def icon_storm_volley(size=64):
    """惊雷剑引：左下放射的剑，每把都挨一道雷。"""
    img = canvas(size)
    d = ImageDraw.Draw(img)
    ox, oy = 14.0, 50.0
    for i in range(5):
        a = math.radians(-90 + i * 24)
        _sword(d, ox, oy, 34.0, a, CYAN, GOLD)
    for i in range(5):
        a = math.radians(-90 + i * 24)
        tx, ty = ox + math.cos(a) * 34.0, oy + math.sin(a) * 34.0
        _bolt(d, tx, ty - 6.0, 13.0, WHITE)
    out, mask = finish(img, size)
    return out


JOBS = [
    ("skill_dash_blade.png", icon_dash_blade),
    ("skill_ring_release.png", icon_ring_release),
    ("skill_fire_field.png", icon_fire_field),
    ("skill_charge_storm.png", icon_charge_storm),
    ("skill_pierce_shuttle.png", icon_pierce_shuttle),
    ("skill_detonate_all.png", icon_detonate_all),
    ("skill_inferno_ring.png", icon_inferno_ring),
    ("skill_storm_volley.png", icon_storm_volley),
]

if __name__ == "__main__":
    made = []
    for name, fn in JOBS:
        im = fn(64)
        im.save(os.path.join(UI, name))
        made.append(name)
    print("wrote %d 张神通占位图标" % len(made))
    cell = 160
    sheet = Image.new("RGBA", (cell * 4, cell * 2), (24, 28, 36, 255))
    for i, name in enumerate(made):
        im = Image.open(os.path.join(UI, name)).convert("RGBA").resize((cell, cell), Image.NEAREST)
        sheet.alpha_composite(im, ((i % 4) * cell, (i // 4) * cell))
    shots = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "_shots")
    os.makedirs(shots, exist_ok=True)
    sheet.save(os.path.join(shots, "skill_icons_p7.png"))
    print("contact sheet -> _shots/skill_icons_p7.png")
