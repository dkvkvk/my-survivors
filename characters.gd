class_name Characters

## 身份表（P7 多角色）：决定开局自带的"签名法宝"、属性偏向与主角配色。
##
## 本命飞剑是**每个身份都有的基础法宝**（没有它就没有自动攻击，开局会没法玩），
## 所以身份差异体现在：额外自带哪把法宝 + 属性偏向 + 主角配色。
## 配色是代码调色（Color 乘在主角精灵上），不需要额外美术；
## 想要各自独立的行走表，见 XIANXIA_ART_PROMPTS.md 第八节 B 组提示词。

const DEFAULT_ID := "shou_shan"

const LIST := [
	{
		"id": "shou_shan",
		"name": "守山人",
		"desc": "三代守夜，剑案传家。身板与出手都均衡。",
		"tint": Color(1, 1, 1),
		"start_extra_weapon": "",
		"health_mult": 1.0, "speed_mult": 1.0, "fire_rate_mult": 1.0, "mana_max_mult": 1.0,
	},
	{
		"id": "fu_xiu",
		"name": "符修",
		"desc": "万宝楼掌柜的弟子。随身带符阵，灵力深厚，但身板脆。",
		"tint": Color(1.0, 0.8, 0.55),
		"start_extra_weapon": "mine",
		"health_mult": 0.75, "speed_mult": 1.0, "fire_rate_mult": 1.0, "mana_max_mult": 1.4,
	},
	{
		"id": "jian_xiu",
		"name": "剑修",
		"desc": "青冥山弃徒。剑环护身、出手极快，脚下却慢半拍。",
		"tint": Color(0.75, 0.92, 1.0),
		"start_extra_weapon": "orbit_blade",
		"health_mult": 1.0, "speed_mult": 0.9, "fire_rate_mult": 1.25, "mana_max_mult": 1.0,
	},
]


static func get_def(id: String) -> Dictionary:
	for c in LIST:
		if str(c["id"]) == id:
			return c
	return LIST[0]


static func has(id: String) -> bool:
	for c in LIST:
		if str(c["id"]) == id:
			return true
	return false


## 当前身份（存档里没有或写了个不存在的 id 时，退回默认）
static func current_id() -> String:
	var id: String = SaveGame.get_character()
	return id if has(id) else DEFAULT_ID


static func current_def() -> Dictionary:
	return get_def(current_id())
