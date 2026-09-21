# 项目来源与版权说明

本项目基于 GDQuest 的开源教学项目二次开发，美术已在 U7 阶段全部替换为 CC0 素材（见下表），**当前已具备商用条件**。

- 上游仓库：https://github.com/gdquest-demos/getting-started-with-godot-4
- 配套免费教程：https://www.gdquest.com/library/first_2d_game_godot4_vampire_survivor/
- 上游原始许可证全文见 [UPSTREAM_LICENSE](UPSTREAM_LICENSE.md)

## 上游许可证要点

上游项目采用双许可证：

1. **代码**（`.gd` 脚本、场景、着色器等）：**MIT** —— 可自由修改、发布、商用，保留版权声明即可。本项目继续沿用。
2. **美术素材**：原 **CC-BY-NC-SA 4.0**（非商用）——**已全部移除并替换**（原 `characters/`、`trees/`、`pistol/` 目录已删除，见 git 历史）。

## 当前素材清单（全部可商用）

| 素材/模块 | 来源 | 许可证 |
|---|---|---|
| 代码（上游继承 + 二开） | GDQuest / 本项目 | MIT |
| `assets/hero/` 忍者角色与影子 | [Ninja Adventure by pixel-boy](https://pixel-boy.itch.io/ninja-adventure)（[GitHub 镜像](https://github.com/pixel-boy/NinjaAdventure)） | CC0 |
| `assets/mobs/` 史莱姆/蝙蝠/重甲/野兽（各两帧） | [Kenney Pixel Platformer](https://kenney.nl/assets/pixel-platformer) | CC0 |
| `assets/tiles/` 瓦片集（墙/货箱/服务器/天线/水晶/灌木） | 本项目脚本生成像素图 | CC0（自制） |
| `addons/saltmire_juice/` 打击感套件 | [Saltmire Juice](https://github.com/saltmire/saltmire-juice) | MIT |
| `sounds/*.wav` 6 个音效 | [Juhani Junkala 8-bit 音效包](https://opengameart.org/content/512-sound-effects-8-bit-style) | CC0 |
| `sounds/bgm_*.wav` 两首循环 BGM | 本项目脚本合成（`synth_bgm.py` 思路，见提交历史） | CC0（自制） |
| `backgrounds/grass-ground-soft.png` 草地地面 | [Seamless Grass II](https://opengameart.org/content/seamless-grass-texture-ii) | CC0 |
| `fonts/` 中文像素字体 + OFL.txt | [Fusion Pixel（缝合像素）by TakWolf](https://github.com/TakWolf/fusion-pixel-font) | SIL OFL 1.1 |
| 代码绘制的视觉（经验宝石/飞刀/光环/手里剑/伤害数字） | 本项目 | 随项目 MIT |
| `assets/fx/` 特效贴图（光晕/星芒/火花/烟雾） | 本项目用 Python 脚本程序化生成（见 ASSETS.md 说明） | CC0（自制） |
| `vfx.gd` 特效库（冲击环/斩击弧/拖尾/全屏闪/天雷等） | 本项目纯代码绘制 | 随项目 MIT |

Kenney 包随附的许可原文见 `assets/Kenney-License.txt`。

| `assets/ui/` 主菜单背景、金币/宝箱/宝石/手里剑图标；`assets/mobs/mech_bat_*` 机械蝙蝠 | AI 生成（Google Gemini 图像模型/Nano Banana，提示词见提交历史），经像素化与抠底处理 | 遵循 [Gemini API 商用条款](https://ai.google.dev/gemini-api/terms)（允许商用，不得主张生成物为独立版权作品） |

> 提示：OFL 1.1 对字体保留名称"缝合像素/Fusion Pixel"，未修改的原文件分发不受影响。
