class_name Balance

## 全部可调数值集中在这里，改平衡只动这一个文件。
## U3 的升级三选一会把这些常量换成可变数值（玩家身上的加成叠加）。

# 玩家
const PLAYER_SPEED := 600.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_DAMAGE_RATE := 6.0  # 每个重叠敌人每秒掉的血

# 敌人变体（U4）：血量/速度区间/体型/色调/经验/接触伤害倍率
const MOB_VARIANTS := {
	"slime": {"hp": 2, "speed": [200.0, 300.0], "scale": 1.0, "color": Color(1, 1, 1), "xp": 1, "contact": 1.0},
	"runner": {"hp": 1, "speed": [380.0, 460.0], "scale": 0.8, "color": Color(1.45, 1.25, 0.6), "xp": 1, "contact": 1.0},
	"tank": {"hp": 8, "speed": [110.0, 150.0], "scale": 1.7, "color": Color(0.75, 0.95, 0.75), "xp": 5, "contact": 1.5},
	"elite": {"hp": 20, "speed": [240.0, 280.0], "scale": 2.1, "color": Color(1.5, 0.6, 0.6), "xp": 15, "contact": 2.5},
}

# 波次表：t=生效时间（秒），spawn=刷怪间隔，weights=各变体出现权重
const WAVES := [
	{"t": 0.0, "spawn": 0.85, "weights": {"slime": 1.0}},
	{"t": 45.0, "spawn": 0.65, "weights": {"slime": 0.75, "runner": 0.25}},
	{"t": 100.0, "spawn": 0.5, "weights": {"slime": 0.55, "runner": 0.3, "tank": 0.15}},
	{"t": 160.0, "spawn": 0.4, "weights": {"slime": 0.35, "runner": 0.35, "tank": 0.2, "elite": 0.1}},
	{"t": 240.0, "spawn": 0.32, "weights": {"slime": 0.25, "runner": 0.35, "tank": 0.25, "elite": 0.15}},
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

# 经验与成长（U3）
const GEM_VALUE := 1
const PICKUP_RADIUS := 260.0
const GEM_DRIFT_SPEED := 24.0  # 宝石缓慢滚向玩家的速度
const LEVEL_UP_HEAL := 10.0  # 每次升级附带的小回复


## 升到 level 级需要攒的经验：前期轻松（5/7/9……），
## 中期稳步上涨，11 级后封顶稳定在 25。
static func xp_for_level(level: int) -> int:
	return int(minf(3.0 + level * 2.0, 25.0))
