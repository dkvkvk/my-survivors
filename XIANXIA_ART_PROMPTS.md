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

## 一、待生成

> ✅ **当前没有待生成**。
>
> 上一批（守山人 down / up / left 三张，32px 格）已于 2026-10-01 生成并接入：
> `assets/hero/char_shou_shan_sheet.png`（128×128，每方向独立归一到同高）。
> 按本文件规矩接入后即删提示词；现状查 `ASSETS.md`，经验查 `HANDOVER.md` 坑 #23。

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
