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

## 二、妖物美术总则（重要：要"精怪"，不要"腐尸"）

玩家一局要成百上千次地盯着这些怪看——**恶心会让人不想玩，精巧的妖怪反而让人愿意看。**
所以所有妖物都按"精怪"来画，不按"尸怪"来画。

**五条硬规矩：**

1. **材质器物化**：往 **漆器 / 玉石 / 铜锈 / 釉面 / 绸缎 / 符纸** 上靠——有光泽、有工艺感；
   不要"烂掉的生物组织"。描述外观时**不要**用 corpse / rotting / gore / pus / slime / blood 这类词；
   只在提示词**句尾**以 NO / NOT 的形式排除它们（写在前面反而容易被模型画出来）。
2. **一物一亮点**：每个妖物只给**一处**夺目之处（琥珀足尖 / 月白面盘 / 铜锈符文 / 朱红独目），其余压低。
   像素小人靠"色块 + 轮廓 + 一点高光"，**不要纹理噪点**。
3. **眼睛是发光小圆点**，不要写实眼球、不要眼白。
4. **红是危险专用**：只有赤目狼妖的目、妖王的瞳、煞气警戒环可以带红，其余妖物**一律不带红**。
5. **体型讨喜**：鸮要圆润、虫要整齐、傀要敦实、狼要修长——**不要瘦骨嶙峋、不要破破烂烂**。

**反例清单（出现即算失败）**：腐肉、血污、脓疮、骷髅、粘液、写实眼球、破布条、伤口。

**妖物配色表**（与玩家色"青碧"明确拉开）：

| 妖物 | 主色 | 亮点 | HEX 参考 |
|---|---|---|---|
| 百足虫 | 墨玉绿（漆面甲节） | 琥珀足尖 + 幽碧眼 | #3E7A5E / #C9962E |
| 阴风鸮 | 靛紫羽 | 月白面盘 + 幽紫眼 | #4A3A6E / #CFE8E0 |
| 蛮石傀 | 苔青石 | 铜锈符文（微光）+ 琥珀眼 | #5E7A6A / #7FC8A0 |
| 赤目狼妖 | 玄墨毛 | 朱红目（唯一红点） | #1E1A24 / #C33B2F |
| 妖王 | 玄炭甲壳 | 暗金云纹 + 血瞳 | #22202A / #8A6B2A / #C33B2F |

---

## 三、小妖（4 种 × 2 帧 = 8 张）

> 先出第 1 帧，确认满意后用**参考图改姿势**出第 2 帧。两帧必须同尺寸同构图。

### 2. `mech_slime_0.png` / `mech_slime_1.png` —— 百足虫（"机械史莱姆"位；断而不僵）
- **目标**：~48×20（长而低；生成大图我缩）
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a demon centipede (baizu): long low body of polished jade-green lacquer
segments, each segment edged with a thin amber line, a neat comb of small amber-tipped legs
along both sides, two slender antennae curling forward, two soft glowing jade-green eyes,
crawling pose seen from the side, elegant and slightly cute, tidy and jewel-like,
color palette: dark ink-blue night, jade-green (#3E7A5E) lacquer plates, amber (#C9962E) leg tips,
soft jade-green eye glow, NO red, NO blood, NO slime, NO gore,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

- **第 2 帧**（把第 1 帧当**参考图**改姿势，别重新描述整体；同尺寸同构图同配色，后缀限制照旧）：`body undulating in a crawl cycle, legs rippling like a wave, antennae tilted the other way`

### 3. `mech_bat_0.png` / `mech_bat_1.png` —— 阴风鸮（"机械蝙蝠"位；会飞·穿墙·俯冲）
- **目标**：~54×24
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a night-owl spirit: plump round-bodied owl with indigo-violet feathers,
a moon-white facial disc, two large soft violet glowing eyes, tiny beak, short wisp of dark
mist trailing from the wing tips, wings spread in flight, seen from the side,
cute and mysterious, NOT scary, NOT gory,
color palette: dark ink-blue night, indigo-violet (#4A3A6E) feathers, moon-white (#CFE8E0) face,
soft violet eye glow, NO red, NO blood,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

- **第 2 帧**（把第 1 帧当**参考图**改姿势，别重新描述整体；同尺寸同构图同配色，后缀限制照旧）：`wings folded tight, tucked into a steep dive`

### 4. `mech_knight_0.png` / `mech_knight_1.png` —— 蛮石傀（"重甲兵"位；肉厚·撞墙开路）
- **目标**：~26×24（矮壮）
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a stone guardian golem: short stocky figure carved from mossy grey-green
stone, dignified simple features like an old mountain boundary statue, shoulders capped with
soft moss, faint patina-green runes carved on its chest and arms, two calm amber-glowing eyes,
heavy blunt arms, mid-stride walking pose, seen from the side, sturdy and noble, NOT rotting,
color palette: dark ink-blue night, mossy grey-green stone (#5E7A6A), patina rune glow (#7FC8A0),
warm amber eyes, NO red, NO blood, NO cracks with gore,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

- **第 2 帧**（把第 1 帧当**参考图**改姿势，别重新描述整体；同尺寸同构图同配色，后缀限制照旧）：`other leg forward, body leaning harder into the step`

### 5. `mech_beast_0.png` / `mech_beast_1.png` —— 赤目狼妖（"魔化野兽"位；扑杀）
- **目标**：~48×24
- **提示词（第 1 帧）**：

```text
pixel art game enemy, a demon wolf: sleek elegant wolf with ink-black fur fading to deep violet
at the paws, a flowing silver-grey back stripe, two glowing cinnabar-red eyes (its ONLY red
feature), running pose with legs stretched, seen from the side, fierce but beautiful,
NOT gaunt, NOT gory, NOT scarred,
color palette: dark ink-blue night, ink-black (#1E1A24) fur, deep violet (#4A3A6E) accents,
cinnabar (#C33B2F) eyes only, NO blood,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

- **第 2 帧**（把第 1 帧当**参考图**改姿势，别重新描述整体；同尺寸同构图同配色，后缀限制照旧）：`gallop stride, body stretched longer, front paws reaching`

---

## 三·五、妖王（2 张）

### 6. `boss_0.png` / `boss_1.png` —— 妖王 · 血瞳魔君
- **目标**：~52×32（生成大图我缩）
- **提示词（第 1 帧）**：

```text
pixel art game boss, a majestic demon lord: towering figure in dark lacquered carapace like
polished black armor, faint dark-gold cloud patterns engraved on the plates, two curved horns,
one single large crimson glowing eye on the chest, a long cloak of black mist pooling at its feet,
standing heavy and imposing, seen from the side, awe-inspiring and beautiful, NOT gory, NOT rotting,
color palette: dark ink-blue night, charcoal-black (#22202A) carapace, faint dark-gold (#8A6B2A)
engraving, crimson (#C33B2F) eye glow only, NO blood, NO wounds,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

- **第 2 帧**（把第 1 帧当**参考图**改姿势，别重新描述整体；同尺寸同构图同配色，后缀限制照旧）：`lunging forward, arms swung back, the eye burning brighter`

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

> 全部 **1:1、单图标、洋红底**；生成 64×64 或更大都可以，我负责缩到目标尺寸。
> 图标同样走"器物"美学：**有光泽、有工艺感**——别画成脏兮兮的碎块。
> 下面每一条都是**完整可复制**的提示词，末尾已带通用后缀。

**通用后缀**（单独使用时记得带上）：

```text
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

---

### 掉落物（5 张）

#### 9. `icon_coin.png` —— 灵石（金币位）
- **目标**：10×11（很小，靠发光辨识）　**用途**：`coin.gd` 掉落物
- **提示词**：

```text
pixel art game asset icon, a single spirit stone: a small cut crystal of pale jade, roughly
faceted, soft jade-cyan light glowing from inside, one tiny white highlight on a facet,
standing upright and centered, clean and valuable-looking,
color palette: pale jade-white body, jade-cyan (#55E0C8) inner glow, a thin gold rim,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 10. `icon_chest.png` —— 藏宝匣（宝箱位）
- **目标**：12×10　**用途**：`chest.gd` 首领掉落
- **提示词**：

```text
pixel art game asset icon, a small Chinese treasure box: dark lacquered wood chest with a
rounded lid, two gold bands around it, a gold cloud-pattern lock plate on the front,
a faint warm gold light seeping from the seam of the lid,
color palette: dark red-brown lacquer, gold (#E8B84A) fittings, warm gold seam glow,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 11. `icon_gem.png` —— 灵珠（经验位）
- **目标**：9×12　**用途**：`xp_gem.tscn`
- **提示词**：

```text
pixel art game asset icon, a single spirit orb: a perfectly round pearl of jade-cyan light,
a bright white core inside a soft cyan halo, two tiny sparkles, floating,
color palette: jade-cyan (#55E0C8) glow and white core only,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 12. `icon_shuriken.png` —— 飞剑（弹体位，全屏高频出现）
- **目标**：16×16　**用途**：`bullet_2d.gd` 弹体、武器表"本命飞剑"图标
- ⚠️ **必须侧面朝右**（代码按朝向旋转），轮廓要极干净——一局要在屏幕上出现几千次。
- **提示词**：

```text
pixel art game asset icon, a single small flying sword seen from the side, pointing to the right,
slim white-steel blade with a bright edge, small gold guard, short red tassel at the pommel,
clean readable silhouette even at very small size,
color palette: white-steel blade, gold (#E8B84A) guard, cinnabar (#B5352C) tassel,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 13. `icon_weapon_drop.png` —— 法宝光华（地上掉的武器）
- **目标**：32×32　**用途**：`weapon_drop.gd`
- **提示词**：

```text
pixel art game asset icon, a small floating flying sword treasure: a slim jade-cyan sword
hovering upright, a soft golden halo behind it, a few tiny light motes rising around it,
readable at very small size,
color palette: jade-cyan (#55E0C8) blade, gold (#E8B84A) halo, white highlights,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

---

### 悟道卡（5 张，约 22×22）

#### 14. `card_speed.png` —— 缩地成寸
- **用途**：`upgrades.gd` speed 卡
- **提示词**：

```text
pixel art game asset icon, a pair of straw sandals with three curved wind streaks behind them,
suggesting instant travel, simple and readable,
color palette: straw yellow-brown sandals, jade-cyan (#55E0C8) wind streaks,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 15. `card_fire_rate.png` —— 疾剑诀
- **用途**：`upgrades.gd` fire_rate 卡
- **提示词**：

```text
pixel art game asset icon, a small flying sword pointing to the upper right with three sharp
speed lines trailing behind it, motion-focused,
color palette: jade-cyan (#55E0C8) blade and speed lines, white edge highlight,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 16. `card_damage.png` —— 剑气加身
- **用途**：`upgrades.gd` damage 卡
- **提示词**：

```text
pixel art game asset icon, a single sword blade seen edge-on with a brilliant white-hot cutting
edge and a few sparks flying off it, sharp and powerful,
color palette: steel-grey blade, white-hot edge glow, jade-cyan (#55E0C8) sparks,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 17. `card_max_health.png` —— 固本培元
- **用途**：`upgrades.gd` max_health 卡
- **提示词**：

```text
pixel art game asset icon, a small Chinese medicine gourd tied with a red cord, a small red
paper seal stuck on its side, a soft warm glow around it, wholesome,
color palette: warm brown gourd, cinnabar (#B5352C) cord and seal, soft warm glow,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 18. `card_magnet.png` —— 聚灵引
- **用途**：`upgrades.gd` magnet 卡
- **提示词**：

```text
pixel art game asset icon, a swirl of jade-cyan spirit energy spiraling inward, drawing three
small glowing orbs toward its center, clean circular composition,
color palette: jade-cyan (#55E0C8) swirl and orbs, white core,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

---

### 神通（4 张，64×64）

#### 19. `skill_shuriken.png` —— 万剑归宗
- **用途**：`skills.gd` shuriken_burst、技能栏
- **提示词**：

```text
pixel art game skill icon, dozens of tiny flying swords bursting outward radially from a bright
center point, like a lotus of blades, energetic and symmetrical,
color palette: jade-cyan (#55E0C8) blades, white center flash,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 20. `skill_orbit_blade.png` —— 剑气纵横
- **用途**：`skills.gd` blade_storm
- **提示词**：

```text
pixel art game skill icon, a ring of six small flying swords spinning around an empty center,
each blade tilted along the circle, a faint motion arc behind them,
color palette: jade-cyan (#55E0C8) blades and motion arc, white edge highlights,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 21. `skill_aura.png` —— 大日焚天
- **用途**：`skills.gd` sunburst
- **提示词**：

```text
pixel art game skill icon, a blazing sun disc: a bright golden core surrounded by a ring of
stylized flame tongues, radiant, warm and symmetrical,
color palette: gold (#E8B84A) flames, white-hot core, a thin cinnabar (#C33B2F) outer rim,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 22. `skill_chain_lightning.png` —— 九天神雷
- **用途**：`skills.gd` thunder
- **提示词**：

```text
pixel art game skill icon, a thick vertical lightning bolt striking straight down, three smaller
branches arcing off it, brilliant white core with cyan-white glow, symmetrical,
color palette: white core, jade-cyan (#55E0C8) glow, deep blue-violet (#3A3A6E) outline,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

---

### 炼材与残卷（3 张，32×32）

#### 23. `icon_material_scrap.png` —— 玄铁
- **用途**：`weapons.gd` MATERIALS.scrap
- **提示词**：

```text
pixel art game asset icon, a chunk of raw dark iron ore: an angular black-blue lump with one
cold metallic glint on a sharp edge, a few tiny iron filings beside it,
color palette: black-blue iron, cold white glint, no warm colors,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 24. `icon_material_crystal.png` —— 雷魄
- **用途**：`weapons.gd` MATERIALS.crystal
- **提示词**：

```text
pixel art game asset icon, a single thunder-soul crystal shard: a violet-blue faceted shard
standing upright, two tiny white static arcs crackling around its tip,
color palette: violet-blue (#5A5AB4) crystal, white static arcs, faint cyan glow,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 25. `icon_skill_book.png` —— 神通残卷（技能切换书）
- **用途**：`pickup_drop.gd` kind = book
- ⚠️ 别让模型写汉字：用**抽象笔触**表示字迹。
- **提示词**：

```text
pixel art game asset icon, a partially unrolled ancient scroll: yellowed paper with a torn edge,
a red wax seal, a few abstract dark ink brush strokes (no readable characters), one corner curled,
color palette: aged paper cream, cinnabar (#B5352C) seal, dark ink strokes,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

---

### 可选：4 件法宝专属图标（32×32）

> 现在武器表复用的是旧卡图标，趁机补齐 4 张专属的（`weapons.gd` 里把 icon 指过来即可）。

#### 26. `icon_fa_sword.png` —— 本命飞剑

```text
pixel art game asset icon, a single Chinese flying sword standing upright, slim jade-cyan blade,
small gold guard, a red tassel hanging from the pommel, soft glow along the edge,
color palette: jade-cyan (#55E0C8) blade, gold (#E8B84A) guard, cinnabar (#B5352C) tassel,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 27. `icon_fa_ring.png` —— 周天剑环

```text
pixel art game asset icon, five small flying swords arranged in a perfect circle, all blades
pointing outward, connected by a faint jade-cyan thread of light,
color palette: jade-cyan (#55E0C8) blades and thread, white highlights,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 28. `icon_fa_fire.png` —— 离火法环

```text
pixel art game asset icon, a ring of stylized orange-gold alchemy flame forming a perfect circle,
hollow center, a few flame tongues licking outward,
color palette: orange-gold flame, white-hot inner edge,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 29. `icon_fa_talisman.png` —— 连环雷符

```text
pixel art game asset icon, a single yellow paper talisman strip with a bold red thunder sigil
painted on it, two tiny white lightning arcs jumping off its corners,
color palette: paper yellow, cinnabar (#B5352C) sigil, white arcs, faint cyan glow,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

---

### P6 补充图标（2 件法宝 + 2 个神通，**当前是代码生成的占位，可随时替换**）

> 第 5/6 把法宝（回风梭 / 地火符阵）的图标暂时由 `tools/gen_weapon_icons.py` 用代码绘制，
> 风格与上面 4 张同规格（32×32 / 64×64、1px 暗描边）。想要更精细就按下表生成后**覆盖同名文件**，
> 不用改任何代码（`weapons.gd` / `skills.gd` 里的路径已经指向它们）。

#### 30. `icon_fa_boomerang.png` —— 回风梭（32×32）

```text
pixel art game asset icon, a single jade-cyan boomerang seen from the side, two tapered arms with
sharp pointed tips meeting at a thick elbow, a thin white highlight along the upper edge, two short
pale-cyan wind streaks trailing below it,
color palette: jade-cyan (#55E0C8) body, deeper teal (#2E9E9C) shade, white highlight,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 31. `icon_fa_mine.png` —— 地火符阵（32×32）

```text
pixel art game asset icon, a hexagonal dark iron rune plate seen from above, its center holding a
bright paper-yellow talisman face with a bold cinnabar-red thunder sigil, three tiny gold sparks
floating around the rim,
color palette: dark slate steel (#4E5C6E) plate, paper yellow (#FFD98A) face, cinnabar (#B5352C) sigil,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 32. `skill_boomerang.png` —— 风卷残云（64×64）

```text
pixel art game skill icon, one large jade-cyan boomerang spinning at the center with three pairs of
short pale wind streaks sweeping outward on both sides, thin motion arcs behind it,
color palette: jade-cyan (#55E0C8) body, deeper teal (#2E9E9C) shade, white highlights, dark ink-blue outline,
solid magenta background (#FF00FF), single object only, pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

#### 33. `skill_mine.png` —— 十方雷网（64×64）

```text
pixel art game skill icon, six small iron rune mines arranged in a hexagon ring, connected to each other
by crackling pale-cyan lightning lines, a larger bright rune core in the middle,
color palette: dark slate steel (#4E5C6E), paper yellow (#FFD98A), cinnabar (#B5352C) sigils,
jade-cyan (#55E0C8) lightning, dark ink-blue outline,
solid magenta background (#FF00FF), pixel art, 16-bit retro game style,
crisp pixels, clean readable silhouette, no text, no watermark, no border
```

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
