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
const MOB_HEALTH := 3

# 子弹
const BULLET_SPEED := 1000.0
const BULLET_RANGE := 1200.0

# 武器与刷怪（场景里 Timer 的 wait_time 会在 _ready 时被这些值覆盖）
const GUN_FIRE_INTERVAL := 0.353
const SPAWN_INTERVAL := 0.3

# 经验与成长（U3）
const GEM_VALUE := 1
const PICKUP_RADIUS := 260.0
const LEVEL_UP_HEAL := 10.0  # 每次升级附带的小回复


## 升到 level 级需要攒的经验：前期轻松（4/6/8……），
## 中期稳步上涨，后期封顶稳定在 40，不再无限膨胀。
static func xp_for_level(level: int) -> int:
	return int(minf(2.0 + level * 2.0, 40.0))
