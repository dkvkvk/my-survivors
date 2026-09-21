class_name Skills

## 主动技能表（P6 技能系统）。
## 每个技能：id / 名称 / 图标 / 耗蓝 / 冷却 / 描述 / 触发方式。
## 想加技能：这里加一条，player.gd 的 cast_skill() 加一个分支。
##
## 设计（与用户确认）：
## - 技能槽最多 4 个，键位 1/2/3/4
## - 施放消耗蓝条（Balance.MANA_*）
## - 武器掉落获得，每把武器自带技能；武器可升级
## - 两个技能可融合成融合技能（见 FUSIONS，后续实现）

const LIST := [
	{
		"id": "shuriken_burst",
		"name": "手里剑乱舞",
		"icon": "res://assets/ui/skill_shuriken.png",
		"mana": 20.0, "cd": 6.0,
		"desc": "向四周爆发一圈手里剑（伤害吃手里剑武器等级）",
		"from": "gun",
	},
	{
		"id": "blade_storm",
		"name": "刃风暴",
		"icon": "res://assets/ui/skill_orbit_blade.png",
		"mana": 25.0, "cd": 8.0,
		"desc": "刀刃急速扩张，横扫周围",
		"from": "orbit_blade",
	},
	{
		"id": "sunburst",
		"name": "烈日爆发",
		"icon": "res://assets/ui/skill_aura.png",
		"mana": 30.0, "cd": 10.0,
		"desc": "光环瞬间扩大并灼烧全场",
		"from": "aura",
	},
	{
		"id": "thunder",
		"name": "雷神之怒",
		"icon": "res://assets/ui/skill_chain_lightning.png",
		"mana": 35.0, "cd": 12.0,
		"desc": "向四周劈下多道闪电，连击全场",
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
	{"requires": ["blade_storm", "sunburst"], "result": "inferno_ring", "name": "炼狱轮环"},
	{"requires": ["shuriken_burst", "thunder"], "result": "storm_volley", "name": "雷暴连矢"},
]
