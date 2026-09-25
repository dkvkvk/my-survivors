# 交接文档（HANDOVER）

> 《不退》（NO RETREAT，repo 名 my-survivors）——Godot 4.7 割草幸存者游戏。
> 世界观：中国修仙世界（魔渊妖潮 · 青冥山守夜）。胜利条件：活满 15 分钟（守到黎明）或击破 3 只妖王。

> **修仙化改版进度（2026-09-21 全部完成）**：批次 A（文案与系统命名）✅、批次 B~E（图标 / 地图 / 角色 / 背景美术）✅、批次 F（文档术语清洗）✅。
> 38 张生图经 `tools/import_ai_art.py` 入库，实机截图逐张验收通过。世界观见 `WORLDVIEW.md`，改造清单见 `REFACTOR_XIANXIA.md`，生图清单见 `XIANXIA_ART_PROMPTS.md`。
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
- 核心割草循环：更次刷怪（5 档）、4 变体怪 + 三段冲锋 AI 妖王（每 3 分钟，血量递增，掉藏宝匣）
- 成长：灵珠 → 三选一强化卡（8 张，含图标）→ 法宝 5 级后第 6 张同名卡进化（刃风暴/烈日领域/剑光化灵）
- 局外：灵石掉落 → 死亡入账 → 坊市万宝楼 4 种永久强化（存档持久）
- 地图：无缝青石板 + 分块拼接障碍（9 种 16×16 瓦片模板随机旋转镜像，5×5 流式加载，瓦片碰撞）
- 视觉：守山人主角为 Ninja Adventure CC0 的 4×4 方向行走表（非 AI，见 NOTICE.md）；其余 AI 生成（四种怪两帧动画、妖王、UI 图标、菜单/结算背景、封面）+ 脚本自制（地板/瓦片集）；中文像素字体 Fusion Pixel（OFL）；全局主题/暗角/黑场过渡/灵光浮尘
- 音频：6 个 CC0 音效 + 两首脚本合成循环 BGM
- 平衡基准：**站桩挂机必死**。2026-09-21 实测：站桩约 **12~13 秒**死亡（旧碰撞规则 12.9s、新规则 12.3s，墙不改变站桩难度）

P6 法宝/技能系统（进行中，权威设计见 `WEAPON_SYSTEM.md`）：
- 蓝条 + 4 技能槽（键位 1/2/3/4）+ 冷却 + 技能 HUD
- **模型 B：一把法宝 = 一个被动效果 + 一组技能**；被动等级 = 法宝品阶，满级自动进化
  - 被动由 `player._apply_weapon_passive()` 分发；加法宝要同步改 `_clear_weapon_passive()` / `_evolve_weapon()`
- 乾坤袋（按 B）、法宝掉落（按 F 拾取 + 替换面板）、材料掉落、法宝升级（材料 + 斩妖数）
- 升级三选一只出属性卡；藏宝匣奖励改走法宝/材料体系
- **开局选法宝**（4 张卡 = 本命飞剑 + 随机 3 把，暂停游戏；选本命飞剑 = 起手 3 阶）+ 掉落率 4%→12% + 开局保底
- **6 把法宝**：本命飞剑 / 周天剑环 / 离火法环 / 连环雷符 / **回风梭** / **地火符阵**
  （法宝位仍是 4 → 拾到未持有的第 5 把会弹替换面板，"带哪几件"成为真实取舍）
- **精确斩妖归属**：`take_damage(amount, knockback, source)`，斩妖经验只记给致命一击的法宝
- **触屏操作（P2b）**：左下虚拟摇杆 + 右下神通按钮 + **右上三个功能按钮（拾取 / 乾坤袋 / 暂停）**，
  纯代码 Line2D 圆环 + 光晕，只在真有触摸时存在（桌面键鼠下自毁）。
  手机上没有 F / B / Esc，这三个入口是"能不能玩"的前提；乾坤袋面板也因此补了**可点的「关闭」按钮**
  （原来只能按 Esc 关，手机上打开就永远关不掉、卡在暂停里）
- **特效系统（`vfx.gd` + `assets/fx/`）**：技能起手冲击环 / 旋转刀光 / 金色爆发 / 天雷落柱、命中爆点、
  斩妖爆炸、拾取星芒、升级光柱、枪口闪光、子弹与飞刀拖尾、妖王蓄力预警圈、技能栏冷却完成闪光
  - ⚠️ 特效节点一律 `PROCESS_MODE_ALWAYS`：升级/结算会暂停游戏，跟着暂停会把短命特效冻在画面上
  - ⚠️ 全屏闪全局**复用同一块遮罩**，多次调用只刷新颜色（否则连续放技能会叠成一片死白）

## 2. 架构速览

详细导览见 `ARCHITECTURE.md`（与代码同步维护）。关键点：

| 文件 | 职责 |
|---|---|
| `balance.gd` | ★ 全部数值：更次表/变体（含贴图路径）/法宝/进化/妖王/灵石/商店/击退 |
| `upgrades.gd` | ★ 卡池（8 张卡含 icon 路径）。加卡 = 加一行 + player.apply_upgrade 加分支 |
| `game.gd` | 主循环：刷怪/更次/HUD/妖王计时/Boss 警告/灵石计数/挂载 ChunkMap |
| `player.gd` | 移动/血量/经验/强化应用/法宝化灵状态机/商店加成应用/卡池过滤 |
| `mob.gd` | 怪+妖王（setup_boss 升格）/三段 AI/受击击退/掉落（宝石/灵石/藏宝匣）/**专属能力**（分裂·飞扑·扑击·撞碎障碍·卡墙自愈） |
| `enemy_sprite.gd` | 怪外观适配器（两帧动画+受击压扁），贴图路径来自 balance 变体表 |
| `hero.gd` | 守山人：4 列=朝向(下上左右) × 行 0-3=行走帧 的表切帧，速度驱动自动选向 |
| `chunk_map.gd` | 分块地图：TileSet 代码构建（碰撞挂瓦片）、模板随机拼接、流式加载 |
| `orbit_blades.gd` / `aura.gd` / `gun.gd` / `chain_lightning.gd` / `boomerang.gd` / `mine.gd` | 六法宝 + 各自 evolve() 进化形态（后三把纯代码绘制） |
| `coin.gd` / `chest.gd` / `xp_gem` | 掉落物（磁吸拾取 / 走近开启随机奖励） |
| `save.gd` | `class_name SaveGame` 纯静态：records+coins+upgrades 存 `user://records.json` |
| `main_menu/shop/level_up_ui/pause_ui/game_over` | 各 UI（CanvasLayer + process_mode=3 暂停模式） |
| `victory_ui.gd` | 胜利结算（P5）：活满 `SURVIVE_WIN_TIME` 或击破 `VICTORY_BOSS_KILLS` 只妖王触发 |
| `fader.gd` | autoload：黑场过渡 + 暗角后期（切场景统一走 `Fader.fade_to_scene()`） |
| `audio.gd` | autoload：12 池音效 + `play_music()` 循环 BGM |
| `touch_controls.gd` | 触屏操作层（P2b）：虚拟摇杆 + 4 神通按钮 + 右上拾取/乾坤袋/暂停；桌面下自毁；玩家通过 `touch_input` 组读方向 |
| `vfx.gd` | ★ autoload `VFX`：**全局特效库**（冲击环/斩击弧/爆散粒子/拖尾/全屏闪/天雷落点/掉落物底衬与爆点），纯代码绘制 + `assets/fx/` 像素贴图 |
| `theme.tres` + `fonts/` | 全局像素主题；字号取 12 的倍数 |
| `assets/` | hero/mobs/ui/tiles/ground —— AI 生成 + 自制，全部可商用（见 NOTICE.md） |

**三条铁律约定**：
1. 伤害单一入口 `mob.take_damage(amount, knockback, source)`——新法宝零改动接入；
   `source` 填自己法宝 id，用于**精确斩妖归属**（致命一击的法宝才 +1 斩妖数，见 `player.add_kill_credit`）
2. 碰撞层：**1=玩家 · 2=敌人 · 3=障碍**；障碍挡玩家，也挡**不穿墙的怪**（`balance.gd` 变体表的 `phasing`，目前只有会飞的阴风鸮为 true）；**子弹一律穿行**（防自动瞄准浪费）；妖王天生穿墙；地面怪被墙卡住约 2.4 秒会短暂穿墙脱困（`mob.gd` 卡墙自愈）。玩家碰撞是"脚部小碰撞"36×22
3. 所有可调数值进 `balance.gd`，别散落硬编码
4. **掉落物可读性**：图标一律垫 `VFX.drop_halo()` 暗色底衬、出现时调 `VFX.drop_spawn_for(self, 颜色)` 出爆点；
   重要掉落（法宝/藏宝匣）再加一根光柱。⚠️ `drop_spawn_for` 是**延迟一帧**取坐标的——掉落物 `_ready()` 时坐标还没被调用方赋值
5. **加特效走 `VFX` 原语**（`VFX.impact` / `shockwave` / `slash_arc` / `burst` / `screen_flash` / `trail`），
   别在各处手搓特效节点——统一入口才能统一风格、统一限流（`FX_LIMIT`）
5b. **震屏/定帧也必须走统一入口**：`VFX.shake(camera, amount)` / `VFX.hitstop(sec, priority)`，
   **不要直接调 `Juice.shake` / `Juice.hitstop`**（L0 判据 `fx-entry` 会拦）。
   原因见坑 #15：trauma 是累加的，散落的高频调用会把画面顶在最大抖动、把 time_scale 钉在 0。
6. **加一种怪/一个能力** = `balance.gd` 的 `MOB_VARIANTS` 加一行（含 `ability` / `phasing`）+ `ABILITIES` 加一条数值
   + `mob.gd` 的 `_apply_ability()` / `_update_ability()` 加一个分支。数值一律进 `ABILITIES`，别写死在 mob.gd

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
**坑**：该模式下 CharacterBody2D 不会真的位移（Area 的 body_entered 倒是会触发）；
要测"真的动起来了"就在真实运行里用 `--quit-after` + 打印坐标（见下面的触屏探针做法）。
另外 **合成 InputEvent 投递不可靠**（`Input.parse_input_event` + `flush_buffered_events` 后仍时有时无），
要测输入逻辑就直接调目标节点的方法。

### 字体子集（改了中文文案必做）
```bash
python tools/subset_font.py          # 重新裁剪 + 校验（漏字会打印缺哪个码位）
python tools/subset_font.py --check  # 只校验（L0 判据 font-coverage 用的就是它）
```
扫 `*.gd`（先剥注释）/ `*.tscn` / `*.tres` 收集字符 → `pyftsubset` → 逐码位比对 cmap。
**注意**：往界面加新汉字（或新符号）后必须重跑，否则运行时是豆腐块；
原字体若被裁没了，用 `git checkout -- fonts/` 拿回全量版再重裁。

### 调手感（抖动 / 定帧）——别靠感觉，看数
```bash
# 测试钩子（见本节末）：
#   MS_AUTOSTART=1  跳过菜单与开局选法宝，直接进战斗（省得手点）
#   MS_FEEL_PROBE=1 每 120 帧汇报手感 + 性能：抖动强度分布、定帧冻结比例、同屏怪数与特效数、帧率
G="/d/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
MS_AUTOSTART=1 MS_FEEL_PROBE=1 "$G" --path /e/games/my-survivors --quit-after 1800 2>&1 | grep FEELSTAT
# 例：frames=120 mean=0.27 max=3.18 over4=0% over10=0% frozen=3% mobs=10 fps=119(min 118) fx=48
# 实测（后期波次 14 只怪 + 48 个特效）：fps 117~119（min 116）—— 性能不是瓶颈
```
实测基线（2026-09-24 修复前）→ 修复后：
| 指标 | 修复前 | 修复后（日常战斗 / 妖王期） |
|---|---|---|
| 平均偏移 | 1.3~9.7px | 0.1~0.8px / 2~3.7px |
| >4px 帧占比 | 0~84% | 0~3% / 21~38% |
| 定帧冻结占比 | 6~22% | 3~7% |
调参入口只有一个：`balance.gd` 的 `CAMERA_SHAKE_GAIN`（整体强度）。
⚠️ 后期同屏怪多（10 只以上连杀）时抖动会回升（实测 >4px 占 41% 的帧）——
那时调 `CAMERA_SHAKE_SWARM_FLOOR`（0.35 → 更小）比调 GAIN 更对症。

### 触屏与移动端验证（本机没有触摸屏）
```bash
# 强制开启触屏层（桌面调试/截图）：命令行 --touch，或环境变量 MS_TOUCH=1
G="/d/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
MS_TOUCH=1 "$G" --path /e/games/my-survivors --resolution 1280x720 --position 0,0
# 验证"摇杆真的推得动角色" + 排查"画面在转"
# 探针会每 90 帧在右/左之间交替，并每 15 帧打印 速度/动画/flip/精灵与相机的 rotation
MS_TOUCH=1 MS_TOUCH_PROBE=1 "$G" --path /e/games/my-survivors --quit-after 900 2>&1 | grep PROBE
```
**坑**：headless `--script` 模式下**合成 InputEvent 投递不可靠**（`Input.parse_input_event` + flush 后仍时有时无），
且 CharacterBody2D 不会真的位移。所以 L0 判据 `touch-controls` 直接驱动触屏层的方法，
"角色真的被摇杆推着走"用上面的 `MS_TOUCH_PROBE` 在**真实运行**里看坐标（实测 ~300px/s）。

### 实机点测（无 computer-use 时的替代）
后台启动 exe → PowerShell `SendKeys`（TAB/ENTER/{D}/{S}…）模拟操作 → `CopyFromScreen` 截图 → `Read` 图片 → 视觉模型核对。历史会话全靠这套验证 UI。

## 4. 发布流程（推送 GitHub）

- **2026-09-24 更新：直连 github.com 已可用**（`curl -s -o /dev/null -w '%{http_code}' https://github.com` → 200）。
- ⚠️ 但本机 git 里存着旧的代理配置 `http.proxy=http://127.0.0.1:7897`，而 Clash 通常没开 →
  `git push` 会报 "Failed to connect to github.com port 443 via 127.0.0.1"。
  **直接绕过它推**：`git -c http.proxy= -c https.proxy= push origin main`
  （想彻底清掉：`git config --unset http.proxy`）
- ⚠️ 但 DNS 也会时不时被污染：`curl https://github.com` → 000，而
  `curl --resolve github.com:443:140.82.113.4 https://github.com` → 200。
  这时用**本地 CONNECT 代理**兜底（已入库，不用再手搓）：

  ```bash
  # 起代理 + 推送 + 收工，必须在同一条命令里（bash 工具退出会带走后台进程）
  python tools/gh_push_proxy.py --port 7899 &      # 自动挑一个可达 IP
  sleep 2
  git -c http.proxy=http://127.0.0.1:7899 push origin main
  ```

  `python tools/gh_push_proxy.py --probe` 可先看哪些候选 IP 可达（2026-09-24 实测 140.82.113.4 可用）。
  想常驻就在自己的终端里跑，别用一次性 bash 工具。
- 推送 main 自动触发 Actions：Windows exe（Artifact）+ Web（部署 Pages）。**Web 预设的 export_path 不能为空**（踩过：空路径导致 CI 失败）。

### 发正式版（长期可下载）——`release.yml`

产物（Artifact）只保留 1 天、且占 Actions 配额，**不适合当"可下载的正式版"**。
要发长期版本就打 tag：

```bash
git tag v0.6.0 && git push origin v0.6.0     # 打 tag 即自动构建 + 建 Release + 附 exe
```

- 触发：`.github/workflows/release.yml`（`push tags: v*`，也可在 Actions 页手动触发并填 tag）
- 产物：**单文件 `my-survivors.exe`**（`binary_format/embed_pck=true`，无需附带 pck）
- Release 附件走**仓库存储**，不占 Actions 配额、不受保留期限制
- 同一 tag 重跑：已存在 Release 时只更新说明与附件（`--clobber`）
- 版本号只是 tag 名（`project.godot` 没有版本字段），随便改；重发就删 tag 重打

### ⚠️ Actions 产物存储只有 0.5GB（免费额度）——2026-09-24 踩过

每次推送产出两个产物：`my-survivors-windows` ≈44MB + `github-pages` ≈17MB。
**默认保留 90 天**，于是 87 次构建攒到 **3.1GB**，GitHub 发来"You have used 100% of the Actions storage"告警
（继续超用会按量计费；若账号设了 $0 预算则**后续运行直接被挡住**）。已处理：

1. 仓库默认保留期改 1 天：`gh api -X PUT repos/dkvkvk/my-survivors/actions/permissions/artifact-and-log-retention -F days=1`
2. 工作流里 `actions/upload-artifact` 显式 `retention-days: 1`
   （`upload-pages-artifact` 不接这个参数，靠上面的仓库默认值兜底）

**查/清产物**：
```bash
# 看现状（数量 + 总量）
gh api "repos/dkvkvk/my-survivors/actions/artifacts?per_page=100" \
  --jq '.artifacts | length, (map(.size_in_bytes) | add / 1048576)'

# 删掉除最新 2 个之外的全部
gh api "repos/dkvkvk/my-survivors/actions/artifacts?per_page=100" \
  --jq '.artifacts | sort_by(.created_at) | reverse | .[2:] | .[].id' \
  | while read id; do gh api -X DELETE "repos/dkvkvk/my-survivors/actions/artifacts/$id" >/dev/null; done
```

**踩过的坑**：想"保留每个名字最新的一个"时，别写成
`[.artifacts | ... | map(.[0].id)] | .[]` —— 外面多套一层方括号会让 jq 输出**一个数组**，
于是 `grep -qx` 匹配不上，循环把**全部**产物都删了（含最新的那份，只能重新构建补回来）。
- 匿名 GitHub API 有限流，查 CI 用 `gh run list --repo dkvkvk/my-survivors`（本机 gh 已认证）。

## 5. 美术管线（game-art-gen skill）

- skill 位置：`~/.agents/skills/game-art-gen/`（SKILL.md 工作流 + scripts/generate.py + scripts/process.py + references/presets.md 提示词模板）
- 用户用**网页版 Nano Banana**生成（无 API），流程：我给提示词 → 用户生成 → 放 `E:\games` → 我处理接入。
- 比例铁律：单体精灵/图标 1:1；两帧动画=第一帧 1:1 + 参考图改姿势（不要双格表，格子会压扁）；4×4 方向表 1:1；背景/封面 16:9。
- 提示词必带：`solid magenta background (#FF00FF)` + `no text, no watermark` + `crisp pixels`。
- 处理管线：python tools/import_ai_art.py（洋红抠底 → bbox → 等比装 box → 两帧统一量化 → 画布对齐）
  → tileset 额外跑 tools/postprocess_tiles.py（阴影描边）
  → 妖物额外跑 tools/postprocess_mobs.py（提亮 1.18x + 提饱和 1.08x + 1px 暗描边；修仙素材夜色基调，不提亮会看不见怪）
  → headless 验证 → 实机截图核对。规格表在脚本末尾，改素材只改那张表。
- 新怪贴图：改 `balance.gd` 变体表的 sprites 路径即可；妖王放 `assets/mobs/boss_0/1.png` 自动生效。
- AI 素材商用条款遵循 Gemini API 条款，NOTICE.md 已登记。

## 6. 踩过的坑（接手前必读）

1. **GDScript 类型推断**：`:=` 对 Variant 会报 "Cannot infer"——凡 `get_parent().xxx`、字典取值、字符串索引结果，一律显式类型（`var x: float = ...`）。
2. `for x in (a, b, c)` 是语法错误（元组），要 `[a, b, c]`；argparse 的 `--in` 撞 Python 关键字（用 `dest="infile"`）。
3. GLSL 着色器没有 `:=`。
4. **缩进即逻辑**：曾有死亡判定被误缩进进击退分支、怪打不死查了半天——大改后 grep 检查关键 if 的层级。
5. Godot 会在运行后回写 project.godot / .tscn（加 uid 等），手改场景文件后 import 一次再看 diff；`.tscn` 手工编辑时 ext_resource 的 id 必须真实存在（引用不存在资源=Parse Error 指向使用行）。
6. TileSet 物理：必须先 `add_source` 再给 TileData 加碰撞多边形（顺序反了碰撞静默失效）。
7. 怪物碰撞圆/受击框几何要保证"攻击环最远停点 + 碰撞半径 > 受击框半宽"，否则掉血链路断（HurtBox mask 必须=2）。
8. **项目改名会改 user:// 目录**。原来只设了 `config/custom_user_dir_name` 而**漏了 `config/use_custom_user_dir=true`**，所以设置一直没生效——存档实际落在 `app_userdata/不退/`（历史遗留 `My Survivors/`、`忍者今天也在割韭菜/` 都是改名留下的孤儿目录）。**2026-09-21 已补上该开关**，现在固定为 `%APPDATA%/my-survivors/`（注意：开启 use_custom_user_dir 后**不再**放在 `Godot/app_userdata/` 下）。
9. 窗口标题=project.godot 的 config/name（**不退**）；仓库名/导出文件名仍是 my-survivors。
10. **贴图放错文件**：曾有"道具在乱跑"——AI 生成的是 3×3 升级卡图标九宫格，却被写进了 `assets/hero/ninja_sheet.png`，`hero.gd` 按 16px 切成 4×4 方向表，于是玩家身上显示的是图标碎片（同时 2c39948 那版提交的这张表 sha=1f5e0af1…，是坏的那张）。`ninja_sheet.png` 必须是 64×64 的 4×4 方向行走表（当前是 Ninja Adventure CC0 的忍者表，修仙化后换成守山人，**路径不变**），已从 `97e93c6` 恢复，正确 sha256=`e0e7f05107190e2b5f5d650e4479c3e84d051e4826d7bb9ff69f4be56db34aaa`（2026-09-21 修仙化后换成守山人表，哈希随之更新）。**教训**：接入素材后必须实机截图核对"是谁在用这张图"，别只看文件名。
10b. **弹窗层级必须高于 HUD**：`HUD` 是 `layer = 10`，而 GameOver/LevelUpUI/PauseUI/VictoryUI 原来都是默认 `layer = 1`，
    于是结算界面上还显示斩妖/守夜/经验条/等级/灵石/蓝条，技能栏直接压在"回到主菜单"按钮上；
    HUD 里的低血量红色脉冲也会盖在结算背景上（截图看起来整张偏红）。**已把四个弹窗改成 `layer = 30`，乾坤袋 `25`**，
    并在结算时 `$HUD.hide()`。加新弹窗记得跟这个层级表对齐。
10c. **给怪开碰撞前，先把障碍挪到独立层**：原来障碍和玩家都在层 1，
    所以让怪撞墙（把怪的 `collision_mask` 设成 1）会连**玩家**一起撞上，怪会贴着玩家的脚部碰撞体停住、把玩家挤住。
    现已改成 **1=玩家 · 2=敌人 · 3=障碍**（`chunk_map.gd` 瓦片物理层 = 4，`player.tscn` mask = 5）。
    以后加会被挡住的实体，认准层号，别再把层 1 当世界层。
10d. **撞碎瓦片时别用接触点直接取格**：物理接触点经常正好压在瓦片边界线上，local_to_map() 会把它解析到隔壁的空格，
    于是 get_cell_source_id() 返回 -1，撞墙逻辑被 continue 掉——现象是"滑动碰撞明明有，墙却永远碎不了"（蛮石傀就这么哑了一轮）。
    正解：沿碰撞法线往瓦片内部挪半格再取格，并做 3x3 邻域兜底。另外实测：运行时 set_cell() / erase_cell() 的物理体是会同步刷新的，不会留空气墙。
11. **左右列映射别乱改**：上面那张坏图标表曾让人以为"新表左右列相反"，于是 `hero.gd` 的 `DIR_COL` 被改成 `left:3, right:2`——结果向左走时人是倒着走的。恢复正版表后已改回标准顺序 `{"down":0,"up":1,"left":2,"right":3}`（col2 面朝左、col3 面朝右，已验证）。**换方向表后必须重新核对左右**：把该朝向的行走帧渲染出来看脸朝哪边，不要凭围巾位置猜。
11b. **精灵表某列"帧间朝向不一致"**：坏列当走路循环播会像"边走边转身"（往左往右都像）。`hero.gd` 的
    `DIR_COL` / `MIRROR_OF` 就是为绕开坏列而设的**镜像机制**（坏列不用，改镜像好列）。
    **判断某列能不能用**：量该列 4 帧的"身体质心 x 极差"（>1.5px 就是坏的）与"肤色质心相对身体质心的符号"
    （侧向帧的朝向；4 帧符号必须一致）。现在有机器判据：`python tools/qa/check_hero_columns.py`
    （L0 判据 `hero-columns`，还能 `--preview out.png` 导出四向帧预览图肉眼核对）。

    ⚠️ **2026-09-24 更正（重要）**：上面"col2 坏 / col3 好"是**旧忍者表**上的实测结论，
    **修仙化换成守山人表后失效了**——换表后实际是 col2 自洽（6.5/6.4/6.5/6.5，脸一律朝左）、
    **col3 的 row0 坏**（8.5 vs 6.4/6.5/6.5，且脸朝右而其余 3 帧朝左）。旧映射（用 col3 并镜像它当左向）
    于是让**左右两个方向都**出现"每循环翻一次朝向 + 跳 2px"的旋转感（用户报障："向左走或向右都会旋转的走"）。
    现在改成 `DIR_COL = {down:0, up:1, left:2}` + `MIRROR_OF = {right:"left"}`。
    **教训**：换方向表后必须重新量化核对，别信文档里的旧结论。
12. **一整批素材互相错位**（2c39948 那批 AI 生成）：
    - `ninja_sheet.png` 装的是升级卡图标九宫格 → 已换回正版主角表（见第 10 条）；
    - 8 张 `card_*.png` 装的是主角表碎片 → 已从九宫格里按格裁出正确图标（每张 21~22px）；
    - 4 张 `icon_*.png` 每张被塞了**两个**图标且互相串门（coin 文件里有 coin+chest，chest 文件里有 gem+shuriken…）→ 已拆开、各归各位；
    - 空白/未用：`icon_gem` 的右半是红球、`icon_shuriken` 的左半是灰本命飞剑、`icon_chest` 的右半是灰本命飞剑，均未使用。
    **教训**：AI 生成的图常把多张素材拼在一张里，接入时必须**逐张渲染确认内容**再命名，不能按生成顺序假设。
13. **`.tscn` 里父节点必须先声明**：`Card1Icon`/`Card2Icon` 曾被写在父节点 `Card1`/`Card2` **之前**，Godot 无法挂载，直接把它们丢到场景根并改名成 `LevelUpUI_Card2#Card2Icon`，于是 `level_up_ui.gd` 的 `get_node("Card1/Card1Icon")` 拿到 null，升级卡图标永远不显示（还每局刷 SCRIPT ERROR）。**手工编辑 `.tscn` 后必须确认节点块是父先子后**。
14. **验证素材要固定输入再截图**：`SendKeys` 的 `{A DOWN}` 语法无效（会报 repeat count），用 `keybd_event`；且 harness 场景根节点必须叫 `Game`，否则脚本里写死的 `/root/Game/Player` 全部解析成 null。

15. **抖动/定帧散落各处 → "游戏一直在抖 + 卡"**（2026-09-24）：`Juice.shake` 是 trauma 制
    （`trauma = min(1, trauma + amount)`，实际抖动 = `trauma²`），而**每斩一只怪都 +0.35**、
    妖王冲锋沿途**逐格撞碎瓦片每帧都震**——怪一多 trauma 就被顶在 1.0，画面 51%~84% 的帧偏移 >4px；
    同时**每只怪死亡都 hitstop(0.05)**，连杀时 `time_scale` 有 6%~22% 的帧钉在 0。
    **修法**：`VFX.shake` / `VFX.hitstop` 统一入口 + 连杀"热度"让小抖自动衰减
    （`CAMERA_SHAKE_HEAT_* / SWARM_FLOOR`）+ 大抖（妖王/玩家受击）不受限 + hitstop 最小间隔。
    ⚠️ 标定时注意 `trauma²` 是非线性的：trauma 0.25 只有 0.06×max_offset ≈ 1px，
    所以"降一半 GAIN"会让抖动**几乎消失**（第一版就调过头了，max 从 23px 掉到 2.7px）。
13. **摄像机旋转会被玩家读成"人物在转"**：Juice.shake 的 max_roll 默认 0.08 弧度（4.6°），而我们的 shake 由"打中/被撞"高频触发——实测战斗中摄像机在 **-3.4°~+1.1°** 之间每 0.12 秒随机跳变，画面绕中心转，玩家看到的就是"人物在旋转"（**侧面走路时最明显**，因为侧脸一倾斜特别像转头）。**已改成只位移不旋转**：@@Balance.CAMERA_SHAKE_ROLL = 0.0@@，6 个调用点显式传参（位移抖动保留，打击感不受影响）。想恢复旋转感就把那个常量调大。
    ⚠️ 排查手法备忘：怀疑"角色在转"时，先打印 @@cam.rotation@@（相机是 Player 的子节点：@@Player/Camera2D@@），别急着去改精灵表。

## 7. 待办与机会（按建议优先级）

1. ~~**Web 版瘦身**~~：**2026-09-24 字体子集化已完成** —— Fusion Pixel 4.9MB → **46KB**（379 字）
   （`tools/subset_font.py`，L0 判据 `font-coverage` 守住漏字）。
   线上实测：`index.pck` **8.4MB**（裁剪前约 13MB），`index.wasm` 39.5MB。
   **仍待办**：wasm 本体瘦身（39.5MB 全是 Godot Web 模板，需要自建 custom template 去掉未用模块）。
2. **itch.io 发布页**：封面已备好（`assets/ui/cover.png`），README 可嵌的素材齐全。
3. 玩法 P5：更多法宝/多角色/成就；卡池可加权重与稀有度。
4. 主菜单/商店/暂停按钮加图标（`assets/ui/star.png` 现成备用，八张卡图标可复用）。
5. BGM 可换更好的曲子（现在是脚本合成的，生成思路见 git 历史 synth_bgm）。
6. 妖王目前一只形象，可加多种（模板机制已支持，见 chunk_map 的做法）。
7. ~~手机触屏~~：**2026-09-24 完整可用**——摇杆 + 神通按钮 + 拾取/乾坤袋/暂停三个功能入口，
   乾坤袋补了可点的关闭按钮（`check_touch.gd` 有断言，去掉关闭按钮会 FAIL）。
   **仍待办**：竖屏/横屏布局适配（现在只有横屏布局，手机竖屏会很小）。
7b. ~~**第 5/6 种法宝**~~：**2026-09-22 已完成**（回风梭 / 地火符阵，见 WEAPON_SYSTEM.md）。
    **仍待办**：给每把法宝补第 2 个技能（现在每把只挂 1 个，多技能 UI 已就绪）。
7c. ~~**精确斩妖归属**~~：**2026-09-22 已完成**——`take_damage(amount, knockback, source)` + `died(source)`，
    只给致命一击的法宝 +1；`tools/qa/check_kill_credit.gd` 已接入 L0 判定（判据 `kill-credit`）。
8. README/ARCHITECTURE 与代码保持同步——每次功能落地后更新（本项目的习惯）。

## 8. 其他背景

- 二开源头：GDQuest 教程 getting-started-with-godot-4（代码 MIT）；美术已全部替换，商用无障碍。
- git 提交习惯：中文一行标题+要点列表，一个功能一提交，改完即推（CI 会双端构建）。
- 用户偏好：中文交流；要实机验证截图确认；美术走 AI 生成管线；风格统一：像素 + 修仙（青霓虹 / 朱砂 / 鎏金）。
- 当前工作树干净，全部已推送（HEAD 见 `git log -1`）。
