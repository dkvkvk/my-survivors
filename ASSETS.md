# 图片素材清单（ASSETS）

> 项目《不退》全部图片素材的**权威清单**：尺寸、用途、代码引用点、状态。
> 生成新素材前先看这里，避免重复或错位。最后更新：2026-09-21

## 一、当前已接入（共 32 个）

### 主角

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/hero/ninja_sheet.png` | 64×64 | `hero.gd` | **4×4 方向表**，16px/格：列=下0 上1 左2 右3，行 0-3=行走帧。Ninja Adventure CC0 |
| `assets/hero/shadow.png` | 12×8 | `hero.gd` | 脚下阴影 |

### 敌人（每只两帧，代码按 `balance.gd` 的 sprites 路径加载）

| 文件 | 尺寸 | 变体 | 颜色 |
|---|---|---|---|
| `assets/mobs/mech_slime_0/1.png` | 49×24 | slime 史莱姆 | 青绿 |
| `assets/mobs/mech_bat_0/1.png` | 54×24 | runner 机械蝙蝠 | 紫 |
| `assets/mobs/mech_knight_0/1.png` | 26×24 | tank 重甲兵 | 钢灰 |
| `assets/mobs/mech_beast_0/1.png` | 48×24 | elite 魔化野兽 | 猩红 |
| `assets/mobs/boss_0/1.png` | 52×32 | 首领 | 深灰+红核心 |

> ⚠️ 每对两帧**必须同尺寸**（高度尤其要一致）。宽度可以不同——那是动画本身（蝙蝠扇翅、史莱姆压扁）。

### 地图

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/tiles/tileset.png` | 384×64 | `chunk_map.gd` | **横排 6 格 @64px**，索引即字符：0墙# 1货箱C 2服务器S 3天线A 4水晶c 5灌木b |
| `assets/ground/tech_floor.png` | 256×256 | `survivors_game.tscn` | **无缝平铺**地面，游戏里按 1024px 网格吸附 |

### UI — 升级卡图标（8 张，`upgrades.gd` 引用）

| 文件 | 尺寸 | 对应卡 |
|---|---|---|
| `assets/ui/card_speed.png` | 21×21 | 疾风之靴 |
| `assets/ui/card_magnet.png` | 22×20 | 磁力护符 |
| `assets/ui/card_fire_rate.png` | 21×21 | 灵巧扳机 |
| `assets/ui/card_max_health.png` | 21×22 | 生命祝福 |
| `assets/ui/card_damage.png` | 45×20 | 重装弹药 |
| `assets/ui/card_orbit_blade.png` | 21×22 | 环形刀刃 |
| `assets/ui/card_aura.png` | 21×21 | 灼热光环 |
| `assets/ui/card_split_shot.png` | 22×20 | 分裂弹头 |
| `assets/ui/card_chain_lightning.png` | 16×16 | 链式闪电（**暂用手里剑占位**） |
| `assets/ui/star.png` | 21×21 | 备用（未引用） |

### UI — 掉落物图标

| 文件 | 尺寸 | 引用处 | 对应物品 |
|---|---|---|---|
| `assets/ui/icon_coin.png` | 10×11 | `coin.gd` | 金币 |
| `assets/ui/icon_chest.png` | 12×10 | `chest.gd` | 宝箱 |
| `assets/ui/icon_gem.png` | 9×12 | `xp_gem.tscn` | 经验宝石 |
| `assets/ui/icon_shuriken.png` | 16×16 | `bullet_2d.gd` | 手里剑弹体 |

### UI — 背景大图

| 文件 | 尺寸 | 引用处 | 说明 |
|---|---|---|---|
| `assets/ui/menu_bg.png` | 1920×1080 | `main_menu.tscn` | 主菜单背景 |
| `assets/ui/gameover_bg.png` | 1920×1080 | `survivors_game.tscn` | 失败结算背景（**胜利结算暂时复用这张**） |
| `assets/ui/cover.png` | 1920×1080 | **未引用** | 宣传封面备用 |

### 其他

| 文件 | 尺寸 | 说明 |
|---|---|---|
| `icon.png` | 128×128 | 项目/窗口图标（`project.godot` 的 `config/icon`） |

---

## 二、待生成（提示词见 `ART_PROMPTS.md`）

### 本轮（和风忍者村 + 科技入侵）

| # | 文件名 | 尺寸 | 用途 | 状态 |
|---|---|---|---|---|
| 1 | `menu_bg.jpg` | 1920×1080 | 主菜单背景（左侧 1/3 留空） | ⬜ 待生成 |
| 2 | `gameover_bg.jpg` | 1920×1080 | 失败结算 | ⬜ 待生成 |
| 3 | `victory_bg.jpg` | 1920×1080 | 胜利结算 | ⬜ 待生成 |
| 4 | `cover.jpg` | 1920×1080 | 宣传封面 | ⬜ 待生成 |
| 5 | `tileset_wa.png` | 384×64 | 和风瓦片集（6 格，按顺序） | ⬜ 待生成 |
| 6 | `tech_floor_wa.png` | 256×256 | 和风无缝地面 | ⬜ 待生成 |
| 7 | `menu_loop.mp4` | 1920×1080 | 主菜单循环视频 | ⬜ 待生成（先验证可行性） |

### 下一轮

| 文件名 | 用途 |
|---|---|
| `card_chain_lightning.png` | 链式闪电正式图标（现为占位） |
| 8 张 `card_*.png` 重画 | 和风+科技统一风格 |
| `icon_coin/chest/gem/shuriken` 重画 | 和风化（铜钱/唐柜/勾玉） |
| `title_logo.png` | 标题 Logo（含中文，成功率低，可后置） |
| `sakura_particle.png` | 樱花花瓣粒子（洋红底） |

---

## 三、命名与规格约定

1. **一条提示词只出一张图**，图里只有一个素材（多素材挤一张会导致错位，已踩过坑）。
2. **单体精灵/图标**：纯洋红底 `#FF00FF`，无阴影/地面/渐变。
3. **无缝瓦片/地面**：不要洋红底，铺满整张，`seamless tileable`。
4. **背景大图**：不要出现文字（标题游戏内渲染，方便改名）。
5. **两帧动画**：两帧同尺寸同构图，只改姿势；建议用"参考图改姿势"而不是重新描述。
6. 生成后放 `E:\games\`，按上表文件名命名，我负责抠底/像素化/接入。

## 四、接入流程（我这边）

```
E:/games/xxx.jpg
  → 洋红抠底（r>140 且 b>120 且 g<min(r,b)-70）
  → bbox 裁剪
  → 按目标高度缩放（两帧共用同一缩放，保证视觉大小一致）
  → 水平居中、底部对齐画布
  → 覆盖 assets/ 下对应文件
  → headless 验证 + 实机截图确认
```

> 接入后**务必实机截图核对**：是谁在用这张图、比例对不对、脚底有没有落地。
