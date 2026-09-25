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
		"id": "whirlwind_volley",
		"name": "风卷残云",
		"icon": "res://assets/ui/skill_boomerang.png",
		"mana": 25.0, "cd": 8.0,
		"desc": "万梭齐出，向四方激射（伤害吃回风梭品阶）",
		"from": "boomerang",
	},
	{
		"id": "thunder_net",
		"name": "十方雷网",
		"icon": "res://assets/ui/skill_mine.png",
		"mana": 30.0, "cd": 10.0,
		"desc": "周身布下一圈符雷，齐爆成网",
		"from": "mine",
	},
	{
		"id": "thunder",
		"name": "九天神雷",
		"icon": "res://assets/ui/skill_chain_lightning.png",
		"mana": 35.0, "cd": 12.0,
		"desc": "举手画符，九天之雷当空劈落",
		"from": "chain_lightning",
	},
	# ---------- P7：每把法宝的第 2 神通 ----------
	{
		"id": "dash_blade",
		"name": "御剑疾影",
		"icon": "res://assets/ui/skill_dash_blade.png",
		"mana": 18.0, "cd": 5.0,
		"desc": "化身剑光疾奔，途中撞伤贴身的妖",
		"from": "shuriken",
	},
	{
		"id": "ring_release",
		"name": "剑环外放",
		"icon": "res://assets/ui/skill_ring_release.png",
		"mana": 24.0, "cd": 7.0,
		"desc": "护身剑环一次性向外飞出，扫平近身",
		"from": "orbit_blade",
	},
	{
		"id": "fire_field",
		"name": "焚地火域",
		"icon": "res://assets/ui/skill_fire_field.png",
		"mana": 28.0, "cd": 9.0,
		"desc": "脚下留一片三昧火海，持续灼烧踏入的妖",
		"from": "aura",
	},
	{
		"id": "charge_storm",
		"name": "蓄雷引弧",
		"icon": "res://assets/ui/skill_charge_storm.png",
		"mana": 26.0, "cd": 14.0,
		"desc": "蓄雷数秒：电弧跳得更多、触发更密",
		"from": "chain_lightning",
	},
	{
		"id": "pierce_shuttle",
		"name": "穿云巨梭",
		"icon": "res://assets/ui/skill_pierce_shuttle.png",
		"mana": 22.0, "cd": 6.0,
		"desc": "掷出巨型飞梭，直线穿透一切敌人",
		"from": "boomerang",
	},
	{
		"id": "detonate_all",
		"name": "符阵合围",
		"icon": "res://assets/ui/skill_detonate_all.png",
		"mana": 26.0, "cd": 9.0,
		"desc": "立刻引爆场上所有符雷，连锁成一片雷火",
		"from": "mine",
	},
	# ---------- P7：融合神通（需两把法宝都在场，见 FUSIONS）----------
	{
		"id": "inferno_ring",
		"name": "焚天剑轮",
		"icon": "res://assets/ui/skill_inferno_ring.png",
		"mana": 40.0, "cd": 14.0,
		"desc": "融合：带火的剑环外放，扫过之处留下火域",
		"from": "fusion",
	},
	{
		"id": "storm_volley",
		"name": "惊雷剑引",
		"icon": "res://assets/ui/skill_storm_volley.png",
		"mana": 45.0, "cd": 16.0,
		"desc": "融合：放射剑雨，每一把剑落下都带一道天雷",
		"from": "fusion",
	},
]


## 取某个技能所属的法宝 id（融合技能返回空串）
static func weapon_of_skill(skill_id: String) -> String:
	for w in Weapons.LIST:
		if skill_id in w.get("skills", []):
			return str(w["id"])
	return ""


## 某件法宝**当前可换**的神通：自带技能 + 已满足条件的融合神通。
## 乾坤袋与 player.set_active_skill 都走它，保证"能不能选"只有一处判定。
static func available_for(player: Node, weapon_id: String) -> Array:
	var def: Dictionary = Weapons.get_def(weapon_id)
	var out: Array = def.get("skills", []).duplicate()
	for f in FUSIONS:
		var ok := true
		for sid in f.get("requires", []):
			var owner_id: String = weapon_of_skill(str(sid))
			if owner_id == "" or not player.has_weapon(owner_id):
				ok = false
				break
		if ok and not out.has(str(f["result"])):
			out.append(f["result"])
	return out


## 是不是融合神通（乾坤袋用来标"融合"字样）
static func is_fusion(skill_id: String) -> bool:
	for f in FUSIONS:
		if str(f["result"]) == skill_id:
			return true
	return false


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
