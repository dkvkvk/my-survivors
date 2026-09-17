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
