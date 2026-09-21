p='ASSETS.md'
s=open(p,encoding='utf-8').read()
# 更新背景大图表：加 victory_bg，标注已接入
old = '''| \`assets/ui/menu_bg.png\` | 1920×1080 | \`main_menu.tscn\` | 主菜单背景 |
| \`assets/ui/gameover_bg.png\` | 1920×1080 | \`survivors_game.tscn\` | 失败结算背景（**胜利结算暂时复用这张**） |
| \`assets/ui/cover.png\` | 1920×1080 | **未引用** | 宣传封面备用 |'''
new = '''| \`assets/ui/menu_bg.png\` | 1920×1080 | \`main_menu.tscn\` | 主菜单背景（和风村落+科技入侵） |
| \`assets/ui/gameover_bg.png\` | 1920×1080 | \`survivors_game.tscn\` | 失败结算背景 |
| \`assets/ui/victory_bg.png\` | 1920×1080 | \`survivors_game.tscn\` | 胜利结算背景（鸟居之上·晨曦） |
| \`assets/ui/cover.png\` | 1920×1080 | **未引用** | 宣传封面备用 |'''
assert old in s, 'bg table not found'
s = s.replace(old, new)
# 更新待生成清单：本轮已完成 6 张
old2 = s[s.index('### 本轮（和风忍者村 + 科技入侵）'):s.index('### 下一轮')]
new2 = '''### 本轮（和风忍者村 + 科技入侵）

| # | 文件名 | 尺寸 | 用途 | 状态 |
|---|---|---|---|---|
| 1 | \`menu_bg\` | 1920×1080 | 主菜单背景 | ✅ 已接入 |
| 2 | \`gameover_bg\` | 1920×1080 | 失败结算 | ✅ 已接入 |
| 3 | \`victory_bg\` | 1920×1080 | 胜利结算 | ✅ 已接入 |
| 4 | \`cover\` | 1920×1080 | 宣传封面 | ✅ 已接入（备用） |
| 5 | \`tileset_wa\` | 384×64 | 和风瓦片集（6 格） | ✅ 已接入（抠底后 384×64） |
| 6 | \`tech_floor_wa\` | 256×256 | 和风无缝地面 | ✅ 已接入（2048→256） |
| 7 | \`menu_loop.mp4\` | 1920×1080 | 主菜单循环视频 | ⬜ 待生成 |

'''
s = s.replace(old2, new2)
open(p,'w',encoding='utf-8',newline=chr(10)).write(s)
print('ASSETS.md updated')
