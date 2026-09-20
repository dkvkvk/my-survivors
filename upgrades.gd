class_name Upgrades

## 升级三选一的卡池。id 对应 player.gd 里 apply_upgrade() 的分支。
## 想加新卡：这里加一条，player.gd 里加一个 match 分支即可。

const LIST := [
	{"id": "speed", "icon": "res://assets/ui/card_speed.png", "name": "疾风之靴", "desc": "移动速度 +12%"},
	{"id": "fire_rate", "icon": "res://assets/ui/card_fire_rate.png", "name": "灵巧扳机", "desc": "射击速度 +15%"},
	{"id": "damage", "icon": "res://assets/ui/card_damage.png", "name": "重装弹药", "desc": "子弹伤害 +1"},
	{"id": "max_health", "icon": "res://assets/ui/card_max_health.png", "name": "生命祝福", "desc": "最大生命 +25\n并立即恢复 25"},
	{"id": "magnet", "icon": "res://assets/ui/card_magnet.png", "name": "磁力护符", "desc": "经验拾取范围 +35%"},
	{"id": "orbit_blade", "icon": "res://assets/ui/card_orbit_blade.png", "name": "环形刀刃", "desc": "一把刀刃环绕自身旋转\n满 5 级后进化为刃风暴"},
	{"id": "aura", "icon": "res://assets/ui/card_aura.png", "name": "灼热光环", "desc": "周期灼烧周围敌人\n满 5 级后进化为烈日领域"},
	{"id": "split_shot", "icon": "res://assets/ui/card_split_shot.png", "name": "分裂弹头", "desc": "手枪额外一发扇形散射\n满 5 级后进化为手里剑大师"},
]
