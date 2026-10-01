# -*- coding: utf-8 -*-
"""把一个已拼好的角色行走表按「躯干高度」对齐帧间大小。

为什么不用整帧 bbox：源条里有些帧竖举着剑/抬手，内容 bbox 被拉高，
按 bbox 归一 -> 那些帧的身体被缩得特别小 -> 走路看着一大一小
（实测：剑修 up 列帧间差 40%、符修 up 25%、丹修 left 33%）。

躯干 = 行宽达到「第 75 百分位行宽的 45%」的那些行（细剑/发丝会被排除）。
对齐时：躯干底边保持原位、躯干中轴落到格子中心（不是 bbox 居中，否则伸出的剑会把人物顶偏）。

用法：python tools/normalize_sheet_frames.py <表> [--dry-run] [--deadzone 0.10] [--max-up 1.25]

⚠️ 度量对"举剑/抬手"帧仍可能不准（实测丹修 left f1 被量成躯干 16 而其实正常，
  放大 1.5 倍后反而明显偏大）。所以：**跑完必须人眼复核 left 列的 4 帧**，
  不对就回滚 .bak 备份。
"""
import argparse
import shutil

import numpy as np
from PIL import Image


def body_span(m):
    """返回 (躯干顶行, 躯干底行, 躯干中轴x)；找不到返回 (-1, -1, 0)。"""
    ys, xs = np.nonzero(m)
    if len(ys) == 0:
        return -1, -1, 0.0
    ws = []
    for y in range(ys.min(), ys.max() + 1):
        row = np.nonzero(m[y])[0]
        ws.append(row.max() - row.min() + 1 if len(row) else 0)
    pos = [w for w in ws if w > 0]
    ref = float(np.percentile(pos, 75)) if pos else 0.0
    keep = [i for i, w in enumerate(ws) if w >= ref * 0.45]
    if not keep:
        return -1, -1, 0.0
    top = ys.min() + keep[0]
    bot = ys.min() + keep[-1]
    row = np.nonzero(m[(top + bot) // 2])[0]
    cx = float(row.mean()) if len(row) else float(xs.mean())
    return int(top), int(bot), cx


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('sheet')
    ap.add_argument('--deadzone', type=float, default=0.10)
    ap.add_argument('--max-up', type=float, default=1.25,
                    help='单帧最多放大多少倍（放大=插值会糊；实测放大 1.5 倍会把一帧搞成明显偏大）')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    img = Image.open(a.sheet).convert('RGBA')
    arr = np.asarray(img)
    cell = arr.shape[1] // 4
    labels = ['down', 'up', 'left', 'right']

    spans = {}
    for c, lbl in enumerate(labels):
        spans[lbl] = []
        for r in range(4):
            m = arr[r * cell:(r + 1) * cell, c * cell:(c + 1) * cell][..., 3] > 0
            spans[lbl].append(body_span(m))

    print('  躯干高度（按方向）：')
    target = {}
    for lbl in labels:
        hs = [max(0, s[1] - s[0] + 1) for s in spans[lbl]]
        v = [h for h in hs if h > 0]
        target[lbl] = int(np.median(v)) if v else 0
        print('    %-6s %s  中位 %d' % (lbl, hs, target[lbl]))

    if a.dry_run:
        print('  (dry-run，未改文件)')
        return

    out = Image.new('RGBA', (cell * 4, cell * 4), (0, 0, 0, 0))
    changed = 0
    for c, lbl in enumerate(labels):
        med = target[lbl]
        if med <= 0:
            continue
        for r in range(4):
            frame = img.crop((c * cell, r * cell, c * cell + cell, r * cell + cell))
            m = np.asarray(frame)[..., 3] > 8
            top, bot, cx = spans[lbl][r]
            h = bot - top + 1
            if top < 0 or h <= 0 or abs(h - med) / float(med) <= a.deadzone:
                out.paste(frame, (c * cell, r * cell), frame)
                continue
            ys, xs = np.nonzero(m)
            content = frame.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
            k = med / float(h)
            if k > a.max_up:
                print('    %s f%d 需要放大 x%.2f，超过上限 %.2f —— 跳过（该帧度量可能不准，建议重画源条）'
                      % (lbl, r, k, a.max_up))
                out.paste(frame, (c * cell, r * cell), frame)
                continue
            nw = max(1, int(round(content.width * k)))
            nh = max(1, int(round(content.height * k)))
            scaled = content.resize((nw, nh), Image.LANCZOS)
            dst_y = int(round((bot + 1) - (bot - ys.min() + 1) * k))
            dst_x = int(round(cell * 0.5 - (cx - xs.min()) * k))
            dst = Image.new('RGBA', (cell, cell), (0, 0, 0, 0))
            dst.paste(scaled, (dst_x, dst_y), scaled)
            out.paste(dst, (c * cell, r * cell), dst)
            changed += 1
            print('    %s f%d 躯干 %d -> %d (x%.2f)' % (lbl, r, h, med, k))

    if changed == 0:
        print('  帧间大小本来就一致，未改动')
        return
    alpha = out.getchannel('A')
    rgb = out.convert('RGB').quantize(colors=24, method=Image.MEDIANCUT).convert('RGB')
    q = rgb.convert('RGBA')
    q.putalpha(alpha)
    shutil.copy2(a.sheet, a.sheet + '.bak')
    q.save(a.sheet)
    print('  -> 已修正 %d 帧：%s（备份 .bak）' % (changed, a.sheet))


if __name__ == '__main__':
    main()
