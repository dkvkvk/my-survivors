class_name Characters

## 身份表（P8 多角色）：每个身份 = 一套属性偏向 + 一件**签名法宝** + 一张**专属行走表**。
##
## 设计约定（2026-10-01 用户要求"武器与角色绑定"）：
##   · 本命飞剑是每个身份都自带的基础法宝（没有它就没有自动攻击，开局会没法玩）；
##   · 每个身份再带一件**签名法宝**：选角色即选武器，进游戏不再弹"选法宝"面板；
##   · 每个身份有自己的行走表 `sheet`；素材没到位时自动退回共用表 + 配色 tint 顶着，
##     所以"加表"是纯增量，不阻塞玩法。
##
## 行走表规格与共用表一致（4×4、每格 16px）：列 = 朝向（下 0 / 上 1 / 左 2 / 右 3），行 0-3 = 行走帧。
## ⚠️ 代码里"右向"是**镜像左向列**（见 hero.gd），所以 col3 可以留空/复制左列；
##    真正要紧的是 col0 / col1 / col2 三列各自帧间自洽。
## 提示词见 XIANXIA_ART_PROMPTS.md 第八节 B 组（实测：**一次只要一列 4 帧**才画得准，由我拼表）。

const DEFAULT_ID := "shou_shan"

const LIST := [
	{
		"id": "shou_shan",
		"name": "守山人",
		"desc": "三代守夜，剑案传家。本命飞剑起手 4 阶，身板与出手都均衡，法宝位也更空。",
		"tint": Color(1, 1, 1),
		"accent": Color(0.33, 0.88, 0.78),
		"sheet": "res://assets/hero/ninja_sheet.png",
		"signature_weapon": "",
		"base_weapon_level": 4,
		"signature_level": 0,
		"health_mult": 1.0, "speed_mult": 1.0, "fire_rate_mult": 1.0, "mana_max_mult": 1.0,
	},
	{
		"id": "fu_xiu",
		"name": "符修",
		"desc": "万宝楼掌柜的弟子。随身带符阵，灵力深厚，但身板脆。",
		"accent": Color(0.91, 0.72, 0.29),
		# 三个身份共用主角表时只能靠配色区分——调太淡玩家会说"人物没法切换"，
		# 所以这里用**明显的换色**（2026-09-24 用户反馈后加强）；有专属表后 tint 自动失效
		"tint": Color(1.0, 0.58, 0.22),
		"sheet": "res://assets/hero/char_fu_sheet.png",
		"signature_weapon": "mine",
		"health_mult": 0.75, "speed_mult": 1.0, "fire_rate_mult": 1.0, "mana_max_mult": 1.4,
	},
	{
		"id": "jian_xiu",
		"name": "剑修",
		"desc": "青冥山弃徒。剑环护身、出手极快，脚下却慢半拍。",
		"accent": Color(0.81, 0.91, 0.88),
		"tint": Color(0.52, 0.86, 1.0),
		"sheet": "res://assets/hero/char_jian_sheet.png",
		"signature_weapon": "orbit_blade",
		"health_mult": 1.0, "speed_mult": 0.9, "fire_rate_mult": 1.25, "mana_max_mult": 1.0,
	},
	{
		"id": "dan_xiu",
		"name": "丹修",
		"desc": "青冥观丹房看火的道人。三昧真火缠身，最耐打，出手偏慢。",
		"accent": Color(0.45, 0.78, 0.55),
		"tint": Color(0.62, 1.0, 0.72),
		"sheet": "res://assets/hero/char_dan_sheet.png",
		"signature_weapon": "aura",
		"health_mult": 1.3, "speed_mult": 0.95, "fire_rate_mult": 0.9, "mana_max_mult": 1.0,
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
