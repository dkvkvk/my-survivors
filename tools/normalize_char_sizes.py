# -*- coding: utf-8 -*-
"""按四张行走表反算并写回 characters.gd 的 sprite_mul（人物大小归一）。

背景：AI 立绘的体型差别很大（最宽比最窄宽 82%、最高比最矮高 29%），
但游戏要的是"四个人看起来一样大"。做法是**只改渲染缩放**（不动原图）：
hero.gd 先把格子尺寸归一（16/_cell），再乘这里的 sprite_mul。

用法：
    python tools/normalize_char_sizes.py            # 反算并写回 characters.gd
    python tools/normalize_char_sizes.py --dry-run  # 只看表，不写文件

约定：目标高 14、宽 8.4（16px 格单位）；x 限幅 0.88~1.45、y 限幅 0.80~1.30
（限幅是为了避免把瘦角色拉成竹竿、把敦实的压成纸片）。
"""
import argparse
import io
import os
import re

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEETS = [
    ("shou_shan", "assets/hero/char_shou_shan_sheet.png"),
    ("fu_xiu", "assets/hero/char_fu_sheet.png"),
    ("jian_xiu", "assets/hero/char_jian_sheet.png"),
    ("dan_xiu", "assets/hero/char_dan_sheet.png"),
]
T_H, T_ASPECT = 14.0, 0.60
XLO, XHI = 0.88, 1.45
YLO, YHI = 0.80, 1.30


def measure(path):
    """返回该表"站立帧"的内容尺寸（16px 格单位）：取 col0/col2 的 row0 中位数。"""
    a = np.asarray(Image.open(os.path.join(ROOT, path)).convert("RGBA"))
    cell = a.shape[1] // 4
    ws, hs = [], []
    for col in (0, 2):
        m = a[0:cell, col * cell:(col + 1) * cell][..., 3] > 0
        ys, xs = np.nonzero(m)
        if len(ys) == 0:
            continue
        ws.append((xs.max() - xs.min() + 1) * 16.0 / cell)
        hs.append((ys.max() - ys.min() + 1) * 16.0 / cell)
    if not ws:
        raise RuntimeError("表里找不到内容: " + path)
    return float(np.median(ws)), float(np.median(hs)), cell


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    muls = {}
    print("  角色        格子  站立尺寸(16格)   sprite_mul      归一后")
    for cid, path in SHEETS:
        w16, h16, cell = measure(path)
        xm = min(XHI, max(XLO, T_H * T_ASPECT / w16))
        ym = min(YHI, max(YLO, T_H / h16))
        muls[cid] = (round(xm, 2), round(ym, 2))
        print("  %-11s %3d   %4.1f x %-6.1f   x%.2f y%.2f    %4.1f x %4.1f" % (
            cid, cell, w16, h16, xm, ym, w16 * xm, h16 * ym))

    if args.dry_run:
        print("  (dry-run，未写文件)")
        return

    p = os.path.join(ROOT, "characters.gd")
    s = io.open(p, encoding="utf-8").read()
    for cid, (xm, ym) in muls.items():
        idx = s.index('"id": "%s",' % cid)
        end = s.index("\t},", idx)
        block = s[idx:end]
        m = re.search(r'\t\t"sprite_mul": Vector2\([-0-9., ]+\),', block)
        line = '\t\t"sprite_mul": Vector2(%.2f, %.2f),' % (xm, ym)
        if m:
            s = s[:idx] + block.replace(m.group(0), line) + s[end:]
        else:
            s = s[:end] + line + "\n" + s[end:]
    io.open(p, "w", encoding="utf-8", newline="\n").write(s)
    print("  已写回 characters.gd")


if __name__ == "__main__":
    main()
