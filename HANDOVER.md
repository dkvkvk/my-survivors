# 交接文档（HANDOVER）

> 《不退》（NO RETREAT，repo 名 my-survivors）——Godot 4.7 割草幸存者游戏。
> 世界观：和风忍者村 + 科技入侵。胜利条件：活满 15 分钟或击破 3 只首领。
> 本文写给接手的 AI agent / 开发者：环境、架构、约定、坑、验证与发布流程、待办。

## 0. 快速上手

- 项目路径：`E:\games\my-survivors`（git 仓库，远端 `github.com/dkvkvk/my-survivors`，另有 upstream 指向 GDQuest 教程原仓库）
- 引擎：Godot **4.7.2**，注意可执行文件在**目录**里：
  `D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`（带控制台输出的版本是同目录 `_console.exe`）
- 双击运行：项目根有 `直接运行游戏.bat` / `打开编辑器.bat`
- 主场景：`main_menu.tscn`（主菜单 → 开始游戏 → `survivors_game.tscn`）
- 视口 1920×1080，渲染 `gl_compatibility`，全局纹理过滤 Nearest（像素风）

## 1. 当前状态（2026-09-21）

已完成并上线（CI 全绿、GitHub Pages 在线版同步部署）：
- 核心割草循环：波次刷怪（5 档）、4 变体怪 + 三段冲锋 AI 首领（每 3 分钟，血量递增，掉宝箱）
- 成长：经验宝石 → 三选一强化卡（8 张，含图标）→ 武器 5 级后第 6 张同名卡进化（刃风暴/烈日领域/手里剑大师）
- 局外：金币掉落 → 死亡入账 → 忍具商店 4 种永久强化（存档持久）
- 地图：无缝科技地板 + 分块拼接障碍（9 种 16×16 瓦片模板随机旋转镜像，5×5 流式加载，瓦片碰撞）
- 视觉：忍者主角为 Ninja Adventure CC0 的 4×4 方向行走表（非 AI，见 NOTICE.md）；其余 AI 生成（四种怪两帧动画、首领、UI 图标、菜单/结算背景、封面）+ 脚本自制（地板/瓦片集）；中文像素字体 Fusion Pixel（OFL）；全局主题/暗角/黑场过渡/青色光尘
- 音频：6 个 CC0 音效 + 两首脚本合成循环 BGM
- 平衡基准：**站桩挂机必死**（约 1 分钟），走位风筝才有活路

P6 武器/技能系统（进行中，权威设计见 `WEAPON_SYSTEM.md`）：
- 蓝条 + 4 技能槽（键位 1/2/3/4）+ 冷却 + 技能 HUD
- **模型 B：一把武器 = 一个被动效果 + 一组技能**；被动等级 = 武器等级，满级自动进化
  - 被动由 `player._apply_weapon_passive()` 分发；加武器要同步改 `_clear_weapon_passive()` / `_evolve_weapon()`
- 背包（按 B）、武器掉落（按 F 拾取 + 替换面板）、材料掉落、武器升级（材料 + 击杀数）
- 升级三选一只出属性卡；宝箱奖励改走武器/材料体系
- **特效系统（`vfx.gd` + `assets/fx/`）**：技能起手冲击环 / 旋转刀光 / 金色爆发 / 天雷落柱、命中爆点、
  击杀爆炸、拾取星芒、升级光柱、枪口闪光、子弹与飞刀拖尾、首领蓄力预警圈、技能栏冷却完成闪光
  - ⚠️ 特效节点一律 `PROCESS_MODE_ALWAYS`：升级/结算会暂停游戏，跟着暂停会把短命特效冻在画面上
  - ⚠️ 全屏闪全局**复用同一块遮罩**，多次调用只刷新颜色（否则连续放技能会叠成一片死白）

## 2. 架构速览

详细导览见 `ARCHITECTURE.md`（与代码同步维护）。关键点：

| 文件 | 职责 |
|---|---|
| `balance.gd` | ★ 全部数值：波次表/变体（含贴图路径）/武器/进化/首领/金币/商店/击退 |
| `upgrades.gd` | ★ 卡池（8 张卡含 icon 路径）。加卡 = 加一行 + player.apply_upgrade 加分支 |
| `game.gd` | 主循环：刷怪/波次/HUD/首领计时/Boss 警告/金币计数/挂载 ChunkMap |
| `player.gd` | 移动/血量/经验/强化应用/武器进化状态机/商店加成应用/卡池过滤 |
| `mob.gd` | 怪+首领（setup_boss 升格）/三段 AI/受击击退/掉落（宝石/金币/宝箱） |
| `enemy_sprite.gd` | 怪外观适配器（两帧动画+受击压扁），贴图路径来自 balance 变体表 |
| `hero.gd` | 忍者：4 列=朝向(下上左右) × 行 0-3=行走帧 的表切帧，速度驱动自动选向 |
| `chunk_map.gd` | 分块地图：TileSet 代码构建（碰撞挂瓦片）、模板随机拼接、流式加载 |
| `orbit_blades.gd` / `aura.gd` / `gun.gd` | 三武器 + 各自 evolve() 进化形态 |
| `coin.gd` / `chest.gd` / `xp_gem` | 掉落物（磁吸拾取 / 走近开启随机奖励） |
| `save.gd` | `class_name SaveGame` 纯静态：records+coins+upgrades 存 `user://records.json` |
| `main_menu/shop/level_up_ui/pause_ui/game_over` | 各 UI（CanvasLayer + process_mode=3 暂停模式） |
| `victory_ui.gd` | 胜利结算（P5）：活满 `SURVIVE_WIN_TIME` 或击破 `VICTORY_BOSS_KILLS` 只首领触发 |
| `fader.gd` | autoload：黑场过渡 + 暗角后期（切场景统一走 `Fader.fade_to_scene()`） |
| `audio.gd` | autoload：12 池音效 + `play_music()` 循环 BGM |
| `vfx.gd` | ★ autoload `VFX`：**全局特效库**（冲击环/斩击弧/爆散粒子/拖尾/全屏闪/天雷落点），纯代码绘制 + `assets/fx/` 像素贴图 |
| `theme.tres` + `fonts/` | 全局像素主题；字号取 12 的倍数 |
| `assets/` | hero/mobs/ui/tiles/ground —— AI 生成 + 自制，全部可商用（见 NOTICE.md） |

**三条铁律约定**：
1. 伤害单一入口 `mob.take_damage(amount, knockback)`——新武器零改动接入
2. 碰撞：障碍/墙只挡玩家（物理层 1），**怪物和子弹穿行**（防卡怪、防自动瞄准浪费）；玩家碰撞是"脚部小碰撞"36×22
3. 所有可调数值进 `balance.gd`，别散落硬编码
4. **加特效走 `VFX` 原语**（`VFX.impact` / `shockwave` / `slash_arc` / `burst` / `screen_flash` / `trail`），
   别在各处手搓特效节点——统一入口才能统一风格、统一限流（`FX_LIMIT`）

## 3. 验证流程（重要，别跳过）

### headless 快检
```bash
G="/d/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path /e/games/my-survivors --import 2>&1 | grep -iE "Parse Error|Failed to load|non-existent" | grep -v "Out of bounds"
# 预期只有 colorpicker 插件的 "Out of bounds" 噪音（编辑器插件，无害）
"$G" --headless --path /e/games/my-survivors --quit-after 240 2>&1 | grep -cE "SCRIPT ERROR|SHADER ERROR|no animation"
# 预期 0
```

### 单元/集成测试（`--script` 自定义 MainLoop）
```gdscript
extends SceneTree
func _initialize() -> void: change_scene_to_file("res://survivors_game.tscn")
func _process(_delta) -> bool:  # 必须有返回值，否则 Parse Error
    # 按帧计数推进，用 root.get_node("Game")... 断言后 return true 退出
```
**坑**：该模式下物理不步进，Area 的 overlapping 查询不可靠；要测物理/检测链路就在场景内用帧计数驱动真实节点（参考历史提交里的 test_boss 做法）。

### 实机点测（无 computer-use 时的替代）
后台启动 exe → PowerShell `SendKeys`（TAB/ENTER/{D}/{S}…）模拟操作 → `CopyFromScreen` 截图 → `Read` 图片 → 视觉模型核对。历史会话全靠这套验证 UI。

## 4. 发布流程（推送 GitHub）

- 直连 github.com 被墙；用户代理（Clash，127.0.0.1:7897）经常没开。
- 可用方案：临时 Python CONNECT 代理转发到可达 IP（会轮换，先 `curl -sI -m 6 --resolve github.com:443:<IP> https://github.com` 筛选；近期 20.27.177.113 / 140.82.113.4 多数可用），推送完立即关闭。脚本模式见 git 历史（ghpush_proxy.py）。
- 推送 main 自动触发 Actions：Windows exe（Artifact）+ Web（部署 Pages）。**Web 预设的 export_path 不能为空**（踩过：空路径导致 CI 失败）。
- 匿名 GitHub API 有限流，查 CI 用 `gh run list --repo dkvkvk/my-survivors`（本机 gh 已认证）。

## 5. 美术管线（game-art-gen skill）

- skill 位置：`~/.agents/skills/game-art-gen/`（SKILL.md 工作流 + scripts/generate.py + scripts/process.py + references/presets.md 提示词模板）
- 用户用**网页版 Nano Banana**生成（无 API），流程：我给提示词 → 用户生成 → 放 `E:\games` → 我处理接入。
- 比例铁律：单体精灵/图标 1:1；两帧动画=第一帧 1:1 + 参考图改姿势（不要双格表，格子会压扁）；4×4 方向表 1:1；背景/封面 16:9。
- 提示词必带：`solid magenta background (#FF00FF)` + `no text, no watermark` + `crisp pixels`。
- 处理管线：洋红抠底（r>150 且 b>100 且 g<min(r,b)-60）→ bbox 裁剪 → 像素化（怪 24px/16 色，首领 32px，表整缩 64×64）→ 接入 → 实机截图验证。
- 新怪贴图：改 `balance.gd` 变体表的 sprites 路径即可；首领放 `assets/mobs/boss_0/1.png` 自动生效。
- AI 素材商用条款遵循 Gemini API 条款，NOTICE.md 已登记。

## 6. 踩过的坑（接手前必读）

1. **GDScript 类型推断**：`:=` 对 Variant 会报 "Cannot infer"——凡 `get_parent().xxx`、字典取值、字符串索引结果，一律显式类型（`var x: float = ...`）。
2. `for x in (a, b, c)` 是语法错误（元组），要 `[a, b, c]`；argparse 的 `--in` 撞 Python 关键字（用 `dest="infile"`）。
3. GLSL 着色器没有 `:=`。
4. **缩进即逻辑**：曾有死亡判定被误缩进进击退分支、怪打不死查了半天——大改后 grep 检查关键 if 的层级。
5. Godot 会在运行后回写 project.godot / .tscn（加 uid 等），手改场景文件后 import 一次再看 diff；`.tscn` 手工编辑时 ext_resource 的 id 必须真实存在（引用不存在资源=Parse Error 指向使用行）。
6. TileSet 物理：必须先 `add_source` 再给 TileData 加碰撞多边形（顺序反了碰撞静默失效）。
7. 怪物碰撞圆/受击框几何要保证"攻击环最远停点 + 碰撞半径 > 受击框半宽"，否则掉血链路断（HurtBox mask 必须=2）。
8. **项目改名会改 user:// 目录**。原来只设了 `config/custom_user_dir_name` 而**漏了 `config/use_custom_user_dir=true`**，所以设置一直没生效——存档实际落在 `app_userdata/不退/`（历史遗留 `My Survivors/`、`忍者今天也在割韭菜/` 都是改名留下的孤儿目录）。**2026-09-21 已补上该开关**，现在固定为 `app_userdata/my-survivors/`。
9. 窗口标题=project.godot 的 config/name（**不退**）；仓库名/导出文件名仍是 my-survivors。
10. **贴图放错文件**：曾有"道具在乱跑"——AI 生成的是 3×3 升级卡图标九宫格，却被写进了 `assets/hero/ninja_sheet.png`，`hero.gd` 按 16px 切成 4×4 方向表，于是玩家身上显示的是图标碎片（同时 2c39948 那版提交的这张表 sha=1f5e0af1…，是坏的那张）。`ninja_sheet.png` 必须是 64×64 的 4×4 忍者行走表（Ninja Adventure CC0），已从 `97e93c6` 恢复，正确 sha256=`ea03e60f906dbab72a5be39bba04a8ad0d23854a9b6af8df48df45abf306bcb6`。**教训**：接入素材后必须实机截图核对"是谁在用这张图"，别只看文件名。
11. **左右列映射别乱改**：上面那张坏图标表曾让人以为"新表左右列相反"，于是 `hero.gd` 的 `DIR_COL` 被改成 `left:3, right:2`——结果向左走时人是倒着走的。恢复正版表后已改回标准顺序 `{"down":0,"up":1,"left":2,"right":3}`（col2 面朝左、col3 面朝右，已验证）。**换方向表后必须重新核对左右**：把该朝向的行走帧渲染出来看脸朝哪边，不要凭围巾位置猜。
11b. **精灵表某列"帧间朝向不一致"**：忍者表 col2（左向）4 帧的脸部横坐标实测 9.2/7.0/3.3/10.0 乱跳——它根本不是一套连贯的左向走路，当循环播会像"原地转身"。**别靠对调左右来绕**（那只是把问题换到右边），正解是**镜像正常的右向列**：`hero.gd` 用 `MIRROR_OF = {"left": "right"}` + 播放时 `_sprite.flip_h = (_last_dir == "left")`。
    **判断某列能不能用**：量该列 4 帧的"脸/眼"横坐标，方差大就是坏的（col0 全是 7.5 → 好；col3 是 8.7/7.5/8.5/9.5 → 好；col2 乱跳 → 坏）。
12. **一整批素材互相错位**（2c39948 那批 AI 生成）：
    - `ninja_sheet.png` 装的是升级卡图标九宫格 → 已换回正版忍者表（见第 10 条）；
    - 8 张 `card_*.png` 装的是忍者表碎片 → 已从九宫格里按格裁出正确图标（每张 21~22px）；
    - 4 张 `icon_*.png` 每张被塞了**两个**图标且互相串门（coin 文件里有 coin+chest，chest 文件里有 gem+shuriken…）→ 已拆开、各归各位；
    - 空白/未用：`icon_gem` 的右半是红球、`icon_shuriken` 的左半是灰手里剑、`icon_chest` 的右半是灰手里剑，均未使用。
    **教训**：AI 生成的图常把多张素材拼在一张里，接入时必须**逐张渲染确认内容**再命名，不能按生成顺序假设。
13. **`.tscn` 里父节点必须先声明**：`Card1Icon`/`Card2Icon` 曾被写在父节点 `Card1`/`Card2` **之前**，Godot 无法挂载，直接把它们丢到场景根并改名成 `LevelUpUI_Card2#Card2Icon`，于是 `level_up_ui.gd` 的 `get_node("Card1/Card1Icon")` 拿到 null，升级卡图标永远不显示（还每局刷 SCRIPT ERROR）。**手工编辑 `.tscn` 后必须确认节点块是父先子后**。
14. **验证素材要固定输入再截图**：`SendKeys` 的 `{A DOWN}` 语法无效（会报 repeat count），用 `keybd_event`；且 harness 场景根节点必须叫 `Game`，否则脚本里写死的 `/root/Game/Player` 全部解析成 null。

## 7. 待办与机会（按建议优先级）

1. **Web 版瘦身**：wasm 39MB 首载慢。字体子集化（Fusion Pixel 4.9MB → 用 pyftsubset 按游戏实际用字裁剪到几百 KB）收益最大。
2. **itch.io 发布页**：封面已备好（`assets/ui/cover.png`），README 可嵌的素材齐全。
3. 玩法 P5：更多武器/多角色/成就；卡池可加权重与稀有度。
4. 主菜单/商店/暂停按钮加图标（`assets/ui/star.png` 现成备用，八张卡图标可复用）。
5. BGM 可换更好的曲子（现在是脚本合成的，生成思路见 git 历史 synth_bgm）。
6. 首领目前一只形象，可加多种（模板机制已支持，见 chunk_map 的做法）。
7. 手机触屏虚拟摇杆（Web 版手机不可玩）。
7b. **第 5/6 种武器 + 给武器补多技能**：补齐后"替换面板 / 技能切换书 / 武器掉落"才真正有意义（见 WEAPON_SYSTEM.md 待办）。
7c. **精确击杀归属**：现在每击杀给所有武器各 +1，需要 `take_damage` 带来源武器 id。
8. README/ARCHITECTURE 与代码保持同步——每次功能落地后更新（本项目的习惯）。

## 8. 其他背景

- 二开源头：GDQuest 教程 getting-started-with-godot-4（代码 MIT）；美术已全部替换，商用无障碍。
- git 提交习惯：中文一行标题+要点列表，一个功能一提交，改完即推（CI 会双端构建）。
- 用户偏好：中文交流；要实机验证截图确认；美术走 AI 生成管线；风格统一"像素+科技+忍者"。
- 当前工作树干净，全部已推送（HEAD 见 `git log -1`）。
