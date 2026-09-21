# 不退（NO RETREAT）

一款用 **Godot 4 + GDScript** 开发的 2D 割草幸存者游戏。操控像素小修士在被魔渊妖潮围山的**修仙青冥山**里求生：自动投掷本命飞剑、收集经验与灵石、升级三选一、死亡后在坊市万宝楼购买永久强化。

**胜利条件**：活满 **15 分钟**，或击破 **3 只妖王**——站着不退才是活路。**全部美术素材为 CC0/OFL 可商用**。

> ⚠️ **修仙化改版进行中**（2026-09-21）：**文案与系统命名已全部改为修仙口径**（法宝 / 神通 / 道法 / 坊市 / 妖物……，设定见 `WORLDVIEW.md`）；
> **美术素材仍是旧的和风 / 科技素材**，正按 `XIANXIA_ART_PROMPTS.md` 分批替换（改造清单见 `REFACTOR_XIANXIA.md`）。

> 基于 [GDQuest](https://www.gdquest.com/) 的开源教学项目 [getting-started-with-godot-4](https://github.com/gdquest-demos/getting-started-with-godot-4) 二次开发。

## 在线试玩

**[点击直接玩（GitHub Pages）](https://dkvkvk.github.io/my-survivors/)** — 需要键盘，推荐 Chrome/Edge。

## 玩法

| 按键 | 操作 |
|---|---|
| WASD / 方向键 | 移动（本命飞剑自动瞄准最近的敌人发射） |
| 鼠标点击 / R | 升级和游戏结束界面做选择 |
| Esc | 暂停菜单（继续 / 重开 / 回主菜单） |

**核心循环**：杀怪 → 捡灵珠（会自动滚向你）→ 升级 → 三选一强化 → 变强 → 面对更强的怪。怪物掉**灵石**，死亡结算入账，主菜单的**坊市万宝楼**可购买永久强化（生命/伤害/移速/拾取范围），下一局更强。最高纪录（守夜/斩妖/等级）自动存本地。

**八种强化卡**：疾风之靴（移速）/ 灵巧扳机（射速）/ 重装弹药（伤害）/ 生命祝福（血量）/ 磁力护符（拾取范围），外加三张可叠加的法宝卡——**环形刀刃**（环绕飞刀 +1）/ **灼热光环**（周期灼烧，范围与伤害递增）/ **分裂弹头**（手枪扇形散射 +1 弹）。

**四种敌人**（按时间分波登场）：

| 敌人 | 血量 | 特点 |
|---|---|---|
| 百足虫 | 3 | 基础怪，开局就有 |
| 阴风鸮 | 1 | 飞得快而脆，30 秒后混入 |
| 蛮石傀 | 10 | 大块头，慢但硬，掉 5 经验 |
| 赤目狼妖 | 20 | 泛红巨兽，碰一下 2.5 倍痛，掉 15 经验 |

难度节奏偏紧：站桩挂机会在 1~2 波内被围死，走位风筝怪、规划路线捡宝石才是正解。

## 功能

- 完整成长循环：灵珠磁吸拾取、等级曲线（前期快、后期封顶）
- 升级三选一强化卡（卡池数据驱动，加卡只需在 `upgrades.gd` 加一行）
- 三种可叠加法宝卡：环绕飞刀 / 灼热光环 / 分裂弹头（纯代码绘制，无新增美术素材）
- 法宝化灵（P3）：同名法宝卡满 5 级后第 6 张触发进化——刃风暴（转速翻倍）/ 烈日领域（灼烧减半）/ 剑光化灵（弹丸+2 射速+20%），进化后该卡移出卡池
- 妖王与藏宝匣（P4）：每 3 分钟妖王来袭（三段 AI：追击/蓄力闪白/直线冲锋，血量随斩妖数递增），头顶血条、击退抗性，斩妖必掉藏宝匣——随机开出法宝直升一级（含触发进化）或灵石
- 四种敌人变体 + 五档更次难度曲线（`balance.gd` 两张表全管）
- 分块无限地图：9 种预设计小地图随机拼接（墙/货箱/服务器带碰撞，水晶/灌木装饰），看得见才撞得上
- 主菜单、Esc 暂停菜单、最高纪录本地存档（`user://records.json`，Web 版同样可用）
- 局外成长（P2）：怪物掉灵石 → 死亡入账 → 坊市万宝楼四种永久强化（生命/伤害/移速/磁力，逐级涨价）
- 打击感：震屏、受击闪白、hit-stop 定帧、伤害数字、命中击退、死亡碎片（[Saltmire Juice](https://github.com/saltmire/saltmire-juice)）
- 循环 BGM（菜单/战斗两首，8-bit 风格自制合成）+ 低血量红色脉冲警告
- 像素风统一视觉：守山人主角（四方向行走动画）+ CC0 怪物/装饰、中文像素字体（Fusion Pixel）、全局主题（`theme.tres`）、暗角后期、场景黑场过渡、环境光尘粒子
- 8-bit 音效（CC0）、无缝青石板地面、青色环境光尘、斩妖/时间/经验 HUD

## 本地运行

```bash
git clone https://github.com/dkvkvk/my-survivors.git
# 用 Godot 4.7+ 打开项目，按 F5
```

或下载 [Actions](../../actions) 页面最新构建的 Windows 成品（单文件 exe）。

## 构建

推送到 `main` 自动触发 GitHub Actions：Windows 版上传为 Artifact，网页版自动部署到 GitHub Pages。

## 项目结构

```
main_menu.gd      # 主菜单（项目启动场景）：开始游戏 / 最高纪录
game.gd           # 主逻辑：刷怪、更次、HUD、胜负流程
chunk_map.gd      # ★ 分块无限地图：小地图模板随机拼接 + 瓦片碰撞 + 流式加载
hero.gd           # 守山人角色：四方向待机/行走动画（素材 Ninja Adventure）
player.gd         # 玩家：移动、血量、经验等级、强化与法宝应用
mob.gd            # 敌人：变体属性、软分离围圈、掉宝石、击退
enemy_sprite.gd   # 敌人外观适配器：两帧动画 + 受击压扁（Kenney 素材）
gun.gd / bullet_2d.gd  # 自动发射与旋转本命飞剑（代码绘制）
orbit_blades.gd   # 法宝卡：环绕飞刀（纯代码绘制，可叠加）
aura.gd           # 法宝卡：灼热光环（周期 AoE，可叠加）
xp_gem.gd         # 灵珠：磁吸 + 缓慢滚动
level_up_ui.gd    # 升级三选一界面
pause_ui.gd       # 暂停菜单（Esc）
game_over.gd      # 结算界面：本局战绩 + 新纪录提示
coin.gd           # 灵石掉落物：磁吸拾取（P2 局外经济）
chest.gd          # 藏宝匣：妖王必掉，随机开法宝升级/灵石（P4）
shop.gd / shop.tscn  # 坊市万宝楼：永久强化购买
save.gd           # ★ 存档：最高纪录 + 灵石余额 + 强化等级（user://records.json）
balance.gd        # ★ 全部数值：经验曲线/敌人变体/更次表/法宝
upgrades.gd       # ★ 强化卡池
audio.gd          # 音效池 + 循环 BGM
fader.gd          # 全局过渡：黑场淡入淡出 + 暗角后期（autoload）
theme.tres        # ★ 全局主题：像素字体 + 按钮/进度条样式
assets/           # 素材：主角表（当前 Ninja Adventure CC0，待换守山人）/怪物（当前 Kenney CC0，待换）/地板与瓦片（自制）
fonts/            # Fusion Pixel 中文像素字体（SIL OFL 1.1）
addons/saltmire_juice/
```

## 致谢与许可

| 内容 | 来源 | 许可 |
|---|---|---|
| 代码基础 | GDQuest getting-started-with-godot-4 | MIT |
| 守山人角色 | [Ninja Adventure（pixel-boy）](https://pixel-boy.itch.io/ninja-adventure) | **CC0** |
| 怪物素材 | [Kenney Pixel Platformer](https://kenney.nl/assets/pixel-platformer) | **CC0** |
| 瓦片集（墙/货箱/服务器/水晶等） | 本项目脚本生成 | **CC0（自制）** |
| 青石板地面/装饰 | 本项目脚本生成（无缝平铺） | **CC0（自制）** |
| 打击感插件 | Saltmire Juice | MIT |
| 音效 | Juhani Junkala 8-bit 音效包 | CC0 |
| 背景音乐 | 脚本合成的 8-bit 循环曲（本项目自制） | CC0 |
| 中文字体 | [Fusion Pixel](https://github.com/TakWolf/fusion-pixel-font)（缝合像素） | SIL OFL 1.1 |

完整说明见 [NOTICE.md](NOTICE.md)。**全部美术素材已替换为 CC0/OFL 可商用来源**（原 GDQuest 非商用素材已移除），免费或付费发布均无许可障碍。

## 路线图

- [x] U1 重开/HUD/音效
- [x] U2 打击感
- [x] U3 经验与升级三选一
- [x] U4 敌人变体与更次
- [x] U5 主菜单、暂停菜单、最高纪录存档
- [x] U6 更多法宝（环绕飞刀 / 灼热光环 / 分裂弹头）
- [x] P2 灵石经济与坊市万宝楼（局外永久强化）
- [x] P3 法宝化灵（刃风暴 / 烈日领域 / 剑光化灵）
- [x] P4 妖王与藏宝匣（三段冲锋 AI + 随机奖励）
- [ ] 主题换皮、发布页
