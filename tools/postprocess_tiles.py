"""
瓦片集后处理：给"挡路"的瓦片加接触阴影 + 暗描边 + 顶部边缘光，给"可穿行"的装饰瓦片压暗。
这是"一眼区分地面/遮挡"视觉语言的关键（见 HANDOVER / ASSETS.md）。
用法：python tools/postprocess_tiles.py  [tileset.png 路径，默认 assets/tiles/tileset.png]
换新瓦片美术后必须重跑本脚本，否则丢掉可读性处理。
"""
import sys
import numpy as np
from PIL import Image

T = 64
SOLID = {0, 1, 2, 3}   # 挡路：墙/货箱/丹炉(服务器)/灵幡(天线)
DECOR = {4, 5}         # 可穿行：灵石(水晶)/竹丛(灌木)

def dilate(m, r):
    if r <= 0:
        return m.copy()
    h, w = m.shape
    p = np.pad(m, r)
    out = np.zeros_like(p)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(p, dy, 0), dx, 1)
    return out[r:r + h, r:r + w]

def shift(m, dy, dx=0):
    h, w = m.shape
    out = np.zeros_like(m)
    ys, xs = slice(max(dy,0), h+min(dy,0)), slice(max(dx,0), w+min(dx,0))
    ys2, xs2 = slice(max(-dy,0), h+min(-dy,0)), slice(max(-dx,0), w+min(-dx,0))
    out[ys, xs] = m[ys2, xs2]
    return out

def main(path):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32)
    H, W, _ = a.shape
    n = W // T
    out = a.copy()
    for i in range(n):
        t = a[:, i*T:(i+1)*T]
        mask = t[:, :, 3] > 24
        if not mask.any():
            continue
        if i in SOLID:
            rgb = np.clip(t[:, :, :3] * 1.30, 0, 255)
            sh1, sh2 = shift(mask, 6), shift(mask, 10)
            ring = dilate(mask, 2) & ~mask
            top = mask & ~shift(mask, -2)
            new = np.zeros((T, T, 4), np.float32)
            def put(m, col, al):
                new[m, 0], new[m, 1], new[m, 2] = col
                new[m, 3] = np.maximum(new[m, 3], al)
            put(sh2 & ~mask, (8, 11, 16), 70)
            put(sh1 & ~mask, (8, 11, 16), 145)
            put(ring, (5, 7, 11), 240)
            new[mask, 0], new[mask, 1], new[mask, 2] = rgb[:,:,0][mask], rgb[:,:,1][mask], rgb[:,:,2][mask]
            new[mask, 3] = 255
            new[top, 0] = new[top, 0]*0.45 + 120*0.55
            new[top, 1] = new[top, 1]*0.45 + 235*0.55
            new[top, 2] = new[top, 2]*0.45 + 255*0.55
            out[:, i*T:(i+1)*T] = np.clip(new, 0, 255)
        elif i in DECOR:
            t2 = t.copy()
            t2[:, :, :3] = np.clip(t2[:, :, :3] * 0.92, 0, 255)
            out[:, i*T:(i+1)*T] = t2
    Image.fromarray(out.astype(np.uint8), "RGBA").save(path)
    print("已处理", path, "（%d 格，实体=%s）" % (n, sorted(SOLID)))

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/tiles/tileset.png")
