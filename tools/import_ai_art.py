# -*- coding: utf-8 -*-
"""AI 生图入库管线：洋红抠底 -> bbox 裁剪 -> 等比缩放 -> 统一量化 -> 画布对齐 -> 写入 assets/。

为什么不用通用工具整图缩放：整图缩放会让每张图的画布变成生图模型的 16:9，
游戏里精灵是按画布尺寸定位/对脚的，画布不对齐会出现"怪飘在空中/大小乱跳"。

用法：
  python tools/import_ai_art.py            # 全部
  python tools/import_ai_art.py 图标        # 只做某一组
规格表就在文件末尾，改素材只改那张表。
"""
import os
import sys
import numpy as np
from PIL import Image

SRC = "E:/games/"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def keyout(im):
    """洋红抠底（容忍 JPEG 压缩造成的洋红偏移）。"""
    a = np.asarray(im.convert("RGB")).astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mn = np.minimum(r, b)
    mag = (r > 105) & (b > 85) & (g < mn - 25)
    rgba = np.dstack([a.astype(np.uint8), np.where(mag, 0, 255).astype(np.uint8)])
    return Image.fromarray(rgba, "RGBA")


def erode(m, r=1):
    p = np.pad(m, r, constant_values=False)
    out = p[r:-r, r:-r].copy()
    for dy in (-r, r):
        out &= p[r + dy:p.shape[0] - r + dy, r:-r]
    for dx in (-r, r):
        out &= p[r:-r, r + dx:p.shape[1] - r + dx]
    return out


def trim_halo(img, r=1):
    """内容掩码内收 r 像素，切掉抠底残留的洋红边。"""
    a = np.asarray(img).copy()
    m = erode(a[..., 3] > 0, r)
    a[..., 3] = np.where(m, 255, 0)
    return Image.fromarray(a, "RGBA")


def bbox(img):
    m = np.asarray(img)[..., 3] > 0
    ys, xs = np.nonzero(m)
    if len(xs) == 0:
        return None
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def fit_box(img, box):
    w, h = img.size
    s = min(box[0] / w, box[1] / h)
    rs = Image.BOX if s < 0.35 else Image.LANCZOS
    return img.resize((max(1, int(round(w * s))), max(1, int(round(h * s)))), rs)


def on_canvas(img, size, anchor="bottom"):
    c = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - img.width) // 2
    y = size[1] - img.height if anchor == "bottom" else (size[1] - img.height) // 2
    c.paste(img, (x, max(0, y)), img)
    return c


def quantize_group(imgs, colors):
    """同一组（如两帧）拼一起统一量化，避免调色板漂移造成闪色。"""
    if not colors:
        return imgs
    W = sum(i.width for i in imgs)
    H = max(i.height for i in imgs)
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = 0
    for i in imgs:
        sheet.paste(i, (x, H - i.height), i)
        x += i.width
    alpha = sheet.getchannel("A")
    rgb = sheet.convert("RGB").quantize(colors=colors, method=Image.MEDIANCUT).convert("RGB")
    q = rgb.convert("RGBA")
    q.putalpha(alpha)
    out, x = [], 0
    for i in imgs:
        out.append(q.crop((x, 0, x + i.width, H)))
        x += i.width
    return out


def prep(path, anchor, box, halo=1):
    im = Image.open(path)
    im = keyout(im)
    im = trim_halo(im, halo)
    b = bbox(im)
    if b is None:
        raise RuntimeError("整张被抠空: " + path)
    im = im.crop(b)
    im = fit_box(im, box)
    return im


def save(img, rel):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    img.save(p)
    print("  -> %-44s %s" % (rel, str(img.size)))


# ---------------- 规格表 ----------------
# 图标：等比装进 box，居中放在目标画布上
ICONS = [
    ("icon_coin.jpg", "assets/ui/icon_coin.png", (10, 11), 20),
    ("icon_chest.jpg", "assets/ui/icon_chest.png", (12, 10), 20),
    ("icon_gem.jpg", "assets/ui/icon_gem.png", (9, 12), 20),
    ("icon_weapon_drop.jpg", "assets/ui/icon_weapon_drop.png", (32, 32), 24),
    ("card_speed.jpg", "assets/ui/card_speed.png", (22, 22), 20),
    ("card_fire_rate.jpg", "assets/ui/card_fire_rate.png", (22, 22), 20),
    ("card_max_health.jpg", "assets/ui/card_max_health.png", (22, 22), 20),
    ("card_magnet.jpg", "assets/ui/card_magnet.png", (22, 22), 20),
    ("skill_shuriken.jpg", "assets/ui/skill_shuriken.png", (64, 64), 24),
    ("skill_orbit_blade.jpg", "assets/ui/skill_orbit_blade.png", (64, 64), 24),
    ("skill_aura.jpg", "assets/ui/skill_aura.png", (64, 64), 24),
    ("skill_chain_lightning.jpg", "assets/ui/skill_chain_lightning.png", (64, 64), 24),
    ("icon_material_scrap.jpg", "assets/ui/icon_material_scrap.png", (32, 32), 20),
    ("icon_material_crystal.jpg", "assets/ui/icon_material_crystal.png", (32, 32), 20),
    ("icon_skill_book.jpg", "assets/ui/icon_skill_book.png", (32, 32), 20),
    ("icon_fa_sword.jpg", "assets/ui/icon_fa_sword.png", (32, 32), 20),
    ("icon_fa_ring.jpg", "assets/ui/icon_fa_ring.png", (32, 32), 20),
    ("icon_fa_fire.jpg", "assets/ui/icon_fa_fire.png", (32, 32), 20),
    ("icon_fa_talisman.jpg", "assets/ui/icon_fa_talisman.png", (32, 32), 20),
]

# 弹体：横向长条，按宽度装进 16x16（剑尖朝右，代码按朝向旋转）
BULLET = ("icon_shuriken.jpg", "assets/ui/icon_shuriken.png", (16, 16))

# 卡片特例：剑气卡的刀身底部被模型切掉，先裁上半段
CARD_DAMAGE = ("card_damage.jpg", "assets/ui/card_damage.png", (22, 22))

# 怪物：两帧共用一个 box，脚底对齐
MOBS = [
    ("mech_slime", (56, 18), 24),
    ("mech_bat", (56, 24), 24),
    ("mech_knight", (30, 24), 24),
    ("mech_beast", (52, 24), 24),
    ("boss", (56, 34), 24),
]

# 背景：裁成 16:9 再缩到 1920x1080（不量化）
BGS = ["menu_bg", "gameover_bg", "victory_bg", "cover"]


def do_icons():
    print("[图标]")
    for src, rel, box, colors in ICONS:
        im = prep(SRC + src, "center", box)
        c = on_canvas(im, box, "center")
        save(quantize_group([c], colors)[0], rel)


def do_bullet():
    print("[弹体]")
    src, rel, box = BULLET
    im = prep(SRC + src, "center", box)
    c = on_canvas(im, box, "center")
    save(quantize_group([c], 20)[0], rel)


def do_card_damage():
    print("[剑气卡]")
    src, rel, box = CARD_DAMAGE
    im = Image.open(SRC + src)
    w, h = im.size
    im = im.crop((0, 0, w, int(h * 0.72)))      # 底部被切，取上半段
    im = keyout(im)
    im = trim_halo(im, 1)
    im = im.crop(bbox(im))
    im = fit_box(im, box)
    c = on_canvas(im, box, "center")
    save(quantize_group([c], 20)[0], rel)


def do_mobs():
    print("[怪物两帧]")
    for name, box, colors in MOBS:
        frames = []
        for i in (0, 1):
            frames.append(prep(SRC + "%s_%d.jpg" % (name, i), "bottom", box))
        canv = [on_canvas(f, box, "bottom") for f in frames]
        q = quantize_group(canv, colors)
        for i in (0, 1):
            save(q[i], "assets/mobs/%s_%d.png" % (name, i))


def do_bgs():
    print("[背景]")
    for name in BGS:
        im = Image.open(SRC + name + ".jpg").convert("RGB")
        w, h = im.size
        tw = int(round(h * 16.0 / 9.0))
        if tw <= w:
            x = (w - tw) // 2
            im = im.crop((x, 0, x + tw, h))
        else:
            th = int(round(w * 9.0 / 16.0))
            y = (h - th) // 2
            im = im.crop((0, y, w, y + th))
        im = im.resize((1920, 1080), Image.LANCZOS)
        p = os.path.join(ROOT, "assets/ui/%s.png" % name)
        im.save(p)
        print("  -> assets/ui/%s.png  (1920, 1080)" % name)


def do_tileset():
    print("[瓦片集]")
    im = Image.open(SRC + "tileset.jpg")
    w, h = im.size
    n = 6
    cw = w // n
    tiles = []
    for i in range(n):
        cell = im.crop((i * cw, 0, (i + 1) * cw, h))
        cell = trim_halo(keyout(cell), 1)
        tiles.append(cell.crop(bbox(cell)))
    mx = max(max(t.size) for t in tiles)
    s = 64.0 / mx
    print("  最大瓦片 %dpx -> 统一缩放 %.4f" % (mx, s))
    out = Image.new("RGBA", (64 * n, 64), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        tw, th = max(1, int(round(t.width * s))), max(1, int(round(t.height * s)))
        t = t.resize((tw, th), Image.BOX if s < 0.35 else Image.LANCZOS)
        c = on_canvas(t, (64, 64), "bottom")
        out.paste(c, (i * 64, 0), c)
        print("  格%d %s" % (i, str(c.size)))
    q = quantize_group([out], 24)[0]
    p = os.path.join(ROOT, "assets/tiles/tileset.png")
    q.save(p)
    print("  -> assets/tiles/tileset.png (384, 64)")


def do_floor():
    print("[地面]")
    im = Image.open(SRC + "tech_floor.jpg").convert("RGB")
    w, h = im.size
    side = min(w, h)
    x = (w - side) // 2
    y = (h - side) // 2
    im = im.crop((x, y, x + side, y + side)).resize((256, 256), Image.BOX)
    p = os.path.join(ROOT, "assets/ground/tech_floor.png")
    im.save(p)
    print("  -> assets/ground/tech_floor.png (256, 256)")


def do_hero():
    print("[主角方向表]")
    im = Image.open(SRC + "ninja_sheet.jpg")
    w, h = im.size
    cols, rows = 8, 4
    cw, ch = w // cols, h // rows
    pick = [0, 2, 4, 6]                      # 模型给了每朝向 2 列，取第一列
    cells = []
    for r in range(rows):
        for c in pick:
            cell = im.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
            cell = trim_halo(keyout(cell), 1)
            cells.append(cell.crop(bbox(cell)))
    mx = max(c.height for c in cells)
    s = 14.0 / mx                             # 16px 格子里留 1px 上下余量
    print("  最高帧 %dpx -> 统一缩放 %.4f" % (mx, s))
    sheet = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        tw, th = max(1, int(round(c.width * s))), max(1, int(round(c.height * s)))
        c = c.resize((tw, th), Image.BOX if s < 0.35 else Image.LANCZOS)
        r, col = divmod(i, 4)
        frame = on_canvas(c, (16, 16), "bottom")
        sheet.paste(frame, (col * 16, r * 16), frame)
    q = quantize_group([sheet], 24)[0]
    p = os.path.join(ROOT, "assets/hero/ninja_sheet.png")
    q.save(p)
    print("  -> assets/hero/ninja_sheet.png (64, 64)")


GROUPS = {
    "图标": do_icons, "弹体": do_bullet, "剑气卡": do_card_damage,
    "怪物": do_mobs, "背景": do_bgs, "瓦片": do_tileset,
    "地面": do_floor, "主角": do_hero,
}

if __name__ == "__main__":
    want = sys.argv[1:] or list(GROUPS.keys())
    for k in want:
        GROUPS[k]()
    print("全部完成")
