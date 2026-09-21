class_name Upgrades

## 升级三选一的卡池（P6 起**只出属性卡**）。
## 法宝不再从这里出——法宝改为**掉落物**，见 weapons.gd / WEAPON_SYSTEM.md。
## 想加属性卡：这里加一条，player.gd 里加一个 match 分支即可。

const LIST := [
	{"id": "speed", "icon": "res://assets/ui/card_speed.png", "name": "缩地成寸", "desc": "移动速度 +12%"},
	{"id": "fire_rate", "icon": "res://assets/ui/card_fire_rate.png", "name": "疾剑诀", "desc": "御剑出手 +15%"},
	{"id": "damage", "icon": "res://assets/ui/card_damage.png", "name": "剑气加身", "desc": "剑伤 +1"},
	{"id": "max_health", "icon": "res://assets/ui/card_max_health.png", "name": "固本培元", "desc": "最大生命 +25\n并立即恢复 25"},
	{"id": "magnet", "icon": "res://assets/ui/card_magnet.png", "name": "聚灵引", "desc": "灵珠吸附范围 +35%"},
]
