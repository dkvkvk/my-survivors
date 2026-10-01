# -*- coding: utf-8 -*-
"""把「一个方向一列 4 帧」的角色条拼成 4×4 行走表。

为什么这么做：生图模型画不出严格四向整表（会把四个方向画成「多个略微转头的同向姿势」，
实测三张全废）。所以改成**一次只要一个方向**，右向由**左向列镜像**得到（hero.gd 的 MIRROR_OF）。

输入：E:/games/<角色>_<方向>.jpg（方向 = down / up / left）
输出：assets/hero/char_<角色>_sheet.png（64×64；列 = 下0/上1/左2/右3，行 = 行走帧）

取景基准与共用表对齐：内容高 ≤14px、底边留 1px、水平居中——这样换角色不会忽大忽小。
用法：python tools/assemble_char_strips.py [角色...]
"""
import os
import sys

import numpy as np
from PIL import Image

SRC = "E:/games/"
OUT = "assets/hero/"
CELL = 32           # 16px 格放不下 AI 立绘的细节（实测糊成色块）
CONTENT_H = 28          # 与共用表一致
BOTTOM_PAD = 0          # 与共用表一致：脚踩格子底边（实测共用表底边余量 0）
CELLS = 4               # 每个方向 4 帧


def keyout(im):
    a = np.asarray(im.convert("RGB")).astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mn = np.minimum(r, b)
    mag = (r > 105) & (b > 85) & (g < mn - 25)
    return Image.fromarray(np.dstack([a.astype(np.uint8), np.where(mag, 0, 255).astype(np.uint8)]), "RGBA")


def erode(m, r=1):
    p = np.pad(m, r, constant_values=False)
    out = p[r:-r, r:-r].copy()
    for dy in (-r, r):
        out &= p[r + dy:p.shape[0] - r + dy, r:-r]
    for dx in (-r, r):
        out &= p[r:-r, r + dx:p.shape[1] - r + dx]
    return out


def trim_halo(img, r=1):
    a = np.asarray(img).copy()
    m = erode(a[..., 3] > 0, r)
    a[..., 3] = np.where(m, 255, 0)
    return Image.fromarray(a, "RGBA")


def split_frames(img):
    """把一条横条切成 4 帧。先按竖直空隙分组；细线组剔除、过多则合并；仍不是 4 帧就等分内容区。"""
    a = np.asarray(img)[..., 3] > 0
    cols = a.any(axis=0)
    xs = np.nonzero(cols)[0]
    if len(xs) == 0:
        raise RuntimeError("整条被抠空")
    groups = []
    start = prev = xs[0]
    gap = max(4, int(img.width * 0.012))
    for x in xs[1:]:
        if x - prev > gap:
            groups.append([start, prev])
            start = x
        prev = x
    groups.append([start, prev])
    # 剔除细线（宽度 < 最大组宽 12%）
    widest = max(g[1] - g[0] + 1 for g in groups)
    groups = [g for g in groups if (g[1] - g[0] + 1) >= widest * 0.12]
    # 过多 -> 反复合并最近的两组
    while len(groups) > CELLS:
        d = [groups[i + 1][0] - groups[i][1] for i in range(len(groups) - 1)]
        i = int(np.argmin(d))
        groups[i][1] = groups[i + 1][1]
        del groups[i + 1]
    frames = []
    if len(groups) == CELLS:
        for g in groups:
            frames.append(img.crop((g[0], 0, g[1] + 1, img.height)))
    else:
        # 帧相连：把内容区等分成 4 段
        x0, x1 = xs.min(), xs.max() + 1
        step = (x1 - x0) / float(CELLS)
        for i in range(CELLS):
            frames.append(img.crop((int(x0 + i * step), 0, int(x0 + (i + 1) * step), img.height)))
    return [f.crop(f.getbbox()) for f in frames]


def build(char):
    per_dir = {}
    for d in ("down", "up", "left"):
        path = SRC + "%s_%s.jpg" % (char, d)
        im = trim_halo(keyout(Image.open(path)))
        fr = split_frames(im)
        per_dir[d] = fr
        print("   %s_%s: %d 帧, 尺寸 %s" % (char, d, len(fr), [f.size for f in fr]))
    mx = max(f.height for d in per_dir for f in per_dir[d])
    s = CONTENT_H / float(mx)
    sheet = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 0))
    cols = {"down": 0, "up": 1, "left": 2}
    for d, ci in cols.items():
        for ri, f in enumerate(per_dir[d]):
            w = max(1, int(round(f.width * s)))
            h = max(1, int(round(f.height * s)))
            if s < 0.35:
                f2 = f.resize((w, h), Image.BOX)
            else:
                f2 = f.resize((w, h), Image.LANCZOS)
            cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
            x = (CELL - w) // 2
            y = CELL - BOTTOM_PAD - h
            cell.paste(f2, (x, max(0, y)), f2)
            sheet.paste(cell, (ci * CELL, ri * CELL), cell)
        # 右向 = 左向镜像
        if d == "left":
            for ri in range(2):
                pass
    # 逐行把 col2 镜像写进 col3
    a = np.asarray(sheet).copy()
    left = a[:, 2 * CELL:3 * CELL]
    a[:, 3 * CELL:4 * CELL] = left[:, ::-1]
    sheet = Image.fromarray(a, "RGBA")
    alpha = sheet.getchannel("A")
    rgb = sheet.convert("RGB").quantize(colors=24, method=Image.MEDIANCUT).convert("RGB")
    q = rgb.convert("RGBA")
    q.putalpha(alpha)
    p = OUT + "char_%s_sheet.png" % char
    q.save(p)
    print("   -> %s %s" % (p, q.size))


if __name__ == "__main__":
    for c in (sys.argv[1:] or ["fu", "jian", "dan"]):
        print("[%s]" % c)
        build(c)
    print("完成")
