class_name Upgrades

## 升级三选一的卡池。id 对应 player.gd 里 apply_upgrade() 的分支。
## 想加新卡：这里加一条，player.gd 里加一个 match 分支即可。

const LIST := [
	{"id": "speed", "name": "疾风之靴", "desc": "移动速度 +12%"},
	{"id": "fire_rate", "name": "灵巧扳机", "desc": "射击速度 +15%"},
	{"id": "damage", "name": "重装弹药", "desc": "子弹伤害 +1"},
	{"id": "max_health", "name": "生命祝福", "desc": "最大生命 +25\n并立即恢复 25"},
	{"id": "magnet", "name": "磁力护符", "desc": "经验拾取范围 +35%"},
	{"id": "orbit_blade", "name": "环形刀刃", "desc": "一把刀刃环绕自身旋转\n再次获得数量 +1"},
	{"id": "aura", "name": "灼热光环", "desc": "周期灼烧周围敌人\n再次获得范围与伤害提升"},
	{"id": "split_shot", "name": "分裂弹头", "desc": "手枪额外发射一发扇形\n散射子弹，可叠加"},
]
