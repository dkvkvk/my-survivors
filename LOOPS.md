# LOOPS（本项目的 agent loop 台账）

> 约定：**问题列只由人写，结果列只由 loop 写；状态单向推进，不回溯。**
> 状态枚举：todo -> in-progress -> awaiting-human -> accepted（人翻）/ blocked（升级给人）
> 判定脚本的退出码是最终裁决。状态最多推进到 **awaiting-human**，"完成"那一格由人翻。

## 已采纳的 loop

### L0 · 冒烟 + 素材契约

| 项 | 内容 |
|---|---|
| 目标 | 代码或素材改动后，构建/运行无脚本错误，素材契约不被破坏 |
| 判定 | python tools/qa/loop_judge.py（退出码 0 = 全绿） |
| 判据 | ① headless --import 无 Parse Error / Failed to load / non-existent（已知噪音：colorpicker "Out of bounds"）② headless --quit-after 240 的 SCRIPT ERROR / SHADER ERROR / no animation 计数 = 0 ③ 关键素材尺寸符合规格表 ④ 无缺失 .import ⑤ balance.gd 引用的贴图路径都存在 |
| 停止 | 全绿 → awaiting-human；连续 3 轮同一判据失败 → 升级给人 |
| 边界（must-not） | 不得修改 tools/qa/loop_judge.py 的规格表或放宽判据来让判定通过；不得删除或降级素材来绕过契约检查 |
| 产物 | tools/qa/judge-report.json |

运行：

    python tools/qa/loop_judge.py            # 全量（含 240 帧运行）
    python tools/qa/loop_judge.py --fast     # 只跑静态判定，跳过启动游戏

Godot 路径默认取 HANDOVER §0 的目录；换机器用环境变量覆盖：GODOT_BIN=...

## 待办（人写）

- [ ] 修 HANDOVER §6 坑 #10 的过期 sha256（文档记的是修仙化之前的忍者表哈希，实际已是守山人表）
- [ ] 清掉 assets/check.png.import（孤儿：check.png 已不存在，但 .import 还在 git 里）

## 结果（loop 写）

### 2026-09-22 · L0 判定：pass

- 判定：@@python tools/qa/loop_judge.py@@（全量，含 240 帧运行）→ **退出码 0**，5/5 PASS
  （headless-import / headless-runtime / asset-contract 4 项 / import-hygiene 孤儿=0 / sprite-refs 10 项）
- 产物：@@tools/qa/judge-report.json@@

### 2026-09-22 · 待办处理：awaiting-human

| 待办 | 结果 | 状态 |
|---|---|---|
| 修 HANDOVER §6 坑 #10 的过期 sha256 | 已更新为 @@e0e7f05107190e2b5f5d650e4479c3e84d051e4826d7bb9ff69f4be56db34aaa@@（修仙化后的守山人表），并注明哈希为何变 | awaiting-human |
| 清掉 @@assets/check.png.import@@ 孤儿 | 已删除；import-hygiene 孤儿计数 1 → 0 | awaiting-human |

> 本轮未修改"待办（人写）"列；判定脚本与规格表未改动（边界 must-not）。

### 2026-09-22 · L0 判据增强：script-parse

- 背景：`--import` **不会编译脚本**，没被任何场景引用的坏 `.gd` 抓不到（反向测试实测漏判）
- 判定新增 ③ `script-parse`：用 @@tools/qa/check_scripts.gd@@ 以 SceneTree 逐个 `load()` 全部 38 个 `.gd`，
  抓 @@Parse Error / Failed to load script / SCRIPT ERROR@@ 计数，必须为 0
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，6/6 PASS
  （headless-import / headless-runtime / **script-parse 38 个脚本** / asset-contract 4 项 / import-hygiene 孤儿=0 / sprite-refs 10 项）
- 仓库卫生：@@tools/qa/judge-report.json@@ 与临时验收图 @@_shots/@@ 加入 @@.gitignore@@（本地产物，不再污染 git status）
- 边界合规：只**新增**判据，未放宽任何既有判据与规格表

状态：awaiting-human

### 2026-09-22 · P1 玩法深度：第 5/6 把法宝 + 精确斩妖归属

- 新增判据 ⑤ `kill-credit`：@@tools/qa/check_kill_credit.gd@@ —— 起真实场景造怪打死，
  断言"只有致命一击的法宝 +1 斩妖数、来源不明时兜底给所有法宝"
- 新增判据 ⑥ `weapons-smoke`：@@tools/qa/check_weapons.gd@@ —— 装上 6 把法宝跑真实帧
  （轮换卸装、升满进化、轮放技能），并直接驱动命中回调验证伤害与归属
  （默认 @@--quit-after@@ 停在开局选择界面，法宝根本不会跑）
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，8/8 PASS
- 实测信息：飞梭峰值 20、符雷峰值 5、自然斩妖 5（--script 模式下物理也会步进）
- 边界合规：只**新增**判据，未放宽任何既有判据与规格表

状态：awaiting-human

### 2026-09-22 · P2a Web 首载瘦身：中文字体子集化

- 新增判据 ⑦ `font-coverage`：@@tools/subset_font.py --check@@ ——
  扫全仓 `*.gd`（先剥注释）/ `*.tscn` / `*.tres` 收集字符，与子集字体 cmap 逐码位比对
- 结果：Fusion Pixel **4.9MB → 46KB**（420 字），全量判定 **9/9 PASS**
- 顺带修掉一个真实缺陷：妖王警告文案用的 `⚠` **字体里没有该字形**（一直在渲染豆腐块），
  改成字体自带的 `◆ 妖王现世 ◆`（该缺陷正是被新判据抓出来的）
- 实机验证：子集字体下主菜单 / 开局选法宝 / 战斗 HUD / 技能栏文字全部正常，无豆腐块
- 边界合规：只**新增**判据，未放宽任何既有判据与规格表

状态：awaiting-human

### 2026-09-22 · P2b 触屏操作：虚拟摇杆 + 神通按钮

- 新增 `touch_controls.gd`：左下虚拟摇杆（Line2D 圆环 + 光晕）+ 右下 4 个神通按钮；
  **只在真有触摸时创建**（移动端 / Web 移动端 / 系统报有触摸屏），桌面键鼠下自毁，不抢输入
- 玩家侧：`player._physics_process` 把摇杆方向叠加进 `Input.get_vector(...)`（`touch_input` 组）
- 触屏时技能栏隐藏按键提示（1/2/3/4 没意义）
- 新增判据 ⑧ `touch-controls`：@@tools/qa/check_touch.gd@@（MS_TOUCH=1 强制开启）
  —— 断言摇杆满程/半程模拟量/死区归零、松手归零、神通按钮扣蓝进冷却、按键提示隐藏
- **真实运行验证**：`MS_TOUCH_PROBE=1` 让摇杆固定朝右，角色坐标 ~300px/s 稳定右移
- 已知限制：headless `--script` 下**合成 InputEvent 投递不可靠**，故判据直接驱动触屏层方法；
  CharacterBody2D 在该模式也不位移，所以"真的推得动"必须走真实运行探针
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，**10/10 PASS**
- 边界合规：只**新增**判据，未放宽任何既有判据与规格表

状态：awaiting-human

### 2026-09-24 · 修复「向左/向右走都像在旋转」

- 报障：往左或往右走，角色边走边"转身"
- 排查（三步量化，不靠肉眼）：
  1. 探针打印 500 帧：`hero.rotation` / `sprite.rotation` / `cam.rotation` **全程为 0**、`scale` 恒定
     → 排除相机（坑 #13 已修）与节点变换，问题在**帧**
  2. 量精灵表每帧"不透明像素质心 x"：col0/col1/col2 四帧自洽（极差 0.1px），
     **col3 极差 2.1px**（row0 整体右移 2px），且 **row0 脸朝右、其余 3 帧脸朝左**
  3. 而 `hero.gd` 当时正是"右向用 col3 + 左向镜像 col3" → **左右两个方向都**每循环翻一次朝向
- 修复：`DIR_COL = {down:0, up:1, left:2}` + `MIRROR_OF = {right:"left"}`（坏列整个不用）
- 新增判据 ⑨ `hero-columns`：@@tools/qa/check_hero_columns.py@@ ——
  零依赖解 PNG，校验四向列的"帧间质心极差"与"朝向符号一致性"，可 `--preview` 导出四向帧预览图
- **反向测试**：把映射改回旧值 → 判据 FAIL 且报出 `col3 质心 8.5/6.4/6.5/6.5 极差 2.1` + 朝向不一致
- 文档更正：HANDOVER 坑 #11b 的"col2 坏 / col3 好"是**旧忍者表**结论，换表后失效，已改写并注明教训
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，**11/11 PASS**

状态：awaiting-human

### 2026-09-24 · 修复「游戏抖动过大」

- 报障：画面抖动过大。先量化（新增手感探针 @@MS_FEEL_PROBE=1@@，每 120 帧汇报）
  - 相机偏移：平均 1.3~9.7px、**51%~84% 的帧 >4px**、最多 45% 的帧 >10px → 一直在抖
  - `time_scale` 被 hitstop 钉在 0 的帧占比 **6%~22%** → 同时一直在卡
- 根因：`Juice.shake` 是 trauma 制（累加，抖动 = trauma²），而**每斩一只怪 +0.35**；
  妖王冲锋**逐格撞碎瓦片每帧都震**；**每只怪死亡都 hitstop(0.05)**。怪一多就顶到上限
- 修法：
  - 新增 **VFX 统一入口** `VFX.shake(camera, amount)` / `VFX.hitstop(sec, priority)`，
    7 个震屏点 + 1 个定帧点全部改走它
  - 连杀"热度"（0~1）让小抖自动衰减到 `SWARM_FLOOR`；大抖（妖王 0.9 / 玩家受击 0.5）不受限
  - hitstop 加最小间隔（0.45s）并缩短（0.05→0.03）；撞碎瓦片这类重复事件量级压低
  - 新增判据 ⑩ `fx-entry`：禁止在 VFX 之外直接调 `Juice.shake`/`Juice.hitstop`（反向测试通过）
- 结果（同一条探针命令实测）：日常战斗 mean 0.1~0.8px / >4px 0~3%；
  妖王期 mean 2~3.7px / 峰值 13~17px（该有的分量保留）；定帧冻结 **3~7%**
- ⚠️ 标定教训：`trauma²` 非线性，第一版把 GAIN 降到 0.7 后 max 从 23px 掉到 2.7px（几乎没打击感），
  已重新标定并把"想整体更抖/更稳"收敛到**一个旋钮** `Balance.CAMERA_SHAKE_GAIN`
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，**12/12 PASS**

状态：awaiting-human

### 2026-09-24 · 触屏补齐三个功能入口（Web 手机从"能动"变成"能玩"）

- 问题：`pickup`(F) / `inventory`(B) / `ui_cancel`(Esc) **只有键盘入口**，
  触屏层只给了摇杆 + 神通按钮 → 手机上**捡不了法宝、开不了乾坤袋、暂停不了**；
  而乾坤袋面板**没有可点关闭按钮**，手机上打开就永远关不掉（卡在暂停里）
- 改动：
  - 触屏层右上加「拾取 / 乾坤袋 / 暂停」三个圆钮（直接调面板方法，不模拟按键）
  - 「拾取」只在脚下真有法宝可捡时亮起（`can_touch_pickup`），免得乱点
  - 乾坤袋面板加**「关闭」按钮**；`weapon_drop.gd` 加 `touch_pickup()` / `can_touch_pickup()`
- 判据扩展：@@tools/qa/check_touch.gd@@ 新增断言（点乾坤袋能开 / 面板必须有关闭按钮 /
  点暂停真的暂停树 / 点拾取真捡到法宝）；**反向测试通过**（去掉关闭按钮 → FAIL）
- 字体自愈：本轮新增中文触发 `tools/subset_font.py --restore`
  （就地子集化过的字体补不了新字，自动从 git 取回全量版再裁）→ 380 字 / 41KB
- 实机验证：截图确认三钮渲染正常，且「拾取」在无法宝时自动变暗
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，12/12 PASS

状态：awaiting-human

### 2026-09-24 · P7 神通扩容：每把法宝 2 门 + 2 门融合（共 14 门）

- 新增判据 ⑪ `skills-cast`：@@tools/qa/check_skills.gd@@ —— 把 6 件法宝的**每个可换神通**
  都设为激活并施放（两轮覆盖 6 件法宝，共 28 次施放），断言：扣了灵力 + 新神通真的产生状态
  （疾奔计时 / 外放剑刃 / 火域节点 / 蓄雷标记 / 穿透飞梭 / 引爆补布），
  并校验融合门槛：**缺任一法宝时 available_for 不含融合、set_active_skill 必须拒绝**
- 第 2 神通：御剑疾影（位移+撞伤）/ 剑环外放 / 焚地火域（持续法阵）/ 蓄雷引弧（强化被动）/
  穿云巨梭（直线穿透）/ 符阵合围（引爆全场）
- 融合：焚天剑轮（剑环+法环）、惊雷剑引（飞剑+雷符）；
  "可选范围"收敛到 `Skills.available_for()` 一处，乾坤袋与激活共用
- 图标：8 张新神通图标仍为代码占位（@@tools/gen_skill_icons_p7.py@@），
  AI 生图提示词已写在 `XIANXIA_ART_PROMPTS.md` 第八节 A 组
- 踩坑：`get_node("%唯一名")` 只在**拥有该节点的场景脚本内**有效，跨节点要按路径取
  （测试里 `_game.get_node("%OrbitBlades")` 拿到 null）
- 字体：新增中文触发 `--restore` 自愈 → 423 字 / 46KB
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，**13/13 PASS**

状态：awaiting-human

### 2026-09-24 · P7 多角色：3 个身份（主菜单选择 + 存档）

- 新增 @@characters.gd@@：守山人（均衡）/ 符修（地火符阵起手·灵力 ×1.4·血量 ×0.75）/
  剑修（周天剑环起手·射速 ×1.25·移速 ×0.9）
### 2026-09-24 · P7 设置菜单 + 竖屏提示

- 主菜单左下新增「设 置」：抖动强度（0~150%）/ 音乐音量 / 音效音量，
  写入存档（settings 字典）并**实时生效**（VFX.set_shake_scale / audio.apply_volumes）
- 竖屏提示：触屏设备竖屏时盖一层「请横屏游玩」（横屏设计，竖屏没法玩）；check_touch 加结构断言
- 新增判据 ⑭ `settings-ui`：@@tools/qa/check_settings.gd@@ —— 3 个滑杆写存档并实时生效、
  身份选择器 3 张卡可点并持久化；结束时还原测试前的设置值
- 踩坑：设置值的**存取单位要一致**（滑杆一度存成整数百分比，apply_volumes 按 0~1 读，
  clamp 后直接变成 1.0 —— 测试当场抓出来）
- Web wasm 瘦身配方已写入 HANDOVER（需自建引擎模板，本次不实施）
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，**15/15 PASS**

状态：awaiting-human

- 本命飞剑是**所有身份共有**的基础法宝（没有它就没有自动攻击），
  身份差异 = 签名法宝 + 属性倍率 + 主角配色（代码调色，不需要额外美术；
  独立行走表的提示词已写在 XIANXIA_ART_PROMPTS 第八节 B 组）
- 主菜单加「选择身份」三卡（代码构建），选择写入存档（@@save.gd@@ 新增 character 字段
  与 settings 字典；解析循环泛化以接受字符串/字典）
- 新增判据 ⑬ @@characters@@：复用战斗场景的玩家，把面板重置到商店升级后的基准再重放身份，
  断言签名法宝 / 血量·射速·灵力倍率 / 配色 / 存档回读 / 非法 id 回退默认
- 测法上的两个坑：① 独立实例化 player.tscn 时 %唯一名 解析不到（改用重置+重放）；
  ② 商店升级会干扰绝对值断言（断言改成"基准 × 倍率"的相对值）
- 全量判定：@@python tools/qa/loop_judge.py@@ → **退出码 0**，**14/14 PASS**

状态：awaiting-human

