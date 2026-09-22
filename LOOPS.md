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

（暂无）
