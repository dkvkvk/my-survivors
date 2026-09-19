class_name Balance

## 全部可调数值集中在这里，改平衡只动这一个文件。
## U3 的升级三选一会把这些常量换成可变数值（玩家身上的加成叠加）。

# 玩家
const PLAYER_SPEED := 600.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_DAMAGE_RATE := 9.0  # 每个重叠敌人每秒掉的血：贴身必须痛，站桩必死

# 敌人变体（U4）：血量/速度区间/体型/色调/经验/接触伤害倍率
# sprites：两帧走路贴图（assets/mobs/，Kenney CC0）；color 为白色时用贴图原色
const MOB_VARIANTS := {
	"slime": {"hp": 3, "speed": [200.0, 300.0], "scale": 1.0, "color": Color(1, 1, 1), "xp": 1, "contact": 1.0, "sprites": ["res://assets/mobs/slime_0.png", "res://assets/mobs/slime_1.png"]},
	"runner": {"hp": 1, "speed": [380.0, 460.0], "scale": 0.8, "color": Color(1, 1, 1), "xp": 1, "contact": 1.0, "sprites": ["res://assets/mobs/bat_0.png", "res://assets/mobs/bat_1.png"]},
	"tank": {"hp": 10, "speed": [110.0, 150.0], "scale": 1.7, "color": Color(1, 1, 1), "xp": 5, "contact": 1.5, "sprites": ["res://assets/mobs/knight_0.png", "res://assets/mobs/knight_1.png"]},
	"elite": {"hp": 20, "speed": [240.0, 280.0], "scale": 2.1, "color": Color(1.4, 0.55, 0.55), "xp": 15, "contact": 2.5, "sprites": ["res://assets/mobs/beast_0.png", "res://assets/mobs/beast_1.png"]},
}

# 波次表：t=生效时间（秒），spawn=刷怪间隔，weights=各变体出现权重。
# 节奏偏紧：站桩会在 1~2 波内被围死，走位风筝才有活路。
const WAVES := [
	{"t": 0.0, "spawn": 0.7, "weights": {"slime": 1.0}},
	{"t": 30.0, "spawn": 0.55, "weights": {"slime": 0.7, "runner": 0.3}},
	{"t": 60.0, "spawn": 0.42, "weights": {"slime": 0.55, "runner": 0.3, "tank": 0.15}},
	{"t": 110.0, "spawn": 0.34, "weights": {"slime": 0.35, "runner": 0.35, "tank": 0.2, "elite": 0.1}},
	{"t": 170.0, "spawn": 0.26, "weights": {"slime": 0.25, "runner": 0.35, "tank": 0.25, "elite": 0.15}},
]


## 取存活时间对应的当前波次配置
static func current_wave(run_time: float) -> Dictionary:
	var wave: Dictionary = WAVES[0]
	for w in WAVES:
		if run_time >= w["t"]:
			wave = w
	return wave


## 按波次权重随机挑一个变体名
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

# 武器（场景里 Timer 的 wait_time 会在 _ready 时被这些值覆盖；刷怪间隔由波次表驱动）
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

# 分裂弹头（U6）：手枪额外弹丸围绕瞄准方向的散射间隔
const BULLET_SPREAD_DEG := 12.0

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

# 金币掉落（P2 局外经济）：每变体的掉落概率与数量
const COIN_DROPS := {
	"slime": {"chance": 0.18, "amount": 1},
	"runner": {"chance": 0.25, "amount": 1},
	"tank": {"chance": 1.0, "amount": 3},
	"elite": {"chance": 1.0, "amount": 8},
}
const COIN_VALUE := 1  # 单枚金币面值（掉落数量已按变体折算）

# 商店（P2 局外永久强化）：花费 = cost ×（当前等级+1），效果在 player._ready 应用
const SHOP := [
	{"id": "hp", "name": "体质锻炼", "desc": "初始生命 +20/级", "max": 5, "cost": 15},
	{"id": "dmg", "name": "锋利手里剑", "desc": "初始伤害 +1/级", "max": 5, "cost": 25},
	{"id": "spd", "name": "疾行忍靴", "desc": "移动速度 +6%/级", "max": 3, "cost": 20},
	{"id": "mag", "name": "磁力卷轴", "desc": "拾取范围 +25%/级", "max": 3, "cost": 15},
]
const SHOP_HP_PER_LEVEL := 20.0
const SHOP_DMG_PER_LEVEL := 1
const SHOP_SPD_PER_LEVEL := 0.06
const SHOP_MAG_PER_LEVEL := 0.25


## 升到 level 级需要攒的经验：前期轻松（5/7/9……），
## 中期稳步上涨，11 级后封顶稳定在 25。
static func xp_for_level(level: int) -> int:
	return int(minf(3.0 + level * 2.0, 25.0))
