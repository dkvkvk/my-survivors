# -*- coding: utf-8 -*-
"""妖物可读性后处理：提亮 + 提饱和 + 1px 暗描边。

为什么要这一步：修仙素材整体是"夜色"基调，阴风鸮（近黑）、蛮石傀（深绿）
和蓝灰地面明度接近，玩家在混战里容易"看不见怪"。描边与瓦片用的是同一套
视觉语言（挡路瓦片也是暗描边），所以怪从地面上"抠"出来的方式保持一致。

用法：python tools/postprocess_mobs.py [--bright 1.18] [--sat 1.08] [--outline]
注意：本脚本直接在 assets/mobs/*.png 上就地修改，重复跑会叠加提亮——
      要重来请从生图源图重新走 tools/import_ai_art.py。
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image

OUTLINE_RGB = (12, 14, 22)


def dilate(m, r=1):
    p = np.pad(m, r, constant_values=False)
    out = p[r:-r, r:-r].copy()
    for dy in (-r, r):
        out |= p[r + dy:p.shape[0] - r + dy, r:-r]
    for dx in (-r, r):
        out |= p[r:-r, r + dx:p.shape[1] - r + dx]
    return out


def polish(path, bright, sat, outline):
    im = Image.open(path).convert("RGBA")
    a = np.asarray(im).astype(np.float32)
    rgb, al = a[..., :3], a[..., 3]
    rgb = np.clip(rgb * bright, 0, 255)
    if sat != 1.0:
        g = rgb.mean(axis=2, keepdims=True)
        rgb = np.clip(g + (rgb - g) * sat, 0, 255)
    m = al > 40
    out = np.zeros_like(a)
    out[..., :3] = rgb
    out[..., 3] = np.where(m, 255.0, 0.0)
    if outline:
        ring = dilate(m, 1) & ~m
        out[ring, 0], out[ring, 1], out[ring, 2] = OUTLINE_RGB
        out[ring, 3] = 255.0
    Image.fromarray(out.astype(np.uint8), "RGBA").save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bright", type=float, default=1.18)
    ap.add_argument("--sat", type=float, default=1.08)
    ap.add_argument("--outline", action="store_true", default=True)
    ap.add_argument("--no-outline", dest="outline", action="store_false")
    a = ap.parse_args()
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    files = sorted(glob.glob(os.path.join(root, "assets/mobs/*.png")))
    for f in files:
        polish(f, a.bright, a.sat, a.outline)
        print("  polish %-34s bright=%.2f sat=%.2f outline=%s" % (
            os.path.basename(f), a.bright, a.sat, a.outline))
    print("共处理 %d 张" % len(files))


if __name__ == "__main__":
    main()
