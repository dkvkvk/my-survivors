# 交接文档（HANDOVER）

> 《忍者今天也在割韭菜》（repo 名 my-survivors）——Godot 4.7 割草幸存者游戏。
> 本文写给接手的 AI agent / 开发者：环境、架构、约定、坑、验证与发布流程、待办。

## 0. 快速上手

- 项目路径：`E:\games\my-survivors`（git 仓库，远端 `github.com/dkvkvk/my-survivors`，另有 upstream 指向 GDQuest 教程原仓库）
- 引擎：Godot **4.7.2**，注意可执行文件在**目录**里：
  `D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`（带控制台输出的版本是同目录 `_console.exe`）
- 双击运行：项目根有 `直接运行游戏.bat` / `打开编辑器.bat`
- 主场景：`main_menu.tscn`（主菜单 → 开始游戏 → `survivors_game.tscn`）
- 视口 1920×1080，渲染 `gl_compatibility`，全局纹理过滤 Nearest（像素风）

## 1. 当前状态（2026-09-20）

已完成并上线（CI 全绿、GitHub Pages 在线版同步部署）：
- 核心割草循环：波次刷怪（5 档）、4 变体怪 + 三段冲锋 AI 首领（每 3 分钟，血量递增，掉宝箱）
- 成长：经验宝石 → 三选一强化卡（8 张，含图标）→ 武器 5 级后第 6 张同名卡进化（刃风暴/烈日领域/手里剑大师）
- 局外：金币掉落 → 死亡入账 → 忍具商店 4 种永久强化（存档持久）
- 地图：无缝科技地板 + 分块拼接障碍（9 种 16×16 瓦片模板随机旋转镜像，5×5 流式加载，瓦片碰撞）
- 视觉：全 AI 生成素材（忍者为 4 方向行走表、四种怪两帧动画、首领、UI 图标、菜单/结算背景、封面）+ 脚本自制（地板/瓦片集）；中文像素字体 Fusion Pixel（OFL）；全局主题/暗角/黑场过渡/青色光尘
- 音频：6 个 CC0 音效 + 两首脚本合成循环 BGM
- 平衡基准：**站桩挂机必死**（约 1 分钟），走位风筝才有活路

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
| `fader.gd` | autoload：黑场过渡 + 暗角后期（切场景统一走 `Fader.fade_to_scene()`） |
| `audio.gd` | autoload：12 池音效 + `play_music()` 循环 BGM |
| `theme.tres` + `fonts/` | 全局像素主题；字号取 12 的倍数 |
| `assets/` | hero/mobs/ui/tiles/ground —— AI 生成 + 自制，全部可商用（见 NOTICE.md） |

**三条铁律约定**：
1. 伤害单一入口 `mob.take_damage(amount, knockback)`——新武器零改动接入
2. 碰撞：障碍/墙只挡玩家（物理层 1），**怪物和子弹穿行**（防卡怪、防自动瞄准浪费）；玩家碰撞是"脚部小碰撞"36×22
3. 所有可调数值进 `balance.gd`，别散落硬编码

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
8. 项目改名会改 user:// 目录——已设 `custom_user_dir_name="my-survivors"` 固定，再改名存档不丢。
9. 窗口标题=project.godot 的 config/name（忍者今天也在割韭菜）；仓库名未改。

## 7. 待办与机会（按建议优先级）

1. **Web 版瘦身**：wasm 39MB 首载慢。字体子集化（Fusion Pixel 4.9MB → 用 pyftsubset 按游戏实际用字裁剪到几百 KB）收益最大。
2. **itch.io 发布页**：封面已备好（`assets/ui/cover.png`），README 可嵌的素材齐全。
3. 玩法 P5：更多武器/多角色/成就；卡池可加权重与稀有度。
4. 主菜单/商店/暂停按钮加图标（`assets/ui/star.png` 现成备用，八张卡图标可复用）。
5. BGM 可换更好的曲子（现在是脚本合成的，生成思路见 git 历史 synth_bgm）。
6. 首领目前一只形象，可加多种（模板机制已支持，见 chunk_map 的做法）。
7. 手机触屏虚拟摇杆（Web 版手机不可玩）。
8. README/ARCHITECTURE 与代码保持同步——每次功能落地后更新（本项目的习惯）。

## 8. 其他背景

- 二开源头：GDQuest 教程 getting-started-with-godot-4（代码 MIT）；美术已全部替换，商用无障碍。
- git 提交习惯：中文一行标题+要点列表，一个功能一提交，改完即推（CI 会双端构建）。
- 用户偏好：中文交流；要实机验证截图确认；美术走 AI 生成管线；风格统一"像素+科技+忍者"。
- 当前工作树干净，全部已推送（HEAD 见 `git log -1`）。
