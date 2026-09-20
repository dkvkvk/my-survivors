# 美术素材提示词（ART PROMPTS）

> 交给我（用户）用网页版 Nano Banana / 视频模型生成，生成后放到 `E:\games\`。
> **一条提示词 = 一张图 = 一个素材**，千万别让模型把多个素材画在一张图里。

---

## 〇、项目设定（生成任何图前先读）

- **游戏名：《不退》**（暂定，取自"不会逃跑"——站着不动才是活路）
- **世界观：和风忍者村 + 科技入侵**
  - 鸟居、石灯笼、竹林、樱花、木质建筑、和纸障子
  - 被机械虫群 / 霓虹能量 / 钢铁造物入侵污染
  - 基调：**暗夜为主，青色霓虹 + 樱花粉点缀**
- **主角**：像素小忍者，蓝衣红围巾
- **敌人**：机械史莱姆（青）/ 机械蝙蝠（紫）/ 重甲兵（灰）/ 魔化野兽（红）/ 巨型机甲首领

### 通用铁律

1. **一条提示词只出一张图**，图里只有一个素材。
2. 单体精灵/图标：**纯洋红底 `#FF00FF`**，无阴影、无地面、无渐变背景。
3. 无缝瓦片/地面：**不要洋红底**，要铺满整张，写 `seamless tileable`。
4. 背景大图：**不要出现文字**（标题由游戏内像素字体渲染，方便改名）。
5. 必带：`crisp pixels, pixel art, no anti-aliasing, no blur, no text, no watermark, no border`。

---

## 一、本轮要生成（优先级 1：4 张背景大图）

**统一规格：1920×1080（16:9），横构图，像素风插画。**

> ⚠️ **安全区很重要**：游戏里标题和按钮压在图上，所以
> **菜单图左侧 1/3 要留暗、留空**，别把主体放在那儿。

### 1. `menu_bg.jpg` — 主菜单背景

```
Pixel art game title screen background, a Japanese ninja village at night invaded by technology. A large red torii gate on the right side, traditional wooden houses with paper lanterns, bamboo grove, cherry blossom petals drifting. Cyan neon energy cables and mechanical insect drones crawling over the buildings, glowing cyan circuit cracks in the stone path. Dark navy and black tones with cyan neon glow and pink sakura accents. The LEFT THIRD of the image is dark and empty (reserved for title and buttons), the main subject is on the right. Wide cinematic composition, 16:9. Crisp pixels, pixel art, limited palette, no text, no watermark, no border, no characters in the foreground.
```

### 2. `gameover_bg.jpg` — 失败结算背景

```
Pixel art game over screen background, a defeated ninja kneeling on cracked stone ground in a ruined Japanese ninja village, red torii gate broken in half behind him, mechanical insect swarm crawling over the ruins, dim red emergency glow mixed with dying cyan neon, dark and oppressive mood, falling ash and sakura petals. Center-left composition, the right side is dark and empty for text. Wide cinematic composition, 16:9. Crisp pixels, pixel art, moody limited palette of dark red, black and dying cyan, no text, no watermark, no border.
```

### 3. `victory_bg.jpg` — 胜利结算背景（新增）

```
Pixel art victory screen background, a lone ninja standing triumphantly on top of a tall red torii gate at dawn, mechanical wreckage and broken drones scattered below, the village behind him is free of corruption, warm sunrise light breaking through, cherry blossom petals blowing in the wind, cyan neon finally fading out. Bright and uplifting mood, gold and pink and soft cyan palette. Subject on the right, LEFT THIRD is darker and emptier for text. Wide cinematic composition, 16:9. Crisp pixels, pixel art, no text, no watermark, no border.
```

### 4. `cover.jpg` — 封面（宣传图 / itch.io）

```
Pixel art game cover art, dynamic action composition: a ninja in blue with a red scarf leaping through the air throwing shurikens, facing a massive horde of mechanical monsters flooding into a Japanese ninja village. Red torii gate and pagoda silhouettes in the background, cyan neon energy and glowing eyes in the dark, cherry blossom petals swirling. Strong contrast, dramatic lighting, the ninja is clearly the focal point. Full bleed composition, 16:9, poster quality. Crisp pixels, pixel art, rich colors, no text, no watermark, no border.
```

---

## 二、本轮要生成（优先级 2：和风地图换皮）

> ⚠️ 这两张是**无缝平铺**素材，**不要洋红底**，要铺满整张。

### 5. `tileset_wa.png` — 和风瓦片集（384×64，横排 6 格，每格 64×64）

**必须按这个顺序出 6 个图块**（游戏代码按索引取用）：

| 索引 | 字符 | 内容 | 碰撞 |
|---|---|---|---|
| 0 | `#` | 石墙（整格） | 整格碰撞 |
| 1 | `C` | 木箱（整格） | 整格碰撞 |
| 2 | `S` | 灯笼/神社柱子（整格） | 整格碰撞 |
| 3 | `A` | 鸟居立柱（窄条，只占中间约 18×44） | 窄条碰撞 |
| 4 | `c` | 水晶/勾玉（装饰，不碰撞） | 无 |
| 5 | `b` | 竹子/灌木（装饰，不碰撞） | 无 |

```
Pixel art tileset sheet, exactly 6 square tiles in one horizontal row, each tile 64x64 pixels, top-down view. In order from left to right: (1) a weathered stone wall segment, (2) a wooden crate, (3) a stone shrine pillar with a glowing paper lantern, (4) a tall narrow red torii gate post with cyan neon energy running up it, (5) a floating cyan crystal / magatama gem, (6) a bamboo bush. Japanese ninja village style corrupted by technology: cyan neon accents on all tiles, dark navy and warm wood tones. Each tile fills its full 64x64 cell edge to edge. Crisp pixels, pixel art, 16 colors, no anti-aliasing, no blur, no text, no watermark, no border between tiles.
```

### 6. `tech_floor_wa.png` — 和风地面（256×256，无缝平铺）

```
Seamless tileable pixel art ground texture, 256x256, top-down view. Japanese stone paving of a ninja village at night: irregular grey flagstones with moss, scattered pink cherry blossom petals, and thin glowing cyan circuit cracks running through the stone like technology is infecting the ground. Dark, low contrast, designed to sit behind characters without distracting. The texture must tile seamlessly in all directions. Crisp pixels, pixel art, 16 colors, no anti-aliasing, no blur, no text, no watermark, no border, no vignette.
```

---

## 三、下一轮（等上面接入后再说）

### 图标统一（和风化）
- `card_chain_lightning.png` —— **当前是手里剑占位**，要正式画一张（雷电/注连绳风格）
- 8 张 `card_*.png` 重画成和风 + 科技统一风格
- `icon_coin`（铜钱）/ `icon_gem`（勾玉）/ `icon_chest`（唐柜）/ `icon_shuriken`

### 其他
- `title_logo.png` —— 标题 Logo（含中文"不退"；模型写中文字成功率低，可后置）
- `sakura_particle.png` —— 樱花花瓣粒子（单帧，洋红底）

---

## 四、视频清单（先只做 1 个，验证技术可行性）

> **重要**：Godot 的 `gl_compatibility` 渲染器 + Web 版对视频支持有限。
> 所以**先只做 `menu_loop` 一个**，我验证在 Windows / Web 都能播之后，再批量做其余两个。
> 如果播不了，我会改用**序列帧（PNG 序列）**或代码动画替代。

### 1. `menu_loop.mp4` — 主菜单循环背景（**先做这个**）

| 项 | 要求 |
|---|---|
| 时长 | 8~15 秒 |
| 分辨率 | 1920×1080 |
| 格式 | MP4 / H.264 |
| 循环 | **首尾帧必须能无缝衔接**（结尾 = 开头） |
| 内容 | 基于 `menu_bg` 的镜头缓慢横移 + 樱花飘落 + 霓虹闪烁 + 机械虫爬动 |
| 构图 | **左侧 1/3 保持暗且空旷**（标题按钮压在上面） |

```
Pixel art animated loop, Japanese ninja village at night invaded by technology, slow horizontal camera pan from left to right, cherry blossom petals drifting across the frame, cyan neon cables pulsing softly, small mechanical insect drones crawling slowly over wooden buildings and a large red torii gate. Dark navy and black palette with cyan neon glow and pink sakura accents. The left third of the frame stays dark and empty. Seamless loop, first and last frame must match exactly. Crisp pixels, pixel art aesthetic, no text, no watermark, no characters in the foreground, 16:9.
```

### 2. `logo_intro.mp4` — 开场 Logo 动画（**验证通过后再做**）
- 3~5 秒，1920×1080
- 结尾定格在标题；背景纯黑（方便叠加）
- 内容：忍者刀光划开画面 → 霓虹裂纹蔓延 → 标题浮现

### 3. `death_slowmo.mp4` — 死亡演出（**验证通过后再做**）
- 2~3 秒，1920×1080
- 红白闪 + 慢镜头感；结尾可衔接结算界面

---

## 五、交付清单（本轮）

| # | 文件名 | 尺寸 | 张数 |
|---|---|---|---|
| 1 | `menu_bg.jpg` | 1920×1080 | 1 |
| 2 | `gameover_bg.jpg` | 1920×1080 | 1 |
| 3 | `victory_bg.jpg` | 1920×1080 | 1 |
| 4 | `cover.jpg` | 1920×1080 | 1 |
| 5 | `tileset_wa.png` | 384×64（6 格） | 1 |
| 6 | `tech_floor_wa.png` | 256×256 无缝 | 1 |
| 7 | `menu_loop.mp4` | 1920×1080 / 8~15s | 1（视频，先验证） |

**一张一张生成、一张一张命名**，我接入时就不会错位。
