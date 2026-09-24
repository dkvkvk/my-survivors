class_name Weapons

## 法宝数据表（P6）。
##
## **模型 B（2026-09-21 定稿，权威设计见 WEAPON_SYSTEM.md）**：
##   一把法宝 = 一个**被动效果**（自动生效，等级 = 法宝等级）
##            + 一组**技能**（每场只能选 1 个，占用对应技能槽）
##   被动类型写在 passive 字段，player.gd 的 _apply_weapon_passive() 按此分发。
##   法宝升到 max_level 自动进入"进化形态"（各法宝节点的 evolve()）。
##
## 加法宝：这里加一条 + player._apply_weapon_passive()/_clear_weapon_passive()/_evolve_weapon() 各加分支
## 加技能：skills.gd 加一条 + player._run_skill_effect() 加分支
##
## kills_per_level 说明：斩妖经验**精确归属**给造成致命一击的法宝（见 mob.take_damage 的 source），
## 一把法宝只能拿到自己补刀的那部分斩妖数（4 把平分时约 1/4~1/3）。
## 所以这里的门槛是"归属精确化之后"的数值——2026-09-22 由 100/120/120/150 下调到下面这组。

const MAX_SLOTS := 4          # 法宝上限（与 4 个技能槽对应）

const LIST := [
	{
		"id": "shuriken",
		"name": "本命飞剑",
		"icon": "res://assets/ui/icon_fa_sword.png",
		"max_level": 5,
		"passive": "gun",
		"skills": ["shuriken_burst"],
		"upgrade_material": "scrap",
		"base_cost": 5,
		"kills_per_level": 35,
		"desc": "被动：御剑杀敌，阶高分化多剑",
	},
	{
		"id": "orbit_blade",
		"name": "周天剑环",
		"icon": "res://assets/ui/icon_fa_ring.png",
		"max_level": 5,
		"passive": "orbit_blade",
		"skills": ["blade_storm"],
		"upgrade_material": "scrap",
		"base_cost": 6,
		"kills_per_level": 40,
		"desc": "被动：数剑绕体护身，剑数 = 品阶",
	},
	{
		"id": "aura",
		"name": "离火法环",
		"icon": "res://assets/ui/icon_fa_fire.png",
		"max_level": 5,
		"passive": "aura",
		"skills": ["sunburst"],
		"upgrade_material": "crystal",
		"base_cost": 4,
		"kills_per_level": 40,
		"desc": "被动：周身三昧真火，灼烧近敌",
	},
	{
		"id": "boomerang",
		"name": "回风梭",
		"icon": "res://assets/ui/icon_fa_boomerang.png",
		"max_level": 5,
		"passive": "boomerang",
		"skills": ["whirlwind_volley"],
		"upgrade_material": "scrap",
		"base_cost": 6,
		"kills_per_level": 40,
		"desc": "被动：掷梭回旋，去而复返\n去程返程各伤一次",
	},
	{
		"id": "mine",
		"name": "地火符阵",
		"icon": "res://assets/ui/icon_fa_mine.png",
		"max_level": 5,
		"passive": "mine",
		"skills": ["thunder_net"],
		"upgrade_material": "crystal",
		"base_cost": 5,
		"kills_per_level": 40,
		"desc": "被动：布符于地，妖至即爆\n范围杀伤，可囤积",
	},
	{
		"id": "chain_lightning",
		"name": "连环雷符",
		"icon": "res://assets/ui/icon_fa_talisman.png",
		"max_level": 5,
		"passive": "chain_lightning",
		"skills": ["thunder"],
		"upgrade_material": "crystal",
		"base_cost": 4,
		"kills_per_level": 50,
		"desc": "被动：杀敌引雷，雷窜敌群",
	},
]

## 材料定义（升级消耗）
const MATERIALS := {
	"scrap": {"name": "玄铁", "icon": "res://assets/ui/icon_material_scrap.png"},
	"crystal": {"name": "雷魄", "icon": "res://assets/ui/icon_material_crystal.png"},
}


static func get_def(id: String) -> Dictionary:
	for w in LIST:
		if w["id"] == id:
			return w
	return {}


static func material_name(id: String) -> String:
	var m: Dictionary = MATERIALS.get(id, {})
	return m.get("name", id)


## 升到下一级要多少材料（每级递增）
static func upgrade_cost(def: Dictionary, level: int) -> int:
	return int(def.get("base_cost", 5)) * level


## 该法宝是否已满级
static func is_maxed(def: Dictionary, level: int) -> bool:
	return level >= int(def.get("max_level", 5))
