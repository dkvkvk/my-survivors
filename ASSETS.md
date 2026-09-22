# 图片素材清单（ASSETS）

> 项目《不退》全部图片素材的**权威清单**：尺寸、用途、代码引用点、状态。
> 生成新素材前先看这里，避免重复或错位。
> **最后更新：2026-09-21 —— 全部美术已换成中国修仙素材（AI 生成，管线见第四节）。**

## 一、当前已接入（共 44 个）

### 主角

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/hero/ninja_sheet.png` | 64×64 | `hero.gd` | **4×4 方向表**，16px/格：列=下0 上1 左2 右3，行 0-3=行走帧。AI 生成（模型给的是 8×4 网格，接入时取第 1/3/5/7 列）。⚠️ 左向列由代码镜像右向列 |
| `assets/hero/shadow.png` | 12×8 | `hero.gd` | 脚下阴影 |

### 敌人（每只两帧，代码按 `balance.gd` 的 sprites 路径加载）

| 文件 | 尺寸 | 变体 | 主色 |
|---|---|---|---|
| `assets/mobs/mech_slime_0/1.png` | 56×18 | slime 百足虫 | 墨玉绿 + 琥珀足尖 |
| `assets/mobs/mech_bat_0/1.png` | 56×24 | runner 阴风鸮 | 靛紫 + 月白面盘 |
| `assets/mobs/mech_knight_0/1.png` | 30×24 | tank 蛮石傀 | 苔青石 + 铜锈符光 |
| `assets/mobs/mech_beast_0/1.png` | 52×24 | elite 赤目狼妖 | 棕墨毛 + 朱红目 |
| `assets/mobs/boss_0/1.png` | 56×34 | 妖王·血瞳魔君 | 玄炭甲壳 + 血瞳 |

> ⚠️ 每对两帧**必须同尺寸同画布**（接入脚本会统一缩放、统一量化，避免两帧调色板漂移）。
> ⚠️ 怪物贴图**不做水平翻转**（代码不翻），所以朝向是固定的：现有素材统一朝左。
> ⚠️ 飞剑弹体（`icon_shuriken.png`）必须**朝右**——弹体按速度方向旋转，朝左会"倒着飞"。

### 地图

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/tiles/tileset.png` | 384×64 | `chunk_map.gd` | **横排 6 格 @64px**：0 寨墙 1 货箱 2 丹炉 3 灵幡 4 灵石 5 竹丛<br>⚠️ **挡路的 0-3 已加接触阴影+2px 暗描边+顶部青色边缘光并提亮 1.3x；可穿的 4-5 保持平贴无阴影** —— 这是"一眼区分地面/遮挡"的视觉语言，改图后必须重跑 `python tools/postprocess_tiles.py` |
| `assets/ground/tech_floor.png` | 256×256 | `survivors_game.tscn` | **无缝平铺**青石板山径（`tilecheck` 双向 SEAMLESS），游戏里按 1024px 网格吸附、scale 4 |

### UI — 法宝图标（4 张，`weapons.gd` 引用）

| 文件 | 尺寸 | 对应法宝 |
|---|---|---|
| `assets/ui/icon_fa_sword.png` | 32×32 | 本命飞剑 |
| `assets/ui/icon_fa_ring.png` | 32×32 | 周天剑环 |
| `assets/ui/icon_fa_fire.png` | 32×32 | 离火法环 |
| `assets/ui/icon_fa_talisman.png` | 32×32 | 连环雷符 |

### UI — 神通图标（4 张，`skills.gd` 引用）

| 文件 | 尺寸 | 对应神通 |
|---|---|---|
| `assets/ui/skill_shuriken.png` | 64×64 | 万剑归宗 |
| `assets/ui/skill_orbit_blade.png` | 64×64 | 剑气纵横 |
| `assets/ui/skill_aura.png` | 64×64 | 大日焚天 |
| `assets/ui/skill_chain_lightning.png` | 64×64 | 九天神雷 |

### UI — 悟道卡图标（5 张，`upgrades.gd` 引用）

| 文件 | 尺寸 | 对应道法 |
|---|---|---|
| `assets/ui/card_speed.png` | 22×22 | 缩地成寸 |
| `assets/ui/card_fire_rate.png` | 22×22 | 疾剑诀 |
| `assets/ui/card_damage.png` | 22×22 | 剑气加身（源图刀身底部被切，接入时取上半段） |
| `assets/ui/card_max_health.png` | 22×22 | 固本培元 |
| `assets/ui/card_magnet.png` | 22×22 | 聚灵引 |

### UI — 掉落物图标

| 文件 | 尺寸 | 引用处 | 对应物品 |
|---|---|---|---|
| `assets/ui/icon_coin.png` | 10×11 | `coin.gd` | 灵石 |
| `assets/ui/icon_chest.png` | 12×10 | `chest.gd` | 藏宝匣 |
| `assets/ui/icon_gem.png` | 9×12 | `xp_gem.tscn` | 灵珠 |
| `assets/ui/icon_shuriken.png` | 16×16 | `bullet_2d.gd` | 本命飞剑弹体（**朝右**） |
| `assets/ui/icon_weapon_drop.png` | 32×32 | `weapon_drop.gd` | 法宝掉落（金光+剑） |

### UI — 炼材图标

| 文件 | 尺寸 | 引用处 | 对应物品 |
|---|---|---|---|
| `assets/ui/icon_material_scrap.png` | 32×32 | `weapons.gd` MATERIALS | 玄铁 |
| `assets/ui/icon_material_crystal.png` | 32×32 | `weapons.gd` MATERIALS | 雷魄 |
| `assets/ui/icon_skill_book.png` | 32×32 | `pickup_drop.gd` | 神通残卷 |

### UI — 背景大图

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/ui/menu_bg.png` | 1920×1080 | `main_menu.tscn` | 主菜单：青冥山夜景（山脚镇灯火 / 山腰观宇长明灯 / 山顶镇渊柱青光 / 西北一线裂痕） |
| `assets/ui/gameover_bg.png` | 1920×1080 | `survivors_game.tscn` | 道陨：断剑插在石径上、剑穗散开、妖雾漫来 |
| `assets/ui/victory_bg.png` | 1920×1080 | `survivors_game.tscn` | 黎明：晨光劈开山雾、镇渊柱染金 |
| `assets/ui/cover.png` | 1920×1080 | **未引用** | 宣传封面备用 |

### 特效（`assets/fx/`，本项目脚本程序化生成 = 自制 CC0）

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/fx/glow_64.png` | 64×64 | `vfx.gd` | 径向光晕（剑光 / 升级光柱 / 通用发光），7 级色阶量化 → 像素硬边 |
| `assets/fx/star_64.png` | 64×64 | `vfx.gd` | 四角星芒（命中爆点 / 拾取 / 升级爆散） |
| `assets/fx/spark_32.png` | 32×32 | `vfx.gd` | 火花小菱形（CPUParticles2D 粒子贴图） |
| `assets/fx/smoke_64.png` | 64×64 | `vfx.gd` | 噪声软烟团（斩妖 / 爆炸烟） |

> 特效贴图风格中性，修仙化时**整体保留**；换风格时改 `vfx.gd` 里的路径即可。

### 其他

| 文件 | 尺寸 | 说明 |
|---|---|---|
| `icon.png` | 128×128 | 项目/窗口图标（`project.godot` 的 `config/icon`） |

---

## 二、素材来源与许可

见 `NOTICE.md`。要点：**人物/怪物/瓦片/图标/背景 = AI 生成**（提示词见 `XIANXIA_ART_PROMPTS.md`）；
**特效贴图 = 本项目脚本自制 CC0**；字体 = Fusion Pixel（OFL）。

---

## 三、命名与规格约定

1. **一条提示词只出一张图**，图里只有一个素材（多素材挤一张会导致错位，已踩过坑）。
2. **单体精灵/图标**：纯洋红底 `#FF00FF`，无阴影/地面/渐变。
3. **无缝瓦片/地面**：不要洋红底，铺满整张，`seamless tileable`。
4. **背景大图**：不要出现文字（标题游戏内渲染，方便改名）。
5. **两帧动画**：两帧同尺寸同构图，只改姿势；用"参考图改姿势"而不是重新描述。
6. **怪物要"精怪"不要"腐尸"**：材质器物化（漆/玉/铜/釉/绸/符），一物一亮点，红只属于危险。
7. 生成后放 `E:\games\`，按上表文件名命名（.jpg/.png 都行），我负责抠底/像素化/接入。

## 四、接入流程（`tools/import_ai_art.py`）

`@bash
python tools/import_ai_art.py            # 全部
python tools/import_ai_art.py 图标 怪物   # 只做某几组
`@

管线做的事（**不要用"整图缩放"**：那会让每张图的画布变成生图模型的 16:9，精灵会飘/大小乱跳）：

`@
E:/games/xxx.jpg
  → 洋红抠底（容忍 JPEG 压缩偏移）+ 内容掩码内收 1px 切掉洋红边
  → bbox 裁剪
  → 等比装进目标 box（缩比 <0.35 用 BOX，否则 LANCZOS）
  → 两帧拼一起统一量化（避免两帧调色板漂移）
  → 居中（图标）/ 底部对齐（精灵）放到目标画布
  → 覆盖 assets/ 下对应文件
  → tileset 额外跑 tools/postprocess_tiles.py（阴影/描边）
  → headless 验证 + 实机截图确认
`@

> 接入后**务必实机截图核对**：是谁在用这张图、比例对不对、脚底有没有落地。
> 规格表就在脚本末尾的 `ICONS / MOBS / BGS / BULLET` 里，改素材只改那张表。
