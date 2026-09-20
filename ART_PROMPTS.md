# 美术素材提示词（ART PROMPTS）

> 用途：交给网页版 Nano Banana 生成游戏素材的**逐张提示词**。
> 生成后放到 `E:\games\` 下（不要自己改名，按本文文件名），我来做抠底/像素化/接入。
> 生成一条 = 一张图 = 一个素材。**千万别让模型把多个素材画在一张图里**。

---

## 〇、铁律（上次翻车就翻在这几条）

1. **一条提示词只出一张图、图里只有一个素材**。上次"九宫格"把卡图标、忍者表、道具图标全搅在一起，导致 4 处错位。
2. **两帧动画必须两帧同尺寸、同构图、只改姿势**。上次 `mech_slime_1.png` 变成 24×13 的扁圆顶，跟第一帧 19×24 完全不搭，走路时跳变。
3. 背景**必须**纯洋红 `#FF00FF`，不要阴影、不要地面、不要渐变背景。
4. **不要文字、不要水印、不要边框、不要多余装饰**。
5. 明确写 `crisp pixels, pixel art, no anti-aliasing, no blur`。
6. 我这边处理时会**统一画布尺寸并居中对齐**，但**请你尽量让两帧的视觉大小一致**（这是上次最大的问题）。

**推荐做法**：先生成第 1 帧 → 满意后用「参考图 + 改姿势」生成第 2 帧，而不是重新描述一遍（重新描述很容易变形）。

---

## 一、待重做的敌人贴图（优先，玩家能直接看到问题）

处理规格：抠洋红底 → bbox 裁剪 → 像素化到 **24px 高、16 色** → 两帧统一画布居中。
> **已定美术方向：恢复四色区分 + 加亮描边。** 每只怪一个色系（见下表），并在
> 提示词里统一加上 `with a clean dark outline around the whole silhouette`，保证在深色科技地板上看得清。

| 怪 | 色系 | 描边 |
|---|---|---|
| 史莱姆 | 青绿 cyan-teal | 深青 |
| 蝙蝠 | 紫 purple | 深紫 |
| 重甲兵 | 钢灰 steel grey | 深灰 |
| 魔化野兽 | 猩红 crimson-red | 深红 |

### 1. 史莱姆（替换 mech_slime_0/1.png）— 当前最严重
**第 1 帧**
```
A cute pixel art slime creature, rounded blob shape, glossy cyan-teal body with a lighter highlight on top, two small dark oval eyes, tiny droplet drips at the base, with a clean dark outline around the whole silhouette. Side view facing right. Single centered subject on a solid magenta background (#FF00FF). Crisp pixels, pixel art, 16 colors, no anti-aliasing, no blur, no text, no watermark, no border, no shadow on the ground.
```
**第 2 帧**（用第 1 帧当参考图）
```
Same slime, same size and same position on canvas, same colors and same dark outline. Only change: squash it slightly and shift the two eyes a bit - mid-hop pose. Keep identical canvas size and identical visual scale. Solid magenta background (#FF00FF). Crisp pixels, pixel art, no text, no watermark.
```

### 2. 机械蝙蝠（替换 mech_bat_0/1.png）— 第 2 帧太小
**第 1 帧**
```
A small pixel art mechanical bat, wings spread wide and clearly visible, deep purple metal body with bright cyan glowing eyes and magenta wing membrane, tiny metal rivets, with a clean dark outline around the whole silhouette. Front view. Single centered subject on a solid magenta background (#FF00FF). Crisp pixels, pixel art, 16 colors, high contrast against dark backgrounds, no anti-aliasing, no blur, no text, no watermark.
```
**第 2 帧**（用第 1 帧当参考图）
```
Same mechanical bat, SAME size, SAME position, SAME purple colors and outline. Only change: wings flapped downward (mid-flight), body tilted slightly. Must remain the same overall silhouette size as frame 1. Solid magenta background (#FF00FF). Crisp pixels, pixel art, no text, no watermark.
```

### 3. 重甲兵（替换 mech_knight_0/1.png）— 第 2 帧偏暗
**第 1 帧**
```
A pixel art heavy armored soldier robot, bulky steel-grey armor plates with cyan glowing visor and cyan energy lines, holding a small shield, standing pose, with a clean dark outline around the whole silhouette. Front view. Single centered subject on a solid magenta background (#FF00FF). Crisp pixels, pixel art, 16 colors, bright and clearly readable, no anti-aliasing, no blur, no text, no watermark.
```
**第 2 帧**（用第 1 帧当参考图）
```
Same armored soldier, SAME size, SAME brightness, SAME colors. Only change: legs shifted one step forward (walking). Do not darken the image. Solid magenta background (#FF00FF). Crisp pixels, pixel art, no text, no watermark.
```

### 4. 魔化野兽（可选优化 mech_beast_0/1.png）
**第 1 帧**
```
A pixel art feral beast creature, four-legged predator, dark crimson-red fur with magenta glowing eyes and magenta energy cracks on its back, snarling, with a clean dark outline around the whole silhouette. Side view facing right. Single centered subject on a solid magenta background (#FF00FF). Crisp pixels, pixel art, 16 colors, no anti-aliasing, no blur, no text, no watermark.
```
**第 2 帧**（用第 1 帧当参考图）
```
Same beast, SAME size, SAME position, SAME crimson colors and outline. Only change: legs in mid-run, front leg extended forward. Solid magenta background (#FF00FF). Crisp pixels, pixel art, no text, no watermark.
```

---

## 二、首领（替换 boss_0.png）— 当前是一坨深红噪声

> **已定方向：先只做 1 种首领，但形象做扎实。** 只出 **1 张**，要求剪影清晰、
> 一眼能看出是「大 BOSS」，在深色地板上不糊。
>
> 技能我这边改代码加强（蓄力 → 砸地 AoE 预警圈 → 召唤小怪），不需要额外素材，
> 预警圈和冲击波都用代码画。

处理规格：像素化到 **32px 高**，颜色数可到 32 色。

**首领（boss.png）**
```
A pixel art giant mech boss, hulking humanoid robot, dark steel-grey armor with a bright magenta-red glowing core in the chest, heavy shoulder cannons, glowing cyan visor, menacing wide stance, with a clean dark outline around the whole silhouette so it reads clearly on a dark background. Front view, strong readable silhouette, clearly bigger and more imposing than a normal enemy. Single centered subject on a solid magenta background (#FF00FF). Crisp pixels, pixel art, 32 colors, high contrast, no anti-aliasing, no blur, no text, no watermark, no border.
```

## 三、道具图标优化（可选，当前能用但偏弱）

规格：**单图标**，像素化到约 16px 高，透明底（我会抠）。

**手里剑（替换 icon_shuriken.png）** — 现在是灰白色，在深色地板上几乎看不见
```
A single pixel art shuriken (throwing star), four-pointed, bright silver-white metal with a strong dark outline so it stands out on dark backgrounds, slight cyan glint. Centered, single object on a solid magenta background (#FF00FF). Crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark.
```
**重装弹药卡图标（替换 card_damage.png）** — 现在是个看不懂的橙色弯钩
```
A single pixel art upgrade icon representing "heavy ammo / more bullet damage": a large orange-yellow bullet or shell with a glowing hot tip, dark outline. Centered, single object on a solid magenta background (#FF00FF). Crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark.
```

---

## 四、可选新增素材（先别生成，等定完玩法再说）

- 主菜单/商店/暂停按钮图标
- 新武器素材（取决于下一阶段做什么武器）
- 拾取/升级/进化的粒子特效图
- 成就徽章、角色选择立绘
- 宣传图/itch.io 封面（16:9）

---

## 五、交付清单（本次要生成的）

| # | 文件名（放到 E:\games\） | 张数 |
|---|---|---|
| 1 | slime_f1.png / slime_f2.png | 2 |
| 2 | bat_f1.png / bat_f2.png | 2 |
| 3 | knight_f1.png / knight_f2.png | 2 |
| 4 | beast_f1.png / beast_f2.png（可选） | 2 |
| 5 | boss.png | 1 |
| 6 | shuriken_new.png（可选） | 1 |
| 7 | card_damage_new.png（可选） | 1 |

**核心必做：1~3 + 5（共 7 张）**；4/6/7 有空再出。

**请一定一张一张生成、一张一张命名**，这样我接入时不会再错位。
