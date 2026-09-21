extends Node2D

## 分块地图（chunk streaming）：预设计的 16x16 瓦片小地图随机拼接成无限世界。
## 每块 1024px；玩家周围保持 5x5 块，走远自动回收，回头走地形不变（按坐标取种子）。
## 碰撞挂在瓦片上——看得见的格子才撞得上，从根源上消灭空气墙：
## 墙块/货箱/服务器=整格碰撞，天线=窄条碰撞（与桅杆视觉对齐），水晶/灌木=无碰撞。
## 碰撞层：1=玩家 2=敌人 3=障碍（本文件）。障碍挡玩家和"不穿墙"的怪（见 balance.gd 的 phasing 字段），
## 子弹一律穿行（防自动瞄准浪费弹）；飞行变体（机械蝙蝠）与首领天生穿墙，
## 其余怪被墙挡住超过 STUCK_CHECKS*STUCK_CHECK 秒会短暂穿墙脱困（防怪堆在墙后走不过来）。

const TILE := 64
const CHUNK_TILES := 16
const CHUNK_PX := TILE * CHUNK_TILES  # 1024，与地面吸附网格一致
const KEEP_RADIUS := 2  # 玩家周围保持 5x5 块
const FREE_RADIUS := 3  # 超出 7x7 回收

# 字符 -> 瓦片集图块索引（tileset.png 横排：墙0 货箱1 服务器2 天线3 水晶4 灌木5）
const TILES := {"#": 0, "C": 1, "S": 2, "A": 3, "c": 4, "b": 5}
# 图块索引 -> 碰撞定义："full"=整格，Vector2=底部居中窄条(w,h)，无键=无碰撞
const COLLIDERS := {0: "full", 1: "full", 2: "full", 3: Vector2(18, 44)}

# 小地图模板（16x16）。'.'=空地，其余见 TILES。
const TEMPLATES := [
	# 0 开阔地（出生点专用：只有装饰）
	[
		"................",
		"................",
		"....b.......c...",
		"................",
		"................",
		"........c.......",
		"................",
		".....b..........",
		"................",
		"................",
		".......c....b...",
		"................",
		"................",
		"..b.............",
		"................",
		"................",
	],
	# 1 立柱阵
	[
		"................",
		"................",
		"..##......##....",
		"..##......##....",
		"................",
		"................",
		".......b........",
		"................",
		"................",
		"........c.......",
		"................",
		"................",
		"..##......##....",
		"..##......##....",
		"................",
		"................",
	],
	# 2 房间（外墙带门，内屋藏水晶）
	[
		"#######.########",
		"#..............#",
		"#..b........c..#",
		"#..............#",
		"#...######.....#",
		"#...#....#.....#",
		"#...#.c..#.....#",
		"#...#....#.....#",
		".....#....#.....",
		"#....#..b.#.....",
		"#....###.##.....",
		"#..............#",
		"#..c.......b...#",
		"#..............#",
		"#..............#",
		"#######.########",
	],
	# 3 货箱堆
	[
		"................",
		"................",
		"....CC...CC.....",
		"....CC...CC.....",
		"................",
		"............CC..",
		".....CC.....CC..",
		".....CC.........",
		"................",
		"................",
		".CC.....CC......",
		".CC.....CC......",
		"............CC..",
		"................",
		"....b......c....",
		"................",
	],
	# 4 服务器走廊
	[
		"................",
		"................",
		".SSSSS....SSSSS.",
		".SSSSS....SSSSS.",
		"................",
		"................",
		".......c........",
		"................",
		"................",
		".b..............",
		"................",
		"................",
		".SSSSS....SSSSS.",
		".SSSSS....SSSSS.",
		"................",
		"................",
	],
	# 5 水晶园
	[
		"................",
		"..c.........c...",
		"................",
		".......b........",
		"................",
		"....b......c....",
		"................",
		"........c.......",
		"................",
		"................",
		"....c......b....",
		"................",
		".......b........",
		"..c.............",
		"................",
		"................",
	],
	# 6 天线场
	[
		"................",
		"................",
		"...A........A...",
		"................",
		"................",
		"........A.......",
		".....b..........",
		"................",
		"................",
		".......A...b....",
		"................",
		"................",
		"...A........A...",
		"................",
		"....c...........",
		"................",
	],
	# 7 斜墙（风筝走位用）
	[
		"................",
		".............##.",
		"............##..",
		"...........##...",
		"..........##....",
		".........##.....",
		"........##......",
		".......##.......",
		"......##........",
		".....##.........",
		"....##..........",
		"...##...........",
		"..##............",
		".##.............",
		"................",
		"................",
	],
	# 8 竞技场（货箱围栏）
	[
		"................",
		"....CCCCCCCC....",
		"....C......C....",
		"....C..b...C....",
		"....C......C....",
		"....C..cc..C....",
		"....C......C....",
		"....C......C....",
		"....C......C....",
		"....C..b...C....",
		"....C......C....",
		"....C......C....",
		"....CCCCCCCC....",
		"................",
		".......c........",
		"................",
	],
]

var _chunks := {}  # Vector2i -> TileMapLayer
var _world_seed := 0
var _tile_set: TileSet


func _ready():
	randomize()
	_world_seed = randi()
	z_index = -10
	_build_tile_set()


func _process(_delta):
	_ensure_around(get_parent().player.global_position)


## 用脚本生成 TileSet：图块 + 逐格碰撞多边形（不依赖编辑器资源）
func _build_tile_set() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2(TILE, TILE)
	_tile_set.add_physics_layer()
	_tile_set.set_physics_layer_collision_layer(0, 4)  # 障碍层（第 3 层）：挡玩家 + 不穿墙的怪
	_tile_set.set_physics_layer_collision_mask(0, 0)

	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/tiles/tileset.png")
	src.texture_region_size = Vector2(TILE, TILE)
	# 注意：先把图块源挂到 TileSet（物理层数据此生效），再创建图块与碰撞
	_tile_set.add_source(src, 0)
	for i in TILES.size():
		var coords := Vector2i(i, 0)
		src.create_tile(coords)
		if COLLIDERS.has(i):
			var half := Vector2(TILE, TILE) / 2.0
			var col = COLLIDERS[i]
			var w: float = half.x
			var h: float = half.y
			if col is Vector2:
				w = col.x / 2.0
				h = col.y / 2.0
			var pts := PackedVector2Array([
				Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h),
			])
			var td: TileData = src.get_tile_data(coords, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, pts)


func _ensure_around(pos: Vector2) -> void:
	var cc := Vector2i(
		int(floor(pos.x / float(CHUNK_PX))),
		int(floor(pos.y / float(CHUNK_PX)))
	)
	for x in range(cc.x - KEEP_RADIUS, cc.x + KEEP_RADIUS + 1):
		for y in range(cc.y - KEEP_RADIUS, cc.y + KEEP_RADIUS + 1):
			var key := Vector2i(x, y)
			if not _chunks.has(key):
				_chunks[key] = _make_chunk(key)
	for key in _chunks.keys():
		if maxi(absi(key.x - cc.x), absi(key.y - cc.y)) > FREE_RADIUS:
			_chunks[key].queue_free()
			_chunks.erase(key)


func _make_chunk(coords: Vector2i) -> TileMapLayer:
	var rng := RandomNumberGenerator.new()
	rng.seed = (coords.x * 73856093) ^ (coords.y * 19349663) ^ _world_seed
	# 出生点在 (0,0)，正好是四块的交角——这四块强制用开阔模板，保证出生无遮挡
	var tmpl_id := 0
	if not ((coords.x == 0 or coords.x == -1) and (coords.y == 0 or coords.y == -1)):
		tmpl_id = rng.randi_range(0, TEMPLATES.size() - 1)
	var rot := rng.randi_range(0, 3)
	var mirror := rng.randf() < 0.5

	var layer := TileMapLayer.new()
	layer.tile_set = _tile_set
	add_child(layer)
	layer.position = Vector2(coords.x * CHUNK_PX, coords.y * CHUNK_PX)

	var n := CHUNK_TILES
	for sy in n:
		var row: String = TEMPLATES[tmpl_id][sy]
		for sx in n:
			var ch: String = row[sx]
			if ch == ".":
				continue
			var mx := sx
			if mirror:
				mx = n - 1 - sx
			var dest := Vector2i(mx, sy)
			match rot:
				1:
					dest = Vector2i(sy, n - 1 - mx)
				2:
					dest = Vector2i(n - 1 - mx, n - 1 - sy)
				3:
					dest = Vector2i(n - 1 - sy, mx)
			layer.set_cell(dest, 0, Vector2i(TILES[ch], 0))
	return layer
