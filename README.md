# 忍者今天也在割韭菜 🥬

一款用 **Godot 4 + GDScript** 开发的 2D 割草幸存者游戏。操控像素小忍者在被怪物淹没的科技基地里求生：自动投掷手里剑、收集经验与金币、升级三选一、死亡后在忍具商店购买永久强化，看你能活多久。**全部美术素材为 CC0/OFL 可商用**。

> 基于 [GDQuest](https://www.gdquest.com/) 的开源教学项目 [getting-started-with-godot-4](https://github.com/gdquest-demos/getting-started-with-godot-4) 二次开发。

## 在线试玩

**[点击直接玩（GitHub Pages）](https://dkvkvk.github.io/my-survivors/)** — 需要键盘，推荐 Chrome/Edge。

## 玩法

| 按键 | 操作 |
|---|---|
| WASD / 方向键 | 移动（手里剑自动瞄准最近的敌人发射） |
| 鼠标点击 / R | 升级和游戏结束界面做选择 |
| Esc | 暂停菜单（继续 / 重开 / 回主菜单） |

**核心循环**：杀怪 → 捡经验宝石（会自动滚向你）→ 升级 → 三选一强化 → 变强 → 面对更强的怪。怪物掉**金币**，死亡结算入账，主菜单的**忍具商店**可购买永久强化（生命/伤害/移速/拾取范围），下一局更强。最高纪录（存活/击杀/等级）自动存本地。

**八种强化卡**：疾风之靴（移速）/ 灵巧扳机（射速）/ 重装弹药（伤害）/ 生命祝福（血量）/ 磁力护符（拾取范围），外加三张可叠加的武器卡——**环形刀刃**（环绕飞刀 +1）/ **灼热光环**（周期灼烧，范围与伤害递增）/ **分裂弹头**（手枪扇形散射 +1 弹）。

**四种敌人**（按时间分波登场）：

| 敌人 | 血量 | 特点 |
|---|---|---|
| 史莱姆 | 3 | 基础怪，开局就有 |
| 蝙蝠 | 1 | 飞得快而脆，30 秒后混入 |
| 重甲兵 | 10 | 大块头，慢但硬，掉 5 经验 |
| 魔化野兽 | 20 | 泛红巨兽，碰一下 2.5 倍痛，掉 15 经验 |

难度节奏偏紧：站桩挂机会在 1~2 波内被围死，走位风筝怪、规划路线捡宝石才是正解。

## 功能

- 完整成长循环：经验宝石磁吸拾取、等级曲线（前期快、后期封顶）
- 升级三选一强化卡（卡池数据驱动，加卡只需在 `upgrades.gd` 加一行）
- 三种可叠加武器卡：环绕飞刀 / 灼热光环 / 分裂弹头（纯代码绘制，无新增美术素材）
- 武器进化（P3）：同名武器卡满 5 级后第 6 张触发进化——刃风暴（转速翻倍）/ 烈日领域（灼烧减半）/ 手里剑大师（弹丸+2 射速+20%），进化后该卡移出卡池
- 四种敌人变体 + 五档波次难度曲线（`balance.gd` 两张表全管）
- 分块无限地图：9 种预设计小地图随机拼接（墙/货箱/服务器带碰撞，水晶/灌木装饰），看得见才撞得上
- 主菜单、Esc 暂停菜单、最高纪录本地存档（`user://records.json`，Web 版同样可用）
- 局外成长（P2）：怪物掉金币 → 死亡入账 → 忍具商店四种永久强化（生命/伤害/移速/磁力，逐级涨价）
- 打击感：震屏、受击闪白、hit-stop 定帧、伤害数字、命中击退、死亡碎片（[Saltmire Juice](https://github.com/saltmire/saltmire-juice)）
- 循环 BGM（菜单/战斗两首，8-bit 风格自制合成）+ 低血量红色脉冲警告
- 像素风统一视觉：忍者主角（四方向行走动画）+ CC0 怪物/装饰、中文像素字体（Fusion Pixel）、全局主题（`theme.tres`）、暗角后期、场景黑场过渡、环境光尘粒子
- 8-bit 音效（CC0）、无缝科技感地板、青色环境光尘、击杀/时间/经验 HUD

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
game.gd           # 主逻辑：刷怪、波次、HUD、胜负流程
chunk_map.gd      # ★ 分块无限地图：小地图模板随机拼接 + 瓦片碰撞 + 流式加载
hero.gd           # 忍者角色：四方向待机/行走动画（素材 Ninja Adventure）
player.gd         # 玩家：移动、血量、经验等级、强化与武器应用
mob.gd            # 敌人：变体属性、软分离围圈、掉宝石、击退
enemy_sprite.gd   # 敌人外观适配器：两帧动画 + 受击压扁（Kenney 素材）
gun.gd / bullet_2d.gd  # 自动发射与旋转手里剑（代码绘制）
orbit_blades.gd   # 武器卡：环绕飞刀（纯代码绘制，可叠加）
aura.gd           # 武器卡：灼热光环（周期 AoE，可叠加）
xp_gem.gd         # 经验宝石：磁吸 + 缓慢滚动
level_up_ui.gd    # 升级三选一界面
pause_ui.gd       # 暂停菜单（Esc）
game_over.gd      # 结算界面：本局战绩 + 新纪录提示
coin.gd           # 金币掉落物：磁吸拾取（P2 局外经济）
shop.gd / shop.tscn  # 忍具商店：永久强化购买
save.gd           # ★ 存档：最高纪录 + 金币余额 + 强化等级（user://records.json）
balance.gd        # ★ 全部数值：经验曲线/敌人变体/波次表/武器
upgrades.gd       # ★ 强化卡池
audio.gd          # 音效池 + 循环 BGM
fader.gd          # 全局过渡：黑场淡入淡出 + 暗角后期（autoload）
theme.tres        # ★ 全局主题：像素字体 + 按钮/进度条样式
assets/           # CC0 素材：忍者（Ninja Adventure）/怪物（Kenney）/地板与瓦片（自制）
fonts/            # Fusion Pixel 中文像素字体（SIL OFL 1.1）
addons/saltmire_juice/
```

## 致谢与许可

| 内容 | 来源 | 许可 |
|---|---|---|
| 代码基础 | GDQuest getting-started-with-godot-4 | MIT |
| 忍者角色 | [Ninja Adventure（pixel-boy）](https://pixel-boy.itch.io/ninja-adventure) | **CC0** |
| 怪物素材 | [Kenney Pixel Platformer](https://kenney.nl/assets/pixel-platformer) | **CC0** |
| 瓦片集（墙/货箱/服务器/水晶等） | 本项目脚本生成 | **CC0（自制）** |
| 科技感地面/装饰 | 本项目脚本生成（无缝平铺） | **CC0（自制）** |
| 打击感插件 | Saltmire Juice | MIT |
| 音效 | Juhani Junkala 8-bit 音效包 | CC0 |
| 背景音乐 | 脚本合成的 8-bit 循环曲（本项目自制） | CC0 |
| 中文字体 | [Fusion Pixel](https://github.com/TakWolf/fusion-pixel-font)（缝合像素） | SIL OFL 1.1 |

完整说明见 [NOTICE.md](NOTICE.md)。**全部美术素材已替换为 CC0/OFL 可商用来源**（原 GDQuest 非商用素材已移除），免费或付费发布均无许可障碍。

## 路线图

- [x] U1 重开/HUD/音效
- [x] U2 打击感
- [x] U3 经验与升级三选一
- [x] U4 敌人变体与波次
- [x] U5 主菜单、暂停菜单、最高纪录存档
- [x] U6 更多武器（环绕飞刀 / 灼热光环 / 分裂弹头）
- [x] P2 金币经济与忍具商店（局外永久强化）
- [x] P3 武器进化（刃风暴 / 烈日领域 / 手里剑大师）
- [ ] P4 Boss 与宝箱、主题换皮、发布页
