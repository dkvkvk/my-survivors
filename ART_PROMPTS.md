# 美术素材提示词（ART PROMPTS）

> 用途：交给网页版生图模型生成游戏素材的**逐张提示词**。
> 生成后放到 `E:\games\`，我负责抠底/像素化/接入；**接入后我会删掉原图**，
> 并把本文里对应的提示词也删掉（保持这份文档只留"还没做的"）。
>
> 最后更新：2026-09-21

---

## 〇、铁律（每次生成前先读）

1. **一条提示词只出一张图**，图里只有一个素材（多素材挤一张会导致错位，已踩过坑）。
2. **单体精灵/图标**：纯洋红底 `#FF00FF`，无阴影、无地面、无渐变背景。
3. **无缝瓦片/地面**：不要洋红底，要铺满整张，写 `seamless tileable`。
4. **背景大图**：不要出现文字（标题由游戏内像素字体渲染，方便改名）。
5. 必带：`crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border`。
6. **两帧动画**：两帧同尺寸同构图，只改姿势；建议用"参考图改姿势"而不是重新描述。
7. 生成后按我给的**文件名**命名（我会在文档里写清楚）。

### 项目风格基准

- 世界观：**和风忍者村 + 科技入侵**
- 主色：**青色霓虹** + 红木/和纸 + 金；夜色调
- 主角：蓝衣红围巾的像素小忍者

---

## 一、已完成（提示词已删除，仅留记录）

| 批次 | 内容 | 状态 |
|---|---|---|
| 敌人 | 4 只怪各两帧 + 首领（四色区分 + 描边） | ✅ 已接入 |
| 背景 | 主菜单 / 失败结算 / 胜利结算 / 封面 | ✅ 已接入 |
| 地图 | 和风瓦片集（6 格）+ 无缝地面 | ✅ 已接入 |
| 图标 | 手里剑、弹药卡图标 | ✅ 已接入 |
| P6 | 4 张技能图标 64×64 + 4 张掉落/材料图标 32×32 | ✅ 已接入 |

---

## 二、待生成：特效贴图（可选升级，做了会更华丽）

> 现在特效是 `vfx.gd` 纯代码绘制 + `assets/fx/` 程序化生成的像素贴图（能跑、风格统一）。
> 下面这批是**替换升级**：生图后我接进去，画质会明显提升。**一条提示词只出一张图。**
> 生成后放 `E:\games\` 并按表里的文件名命名，我负责抠底/像素化/接入。

### 1. `fx_ring_128.png` —— 冲击环 / 法阵环（替换 `vfx.gd` 里代码画的圆环）
`@
pixel art game VFX, a single glowing circular shockwave ring seen from the front,
cyan neon (#3FF0FF) energy with faint Japanese paper-charm (ofuda) notches at 4 cardinal points,
thin bright white inner edge, hollow center, perfectly centered and symmetric,
solid magenta background (#FF00FF), crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border
`@

### 2. `fx_slash_128.png` —— 斩击弧（替换代码画的新月刀光）
`@
pixel art game VFX, a single crescent-shaped sword slash arc, cyan-white blade light with a bright white cutting edge,
one clean swoosh crescent shape pointing to the right, tail fading out, no character, no weapon,
solid magenta background (#FF00FF), crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border
`@

### 3. `fx_burst_96.png` —— 爆闪星芒（升级 / 宝箱开启）
`@
pixel art game VFX, a single four-pointed golden starburst flash, warm gold (#FFD24A) with white hot core,
sharp thin spikes radiating out, small paper-charm fragments flying outward, centered and symmetric,
solid magenta background (#FF00FF), crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border
`@

### 4. `fx_thunder_96.png` —— 落雷光柱（雷神之怒落点）
`@
pixel art game VFX, a single vertical lightning bolt striking down, cyan-blue electric glow with white hot core,
jagged zigzag shape, wider at the top and narrower at the bottom, vertical composition,
solid magenta background (#FF00FF), crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border
`@

### 5. `fx_smoke_64.png` —— 和纸烟团（击杀 / 爆炸烟）
`@
pixel art game VFX, a single soft round smoke puff, light warm gray, wispy edges, semi transparent look,
one single puff only, centered,
solid magenta background (#FF00FF), crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border
`@

### 6. `fx_sakura_32.png` —— 樱花花瓣（主菜单 / 场景粒子）
`@
pixel art, a single small pink cherry blossom petal seen from the side, soft pink with a slightly darker tip,
one single petal only, centered,
solid magenta background (#FF00FF), crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border
`@

### 其余可选优化

| 项 | 说明 | 优先级 |
|---|---|---|
| 升级卡图标统一 | 现有 8 张卡图标还是"青蓝科技风"，和新世界观不完全统一 | 中 |
| 掉落物和风化 | 金币→铜钱、宝石→勾玉、宝箱→唐柜 | 低 |
| 标题 Logo | 含中文"不退"；模型写中文易错字，可后置 | 低 |
| 樱花花瓣粒子 | 主菜单已用**代码绘制**的花瓣，要更精致可换图 | 低 |
| 第 5、6 种武器图标 | 新增武器时配套（同时能让"替换面板"在实战生效） | 中 |
| 技能融合图标 | 融合系统还没做（见 `WEAPON_SYSTEM.md` 待办） | 低 |

---

## 三、视频（**格式问题未解决**）

> **实测结论：Godot 4.7 标准版放不了 MP4。**
>
> ```
> ResourceLoader.exists(mp4) = false
> load(mp4) -> null  (No loader found)
> VideoStream 支持的扩展名 = ["ogv", "tres", "res"]   ← 只有 Ogg Theora
> ```
>
> 要播就得转成 **`.ogv`**，而转码需要 ffmpeg —— 本机没有，pip 也装不上（网络被墙）。
>
> **所以视频暂时搁置。** 主菜单已改用**代码驱动动效**（背景视差漂移 + 樱花飘落 + 霓虹呼吸），
> 原生 + Web 都能跑、任何分辨率都清晰、循环天然无缝。
>
> 若将来解决 ffmpeg（例如 `winget install ffmpeg`），再回来做视频。
> 已有的 `menu_loop.mp4` 我保留在 `E:\games\` 没删（还没被成功用上）。

---

## 四、接入流程（我这边）

```
E:/games/xxx.jpg
  → 洋红抠底（r>140 且 b>120 且 g<min(r,b)-60）
  → bbox 裁剪
  → 按目标尺寸缩放（图标装进正方形画布居中；两帧动画共用同一缩放）
  → 覆盖 assets/ 下对应文件
  → headless 验证 + 实机截图确认
  → 删除 E:/games 原图 + 删除本文对应提示词
```

> 接入后**务必实机截图核对**：是谁在用这张图、比例对不对、脚底有没有落地。
