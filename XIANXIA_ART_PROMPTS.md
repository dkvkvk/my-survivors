# 修仙化 · 生图清单（配套 WORLDVIEW.md / REFACTOR_XIANXIA.md）

> 状态：**待世界观确认后开始生成**。生成后放 `E:\games\`，按文件名命名（可加 `_raw` 后缀），
> 我负责抠底 / 像素化 / 缩放 / 接入 / 实机截图验证 / 删除原图。

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

## 一、主角（1 张 · 最难 · 建议最后做）

### 1. `ninja_sheet.png` —— 守山人行走表
- **目标**：64×64（4×4 网格，每格 16×16），1:1
- **用途**：`hero.gd` 按 16px 切帧；列 = 朝向（下0 上1 左2 右3），行 0-3 = 行走帧
- **提示词**：

```text
pixel art sprite sheet, exact 4x4 grid of 16 frames, each frame a small 16x16 pixel character:
a young Chinese cultivator (xianxia hero) walking. dark teal-blue robe with black trim,
a small red hair ribbon trailing behind his head, a flat sword case on his back, dark shoes.
columns = facing direction: column 1 walking facing down (front), column 2 facing up (back),
column 3 facing left, column 4 facing right. rows = 4-frame walk cycle with alternating legs.
chunky pixels, limited palette, consistent size and framing in all 16 frames.
solid magenta background (#FF00FF), pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

- ⚠️ **只要"右向"那一列画得可靠就够了**——代码会用右列镜像出左向（历史坑：左列帧间朝向乱跳）。
  如果生成 4 列质量不稳，可以只生成"单列 4 帧行走（面朝右）×1 张"交给我，我拼接成表。

---

## 二、小妖（4 种 × 2 帧 = 8 张）

> 先出第 1 帧，确认满意后用**参考图改姿势**出第 2 帧。两帧必须同尺寸同构图。

### 2. `mech_slime_0.png` / `mech_slime_1.png` —— 百足虫（对应"机械史莱姆"位；断而不僵）
- **目标**：~48×20（长而低；生成大图我缩）
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a demon centipede: long low segmented body, dark violet-green chitin
plates, a dense comb of small pale legs along both sides, two thin antennae reaching forward,
two small sickly-green glowing eye dots, crawling pose seen from the side,
color palette: dark ink-blue night, dark violet-green plates, sickly green (#4F7A4A) accents,
NO red anywhere,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean silhouette, no text, no watermark, no border
```

- **第 2 帧**：同上 + `body undulating in a crawl cycle, legs rippling, antennae tilted the other way`

### 3. `mech_bat_0.png` / `mech_bat_1.png` —— 阴风鸮（对应"机械蝙蝠"位，会飞·穿墙·俯冲）
- **目标**：~54×24
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a night-owl demon: crow-blue owl with wide spread wings,
small sharp beak, two dead-white glowing eye dots, faint dark mist trailing off wing tips,
flying, seen from the side,
color palette: dark ink-blue body, pale white eyes, faint violet (#6A3D8F) mist,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean silhouette, no text, no watermark, no border
```

- **第 2 帧**：同上 + `wings folded, tucked into a steep dive pose`

### 4. `mech_knight_0.png` / `mech_knight_1.png` —— 蛮石傀（对应"重甲兵"位，肉厚·撞墙开路）
- **目标**：~26×24（矮壮）
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a stone golem made of an old moss-covered boundary stone:
short stocky body of grey rock, thick moss patches on shoulders and back, tiny deep-set glowing eyes,
heavy blunt arms, mid-stride walking pose, seen from the side,
color palette: dark grey stone, dark green moss, dim yellow-green eye glow,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean silhouette, no text, no watermark, no border
```

- **第 2 帧**：同上 + `other leg forward, body leaning harder into the step`

### 5. `mech_beast_0.png` / `mech_beast_1.png` —— 赤目狼妖（对应"魔化野兽"位，扑杀）
- **目标**：~48×24
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a gaunt demonic wolf: lean rib-thin body, spiky spine fur,
two glowing crimson-red eyes, running pose with legs stretched, seen from the side,
color palette: dark grey-brown fur, crimson (#C33B2F) glowing eyes,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean silhouette, no text, no watermark, no border
```

- **第 2 帧**：同上 + `gallop stride, body stretched longer, front paws reaching`

---

## 三、妖王（2 张）

### 6. `boss_0.png` / `boss_1.png` —— 妖王 · 血瞳魔君
- **目标**：~52×32（生成大图我缩）
- **提示词（第 1 帧）**：

```text
pixel art game boss, a towering demon brute: hulking ash-grey body with cracked skin,
one single huge blood-red glowing eye in the chest, two curved horns, long arms with claws,
tattered dark cloth around the waist, ominous crimson mist seeping from its feet,
standing heavy, seen from the side,
color palette: ash grey body, deep crimson (#C33B2F) eye glow, dark ink-blue night mood,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean silhouette, no text, no watermark, no border
```

- **第 2 帧**：同上 + `lunging forward, arms swung back, eye burning brighter`

---

## 四、地图（2 张）

### 7. `tileset.png` —— 瓦片集（6 格横排，规格严格）
- **目标**：384×64（6 格 × 64×64），比例 6:1
- **用途**：`chunk_map.gd`；索引必须按此顺序：**0 寨墙 / 1 货箱 / 2 丹炉 / 3 灵幡 / 4 灵石 / 5 竹丛**
  （0-3 挡路、4-5 可穿行——顺序错了碰撞就全错）
- **提示词**：

```text
pixel art tileset strip, exactly SIX distinct objects in one horizontal row, each object centered
in its own square cell, equal spacing, 6:1 wide strip:
1) a segment of grey stone village wall, 2) a wooden supply crate bound with straw rope,
3) a three-legged bronze alchemy furnace with a small ember glow at its mouth,
4) a tall wooden pole with a hanging yellow paper-talisman banner (narrow object),
5) a small cluster of glowing jade-cyan spirit stone crystals on the ground (low, flat),
6) a cluster of thin bamboo stalks (low, flat).
color palette: dark ink-blue night, grey stone, brown wood, bronze, jade-cyan (#55E0C8) glow,
gold accents. each object fully visible and not touching its neighbors,
solid magenta background (#FF00FF), pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

- ⚠️ 接入后我会重跑 `python tools/postprocess_tiles.py`（挡路瓦片自动加接触阴影+描边+边缘光），无需在图里画阴影。

### 8. `tech_floor.png` —— 无缝地面：青石板山径（夜）
- **目标**：256×256，无缝
- **提示词**：

```text
seamless tileable pixel art texture, top-down view of an ancient Chinese mountain village
stone path at night: dark blue-grey flagstones with irregular edges, thin moss in the cracks,
a few tiny jade-cyan spirit light specks, subtle wear and pebbles,
dark ink-blue night palette (#0E1420 to #1A2333) with sparse jade-cyan (#55E0C8) accents,
fills the entire canvas, perfectly seamless on all four edges,
pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border, no magenta
```

---

## 五、图标（17 张 + 可选 4 张）

> 全部 1:1、单图标、洋红底。目标尺寸由我缩放，生成 64×64 或更大均可。

### 掉落物

| # | 文件 | 内容 | 提示词要点 |
|---|---|---|---|
| 9 | `icon_coin.png` | 灵石 | a single cut spirit-stone crystal, jade-cyan with inner glow |
| 10 | `icon_chest.png` | 藏宝匣 | a small ornate Chinese treasure chest, dark wood with gold bands |
| 11 | `icon_gem.png` | 灵珠 | a single round glowing spirit orb, jade-cyan, tiny sparkle |
| 12 | `icon_shuriken.png` | **飞剑（弹体）** | a single small flying sword seen from the side, pointing RIGHT, white blade, red tassel |
| 13 | `icon_weapon_drop.png` | 法宝掉落 | a small floating flying sword treasure radiating soft glow |

⚠️ 12 号是**全屏高频出现的弹体**，务必侧面朝右（代码按朝向旋转）、轮廓干净。

**示例（12 号完整提示词，其余同格式替换"内容"一句即可）：**

```text
pixel art game asset icon, a single small flying sword seen from the side, pointing to the right,
slim white-steel blade with a bright edge, small gold guard, short red tassel,
clean readable silhouette on dark backgrounds,
solid magenta background (#FF00FF), single object only,
pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

### 悟道卡（5 张）

| # | 文件 | 内容 | 提示词要点 |
|---|---|---|---|
| 14 | `card_speed.png` | 缩地成寸 | a pair of straw sandals with wind streaks behind them |
| 15 | `card_fire_rate.png` | 疾剑诀 | a flying sword with sharp speed lines |
| 16 | `card_damage.png` | 剑气加身 | a sword blade edge glowing with white sharp energy |
| 17 | `card_max_health.png` | 固本培元 | a small Chinese medicine gourd with a red seal |
| 18 | `card_magnet.png` | 聚灵引 | a swirl of spirit energy pulling glowing orbs inward |

### 神通（4 张，64×64）

| # | 文件 | 内容 | 提示词要点 |
|---|---|---|---|
| 19 | `skill_shuriken.png` | 万剑归宗 | many small flying swords bursting outward radially from center |
| 20 | `skill_orbit_blade.png` | 剑气纵横 | a ring of flying swords spinning around a center point |
| 21 | `skill_aura.png` | 大日焚天 | a blazing golden sun disc with a ring of flame |
| 22 | `skill_chain_lightning.png` | 九天神雷 | a vertical lightning bolt striking down with branching arcs |

### 炼材与残卷（3 张）

| # | 文件 | 内容 | 提示词要点 |
|---|---|---|---|
| 23 | `icon_material_scrap.png` | 玄铁 | a chunk of dark raw iron ore with a faint cold glint |
| 24 | `icon_material_crystal.png` | 雷魄 | a violet-blue crystal shard crackling with tiny static arcs |
| 25 | `icon_skill_book.png` | 神通残卷 | a partially unrolled yellowed parchment scroll with a red seal |

### 可选：4 法宝专属图标（武器表现在复用旧卡图，趁机补齐）

| # | 文件 | 内容 |
|---|---|---|
| 26 | `icon_fa_sword.png` | 本命飞剑（竖置，剑穗垂下） |
| 27 | `icon_fa_ring.png` | 周天剑环（小剑围成的环） |
| 28 | `icon_fa_fire.png` | 离火法环（一圈橙金火焰环） |
| 29 | `icon_fa_talisman.png` | 连环雷符（黄纸符 + 电弧） |

---

## 六、背景（4 张，1920×1080，16:9，**无洋红底、无文字**）

### 30. `menu_bg.png` —— 主菜单 · 青冥山夜景全景

```text
pixel art game background, 16:9 wide night vista of a Chinese cultivation mountain:
at the foot, a small quiet village with a few warm lantern lights and one brightly lit shop;
halfway up the slope, a lonely temple hall with a single ever-burning lamp;
on the peak, a tall grey pillar rising into the clouds with a thin jade-cyan light beam;
dark ink-blue night sky with a faint crack of dim red light in the upper-left sky,
pine tree silhouettes, drifting mist,
color palette: dark ink-blue night (#0E1420), jade-cyan glow (#55E0C8), warm gold lantern light,
pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

### 31. `gameover_bg.png` —— 道陨

```text
pixel art game background, 16:9: a fallen cultivator lying on a mountain stone path at night,
his flying sword dropped beside him with its red tassel loose, pale green demon mist creeping
in from the edges of the frame, dark desaturated ink-blue palette with faint sickly green,
the thin crack in the sky slightly brighter than before, melancholic and quiet,
pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

### 32. `victory_bg.png` —— 黎明

```text
pixel art game background, 16:9: dawn breaking over a Chinese mountain ridge,
first golden sunlight spilling across the stone path and low clouds,
the last wisps of green demon mist dissolving in the light, a tall grey pillar silhouette
on the far peak catching the first light, hopeful and calm,
color palette: deep blue night fading into warm gold dawn,
pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

### 33. `cover.png` —— 宣传封面

```text
pixel art game key art, 16:9: seen from behind, a lone cultivator in a dark teal robe with a red
hair ribbon stands on a mountain stone path, several flying swords orbiting around him,
facing an oncoming tide of small demon silhouettes flowing up the slope below,
a faint crack of red light in the night sky above, dramatic composition, hero small in frame,
color palette: dark ink-blue night, jade-cyan sword glows, crimson sky crack,
pixel art, 16-bit retro game style, crisp pixels, no text, no watermark, no border
```

---

## 七、生成顺序建议

1. **第一批（易、立刻见效）**：图标 9~25 号（17 张）
2. **第二批**：小妖 2~5 号（8 张，两帧成对出）
3. **第三批**：地图 7~8 号（2 张，规格最严）
4. **第四批**：妖王 6 号（2 张）
5. **第五批**：背景 30~33 号（4 张）
6. **最后**：主角表 1 号（最难，留足返工余地；4 列画不好就只出"面朝右一列 4 帧"）

**交付**：放 `E:\games\`，按下表文件名命名（加 `_raw` 后缀也行）→ 告诉我 → 我抠底/像素化/接入/截图验证 → 删原图。
