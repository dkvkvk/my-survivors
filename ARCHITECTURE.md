# 项目架构导览（中文）

本项目《不退》（NO RETREAT）：类《吸血鬼幸存者》——玩家操控守山人在青冥山径上御敌，本命飞剑自动瞄准杀敌，妖潮按更次从四面八方涌入；斩妖掉落灵珠与灵石，升级时三选一强化（**只出属性卡**），另有**法宝掉落/材料升级/4 个主动技能**（P6 模型 B）；死亡后灵石入账、可在坊市万宝楼购买永久强化，最高纪录自动存入本地。

## 一、文件总览

| 文件/目录 | 职责 |
|---|---|
| `project.godot` | 项目配置。要求 Godot **4.7**，主场景 `main_menu.tscn`，视口 1920×1080 |
| `main_menu.tscn` + `main_menu.gd` | 主菜单（项目启动场景）：开始游戏、最高纪录展示、退出（Web 版自动隐藏退出按钮） |
| `survivors_game.tscn` + `game.gd` | 战斗场景：刷怪计时器、更次切换、HUD、升级/暂停/结算流程 |
| `player.tscn` + `player.gd` | 玩家：移动、血量、修为、属性卡应用、法宝/材料/技能槽/灵力（P6） |
| `gun.tscn` + `gun.gd` | 本命飞剑（法宝"本命飞剑"的**被动**）：索敌转向、定时开火，弹丸数与伤害随法宝品阶 |
| `orbit_blades.tscn` + `orbit_blades.gd` | 法宝"环形刀刃"的被动：刀刃绕玩家公转撞击伤害，刀刃数 = 法宝品阶（纯代码绘制） |
| `aura.tscn` + `aura.gd` | 法宝"灼热光环"的被动：周期性灼烧范围内敌人，半径/伤害随法宝品阶（碰撞与外观代码生成） |
| `chain_lightning.gd` | 法宝"链式闪电"的被动 + 技能"雷神之怒"：锯齿电弧纯代码绘制（四层辉光） |
| `bullet_2d.tscn` + `bullet_2d.gd` | 子弹：直线飞行、超程销毁、命中回调 |
| `mob.tscn` + `mob.gd` | 敌人：四种变体、追击与软分离围圈、受击、死亡烟雾、掉灵珠、**专属能力**（见三·六节） |
| `xp_gem.tscn` + `xp_gem.gd` | 灵珠：磁吸 + 缓慢滚动（外观代码绘制菱形） |
| `level_up_ui.gd` | 升级三选一界面（暂停 + 弹 3 张卡） |
| `pause_ui.gd` | 暂停菜单（Esc 开关：继续/重开/回主菜单） |
| `game_over.gd` | 失败结算界面：本局战绩、新纪录提示、重开/回主菜单 |
| `victory_ui.gd` | 胜利结算界面（P5）：活满 15 分钟或击破 3 只妖王，理由文案随触发方式变化 |
| `chest.tscn` + `chest.gd` | 藏宝匣（P4/P6）：妖王必掉，走过去开启，随机给材料礼包 / 直接升级一把未满级法宝 / 灵石 |
| `coin.tscn` + `coin.gd` | 灵石掉落物（P2）：磁吸拾取，死亡时入账存档余额 |
| `shop.tscn` + `shop.gd` | 坊市万宝楼（P2）：四种永久强化，数据在 `balance.gd` 的 SHOP 表 |
| `save.gd` | ★ 存档：`class_name SaveGame` 纯静态，读写 `user://records.json`（最高纪录 + 灵石 + 强化等级） |
| `balance.gd` | ★ 全部数值：玩家/敌人变体/更次表/经验曲线/三种法宝的常量 |
| `upgrades.gd` | ★ 强化卡池：**5 张属性卡**（P6 起法宝卡已移出，法宝改为掉落物） |
| `weapons.gd` | ★ 法宝数据表：4 把法宝（被动类型 / 技能列表 / 升级成本 / max_level） |
| `skills.gd` | ★ 主动技能表：4 个技能（耗蓝 / 冷却 / 图标 / 描述）+ `FUSIONS` 融合占位表 |
| `skill_bar.gd` | 技能槽 HUD（4 槽 + 冷却遮罩 + 蓝不够变暗），纯代码构建 |
| `inventory_ui.gd` | 乾坤袋（按 B，纯代码构建）：法宝 4 格 / 技能选择 / 材料 / 升级按钮 / 替换面板 |
| `start_select_ui.gd` | 开局选法宝（进战斗时弹 4 张卡并暂停；本命飞剑为固定基础法宝） |
| `weapon_drop.gd` + `pickup_drop.gd` | 掉落物：法宝（按 F 拾取）、材料（玄铁/雷魄）、神通残卷 |
| `audio.gd` | 音效池 autoload（12 播放器，防重叠、变调随机）+ `play_music()` 循环 BGM |
| `fader.gd` | 全局过渡 autoload：场景切换黑场淡入淡出 + 全屏暗角后期 |
| `vfx.gd` + `assets/fx/` | ★ autoload `VFX`：全局特效库（见下方"特效系统"），纯代码绘制 + 程序化生成的像素贴图 |
| `theme.tres` + `fonts/` | ★ 全局主题：Fusion Pixel 中文像素字体（SIL OFL 1.1）与按钮/进度条统一样式 |
| `vignette.gdshader` | 暗角屏幕后期（透明黑径向叠加，兼容性渲染器友好） |
| `addons/saltmire_juice/` | 打击感插件 autoload：震屏、闪白、hit-stop、伤害数字 |
| `hero.tscn` + `hero.gd` | 守山人主角外观：四方向待机/行走动画（素材在 `assets/hero/`，Ninja Adventure CC0） |
| `chunk_map.gd` | ★ 分块无限地图：9 种预设计 16x16 小地图模板随机旋转镜像拼接，碰撞挂瓦片（看得见才撞得上），玩家周围 5x5 块流式加载 |
| `enemy_sprite.gd` | 敌人外观适配器：两帧走路 + 受击压扁（`mob.gd` 沿用 `%Slime` 接口） |
| `assets/` | ★ 素材库：主角表（当前 Ninja Adventure CC0，待换守山人）+ 怪物两帧/装饰（当前 Kenney CC0，待换），许可见 NOTICE.md |
| `smoke_explosion/`、`assets/ground/`、`sounds/` | 死亡烟雾特效、无缝青石板（自制）、音效与 BGM（均 CC0） |
| `.github/workflows/build.yml` | CI：推送 main 自动导出 Windows 单文件 exe 与 Web 版（部署 GitHub Pages） |

## 二、场景树结构

主菜单（启动场景）：

```
MainMenu (main_menu.gd)
├─ Background / Title / Subtitle        深色背景与标题
├─ RecordsLabel                          _ready 时从 SaveGame 读最高纪录
├─ StartButton                           → change_scene_to_file 切到 survivors_game.tscn
├─ QuitButton                            Web 版（OS.has_feature("web")）自动隐藏
└─ HintLabel                             操作提示
```

战斗场景：

```
Game (game.gd, y_sort_enabled)           ← 战斗场景根节点
├─ Ground (Sprite2D, z=-100)             无限修仙地板：256px 无缝贴图×4 缩放，每帧按 1024px 网格吸附到玩家位置
├─ Timer                                 刷怪计时器，wait_time 每次刷怪后按更次表改写
├─ Player (player.tscn 实例)
│   ├─ Hero (hero.tscn)                   守山人外观（当前仍是忍者素材，待换）：四方向待机/行走动画自动驱动
│   ├─ CollisionShape2D / Camera2D
│   ├─ Gun (gun.tscn)                    本命飞剑被动：自动索敌发射（隐形），吃法宝品阶
│   ├─ Aura (aura.tscn, z=-1)            灼热光环被动：默认隐藏，捡到法宝后 configure(等级) 激活
│   ├─ OrbitBlades (orbit_blades.tscn)   环形刀刃被动：默认 0 把，刀刃数 = 法宝品阶
│   ├─ ChainLightning (chain_lightning.gd) 链式闪电被动 + 雷神之怒技能（纯代码电弧）
│   ├─ HurtBox (Area2D) / HealthBar      受击范围与头顶血条
│   └─ Path2D / PathFollow2D             刷怪环（挂在 Player 下，跟随玩家移动）
├─ GameOver (CanvasLayer, layer=30)       结算遮罩：战绩/新纪录/重开(R)/回主菜单
├─ CanvasLayer (layer=-32)               背景纯色
├─ ChunkMap（game.gd 代码挂载）           分块无限地图：瓦片障碍+碰撞，5x5 流式加载
├─ HUD (CanvasLayer, layer=10)           斩妖数 / 守夜时间 / 经验条 / 等级 / 蓝条 / 技能栏
├─ LevelUpUI (CanvasLayer, layer=30)      升级三选一
├─ PauseUI (CanvasLayer, layer=30)        暂停菜单（Esc）
├─ InventoryUI (CanvasLayer, layer=25)    乾坤袋（按 B）
└─ StartSelectUI (CanvasLayer, layer=30)  开局选法宝（进战斗即弹出，选完才解除暂停）
```

## 三、核心循环与数据流

1. **启动**：`main_menu.tscn` 展示最高纪录 → 开始游戏切到战斗场景 →
   **先弹「开局选法宝」（4 选 1，暂停游戏，见 `start_select_ui.gd`）** → 选完解除暂停正式开打；
   Esc 随时打开暂停菜单（升级/结算/乾坤袋/选法宝界面打开时忽略，避免状态叠加）。
2. **刷怪**：`Timer` 触发 `game.gd:spawn_mob()` → 在跟随玩家的 `PathFollow2D` 环上取随机点（敌人总从屏幕外刷出）→ `mob.setup()` 按更次权重选变体；刷怪间隔由 `Balance.current_wave(run_time)` 从五档更次表动态改写。
3. **敌人 AI**：`mob.gd` 按变体速度追击 `玩家位置 + 环形偏移`（软分离，不会叠成一点），进入攻击距离后停下贴身。
4. **索敌开火**：`gun.gd` 对 Area2D 内第一个敌人 `look_at()`；开火时按 `1 + 玩家额外弹丸` 生成扇形散射子弹（分裂弹头卡）。
5. **伤害汇入口**：子弹 `body_entered`、飞刀 `body_entered`、光环 Timer 周期扫描，最终都调 `mob.take_damage()`（`has_method` 鸭子类型判断，完全解耦——新法宝不需要动敌人代码）。飞刀伤害额外吃"重装弹药"加成。
6. **受击/死亡**：`take_damage()` 播放受击动画、伤害数字（Juice 插件）、扣血；归零时发 `died` 信号（game.gd 计斩妖数）、掉灵珠、生成烟雾特效并自毁。
7. **成长（两条线）**：
   - **属性线**：宝石被磁吸拾取 → `player.add_xp()` → 升级发 `leveled_up` → `LevelUpUI.present()` 暂停弹 3 张属性卡 → `player.apply_upgrade(id)` 应用。
   - **法宝线（P6 模型 B）**：掉落拾取 → `player.add_weapon()` 装位并激活被动 → 乾坤袋里用**材料 + 斩妖数**升级 → 被动等级同步提升 → 满级自动进化（见 `balance.gd` 的 `*_EVOLVE_*`）。
8. **玩家受伤**：`%HurtBox` 内重叠敌人的接触伤害倍率求和，按 9.0/秒·倍率持续掉血（贴身很痛，站桩必死）；血量归零发 `health_depleted`，低于 30% 触发全屏红光脉冲。
9. **游戏结束**：`game.gd` 播放音效 → `GameOver.show_results(斩妖, 守夜, 等级, 灵石)` 展示战绩并经 `SaveGame.submit_run()` 把灵石存入余额 → 暂停。破纪录时显示"★ 新纪录！ ★"。
10. **妖王（P4）**：倒计时到点 `game.gd:_spawn_boss()` → `mob.setup_boss()` 升格（三段 AI：追击→蓄力闪白→直线冲锋，血量随斩妖数递增，击退抗性，头顶血条）→ 斩妖必掉藏宝匣 → 走过去开启随机奖励。

## 三·五、特效系统（`vfx.gd`，autoload `VFX`）

**一个入口、两种实现**：所有特效都从 `VFX` 的原语里出来，内部是「纯代码绘制」+「程序化生成的像素贴图」，
不依赖任何第三方素材（配色统一为 青霓虹 / 金 / 赤红）。

| 原语 | 用途 | 实现 |
|---|---|---|
| `impact(pos, dir, color, strong)` | 命中爆点 | 星芒贴图 + 小环 + 4~7 颗火花 |
| `explosion(pos, r, color)` | 斩妖 / 藏宝匣 | 填充冲击环 + 碎片 + 烟 |
| `shockwave(pos, r, color, dur, w, fill)` | 技能起手 / 灼烧脉冲 | `draw_arc` 双层圆环，先快后慢扩散 |
| `warning_ring(pos, r, color, dur)` | 妖王蓄力预警 | 由外向内收缩的红环 + 淡填充 |
| `slash_arc` / `spin_slash` | 斩击 / 刃风暴 | 外弧+内弧围成的"刀刃"多边形 |
| `burst(pos, n, color, ...)` | 通用爆散 | `CPUParticles2D` + `spark/star/smoke` 贴图 |
| `trail(node, color, w)` | 子弹 / 飞刀拖尾 | `Line2D` 记录目标轨迹 + 渐变淡出 |
| `muzzle_flash` / `pickup_pop` / `levelup_burst` | 开火 / 拾取 / 升级 | 光晕贴图 + 环 + 光柱 |
| `thunder_strike(pos)` | 天雷落点 | 落点环 + 火花 + 短促全屏闪 |
| `screen_flash(color, a, dur)` | 全屏闪 | **全局复用同一块 ColorRect**，只刷新颜色 |

两个必须记住的坑：
1. **特效节点一律 `PROCESS_MODE_ALWAYS`**——升级/结算会 `get_tree().paused = true`，
   特效若跟着暂停，会以半透明状态冻在画面上（升级光柱卡在升级卡后面、闪白卡住不淡）。
2. **同屏特效有上限**（`VFX.FX_LIMIT = 260`）：一次打 40 只怪时自动只出最便宜的效果，防止掉帧。

## 三·六、敌人专属能力（`balance.gd` 的 `ABILITIES` + `mob.gd`）

每种怪一个招牌能力，**数据驱动**：能力名写在 `MOB_VARIANTS` 的 `ability` 字段，数值全在 `ABILITIES` 表。
加能力 = ABILITIES 加一条 + `mob.gd` 的 `_apply_ability()` / `_update_ability()` 加一个分支。

| 变体 | 能力 | 表现 | 关键数值 |
|---|---|---|---|
| 百足虫 slime | **分裂** `split` | 死亡时炸成 2 只更小更快的子体 | 子体血量 x0.35、体型 x0.62、速度 x1.25；场上超过 240 只就不再分裂 |
| 阴风鸮 runner | **飞扑** `dive` + 穿墙 | 短蓄力闪紫 → 朝玩家直线扑一段（贴脸也会扑，扑过头再走回来） | cd 2.6s、射程 460、蓄力 0.22s、突进 0.25s x1.7 速 |
| 蛮石傀 tank | **撞碎障碍** `break_walls` | 被墙挡住就把那块瓦片打掉，给后面的怪开路 | 每次碎瓦间隔 0.35s |
| 赤目狼妖 elite | **扑击** `pounce` | 蓄力更久（地面红圈预警）→ 突进更远的强化扑 | cd 3.2s、射程 420、蓄力 0.35s、突进 0.45s x2.4 速 |
| 妖王 boss | **犁地冲锋** | 冲锋沿途把半径内的瓦片全撞碎 | 半径 120px、每 0.08s 结算一次 |
| （所有地面怪） | **卡墙自愈** | 被墙挡住约 2.4 秒没能靠近玩家 → 短暂穿墙 2 秒脱困 | 见 `mob.gd` 的 `_update_stuck()` |

两个必须记住的坑：
1. **分裂子体不给任何收益**（`can_drop_loot = false`、`xp_value = 0`）——否则一只百足虫等于 3 倍经验与掉落，经济直接膨胀。
2. **飞扑/扑击不要排除"已经贴脸"的情况**：阴风鸮和赤目狼妖是最快的怪，一到玩家身边就停在攻击距离内，
   若排除贴身，飞扑就只在入场那一次触发（实测稳态 0 只在扑）。现在贴身也能扑，扑过头再走回来。

## 四、代码约定（二开前先了解）

- **`%UniqueName`**：`%XXX` 访问场景内勾选"唯一名称"的节点，重构子树时不用改路径。
- **信号解耦**：跨场景通信用信号（如 `died`、`health_depleted`、`leveled_up`），连接在 `.tscn` 的 `[connection]` 里。
- **数值集中**：全部可调参数在 `balance.gd`（`class_name Balance` 静态常量），卡池在 `upgrades.gd`，法宝/技能表在 `weapons.gd` / `skills.gd`。
  **加一张属性卡** = upgrades.gd 加一行 + `player.apply_upgrade()` 加一个分支；
  **加一把法宝** = weapons.gd 加一行 + `player` 的三个分发分支（`_apply_weapon_passive` / `_clear_weapon_passive` / `_evolve_weapon`）；
  **加一个技能** = skills.gd 加一行 + `player._run_skill_effect()` 加一个分支。
- **暂停覆盖层模式**：所有弹出界面（升级/暂停/结算）都是 `CanvasLayer + process_mode=3(ALWAYS) + get_tree().paused`，遮罩用全屏半透明 ColorRect。
- **★ UI 层级（CanvasLayer.layer）**：世界 0 · HUD **10** · 全屏闪 **12** · 乾坤袋 **25** · 弹窗（升级/暂停/失败/胜利）**30** · Fader **128**。
  **新增弹窗一律 layer = 30**，否则会被 HUD 压住——踩过：结算界面上还挂着斩妖/守夜/血条/蓝条，技能栏还压在"回到主菜单"按钮上；
  连 HUD 里的低血量红色脉冲都会盖在结算背景上把它染红。结算时另外 `$HUD.hide()` 收干净。
- **伤害单一入口**：一切法宝最终调 `mob.take_damage(n)`，新法宝零改动接入。
- **★ 碰撞层**：**1 = 玩家 · 2 = 敌人 · 3 = 障碍**。瓦片障碍在层 3（`chunk_map.gd` 的 `set_physics_layer_collision_layer(0, 4)`），玩家 mask = 5，怪 mask = 4。
  谁穿墙由 `balance.gd` 变体表的 `phasing` 决定（只有会飞的阴风鸮 + 妖王）；地面怪被墙卡住约 2.4 秒会短暂穿墙脱困
  （`mob.gd` 的 `_update_stuck()`）；**子弹一律穿行**，防自动瞄准浪费。
- **纯代码绘制**：灵珠菱形、飞刀、光环均不依赖美术素材（新增内容避开上游 CC-BY-NC-SA 素材的商用限制）。
- **存档**：`SaveGame` 纯静态类读写 `user://records.json`（Web 导出走 IndexedDB，同样可用）。
- **Y 排序**：根节点开 `y_sort_enabled`，角色与树的遮挡按 Y 坐标自动处理。
- **音频**：`Audio.play(路径, 可重叠, 音调, 音量)`，autoload 12 播放器池。
- **全局视觉**：`project.godot` 挂 `theme.tres`（像素字体 + 按钮样式），切场景统一走 `Fader.fade_to_scene()`（黑场过渡 + 暗角随 autoload 常驻）；新 UI 字号取 12 的倍数（像素字体在整数倍下最锐）。

## 五、与完整幸存者游戏的差距 = 你的二开空间

目前**没有**的东西（按重要性）：

1. **法宝合成**——法宝满级进化已有（P6 模型 B），但两个技能的组合融合还没有（见 `skills.gd` 的 `FUSIONS` 占位表）
2. **主题换皮**——美术沿用上游素材（非商用许可，商业化前需全部替换，见 NOTICE.md）
3. **局外成长**——没有永久解锁/货币，存档目前只记三项最高纪录
4. **发布页**——已有 Pages 在线版与 CI 构建，缺正式发布页（itch.io/Steam）

## 六、二开路线图（已完成 U1~U6）

- [x] **U1** 重开按钮、斩妖/时间 HUD、8-bit 音效
- [x] **U2** 打击感：震屏、闪白、hit-stop、伤害数字（Saltmire Juice 插件）
- [x] **U3** 灵珠 + 升级三选一（卡池数据驱动）
- [x] **U4** 四种敌人变体 + 五档更次难度曲线（balance.gd 两张表）
- [x] **U5** 主菜单、Esc 暂停菜单、最高纪录存档（user://records.json）
- [x] **U6** 更多法宝：环绕飞刀 / 灼热光环 / 分裂弹头（可叠加卡）
- [ ] 主题换皮（替换全部非商用美术）、正式发布页

## 七、参考资料

- 上游仓库：https://github.com/gdquest-demos/getting-started-with-godot-4
- 配套免费教程（本项目的完整搭建过程）：https://www.gdquest.com/library/first_2d_game_godot4_vampire_survivor/
- 上游完整克隆（含 3D FPS demo 和 starter files）在 `E:\reference\getting-started-with-godot-4`
- 版权说明：见 [NOTICE.md](NOTICE.md)
