class_name Skills

## 主动技能表（P6 技能系统）。
## 每个技能：id / 名称 / 图标 / 耗蓝 / 冷却 / 描述 / 触发方式。
## 想加技能：这里加一条，player.gd 的 cast_skill() 加一个分支。
##
## 设计（与用户确认）：
## - 技能槽最多 4 个，键位 1/2/3/4
## - 施放消耗蓝条（Balance.MANA_*）
## - 法宝掉落获得，每把法宝自带技能；法宝可升级
## - 两个技能可融合成融合技能（见 FUSIONS，后续实现）

const LIST := [
	{
		"id": "shuriken_burst",
		"name": "万剑归宗",
		"icon": "res://assets/ui/skill_shuriken.png",
		"mana": 20.0, "cd": 6.0,
		"desc": "剑分化影，向周身激射一圈剑气（伤害吃本命剑品阶）",
		"from": "gun",
	},
	{
		"id": "blade_storm",
		"name": "剑气纵横",
		"icon": "res://assets/ui/skill_orbit_blade.png",
		"mana": 25.0, "cd": 8.0,
		"desc": "剑环暴涨，横扫四野",
		"from": "orbit_blade",
	},
	{
		"id": "sunburst",
		"name": "大日焚天",
		"icon": "res://assets/ui/skill_aura.png",
		"mana": 30.0, "cd": 10.0,
		"desc": "真火骤涨，如小日炸开",
		"from": "aura",
	},
	{
		"id": "thunder",
		"name": "九天神雷",
		"icon": "res://assets/ui/skill_chain_lightning.png",
		"mana": 35.0, "cd": 12.0,
		"desc": "举手画符，九天之雷当空劈落",
		"from": "chain_lightning",
	},
]


## 按 id 取技能定义（找不到返回空字典）
static func get_def(id: String) -> Dictionary:
	for s in LIST:
		if s["id"] == id:
			return s
	return {}


## 技能是否存在于表中
static func has(id: String) -> bool:
	return not get_def(id).is_empty()


## 融合技能表（P6 后续实现）：两个技能同时装备时可融合。
## result 指向 LIST 里的某个技能 id，或后续单独扩展。
const FUSIONS := [
	{"requires": ["blade_storm", "sunburst"], "result": "inferno_ring", "name": "焚天剑轮"},
	{"requires": ["shuriken_burst", "thunder"], "result": "storm_volley", "name": "惊雷剑引"},
]
