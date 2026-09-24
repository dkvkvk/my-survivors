
# -*- coding: utf-8 -*-
"""校验主角四向走路用的精灵表列是否「帧间自洽 + 朝向正确」。

背景（HANDOVER 坑 #11b）：hero.gd 把 16x16 的 4x4 表按列切帧，某列若帧间不一致
（质心乱跳、或 idle 帧与走路帧朝向相反），播起来就像"边走边转身"——
人眼在 6.6 倍缩放的小人身上很难发现，但可以量化：

  自洽性：该列 4 帧「不透明像素质心 x」的极差 <= 1.5px
  朝向  ：侧向帧的「肤色质心 - 身体质心」符号 = 朝向；4 帧符号必须一致，
          且左向应为负、右向应为正（右向允许由左向列镜像得到）

用法：
    python tools/qa/check_hero_columns.py                 # 校验（L0 判据 hero-columns）
    python tools/qa/check_hero_columns.py --preview out.png  # 顺带导出四向帧预览图
"""
import argparse
import os
import re
import struct
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SHEET = os.path.join(ROOT, "assets", "hero", "ninja_sheet.png")
HERO = os.path.join(ROOT, "hero.gd")
FRAME = 16
ROWS = 4
SPREAD_LIMIT = 1.5      # 4 帧质心极差上限（px）
SIGN_MIN = 0.4          # 朝向符号的显著度下限


def read_png(path):
    """零依赖读 PNG（8bit RGBA/RGB，无隔行）→ (w, h, rgba 函数)。"""
    with open(path, "rb") as fh:
        data = fh.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("不是 PNG")
    pos = 8
    w = h = None
    idat = b""
    bitdepth = colortype = None
    while pos < len(data):
        ln = struct.unpack(">I", data[pos:pos + 4])[0]
        typ = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + ln]
        if typ == b"IHDR":
            w, h, bitdepth, colortype, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if interlace:
                raise ValueError("不支持隔行 PNG")
        elif typ == b"IDAT":
            idat += body
        elif typ == b"IEND":
            break
        pos += 12 + ln
    if bitdepth != 8 or colortype not in (2, 6):
        raise ValueError("只支持 8bit RGB/RGBA")
    nch = 4 if colortype == 6 else 3
    raw = zlib.decompress(idat)
    stride = w * nch
    out = bytearray(w * h * 4)
    prev = bytearray(stride)
    p = 0
    for y in range(h):
        f = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        for i in range(stride):
            a = line[i - nch] if i >= nch else 0
            b = prev[i]
            c = prev[i - nch] if i >= nch else 0
            if f == 1:
                line[i] = (line[i] + a) & 0xFF
            elif f == 2:
                line[i] = (line[i] + b) & 0xFF
            elif f == 3:
                line[i] = (line[i] + (a + b) // 2) & 0xFF
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        prev = line
        for x in range(w):
            o = (y * w + x) * 4
            s = x * nch
            out[o] = line[s]
            out[o + 1] = line[s + 1]
            out[o + 2] = line[s + 2]
            out[o + 3] = line[s + 3] if nch == 4 else 255
    return w, h, out


def is_skin(r, g, b):
    return r > 150 and g > 100 and b > 80 and r >= g >= b


def frame_stats(buf, w, col, row):
    """返回该帧的 (身体质心x, 肤色质心x, 不透明像素数)。"""
    xs, sx = [], []
    for y in range(row * FRAME, row * FRAME + FRAME):
        for x in range(col * FRAME, col * FRAME + FRAME):
            o = (y * w + x) * 4
            if buf[o + 3] < 40:
                continue
            xs.append(x - col * FRAME)
            if is_skin(buf[o], buf[o + 1], buf[o + 2]):
                sx.append(x - col * FRAME)
    if not xs:
        return None
    body = sum(xs) / float(len(xs))
    skin = (sum(sx) / float(len(sx))) if sx else None
    return body, skin, len(xs)


def read_mapping():
    src = open(HERO, "r", encoding="utf-8").read()
    m1 = re.search(r"DIR_COL\s*:=\s*\{([^}]*)\}", src)
    m2 = re.search(r"MIRROR_OF\s*:=\s*\{([^}]*)\}", src)
    if not m1 or not m2:
        raise ValueError("hero.gd 里找不到 DIR_COL / MIRROR_OF")
    dir_col = {k: int(v) for k, v in re.findall(r'"(\w+)"\s*:\s*(\d+)', m1.group(1))}
    mirror = {k: v for k, v in re.findall(r'"(\w+)"\s*:\s*"(\w+)"', m2.group(1))}
    return dir_col, mirror


def resolve(direction, dir_col, mirror):
    """返回 (用哪一列, 是否水平镜像)。"""
    if direction in dir_col:
        return dir_col[direction], False
    if direction in mirror:
        col, flip = resolve(mirror[direction], dir_col, mirror)
        return col, not flip
    raise ValueError("方向 %s 既不在 DIR_COL 也不在 MIRROR_OF" % direction)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", help="导出四向帧预览图（用于肉眼核对）")
    args = ap.parse_args()

    w, h, buf = read_png(SHEET)
    if (w, h) != (FRAME * 4, FRAME * 4):
        print("HEROCOL FAIL: 精灵表尺寸 %dx%d，期望 %dx%d" % (w, h, FRAME * 4, FRAME * 4))
        return 1
    dir_col, mirror = read_mapping()
    problems = []
    for direction in ("down", "up", "left", "right"):
        col, flip = resolve(direction, dir_col, mirror)
        bodies, skins = [], []
        for row in range(ROWS):
            st = frame_stats(buf, w, col, row)
            if st is None:
                problems.append("%s: col%d row%d 是空帧" % (direction, col, row))
                continue
            body, skin, _ = st
            bodies.append(body)
            skins.append(None if skin is None else (skin - body) * (-1 if flip else 1))
        if not bodies:
            continue
        spread = max(bodies) - min(bodies)
        detail = "col%d%s 质心 %s 极差 %.1f" % (
            col, "(镜像)" if flip else "", "/".join("%.1f" % b for b in bodies), spread)
        if spread > SPREAD_LIMIT:
            problems.append("%s: 帧间不自洽（走路会像边走边转身）——%s" % (direction, detail))
        if direction in ("left", "right"):
            vals = [s for s in skins if s is not None]
            if not vals:
                problems.append("%s: 侧向帧看不到肤色，无法判定朝向" % direction)
            else:
                want = -1 if direction == "left" else 1
                wrong = [v for v in vals if (v * want) <= SIGN_MIN]
                if wrong:
                    problems.append("%s: 朝向不对或帧间朝向不一致（肤色偏移 %s，期望符号 %+d）" % (
                        direction, "/".join("%+.1f" % v for v in vals), want))
        print("  %-5s %s" % (direction, detail))

    if args.preview:
        try:
            from PIL import Image
            S = 8
            sheet = Image.new("RGBA", (4 * FRAME * S + 5 * 8, 4 * FRAME * S + 5 * 8), (18, 22, 28, 255))
            src = Image.open(SHEET).convert("RGBA")
            for di, direction in enumerate(("down", "up", "left", "right")):
                col, flip = resolve(direction, dir_col, mirror)
                for row in range(ROWS):
                    fr = src.crop((col * FRAME, row * FRAME, col * FRAME + FRAME, row * FRAME + FRAME))
                    if flip:
                        fr = fr.transpose(Image.FLIP_LEFT_RIGHT)
                    fr = fr.resize((FRAME * S, FRAME * S), Image.NEAREST)
                    sheet.alpha_composite(fr, (8 + row * (FRAME * S + 8), 8 + di * (FRAME * S + 8)))
            sheet.save(args.preview)
            print("preview -> %s（每行一个朝向：下/上/左/右，每列一帧）" % args.preview)
        except ImportError:
            print("（没装 Pillow，跳过预览）")

    if problems:
        for p in problems:
            print("HEROCOL FAIL: " + p)
        print("HEROCOL FAIL")
        return 1
    print("HEROCOL PASS: 四向列均自洽且朝向正确")
    return 0


if __name__ == "__main__":
    sys.exit(main())
