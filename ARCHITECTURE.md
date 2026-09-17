# 项目架构导览（中文）

本项目的玩法：类《吸血鬼幸存者》——玩家移动躲避，手枪自动瞄准开火，史莱姆不断从四周涌入，撑到血量耗尽为止。

## 一、文件总览

| 文件/目录 | 职责 |
|---|---|
| `project.godot` | 项目配置。要求 Godot **4.6**，主场景 `survivors_game.tscn`，视口 1920×1080 |
| `survivors_game.tscn` + `game.gd` | 主场景：敌人刷怪计时器、刷怪路径、Game Over 界面、松树、背景 |
| `player.tscn` + `player.gd` | 玩家：移动、血量、受伤判定、镜头 |
| `gun.tscn` + `gun.gd` | 手枪：索敌转向、定时开火 |
| `bullet_2d.tscn` + `bullet_2d.gd` | 子弹：直线飞行、超程销毁、命中回调 |
| `mob.tscn` + `mob.gd` | 史莱姆敌人：追击玩家、受击、死亡烟雾 |
| `characters/happy_boo/` | 玩家角色（方块小幽灵）的美术与动画 |
| `characters/slime/` | 史莱姆的美术与动画 |
| `pistol/` | 手枪贴图、枪口火光 `muzzle_flash/`、命中特效 `impact/` |
| `smoke_explosion/` | 敌人死亡烟雾特效（含 `.gdshader` 着色器） |
| `trees/` | 松树场景，用于地图装饰与 Y 排序演示 |
| `addons/colorpicker_presets/` | GDQuest 的取色器预设插件（开发辅助，非游戏逻辑） |

## 二、场景树结构

```
Game (game.gd, y_sort_enabled)          ← 根节点
├─ Timer (0.3s 循环)                     → timeout 信号调用 game.gd 的刷怪
├─ Player (player.tscn 实例)
│   ├─ HappyBoo        角色外观与动画
│   ├─ CollisionShape2D
│   ├─ Camera2D        镜头跟随玩家
│   ├─ Gun (gun.tscn)  自动索敌开火
│   ├─ HurtBox (Area2D) 玩家受击范围
│   └─ HealthBar       血条 UI
│       └─ Path2D / PathFollow2D        刷怪环（挂在 Player 下，跟随玩家移动）
├─ GameOver (CanvasLayer)                游戏结束遮罩，默认隐藏
├─ CanvasLayer (layer=-32)               背景纯色
└─ PineTree × 11                         地图装饰
```

## 三、核心循环与数据流

1. **刷怪**：`Timer` 每 0.3 秒触发 `game.gd:spawn_mob()` → 在 `PathFollow2D` 环上取随机点（环跟随玩家，保证敌人总从屏幕外刷出）→ 实例化 `mob.tscn` 加入场景树。
2. **敌人 AI**：`mob.gd:_physics_process()` 每物理帧计算朝向玩家的方向，以 200~300 随机速度 `move_and_slide()` 追击。血量 3，无碰撞伤害判定（伤害靠玩家的 HurtBox 反向结算）。
3. **索敌开火**：`gun.gd:_process()` 用 Area2D 的 `get_overlapping_bodies()` 取第一个敌人 `look_at()` 转向；枪内 Timer 到点调 `shoot()`，从 `%ShootingPoint` 生成子弹。
4. **子弹**：`bullet_2d.gd` 沿自身旋转方向 1000px/s 直线飞，累计飞行 1200px 后自毁；`body_entered` 时自毁并调用对方 `take_damage()`（用 `has_method` 鸭子类型判断，解耦）。
5. **受击/死亡**：`mob.gd:take_damage()` 播放受击动画、扣 1 血；归零时在原地生成 `smoke_explosion` 特效并自毁。
6. **玩家受伤**：`player.gd` 检查 `%HurtBox` 内重叠的敌人数量，按 **每敌 6.0/秒** 持续掉血并同步血条；血量归零发 `health_depleted` 信号。
7. **游戏结束**：`game.gd` 收到信号 → 显示 Game Over 遮罩 → `get_tree().paused = true`。

## 四、代码约定（二开前先了解）

- **`%UniqueName`**：`%XXX` 语法访问场景内勾选了“唯一名称”的节点，重构子树时不用改路径。
- **信号解耦**：跨场景通信用信号（如 `health_depleted`），连接在 `.tscn` 的 `[connection]` 里。
- **数值全硬编码**：移动速度 600、射速、子弹速度 1000、射程 1200、DPS 6.0 都是脚本常量——适合先抄后改成 `@export` 变量。
- **Y 排序**：根节点开了 `y_sort_enabled`，角色与树的遮挡关系按 Y 坐标自动处理。
- **无任何音频文件**：`default_bus_layout.tres` 只是默认总线布局。

## 五、与完整幸存者游戏的差距 = 你的二开空间

目前**没有**的东西（按重要性）：

1. **经验/升级循环**——没有经验掉落、没有升级、没有三选一强化，这是幸存者类游戏的灵魂
2. **敌人多样性**——只有一种史莱姆，无波次曲线
3. **武器成长**——只有一把固定手枪
4. **重开一局**——Game Over 后只能暂停退出，没有重开按钮
5. **战斗反馈**——无击杀数/存活时间 UI、无伤害跳字、无音效
6. **存档/局外成长**——无任何持久化

## 六、二开路线图（按性价比排序）

### 阶段 1：快速上手（每项 0.5~2 小时，适合熟悉代码）
1. **Game Over 重开**：遮罩上加按钮或按 R 键 → `get_tree().reload_current_scene()` + 取消暂停
2. **计分 UI**：击杀数、存活时长（`mob.gd` 死亡处发信号回 `game.gd` 计数）
3. **数值调参**：把各脚本里的常量改成 `@export`，在编辑器里直接调平衡

### 阶段 2：核心肉鸽循环（本阶段做完才算"幸存者类"）
4. **经验宝石**：敌人死亡掉落吸引式经验粒子 → 玩家吸取涨经验条
5. **升级三选一**：满级暂停 + 弹出 3 个随机强化（移速/射速/伤害/血量上限/子弹数），用 UI + `paused` 实现
6. **武器数据驱动**：定义 `WeaponStats` 自定义 Resource（.tres），枪从资源读参数——为多武器打地基

### 阶段 3：内容扩展
7. **新敌人**：抽象出 `MobStats` 资源（速度/血量/伤害/经验），做出快慢、肉脆、精英等变体
8. **波次时间表**：按存活时间切换敌人组合与刷新密度（难度曲线）
9. **第二武器**：环绕弹幕（whip/光环类）或穿透弹，复用 bullet 模式

### 阶段 4：打磨与商业化准备
10. **音频**：Kenney / freesound 找 CC0 音效（注意替换全部原美术素材才能商用，见 NOTICE.md）
11. **打击感**：受击闪白、屏幕震动、伤害跳字
12. **存档**：`user://` 目录 + `FileAccess` 保存最高纪录或局外解锁

## 七、参考资料

- 上游仓库：https://github.com/gdquest-demos/getting-started-with-godot-4
- 配套免费教程（本项目的完整搭建过程）：https://www.gdquest.com/library/first_2d_game_godot4_vampire_survivor/
- 上游完整克隆（含 3D FPS demo 和 starter files）在 `E:\_upstream\getting-started-with-godot-4`
- 版权说明：见 [NOTICE.md](NOTICE.md)
