extends CharacterBody2D

@export var speed := 750.0
@onready var visual: AnimatedSprite2D = $PlaceholderCube

const DEFAULT_PACK_ROOT := "res://Created_a_guy_with_a_torn_white_tank_top_red_short"
const DISGUISE_PACK_ROOT := "res://Doc"

var default_frames: SpriteFrames
var disguise_frames: SpriteFrames
var using_disguise := false
var facing := "south"

func _ready() -> void:
	default_frames = _build_default_frames()
	disguise_frames = _build_pack_frames(DISGUISE_PACK_ROOT)
	set_default_visual()

func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	velocity = dir * speed
	move_and_slide()
	global_position = global_position.round()
	_update_visual(dir)

func set_default_visual() -> void:
	using_disguise = false
	if visual == null:
		return
	visual.sprite_frames = default_frames
	visual.modulate = Color(1, 1, 1, 1)
	visual.play("idle_south")
	visual.stop()
	facing = "south"

func set_disguise_visual() -> void:
	using_disguise = true
	if visual == null:
		return
	visual.sprite_frames = disguise_frames
	visual.modulate = Color(1, 1, 1, 1)
	visual.play("idle_south")
	visual.stop()
	facing = "south"

func _update_visual(dir: Vector2) -> void:
	if visual == null:
		return
	if dir.length_squared() <= 0.0001:
		visual.play("idle_%s" % facing)
		visual.stop()
		return

	if absf(dir.x) > absf(dir.y):
		facing = "east" if dir.x > 0.0 else "west"
	else:
		facing = "south" if dir.y > 0.0 else "north"
	visual.play("walk_%s" % facing)

func _build_default_frames() -> SpriteFrames:
	return _build_pack_frames(DEFAULT_PACK_ROOT)

func _build_pack_frames(pack_root: String) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle_south")
	frames.add_animation("idle_north")
	frames.add_animation("idle_east")
	frames.add_animation("idle_west")
	frames.add_animation("walk_south")
	frames.add_animation("walk_north")
	frames.add_animation("walk_east")
	frames.add_animation("walk_west")

	for anim in ["idle_south", "idle_north", "idle_east", "idle_west"]:
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 1.0)
	for anim in ["walk_south", "walk_north", "walk_east", "walk_west"]:
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 10.0)

	_add_single_frame(frames, "idle_south", "%s/rotations/south.png" % pack_root)
	_add_single_frame(frames, "idle_north", "%s/rotations/north.png" % pack_root)
	_add_single_frame(frames, "idle_east", "%s/rotations/east.png" % pack_root)
	_add_single_frame(frames, "idle_west", "%s/rotations/west.png" % pack_root)

	_add_walk_frames(frames, "walk_south", "%s/animations/walk/south" % pack_root)
	_add_walk_frames(frames, "walk_north", "%s/animations/walk/north" % pack_root)
	_add_walk_frames(frames, "walk_east", "%s/animations/walk/east" % pack_root)
	_add_walk_frames(frames, "walk_west", "%s/animations/walk/west" % pack_root)
	return frames

func _add_single_frame(frames: SpriteFrames, animation: String, path: String) -> void:
	var tex := load(path)
	if tex is Texture2D:
		frames.add_frame(animation, tex)

func _add_walk_frames(frames: SpriteFrames, animation: String, dir_path: String) -> void:
	for i in range(6):
		var tex := load("%s/frame_%03d.png" % [dir_path, i])
		if tex is Texture2D:
			frames.add_frame(animation, tex)
