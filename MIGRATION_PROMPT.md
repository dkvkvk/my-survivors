# 接手提示词（复制下面整段给新对话）

我接手一个正在开发的 Godot 4 游戏项目，请你先读文档再动手。

## 项目基本情况

- **项目路径**：`E:\games\my-survivors`（Windows，git 仓库）
- **远端**：https://github.com/dkvkvk/my-survivors （分支 main）
- **游戏名**：《不退》（NO RETREAT）
- **类型**：2D 割草幸存者（类吸血鬼幸存者）
- **世界观**：和风忍者村 + 科技入侵（青霓虹 + 红木/和纸 + 金）
- **引擎**：Godot **4.7.2**，可执行文件在目录里：
  `D:\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
  （带 `_console` 的版本才有控制台输出，调试用它）
- **胜利条件**：活满 15 分钟 **或** 击破 3 只首领

## 先读这几份文档（按顺序）

1. `HANDOVER.md` —— 环境、架构、约定、**踩过的坑**、验证流程（最重要）
2. `WEAPON_SYSTEM.md` —— 武器/技能系统设计（**唯一权威**，改设计先改它）
3. `ASSETS.md` —— 图片素材清单（尺寸/用途/引用点）
4. `ART_PROMPTS.md` —— 待生成的素材提示词（只留还没做的）
5. `ARCHITECTURE.md` / `README.md` —— 架构与玩法总览
6. `ROADMAP.md` —— 分批路线图

## 当前进度

**已完成**：
- 核心割草循环、波次刷怪、4 种怪 + 首领（三段冲锋 AI）、宝箱
- 经验宝石 + 升级三选一（**现在只出属性卡**，武器卡已移出）
- 局外：金币 → 忍具商店 4 种永久强化
- 分块无限地图（和风瓦片集 + 无缝地面）
- 主菜单 / 暂停 / 失败结算 / **胜利结算**（新增）
- 主菜单**代码驱动动效**（背景视差漂移 + 樱花粒子 + 霓虹呼吸）
- **P6 武器/技能系统**：
  - 蓝条（法力）+ 4 技能槽（键位 **1/2/3/4**）+ 冷却
  - 4 个技能效果（手里剑乱舞/刃风暴/烈日爆发/雷神之怒）
  - 武器数据表 `weapons.gd`（4 把，上限 4）
  - **背包（按 B）**：武器格 + 技能选择 + 材料 + 升级按钮
  - **武器掉落 + 按 F 拾取 + 替换面板**
  - 材料掉落（铁屑/雷晶）+ 技能切换书掉落
  - 击杀数累积（武器升级条件）
  - 技能图标/材料图标已接入

**待做（见 WEAPON_SYSTEM.md）**：
- 技能融合（已推迟）
- 第 5/6 种武器（加了这个"替换面板"才会在实战生效）
- 给武器补多个技能（现在每把只挂 1 个）
- 精确击杀归属（现在每击杀给所有武器各 +1）

## 铁律约定（改动前必看）

1. **所有数值进 `balance.gd`**，别散落硬编码
2. **伤害单一入口** `mob.take_damage(amount, knockback)` —— 新武器零改动接入
3. **碰撞**：障碍只挡玩家（物理层 1），怪物和子弹穿行
4. 加技能 = `skills.gd` 加一行 + `player._run_skill_effect()` 加分支
5. 加武器 = `weapons.gd` 加一行
6. 加属性卡 = `upgrades.gd` 加一行 + `player.apply_upgrade()` 加分支
7. **UI 尽量纯代码构建**（如 `skill_bar.gd` / `inventory_ui.gd`），少往场景塞节点

## 已知的坑（HANDOVER 第 6 节有完整版）

1. **GDScript `var x := ...`**：对 Variant（如 `get_parent().xxx`、字典取值）会报 "Cannot infer" —— 必须显式写类型
2. **`.tscn` 手工编辑**：节点块必须**父先子后**，否则 Godot 把子节点丢到场景根并改名
3. **新 PNG 必须先 `--import`**，否则 `ResourceLoader.exists()` 为 false、图不显示
4. **精灵缩放别叠加**：`mob.tscn` 的精灵曾自带 3 倍缩放，和 `setup()` 的 scale 相乘导致怪巨大
5. **Godot 4.7 的 CPUParticles2D**：枚举是 `EMISSION_SHAPE_RECTANGLE`（不是 BOX）、属性是 `emission_rect_extents`（不是 box_extents）
6. **Godot 标准版放不了 MP4**，只支持 Ogg Theora（`.ogv`）
7. 物理回调里增删节点必须 `call_deferred`

## 验证流程（别跳过）

```bash
G="/d/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
# 1) 先 import（有新素材时必做）
"$G" --headless --path /e/games/my-survivors --import
# 2) 跑 200~300 帧看有无报错
"$G" --headless --path /e/games/my-survivors --quit-after 300 2>&1 | grep -cE "SCRIPT ERROR|SHADER ERROR"
# 期望 0（import 时 colorpicker 插件的 "Out of bounds" 是已知无害噪音）
```

**实机截图验证**（重要）：写一个临时 driver 场景挂在游戏根节点下，
用 `get_viewport().get_texture().get_image().save_png()` 抓图，我读图确认。
- ⚠️ 游戏会 **暂停**（升级/结算/背包），driver 必须设 `process_mode = PROCESS_MODE_ALWAYS`，否则停摆
- ⚠️ 临时场景的**根节点必须叫 `Game`**，否则脚本里写死的 `/root/Game/Player` 解析为 null
- 验证完**删掉所有临时文件**（`_*.gd` / `_*.tscn` / `_*.png` / `_*.import` / `_*.uid`）

## 发布流程

- 直连 github 有时被墙；本机 Clash 代理 `127.0.0.1:7897`（经常没开）
- 代理没开时用：`git -c http.proxy= -c https.proxy= push origin main`
- 推送 main 自动触发 Actions（Windows exe + Web 部署 Pages）
- 查 CI：`gh run list --repo dkvkvk/my-survivors`

## 我的偏好（重要）

1. **中文交流**
2. **要实机截图确认**，不要只说"改好了"
3. **美术走生图管线**：我写好提示词给你 → 我用网页版生图 → 放 `E:\games\` → 你处理接入
   - **接入后请删掉原图**，并**删掉 `ART_PROMPTS.md` 里对应的提示词**（只留还没做的）
4. **每完成一块就 commit + push**，中文提交信息（一行标题 + 要点列表）
5. 先问清需求再动手，尤其是玩法改版；拿不准就问我

## 下一步我想做的

先**实机试玩调手感**（掉落率、蓝耗、冷却、技能威力、升级所需击杀数），
调顺后再考虑加内容（第 5/6 种武器、多技能、技能融合）。

---

请先读 `HANDOVER.md` 和 `WEAPON_SYSTEM.md`，然后告诉我你理解的项目现状，
再问我要从哪里开始。
