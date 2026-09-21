class_name Balance

## 全部可调数值集中在这里，改平衡只动这一个文件。
## U3 的升级三选一会把这些常量换成可变数值（玩家身上的加成叠加）。

# 玩家
const PLAYER_SPEED := 600.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_DAMAGE_RATE := 9.0  # 每个重叠敌人每秒掉的血：贴身必须痛，站桩必死

# 敌人变体（U4）：血量/速度区间/体型/色调/经验/接触伤害倍率
# sprites：两帧走路贴图（assets/mobs/，Kenney CC0）；color 为白色时用贴图原色
# phasing：是否天生穿墙。地面单位一律 false（会被障碍挡住，贴墙滑行绕路），
#          只有会飞的变体给 true。被墙卡住超过约 2.4 秒的怪会短暂穿墙脱困（mob.gd 自愈）。
# ability：该变体的专属能力（见下方 ABILITIES 表）。
#          加一种怪 = MOB_VARIANTS 加一行 + ABILITIES 加一条 + mob.gd 加一个分支。
# hit_radius：碰撞/接触判定圆半径（世界像素）。按"身体"给，不要按包围盒——
# 蝙蝠展翼 54px、野兽 48px，若按包围盒给半径会出现"没碰到却掉血"。
# 变体专属能力表（数值全在这里，mob.gd 只负责按名字执行）
#   split       死亡时分裂成小史莱姆（子体不再分裂、不掉任何收益）
#   dive        飞扑：短蓄力后向玩家直线突进一段
#   pounce      扑击：蓄力更久、突进更远的强化版飞扑（魔化野兽）
#   break_walls 撞碎障碍：被墙挡住时直接把瓦片打掉，给后面的怪开路
const ABILITIES := {
	"split": {
		"count": 2,            # 分裂出几只
		"hp_ratio": 0.35,      # 子体血量 = 父体变体血量 x 该比例（至少 1）
		"scale": 0.62,         # 子体体型
		"speed_mult": 1.25,    # 子体更快
		"max_mobs": 240,       # 场上怪超过这个数就不再分裂（防后期爆炸）
	},
	# 飞扑距离 ≈ speed x speed_mult x time（蝙蝠 380~460 x 1.7 x 0.25 ≈ 160~195px）
	"dive": {
		"cd": 2.6, "range": 460.0, "windup": 0.22, "time": 0.25, "speed_mult": 1.7,
		"flash": Color(1.7, 1.3, 2.4),
	},
	"pounce": {
		"cd": 3.2, "range": 420.0, "windup": 0.35, "time": 0.45, "speed_mult": 2.4,
		"flash": Color(2.6, 0.8, 0.7),
	},
	"break_walls": {
		"cd": 0.35,            # 每次撞碎瓦片的间隔（防一帧碎一片）
	},
}

const MOB_VARIANTS := {
	"slime": {"hp": 3, "speed": [200.0, 300.0], "scale": 2.4, "hit_radius": 24.0, "color": Color(1, 1, 1), "xp": 1, "contact": 1.0, "phasing": false, "ability": "split", "sprites": ["res://assets/mobs/mech_slime_0.png", "res://assets/mobs/mech_slime_1.png"]},
	# 机械蝙蝠：会飞，无视地形（唯一天生穿墙的杂兵）
	"runner": {"hp": 1, "speed": [380.0, 460.0], "scale": 2.2, "hit_radius": 12.0, "color": Color(1, 1, 1), "xp": 1, "contact": 1.0, "phasing": true, "ability": "dive", "sprites": ["res://assets/mobs/mech_bat_0.png", "res://assets/mobs/mech_bat_1.png"]},
	"tank": {"hp": 10, "speed": [110.0, 150.0], "scale": 3.0, "hit_radius": 28.0, "color": Color(1, 1, 1), "xp": 5, "contact": 1.5, "phasing": false, "ability": "break_walls", "sprites": ["res://assets/mobs/mech_knight_0.png", "res://assets/mobs/mech_knight_1.png"]},
	"elite": {"hp": 20, "speed": [240.0, 280.0], "scale": 2.6, "hit_radius": 22.0, "color": Color(1.4, 0.55, 0.55), "xp": 15, "contact": 2.5, "phasing": false, "ability": "pounce", "sprites": ["res://assets/mobs/mech_beast_0.png", "res://assets/mobs/mech_beast_1.png"]},
}

# 更次表：t=生效时间（秒），spawn=刷怪间隔，weights=各变体出现权重。
# 节奏偏紧：站桩会在 1~2 波内被围死，走位风筝才有活路。
const WAVES := [
	{"t": 0.0, "spawn": 0.7, "weights": {"slime": 1.0}},
	{"t": 30.0, "spawn": 0.55, "weights": {"slime": 0.7, "runner": 0.3}},
	{"t": 60.0, "spawn": 0.42, "weights": {"slime": 0.55, "runner": 0.3, "tank": 0.15}},
	{"t": 110.0, "spawn": 0.34, "weights": {"slime": 0.35, "runner": 0.35, "tank": 0.2, "elite": 0.1}},
	{"t": 170.0, "spawn": 0.26, "weights": {"slime": 0.25, "runner": 0.35, "tank": 0.25, "elite": 0.15}},
]


## 取守夜时间对应的当前更次配置
static func current_wave(run_time: float) -> Dictionary:
	var wave: Dictionary = WAVES[0]
	for w in WAVES:
		if run_time >= w["t"]:
			wave = w
	return wave


## 按更次权重随机挑一个变体名
static func pick_variant(wave: Dictionary) -> String:
	var total := 0.0
	for k in wave["weights"]:
		total += wave["weights"][k]
	var r := randf() * total
	for k in wave["weights"]:
		r -= wave["weights"][k]
		if r <= 0.0:
			return k
	return "slime"

# 子弹
const BULLET_SPEED := 1000.0
const BULLET_RANGE := 1200.0

# 法宝（场景里 Timer 的 wait_time 会在 _ready 时被这些值覆盖；刷怪间隔由更次表驱动）
const GUN_FIRE_INTERVAL := 0.32

# 环绕飞刀（U6）：刀刃绕玩家旋转，碰到敌人造成伤害
const ORBIT_BLADE_DAMAGE := 2  # 基础伤害，额外吃"重装弹药"每张 +1
const ORBIT_BLADE_RADIUS := 150.0  # 公转半径
const ORBIT_BLADE_ROT_SPEED := 3.0  # 角速度（弧度/秒）
const ORBIT_BLADE_HIT_CD := 0.5  # 同一敌人两次受击的间隔

# 灼热光环（U6）：周期性灼烧玩家周围的敌人
const AURA_BASE_RADIUS := 130.0  # 1 级半径
const AURA_RADIUS_STEP := 35.0  # 每升 1 级的半径增量
const AURA_BASE_DAMAGE := 1
const AURA_DAMAGE_STEP := 1  # 每升 1 级的伤害增量
const AURA_INTERVAL := 1.0  # 灼烧周期（秒）

# （已并入品阶）（U6）：手枪额外弹丸围绕瞄准方向的散射间隔
const BULLET_SPREAD_DEG := 12.0

# 链式闪电（P5）：命中敌人后在附近敌人之间跳跃，逐跳衰减。
# 触发源是"任何一次命中"（子弹/飞刀），所以它吃现有法宝的频率，不单独占一个开火节奏。
const CHAIN_TRIGGER_CD := 0.25  # 触发冷却，防止连发时每颗子弹都拉一次电弧
const CHAIN_RANGE := 220.0  # 跳向下一只敌人的最大距离
const CHAIN_BASE_JUMPS := 2  # 1 级时跳跃次数
const CHAIN_JUMP_STEP := 1  # 每升 1 级的跳跃次数增量
const CHAIN_BASE_DAMAGE := 1  # 第一跳伤害
const CHAIN_DAMAGE_STEP := 1  # 每升 1 级的伤害增量
const CHAIN_FALLOFF := 0.5  # 每跳伤害衰减比例（0.5 = 每跳减半）
const CHAIN_LINE_LIFE := 0.18  # 电弧残留时间（秒）
const CHAIN_LINE_JITTER := 9.0  # 电弧抖动幅度（像素）

# 法宝进化（P3→P6）：**法宝升到 weapons.gd 的 max_level 时自动进入进化形态**。
# （旧版"第 6 张同名卡触发进化"已随法宝卡移出卡池而取消）
# 环形刀刃 → 刃风暴
const BLADE_EVOLVE_ROT_MULT := 2.2  # 转速倍率
const BLADE_EVOLVE_RADIUS_BONUS := 60.0
const BLADE_EVOLVE_DAMAGE_BONUS := 3
# 灼热光环 → 烈日领域
const AURA_EVOLVE_INTERVAL := 0.5  # 灼烧间隔减半
const AURA_EVOLVE_DAMAGE_BONUS := 2
# （已并入品阶） → 剑光化灵
const GUN_EVOLVE_EXTRA_BULLETS := 2
const GUN_EVOLVE_FIRE_RATE_MULT := 1.2
# 链式闪电 → 雷神之怒
const CHAIN_EVOLVE_EXTRA_JUMPS := 2  # 跳跃次数 +2
const CHAIN_EVOLVE_FALLOFF := 0.3  # 衰减放缓（0.3 = 每跳只减三成）

# 主动技能数值（P6）
const SKILL_SHURIKEN_COUNT := 10      # 万剑归宗放射数量
const SKILL_SHURIKEN_DAMAGE_BONUS := 1
const SKILL_BLADE_RADIUS := 260.0     # 刃风暴横扫半径
const SKILL_BLADE_DAMAGE := 8
const SKILL_AURA_RADIUS := 420.0      # 烈日爆发范围
const SKILL_AURA_DAMAGE := 12

# 法宝掉落（P6）：普通怪小概率掉；妖王必掉（见 mob.gd）
const WEAPON_DROP_CHANCE := 0.12
# 材料掉落概率（P6 法宝升级用）
const MATERIAL_DROP_CHANCE := 0.22   # 玄铁
const CRYSTAL_DROP_CHANCE := 0.06    # 雷魄
const SKILL_BOOK_DROP_CHANCE := 0.02 # 神通残卷

# 法宝获取（P6 调整）：原来 4% 太稀，开局两分钟一把都掉不出来（实测站桩 3 分钟 66 斩妖 = 0 把）。
# 现在提高基础概率 + 开局保底，并且限制地上同时存在的把数，避免满地掉落物堆积。
const WEAPON_PITY_TIME := 90.0   # 开局这段时间内启用保底
const WEAPON_PITY_KILLS := 12    # 每积累这么多次斩妖还没掉够法宝就必掉一把
const WEAPON_PITY_MAX := 2       # 保底最多给几把
const WEAPON_DROP_MAX_GROUND := 8 # 地上同时最多留几把（超了回收最早的一把）
# 开局选法宝：本命飞剑是固定基础法宝，选它 = 起手直接给到这个等级
const START_WEAPON_LEVEL := 3

# 法宝被动（P6 模型 B）：法宝 = 被动效果 + 提供技能，**被动等级 = 法宝等级**。
# 本命飞剑（被动=自动投掷）：每 WEAPON_SHURIKEN_LEVEL_STEP 级多 1 发弹丸、+1 伤害；射速线性提升
const WEAPON_SHURIKEN_LEVEL_STEP := 2         # 每 2 级：弹丸 +1、伤害 +1
const WEAPON_SHURIKEN_RATE_PER_LEVEL := 0.10  # 每级射速 +10%
# 环形刀刃 / 灼热光环 / 链式闪电的被动等级直接传给各自节点，曲线见各自 *_STEP 常量

# 技能「雷神之怒」（P6）：同时向多个目标劈下闪电，每道都额外跳跃、伤害提升
const SKILL_THUNDER_ORIGINS := 4        # 同时起跳的闪电数量
const SKILL_THUNDER_EXTRA_JUMPS := 3    # 每道闪电的额外跳跃次数
const SKILL_THUNDER_DAMAGE_BONUS := 2   # 每跳伤害加成
const SKY_BOLT_HEIGHT := 900.0          # 天雷从目标上方多高处劈下（视觉用）

# 灵力（蓝条，P6 技能系统）：技能消耗蓝，随时间回复。
const MANA_MAX := 100.0
const MANA_START := 100.0
const MANA_REGEN := 6.0  # 每秒回复

# 胜利条件（P5）：活满 SURVIVE_WIN_TIME 秒，或斩妖 VICTORY_BOSS_KILLS 只妖王，任一达成即胜利。
const SURVIVE_WIN_TIME := 900.0  # 15 分钟
const VICTORY_BOSS_KILLS := 3

# 妖王（P4）：每 BOSS_INTERVAL 秒来袭一只，血量按来过几只递增。
# 三段循环 AI：追击 3s → 蓄力 0.7s（闪白预示）→ 冲锋 0.8s（3.2 倍速直线）。
const BOSS_INTERVAL := 180.0
const BOSS_FIRST_DELAY := 120.0  # 首只妖王出现时间
const BOSS_BASE_HP := 150
const BOSS_HP_PER_KILL := 120  # 每斩妖一只，下一只更肉
const BOSS_SPEED := 170.0
const BOSS_CHARGE_SPEED_MULT := 3.2
const BOSS_CHARGE_PHASE := {"chase": 3.0, "windup": 0.7, "dash": 0.8}
const BOSS_SCALE := 3.6  # 新妖王素材是 52x32 的精细立绘，2.2 已有 114x70 的压迫感
const BOSS_COLOR := Color(1.6, 0.45, 0.45)
const BOSS_XP := 50
const BOSS_CONTACT := 3.0
const BOSS_KNOCKBACK_RESIST := 0.2  # 吃击退的比率
const BOSS_HIT_RADIUS := 38.0  # 妖王身体判定圆（世界像素，不跟精灵缩放）
# 妖王冲锋时会把沿途的瓦片障碍撞碎（自己穿墙，但顺手给玩家和杂兵开路）
const BOSS_BREAK_RADIUS := 120.0  # 以妖王为中心，这个半径内的瓦片被撞碎
const BOSS_BREAK_CD := 0.08       # 撞碎节流（秒）
# 妖王专属贴图（AI 生成后放入 assets/mobs/；缺失时回退用坦克贴图染色）
const BOSS_SPRITES := ["res://assets/mobs/boss_0.png", "res://assets/mobs/boss_1.png"]

# 宝箱（P4）：妖王必掉，走过去开启，随机奖励。
# 权重：材料礼包 → 直接升级 → 其余灵石
const CHEST_COIN_MIN := 15
const CHEST_COIN_MAX := 25
const CHEST_MATERIAL_CHANCE := 0.5     # 材料礼包
const CHEST_FREE_UPGRADE_CHANCE := 0.2 # 免材料免斩妖，直接给一把已持有法宝 +1 级
const CHEST_SCRAP_AMOUNT := 8
const CHEST_CRYSTAL_AMOUNT := 3

# 击退（P1 打磨）：命中把敌人推开，数值为初速度（px/s），摩擦衰减见 mob.gd
const KNOCKBACK_BULLET := 220.0
const KNOCKBACK_BLADE := 160.0
const KNOCKBACK_MAX := 420.0  # 叠加上限，防止连发把怪打飞出屏
const KNOCKBACK_FRICTION := 900.0  # 每秒衰减的初速度量

# 经验与成长（U3）
const GEM_VALUE := 1
const PICKUP_RADIUS := 260.0
const GEM_DRIFT_SPEED := 24.0  # 宝石缓慢滚向玩家的速度
const LEVEL_UP_HEAL := 10.0  # 每次升级附带的小回复

# 灵石掉落（P2 局外经济）：每变体的掉落概率与数量
const COIN_DROPS := {
	"slime": {"chance": 0.18, "amount": 1},
	"runner": {"chance": 0.25, "amount": 1},
	"tank": {"chance": 1.0, "amount": 3},
	"elite": {"chance": 1.0, "amount": 8},
}
const COIN_VALUE := 1  # 单枚灵石面值（掉落数量已按变体折算）

# 商店（P2 局外永久强化）：花费 = cost ×（当前等级+1），效果在 player._ready 应用
const SHOP := [
	{"id": "hp", "name": "炼体诀", "desc": "初始生命 +20/级", "max": 5, "cost": 15},
	{"id": "dmg", "name": "淬剑术", "desc": "初始剑伤 +1/级", "max": 5, "cost": 25},
	{"id": "spd", "name": "神行符", "desc": "移动速度 +6%/级", "max": 3, "cost": 20},
	{"id": "mag", "name": "聚灵阵", "desc": "拾取范围 +25%/级", "max": 3, "cost": 15},
]
const SHOP_HP_PER_LEVEL := 20.0
const SHOP_DMG_PER_LEVEL := 1
const SHOP_SPD_PER_LEVEL := 0.06
const SHOP_MAG_PER_LEVEL := 0.25


## 升到 level 级需要攒的经验：前期轻松（5/7/9……），
## 中期稳步上涨，11 级后封顶稳定在 25。
static func xp_for_level(level: int) -> int:
	return int(minf(3.0 + level * 2.0, 25.0))
