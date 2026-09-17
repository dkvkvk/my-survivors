# My Survivors 🎮

一款用 **Godot 4 + GDScript** 开发的 2D 割草幸存者游戏。操控小方块幽灵在被史莱姆淹没的荒野中求生：自动射击、收集经验、升级三选一，看你能活多久。

> 基于 [GDQuest](https://www.gdquest.com/) 的开源教学项目 [getting-started-with-godot-4](https://github.com/gdquest-demos/getting-started-with-godot-4) 二次开发。

## 在线试玩

**[点击直接玩（GitHub Pages）](https://dkvkvk.github.io/my-survivors/)** — 需要键盘，推荐 Chrome/Edge。

## 玩法

| 按键 | 操作 |
|---|---|
| WASD / 方向键 | 移动（枪自动瞄准最近的敌人开火） |
| 鼠标点击 / R | 升级和游戏结束界面做选择 |

**核心循环**：杀怪 → 捡经验宝石（会自动滚向你）→ 升级 → 三选一强化 → 变强 → 面对更强的怪。

**五种强化卡**：疾风之靴（移速）/ 灵巧扳机（射速）/ 重装弹药（伤害）/ 生命祝福（血量）/ 磁力护符（拾取范围）。

**四种敌人**（按时间分波登场）：

| 敌人 | 血量 | 特点 |
|---|---|---|
| 史莱姆 | 2 | 基础怪，开局就有 |
| 疾跑怪 | 1 | 金黄色，快而脆 |
| 坦克 | 8 | 大只头，慢但硬，掉 5 经验 |
| 精英 | 20 | 红色巨兽，碰一下 2.5 倍痛，掉 15 经验 |

## 功能

- 完整成长循环：经验宝石磁吸拾取、等级曲线（前期快、后期封顶）
- 升级三选一强化卡（卡池数据驱动，加卡只需在 `upgrades.gd` 加一行）
- 四种敌人变体 + 五档波次难度曲线（`balance.gd` 两张表全管）
- 打击感：震屏、受击闪白、hit-stop 定帧、伤害数字（[Saltmire Juice](https://github.com/saltmire/saltmire-juice)）
- 8-bit 音效（CC0）、无限滚动草地地图、击杀/时间/经验 HUD

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
game.gd            # 主逻辑：刷怪、波次、HUD、胜负流程
player.gd          # 玩家：移动、血量、经验等级、强化应用
mob.gd             # 敌人：变体属性、软分离围圈、掉宝石
gun.gd / bullet_2d.gd
xp_gem.gd          # 经验宝石：磁吸 + 缓慢滚动
level_up_ui.gd     # 升级三选一界面
balance.gd         # ★ 全部数值：经验曲线/敌人变体/波次表
upgrades.gd        # ★ 强化卡池
audio.gd           # 音效池（12 播放器，防重叠变调）
addons/saltmire_juice/
```

## 致谢与许可

| 内容 | 来源 | 许可 |
|---|---|---|
| 代码基础 | GDQuest getting-started-with-godot-4 | MIT |
| 角色美术 | GDQuest | **CC-BY-NC-SA（非商用）** |
| 打击感插件 | Saltmire Juice | MIT |
| 音效 | Juhani Junkala 8-bit 音效包 | CC0 |
| 草地贴图 | OpenGameArt Seamless Grass II | CC0 |

完整说明见 [NOTICE.md](NOTICE.md)。**注意**：本项目当前美术素材为非商用许可，发布免费游戏没问题，商业化前需替换全部美术。

## 路线图

- [x] U1 重开/HUD/音效
- [x] U2 打击感
- [x] U3 经验与升级三选一
- [x] U4 敌人变体与波次
- [ ] U5 主菜单、暂停菜单、最高纪录存档
- [ ] U6 更多武器、主题换皮、发布页
