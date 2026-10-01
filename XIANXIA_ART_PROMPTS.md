# 修仙化 · 生图清单（只留「还没做的」）

> 用途：交给网页版生图模型生成素材的**逐张提示词**。
> **生成并接入后，对应提示词就删掉**——已经做了的看 `ASSETS.md`，历史经验看 `HANDOVER.md`。
> **最后更新：2026-10-01**（审计：本文提到的 56 个文件里 53 个已接入，故清理为只留待生成）

---

## 〇、总规范（每张都适用）

**通用后缀（每条提示词末尾都带上）：**

```text
pixel art, 16-bit retro game style, crisp pixels, clean readable silhouette,
no anti-aliasing, no blur, no text, no watermark, no border
```

**单体精灵 / 图标额外加**：`solid magenta background (#FF00FF), single object only, one image contains exactly one asset`
（历史坑：AI 常把多个素材挤进一张图，导致错位。）

**调色板（写进提示词）：**

```text
color palette: dark ink-blue night (#0E1420 base, #1A2333 stone), jade-cyan spirit glow (#55E0C8),
gold accents (#E8B84A), cinnabar red (#B5352C), moon-white highlights (#CFE8E0)
```

**两帧动画规则**：先出第一帧 → 用**参考图改姿势**出第二帧（同尺寸同构图，只改姿势）。
**背景 / 无缝贴图**：不要洋红底，铺满整张；无缝的要写 `seamless tileable`。

---

## 一、待生成（当前 3 张）

> 生成好丢到 `E:\games\`，说一声即可：我抠底 → 切帧 → 统一缩放 → 拼表 → 导入 → 实机核对 → 删原图。

### 1. 守山人行走表重画（3 张 · 对齐 32px 格）

> **为什么**：守山人一直用最早的 16px 格旧表，另外三个身份是 32px 格；
> 尺寸已用 `sprite_mul` 拉齐，但**像素颗粒差一倍**（他在屏幕上是「大方块」）。
> 重画后他与另外三人从尺寸到画风完全一套。
> **造型要一致**（他已是玩家的熟面孔）：**玄青道袍 + 黑边 + 红发带 + 背后剑匣**。
> 命名 `shou_shan_down.png` / `shou_shan_up.png` / `shou_shan_left.png`。
> 交付后我先量一次朝向再拼（这三张也应该是「朝左」的侧面；不对我会镜像）。

#### 1-a `shou_shan_down.png` —— 朝下（正面）

```text
pixel art sprite strip, one single row of 4 frames side by side, four equal cells, no gaps,
no grid lines: a small Chinese mountain night-watch cultivator walking, facing DOWN the whole time (front view: face and both eyes visible, arms hanging at the sides).
Frame 1 = contact pose, frame 2 = passing pose, frame 3 = contact pose (opposite legs),
frame 4 = passing pose. Same body height, same horizontal position, same head position in all
4 frames - only the legs and arms move.
character: dark teal-blue robe with black trim, black hair in a topknot tied with a small red
ribbon, a flat dark sword case strapped on his back, dark trousers, black shoes, pale round face.
color palette: dark teal-blue (#1E4F5C) robe, black trim, cinnabar red (#B5352C) ribbon,
skin tone (#E8C09A), dark ink-blue night (#0E1420) outline,
solid magenta background (#FF00FF), pixel art, 16-bit retro game style, crisp pixels,
clean readable silhouette, no text, no watermark, no border
```

#### 1-b `shou_shan_up.png` —— 朝上（背面）

```text
pixel art sprite strip, one single row of 4 frames side by side, four equal cells, no gaps,
no grid lines: a small Chinese mountain night-watch cultivator walking, facing UP the whole time (back view: no face visible, you see the back of the head and the sword case on his back).
Frame 1 = contact pose, frame 2 = passing pose, frame 3 = contact pose (opposite legs),
frame 4 = passing pose. Same body height, same horizontal position, same head position in all
4 frames - only the legs and arms move.
character: dark teal-blue robe with black trim, black hair in a topknot tied with a small red
ribbon, a flat dark sword case strapped on his back, dark trousers, black shoes, pale round face.
color palette: dark teal-blue (#1E4F5C) robe, black trim, cinnabar red (#B5352C) ribbon,
skin tone (#E8C09A), dark ink-blue night (#0E1420) outline,
solid magenta background (#FF00FF), pixel art, 16-bit retro game style, crisp pixels,
clean readable silhouette, no text, no watermark, no border
```

#### 1-c `shou_shan_left.png` —— 朝左（侧面）

```text
pixel art sprite strip, one single row of 4 frames side by side, four equal cells, no gaps,
no grid lines: a small Chinese mountain night-watch cultivator walking, facing LEFT the whole time (profile view: face on the LEFT side of the head in all 4 frames).
Frame 1 = contact pose, frame 2 = passing pose, frame 3 = contact pose (opposite legs),
frame 4 = passing pose. Same body height, same horizontal position, same head position in all
4 frames - only the legs and arms move.
character: dark teal-blue robe with black trim, black hair in a topknot tied with a small red
ribbon, a flat dark sword case strapped on his back, dark trousers, black shoes, pale round face.
color palette: dark teal-blue (#1E4F5C) robe, black trim, cinnabar red (#B5352C) ribbon,
skin tone (#E8C09A), dark ink-blue night (#0E1420) outline,
solid magenta background (#FF00FF), pixel art, 16-bit retro game style, crisp pixels,
clean readable silhouette, no text, no watermark, no border
```

---

## 二、可选（未排期，想升级时再来找我写完整提示词）

- **P6 两件法宝的图标**：`icon_fa_boomerang.png` / `icon_fa_mine.png` 与它们的神通图标
  `skill_boomerang.png` / `skill_mine.png` ——现在是**代码生成的占位**，能用、不丢人。
- **特效贴图升级**：把 `vfx.gd` 里代码画的圆环/刀光/爆闪换成贴图（fx_ring / fx_slash / fx_burst / fx_thunder）。
  现在是代码画 + 4 张程序化贴图，观感已经成立。

---

## 三、生成与交付流程（每次生成前读一遍）

1. **规格**：见「一」里每条提示词；通用风格/调色板见本文开头的「〇、总规范」。
2. **背景**：精灵与图标一律**纯洋红 `#FF00FF`**；瓦片与地面**无缝、无洋红**；背景 1920×1080、16:9、无文字。
3. **一张图只做一件事**：一个精灵 / 一列行走帧 / 一张贴图。
4. **行走帧**：**一张图只画一个方向、一列 4 帧**（右向不必出图，由左向镜像得到）。
   ⚠️ 别一次要「整张 4×4 表」：模型会把四个方向画成「多个略微转头的同向姿势」（实测三张全废）。
5. **朝向**：侧面条必须是**脸朝左**——代码与判定脚本 `hero-columns` 都以此为准。
   ⚠️ 实测模型经常画成朝右；我拼表前会先量一次朝向，不对就镜像。
6. **命名与交付**：`<用途>_<方向>.png`（例 `shou_shan_down.png`），丢 `E:\games\`。
7. **我这边**：抠底 → 切帧 → 统一缩放 → 拼表 → `--import` → `L0 判定` → 实机截图 → 删原图。

---
