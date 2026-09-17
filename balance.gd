class_name Balance

## 全部可调数值集中在这里，改平衡只动这一个文件。
## U3 的升级三选一会把这些常量换成可变数值（玩家身上的加成叠加）。

# 玩家
const PLAYER_SPEED := 600.0
const PLAYER_MAX_HEALTH := 100.0
const PLAYER_DAMAGE_RATE := 6.0  # 每个重叠敌人每秒掉的血

# 敌人
const MOB_MIN_SPEED := 200.0
const MOB_MAX_SPEED := 300.0
const MOB_HEALTH := 2

# 子弹
const BULLET_SPEED := 1000.0
const BULLET_RANGE := 1200.0

# 武器（场景里 Timer 的 wait_time 会在 _ready 时被这些值覆盖）
const GUN_FIRE_INTERVAL := 0.32
const SPAWN_INTERVAL_START := 0.85  # 开局刷怪间隔（轻松）
const SPAWN_INTERVAL_MIN := 0.35    # 3 分钟后的最快刷怪间隔
const SPAWN_RAMP_TIME := 180.0     # 从开局到最难所用的秒数

# 经验与成长（U3）
const GEM_VALUE := 1
const PICKUP_RADIUS := 260.0
const GEM_DRIFT_SPEED := 24.0  # 宝石缓慢滚向玩家的速度
const LEVEL_UP_HEAL := 10.0  # 每次升级附带的小回复


## 升到 level 级需要攒的经验：前期轻松（5/7/9……），
## 中期稳步上涨，11 级后封顶稳定在 25。
static func xp_for_level(level: int) -> int:
	return int(minf(3.0 + level * 2.0, 25.0))


## 刷怪间隔随时间从 SPAWN_INTERVAL_START 渐进降到 SPAWN_INTERVAL_MIN，
## 让难度平滑上升而不是开局就全速刷怪。
static func spawn_interval(run_time: float) -> float:
	var t := clampf(run_time / SPAWN_RAMP_TIME, 0.0, 1.0)
	return lerpf(SPAWN_INTERVAL_START, SPAWN_INTERVAL_MIN, t)
