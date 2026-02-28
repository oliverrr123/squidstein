@tool
extends Node2D

@onready var cam: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Cell/Player
@onready var other_guy: Sprite2D = $Hall/OtherGuy
@onready var cell_tiles: TileMapLayer = $Cell/TileMap
@onready var hall_tiles: TileMapLayer = $Hall/TileMap
@onready var hallway_tiles: TileMapLayer = $Hallway/TileMap
@onready var cell_walls: StaticBody2D = $Cell/Walls
@onready var hall_walls: StaticBody2D = $Hall/Walls
@onready var hallway_walls: StaticBody2D = $Hallway/Walls

@export var tile_size := 96
@export var room_size := Vector2i(24, 14)
@export var door_row := 7
@export var hallway_tiles_wide := 6
@export var hall_offset := Vector2.ZERO

var room_a_center := Vector2.ZERO

func _ready() -> void:
	# Build the blockout in both editor and runtime so layout is visible while editing.
	var tileset := _create_placeholder_tileset()
	cell_tiles.tile_set = tileset
	hall_tiles.tile_set = tileset
	hallway_tiles.tile_set = tileset

	_build_room(cell_tiles, true, true)
	_build_room(hall_tiles, false, true)
	_build_hallway(hallway_tiles)

	var room_w := float(room_size.x * tile_size)
	var hall_w := float(hallway_tiles_wide * tile_size)
	hall_offset = Vector2(room_w + hall_w, 0)
	var hallway_offset := Vector2(room_w, 0)
	hall_tiles.position = hall_offset
	hallway_tiles.position = hallway_offset
	hall_walls.position = hall_offset
	hallway_walls.position = hallway_offset

	_build_room_colliders(cell_walls, true, true)
	_build_room_colliders(hall_walls, false, true)
	_build_hallway_colliders(hallway_walls)

	var room_px := Vector2(room_size.x * tile_size, room_size.y * tile_size)
	room_a_center = room_px / 2.0
	var room_b_center := hall_offset + room_px / 2.0
	player.global_position = room_a_center + Vector2(-tile_size * 3.0, 0)
	other_guy.global_position = room_b_center + Vector2(tile_size * 3.0, 0)
	other_guy.flip_h = true
	cam.global_position = player.global_position

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	cam.global_position = player.global_position

func _create_placeholder_tileset() -> TileSet:
	var img := Image.create(tile_size * 3, tile_size, false, Image.FORMAT_RGBA8)
	# Floor, wall, and door are intentionally high-contrast for blockout readability.
	img.fill(Color(0.34, 0.34, 0.36, 1.0))
	img.fill_rect(Rect2i(tile_size, 0, tile_size, tile_size), Color(0.07, 0.08, 0.12, 1.0))
	img.fill_rect(Rect2i(tile_size * 2, 0, tile_size, tile_size), Color(0.86, 0.67, 0.15, 1.0))

	var tex := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))
	source.create_tile(Vector2i(2, 0))

	var tileset := TileSet.new()
	tileset.add_source(source, 0)
	return tileset

func _build_room(tilemap: TileMapLayer, door_on_right: bool, has_door: bool) -> void:
	tilemap.clear()
	for y in range(room_size.y):
		for x in range(room_size.x):
			var border := x == 0 or y == 0 or x == room_size.x - 1 or y == room_size.y - 1
			var door_here := false
			if has_door and y == door_row:
				door_here = (door_on_right and x == room_size.x - 1) or (not door_on_right and x == 0)

			var atlas := Vector2i(0, 0)
			if border:
				atlas = Vector2i(1, 0)
			if door_here:
				atlas = Vector2i(2, 0)

			tilemap.set_cell(Vector2i(x, y), 0, atlas, 0)

func _build_hallway(tilemap: TileMapLayer) -> void:
	tilemap.clear()
	for y in range(room_size.y):
		for x in range(hallway_tiles_wide):
			var border := y == 0 or y == room_size.y - 1
			var atlas := Vector2i(0, 0)
			if border:
				atlas = Vector2i(1, 0)
			tilemap.set_cell(Vector2i(x, y), 0, atlas, 0)

func _build_room_colliders(body: StaticBody2D, door_on_right: bool, has_door: bool) -> void:
	for child in body.get_children():
		child.queue_free()

	var room_w := float(room_size.x * tile_size)
	var room_h := float(room_size.y * tile_size)
	var t := float(tile_size)

	_add_collider(body, Vector2(room_w / 2.0, t / 2.0), Vector2(room_w, t))
	_add_collider(body, Vector2(room_w / 2.0, room_h - t / 2.0), Vector2(room_w, t))

	if not has_door:
		_add_collider(body, Vector2(t / 2.0, room_h / 2.0), Vector2(t, room_h))
		_add_collider(body, Vector2(room_w - t / 2.0, room_h / 2.0), Vector2(t, room_h))
		return

	var door_center_y := (float(door_row) + 0.5) * t
	var gap := t
	var upper_h := door_center_y - gap / 2.0
	var lower_h := room_h - (door_center_y + gap / 2.0)

	if door_on_right:
		_add_collider(body, Vector2(t / 2.0, room_h / 2.0), Vector2(t, room_h))
		if upper_h > 0:
			_add_collider(body, Vector2(room_w - t / 2.0, upper_h / 2.0), Vector2(t, upper_h))
		if lower_h > 0:
			_add_collider(body, Vector2(room_w - t / 2.0, room_h - lower_h / 2.0), Vector2(t, lower_h))
	else:
		_add_collider(body, Vector2(room_w - t / 2.0, room_h / 2.0), Vector2(t, room_h))
		if upper_h > 0:
			_add_collider(body, Vector2(t / 2.0, upper_h / 2.0), Vector2(t, upper_h))
		if lower_h > 0:
			_add_collider(body, Vector2(t / 2.0, room_h - lower_h / 2.0), Vector2(t, lower_h))

func _add_collider(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	parent.add_child(collision)

func _build_hallway_colliders(body: StaticBody2D) -> void:
	for child in body.get_children():
		child.queue_free()

	var t := float(tile_size)
	var width := float(hallway_tiles_wide * tile_size)
	var room_h := float(room_size.y * tile_size)

	_add_collider(body, Vector2(width / 2.0, t / 2.0), Vector2(width, t))
	_add_collider(body, Vector2(width / 2.0, room_h - t / 2.0), Vector2(width, t))
