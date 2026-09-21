# 项目架构导览（中文）

本项目《不退》（NO RETREAT）：类《吸血鬼幸存者》——玩家操控忍者在科技基地里躲避，手里剑自动瞄准发射，敌人按波次从四周涌入；击杀掉落经验宝石与金币，升级时三选一强化（**只出属性卡**），另有**武器掉落/材料升级/4 个主动技能**（P6 模型 B）；死亡后金币入账、可在忍具商店购买永久强化，最高纪录自动存入本地。

## 一、文件总览

| 文件/目录 | 职责 |
|---|---|
| `project.godot` | 项目配置。要求 Godot **4.7**，主场景 `main_menu.tscn`，视口 1920×1080 |
| `main_menu.tscn` + `main_menu.gd` | 主菜单（项目启动场景）：开始游戏、最高纪录展示、退出（Web 版自动隐藏退出按钮） |
| `survivors_game.tscn` + `game.gd` | 战斗场景：刷怪计时器、波次切换、HUD、升级/暂停/结算流程 |
| `player.tscn` + `player.gd` | 玩家：移动、血量、经验等级、属性卡应用、武器/材料/技能槽/法力（P6） |
| `gun.tscn` + `gun.gd` | 手里剑（武器"手里剑"的**被动**）：索敌转向、定时开火，弹丸数与伤害随武器等级 |
| `orbit_blades.tscn` + `orbit_blades.gd` | 武器"环形刀刃"的被动：刀刃绕玩家公转撞击伤害，刀刃数 = 武器等级（纯代码绘制） |
| `aura.tscn` + `aura.gd` | 武器"灼热光环"的被动：周期性灼烧范围内敌人，半径/伤害随武器等级（碰撞与外观代码生成） |
| `chain_lightning.gd` | 武器"链式闪电"的被动 + 技能"雷神之怒"：锯齿电弧纯代码绘制（四层辉光） |
| `bullet_2d.tscn` + `bullet_2d.gd` | 子弹：直线飞行、超程销毁、命中回调 |
| `mob.tscn` + `mob.gd` | 敌人：四种变体、追击与软分离围圈、受击、死亡烟雾、掉经验宝石 |
| `xp_gem.tscn` + `xp_gem.gd` | 经验宝石：磁吸 + 缓慢滚动（外观代码绘制菱形） |
| `level_up_ui.gd` | 升级三选一界面（暂停 + 弹 3 张卡） |
| `pause_ui.gd` | 暂停菜单（Esc 开关：继续/重开/回主菜单） |
| `game_over.gd` | 失败结算界面：本局战绩、新纪录提示、重开/回主菜单 |
| `victory_ui.gd` | 胜利结算界面（P5）：活满 15 分钟或击破 3 只首领，理由文案随触发方式变化 |
| `chest.tscn` + `chest.gd` | 宝箱（P4/P6）：首领必掉，走过去开启，随机给材料礼包 / 直接升级一把未满级武器 / 金币 |
| `coin.tscn` + `coin.gd` | 金币掉落物（P2）：磁吸拾取，死亡时入账存档余额 |
| `shop.tscn` + `shop.gd` | 忍具商店（P2）：四种永久强化，数据在 `balance.gd` 的 SHOP 表 |
| `save.gd` | ★ 存档：`class_name SaveGame` 纯静态，读写 `user://records.json`（最高纪录 + 金币 + 强化等级） |
| `balance.gd` | ★ 全部数值：玩家/敌人变体/波次表/经验曲线/三种武器的常量 |
| `upgrades.gd` | ★ 强化卡池：**5 张属性卡**（P6 起武器卡已移出，武器改为掉落物） |
| `weapons.gd` | ★ 武器数据表：4 把武器（被动类型 / 技能列表 / 升级成本 / max_level） |
| `skills.gd` | ★ 主动技能表：4 个技能（耗蓝 / 冷却 / 图标 / 描述）+ `FUSIONS` 融合占位表 |
| `skill_bar.gd` | 技能槽 HUD（4 槽 + 冷却遮罩 + 蓝不够变暗），纯代码构建 |
| `inventory_ui.gd` | 背包（按 B，纯代码构建）：武器 4 格 / 技能选择 / 材料 / 升级按钮 / 替换面板 |
| `weapon_drop.gd` + `pickup_drop.gd` | 掉落物：武器（按 F 拾取）、材料（铁屑/雷晶）、技能切换书 |
| `audio.gd` | 音效池 autoload（12 播放器，防重叠、变调随机）+ `play_music()` 循环 BGM |
| `fader.gd` | 全局过渡 autoload：场景切换黑场淡入淡出 + 全屏暗角后期 |
| `theme.tres` + `fonts/` | ★ 全局主题：Fusion Pixel 中文像素字体（SIL OFL 1.1）与按钮/进度条统一样式 |
| `vignette.gdshader` | 暗角屏幕后期（透明黑径向叠加，兼容性渲染器友好） |
| `addons/saltmire_juice/` | 打击感插件 autoload：震屏、闪白、hit-stop、伤害数字 |
| `hero.tscn` + `hero.gd` | 忍者主角外观：四方向待机/行走动画（素材在 `assets/hero/`，Ninja Adventure CC0） |
| `chunk_map.gd` | ★ 分块无限地图：9 种预设计 16x16 小地图模板随机旋转镜像拼接，碰撞挂瓦片（看得见才撞得上），玩家周围 5x5 块流式加载 |
| `enemy_sprite.gd` | 敌人外观适配器：两帧走路 + 受击压扁（`mob.gd` 沿用 `%Slime` 接口） |
| `assets/` | ★ CC0 素材库：忍者（Ninja Adventure）+ 怪物两帧/装饰（Kenney），许可见 NOTICE.md |
| `smoke_explosion/`、`assets/ground/`、`sounds/` | 死亡烟雾特效、无缝科技地板（自制）、音效与 BGM（均 CC0） |
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
├─ Ground (Sprite2D, z=-100)             无限科技地板：256px 无缝贴图×4 缩放，每帧按 1024px 网格吸附到玩家位置
├─ Timer                                 刷怪计时器，wait_time 每次刷怪后按波次表改写
├─ Player (player.tscn 实例)
│   ├─ Hero (hero.tscn)                   忍者外观：四方向待机/行走动画自动驱动
│   ├─ CollisionShape2D / Camera2D
│   ├─ Gun (gun.tscn)                    手里剑被动：自动索敌发射（隐形），吃武器等级
│   ├─ Aura (aura.tscn, z=-1)            灼热光环被动：默认隐藏，捡到武器后 configure(等级) 激活
│   ├─ OrbitBlades (orbit_blades.tscn)   环形刀刃被动：默认 0 把，刀刃数 = 武器等级
│   ├─ ChainLightning (chain_lightning.gd) 链式闪电被动 + 雷神之怒技能（纯代码电弧）
│   ├─ HurtBox (Area2D) / HealthBar      受击范围与头顶血条
│   └─ Path2D / PathFollow2D             刷怪环（挂在 Player 下，跟随玩家移动）
├─ GameOver (CanvasLayer, process_mode=3)  结算遮罩：战绩/新纪录/重开(R)/回主菜单
├─ CanvasLayer (layer=-32)               背景纯色
├─ ChunkMap（game.gd 代码挂载）           分块无限地图：瓦片障碍+碰撞，5x5 流式加载
├─ HUD (CanvasLayer, layer=10)           击杀数 / 存活时间 / 经验条 / 等级
├─ LevelUpUI (CanvasLayer, process_mode=3) 升级三选一
└─ PauseUI (CanvasLayer, process_mode=3)   暂停菜单（Esc）
```

## 三、核心循环与数据流

1. **启动**：`main_menu.tscn` 展示最高纪录 → 开始游戏切到战斗场景；Esc 随时打开暂停菜单（升级/结算界面打开时忽略，避免状态叠加）。
2. **刷怪**：`Timer` 触发 `game.gd:spawn_mob()` → 在跟随玩家的 `PathFollow2D` 环上取随机点（敌人总从屏幕外刷出）→ `mob.setup()` 按波次权重选变体；刷怪间隔由 `Balance.current_wave(run_time)` 从五档波次表动态改写。
3. **敌人 AI**：`mob.gd` 按变体速度追击 `玩家位置 + 环形偏移`（软分离，不会叠成一点），进入攻击距离后停下贴身。
4. **索敌开火**：`gun.gd` 对 Area2D 内第一个敌人 `look_at()`；开火时按 `1 + 玩家额外弹丸` 生成扇形散射子弹（分裂弹头卡）。
5. **伤害汇入口**：子弹 `body_entered`、飞刀 `body_entered`、光环 Timer 周期扫描，最终都调 `mob.take_damage()`（`has_method` 鸭子类型判断，完全解耦——新武器不需要动敌人代码）。飞刀伤害额外吃"重装弹药"加成。
6. **受击/死亡**：`take_damage()` 播放受击动画、伤害数字（Juice 插件）、扣血；归零时发 `died` 信号（game.gd 计击杀数）、掉经验宝石、生成烟雾特效并自毁。
7. **成长（两条线）**：
   - **属性线**：宝石被磁吸拾取 → `player.add_xp()` → 升级发 `leveled_up` → `LevelUpUI.present()` 暂停弹 3 张属性卡 → `player.apply_upgrade(id)` 应用。
   - **武器线（P6 模型 B）**：掉落拾取 → `player.add_weapon()` 装位并激活被动 → 背包里用**材料 + 击杀数**升级 → 被动等级同步提升 → 满级自动进化（见 `balance.gd` 的 `*_EVOLVE_*`）。
8. **玩家受伤**：`%HurtBox` 内重叠敌人的接触伤害倍率求和，按 9.0/秒·倍率持续掉血（贴身很痛，站桩必死）；血量归零发 `health_depleted`，低于 30% 触发全屏红光脉冲。
9. **游戏结束**：`game.gd` 播放音效 → `GameOver.show_results(击杀, 存活, 等级, 金币)` 展示战绩并经 `SaveGame.submit_run()` 把金币存入余额 → 暂停。破纪录时显示"★ 新纪录！ ★"。
10. **首领（P4）**：倒计时到点 `game.gd:_spawn_boss()` → `mob.setup_boss()` 升格（三段 AI：追击→蓄力闪白→直线冲锋，血量随击杀数递增，击退抗性，头顶血条）→ 击杀必掉宝箱 → 走过去开启随机奖励。

## 四、代码约定（二开前先了解）

- **`%UniqueName`**：`%XXX` 访问场景内勾选"唯一名称"的节点，重构子树时不用改路径。
- **信号解耦**：跨场景通信用信号（如 `died`、`health_depleted`、`leveled_up`），连接在 `.tscn` 的 `[connection]` 里。
- **数值集中**：全部可调参数在 `balance.gd`（`class_name Balance` 静态常量），卡池在 `upgrades.gd`，武器/技能表在 `weapons.gd` / `skills.gd`。
  **加一张属性卡** = upgrades.gd 加一行 + `player.apply_upgrade()` 加一个分支；
  **加一把武器** = weapons.gd 加一行 + `player` 的三个分发分支（`_apply_weapon_passive` / `_clear_weapon_passive` / `_evolve_weapon`）；
  **加一个技能** = skills.gd 加一行 + `player._run_skill_effect()` 加一个分支。
- **暂停覆盖层模式**：所有弹出界面（升级/暂停/结算）都是 `CanvasLayer + process_mode=3(ALWAYS) + get_tree().paused`，遮罩用全屏半透明 ColorRect。
- **伤害单一入口**：一切武器最终调 `mob.take_damage(n)`，新武器零改动接入。
- **纯代码绘制**：经验宝石菱形、飞刀、光环均不依赖美术素材（新增内容避开上游 CC-BY-NC-SA 素材的商用限制）。
- **存档**：`SaveGame` 纯静态类读写 `user://records.json`（Web 导出走 IndexedDB，同样可用）。
- **Y 排序**：根节点开 `y_sort_enabled`，角色与树的遮挡按 Y 坐标自动处理。
- **音频**：`Audio.play(路径, 可重叠, 音调, 音量)`，autoload 12 播放器池。
- **全局视觉**：`project.godot` 挂 `theme.tres`（像素字体 + 按钮样式），切场景统一走 `Fader.fade_to_scene()`（黑场过渡 + 暗角随 autoload 常驻）；新 UI 字号取 12 的倍数（像素字体在整数倍下最锐）。

## 五、与完整幸存者游戏的差距 = 你的二开空间

目前**没有**的东西（按重要性）：

1. **武器合成**——武器满级进化已有（P6 模型 B），但两个技能的组合融合还没有（见 `skills.gd` 的 `FUSIONS` 占位表）
2. **主题换皮**——美术沿用上游素材（非商用许可，商业化前需全部替换，见 NOTICE.md）
3. **局外成长**——没有永久解锁/货币，存档目前只记三项最高纪录
4. **发布页**——已有 Pages 在线版与 CI 构建，缺正式发布页（itch.io/Steam）

## 六、二开路线图（已完成 U1~U6）

- [x] **U1** 重开按钮、击杀/时间 HUD、8-bit 音效
- [x] **U2** 打击感：震屏、闪白、hit-stop、伤害数字（Saltmire Juice 插件）
- [x] **U3** 经验宝石 + 升级三选一（卡池数据驱动）
- [x] **U4** 四种敌人变体 + 五档波次难度曲线（balance.gd 两张表）
- [x] **U5** 主菜单、Esc 暂停菜单、最高纪录存档（user://records.json）
- [x] **U6** 更多武器：环绕飞刀 / 灼热光环 / 分裂弹头（可叠加卡）
- [ ] 主题换皮（替换全部非商用美术）、正式发布页

## 七、参考资料

- 上游仓库：https://github.com/gdquest-demos/getting-started-with-godot-4
- 配套免费教程（本项目的完整搭建过程）：https://www.gdquest.com/library/first_2d_game_godot4_vampire_survivor/
- 上游完整克隆（含 3D FPS demo 和 starter files）在 `E:\reference\getting-started-with-godot-4`
- 版权说明：见 [NOTICE.md](NOTICE.md)
