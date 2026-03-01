extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var player_cube: CanvasItem = $Player/PlaceholderCube
@onready var trigger_area: Area2D = $StoryTrigger
@onready var guard: CharacterBody2D = $Guard
@onready var guard_cube: AnimatedSprite2D = $Guard/GuardCube
@onready var other_guy: Node2D = $OtherGuy
@onready var other_guy_cube: AnimatedSprite2D = $OtherGuy/OtherGuyCube
@onready var doctor: Node2D = $Doctor
@onready var doctor_cube: AnimatedSprite2D = $Doctor/DoctorCube
@onready var disguise_area: Area2D = $DoctorDisguiseArea
@onready var pre_surgery_door_lock: CollisionShape2D = $PreSurgeryDoorLock/CollisionShape2D
@onready var pre_surgery_door_lintel: CanvasItem = $Blockout/EndRoomToPreDoorLintel
@onready var dialogue_panel: Panel = $DialogueUI/Panel
@onready var dialogue_label: Label = $DialogueUI/Panel/DialogueText
@onready var dialogue_ui: CanvasLayer = $DialogueUI
@onready var cell_door_lock: CollisionShape2D = $CellDoorLock/CollisionShape2D
@onready var cell_door_lintel: CanvasItem = $Blockout/CellDoorLintel
@onready var hall_door_lintel: CanvasItem = $Blockout/HallDoorLintel
@onready var end_room_door_lintel: CanvasItem = $Blockout/EndRoomDoorLintel
@onready var music_player: AudioStreamPlayer = $Music
@onready var minigame_ui: CanvasLayer = $MinigameUI
@onready var struggle_label: Label = $MinigameUI/Panel/PromptLabel
@onready var hits_label: Label = $MinigameUI/Panel/HitsLabel
@onready var timing_line: ColorRect = $MinigameUI/Panel/TimingLine
@onready var target_zone: ColorRect = $MinigameUI/Panel/TimingLine/TargetZone
@onready var needle: ColorRect = $MinigameUI/Panel/TimingLine/Needle

@export var guard_speed := 300.0
@export var guard_escort_speed := 470.0
@export var npc_follow_speed := 240.0
@export var doctor_speed := 180.0
const GUARD_SPAWN_POSITION := Vector2(1360, -700)
const PLAYER_ESCORT_OFFSET := Vector2(90, 0)
const PLAYER_GRAB_DISTANCE := 110.0
const CELL_DOOR_TOUCH_DISTANCE := 70.0
const BED_POSITION := Vector2(4240, -5080)
const DOCTOR_TARGET_OFFSET := Vector2(0, 120)
const DOCTOR_BED_POSITION := BED_POSITION
const PLAYER_BED_SIDE_POSITION := BED_POSITION + Vector2(-130, 120)
const DOCTOR_START_POSITION := Vector2(4470, -5080)
const DOCTOR_DISGUISE_TEXTURE := preload("res://doc_guy.png")
const DOCTOR_FAINT_TEXTURE := preload("res://docsuitx.png")
const DOCTOR_LOOTED_TEXTURE := preload("res://docx.png")
const PLAYER_DEFAULT_TEXTURE := preload("res://guy.png")
const PLAYER_BED_TEXTURE := preload("res://Created_a_guy_with_a_torn_white_tank_top_red_short/rotations/south.png")
const DOCTOR_DEFAULT_TEXTURE := preload("res://doc.png")
const LOCK_ICON_TEXTURE := preload("res://lock.png")
const SUNBURST_TEXTURE := preload("res://sunburst.png")
const KIDNAPPER_PACK_ROOT := "res://Kidnapper"
const VICTIM_PACK_ROOT := "res://Victim"
const DOCTOR_PACK_ROOT := "res://Doc"
const PRE_SURGERY_UNLOCK_DISTANCE := 140.0
const KEY_USE_MAX := 11
const CUE_PICKUP_AMOUNT := 1
const KEY_IMAGE_BASE_NAMES := [
	"one",
	"two",
	"three",
	"four",
	"five",
	"six",
	"seven",
	"eight",
	"nine",
	"ten",
	"eleven",
]
const KEY_IMAGE_EXTENSIONS := ["png", "webp", "jpg", "jpeg"]
const CHECKPOINT_CELL_POSITION := Vector2(500, 400)
const CHECKPOINT_DOCTOR_POSITION := Vector2(3920, -4920)
const CHECKPOINT_PRE_SURGERY_POSITION := Vector2(5240, -5080)
const CHECKPOINT_STORAGE_POSITION := Vector2(520, -3920)
const CHECKPOINT_GALLERY_POSITION := Vector2(0, -5520)
const CUE_TWO_PICKUP_POSITION := Vector2(5520, -5080)
const CUE_THREE_PICKUP_POSITION := Vector2(4960, -5200) # Staff Room desk
const STORAGE_DOOR_POSITION := Vector2(1168, -3920) # Hallway wall gateway to storage area
const STORAGE_DOOR_INTERACT_HALF_WIDTH := 220.0
const STORAGE_DOOR_INTERACT_HALF_HEIGHT := 260.0
const STORAGE_CUE_FOUR_POSITION := Vector2(460, -4040)
const STORAGE_BOX_POSITION := Vector2(120, -3920)
const STORAGE_ELEVATOR_POSITION := Vector2(536, -3760)
const UPPER_ELEVATOR_POSITION := Vector2(0, -5040)
const CUE_FIVE_INVOICE_TEXT := "Invoice (Cue 5):\nFrom: Black Reef Cargo Node\nTo: Isla de Niebla Research Depot (unlisted island)\nConsignee: Nereid Bio-Logistics\nGoods: 12 sealed medical crates (human material)\n\nThis links the operation to an unknown island site."
const HALL_DOOR_POSITION := Vector2(1552, 400)
const END_ROOM_DOOR_POSITION := Vector2(3472, -4920)
const GALLERY_CLOCK_POSITION := Vector2(-560, -5580)
const GALLERY_BOOKSHELF_POSITION := Vector2(560, -5560)
const GALLERY_STATUE_POSITION := Vector2(0, -5420)
const CUE_SEVEN_STATUE_TEXT := "Cue 7 (Statue): Carved gallery statue fragment.\nIt appears ceremonial and tied to this facility's hidden leadership.\n\nLikely important for the upper-floor puzzle later."
const CUE_ELEVEN_CHARITY_TEXT := "Cue 11 (Charity Press File): Public reports show he funded a children's hospital charity campaign with large donations.\n\nLikely a PR shield to look untouchable while hiding what happens in this facility."
const GALLERY_CODE_REQUIRED := "2014"
const GALLERY_CODE_MAX_LEN := 4
const ROOM_CELL := Rect2(0, 0, 1200, 800)
const ROOM_HALLWAY := Rect2(1200, -5000, 320, 5800)
const ROOM_TURN1 := Rect2(1520, -3200, 1600, 320)
const ROOM_TURN_VERTICAL := Rect2(2800, -5000, 320, 2120)
const ROOM_TURN2 := Rect2(3120, -5000, 320, 320)
const ROOM_END := Rect2(3440, -5480, 1200, 800)
const ROOM_PRE := Rect2(4640, -5480, 1200, 800)
const ROOM_STORAGE := Rect2(-484, -4400, 1620, 960)
const ROOM_SECOND_FLOOR := Rect2(-980, -6200, 1960, 1360)

enum SequenceState {
	IDLE,
	DIALOGUE,
	GUARD_TO_GUY,
	ESCORT_OUT,
	WAIT_FOR_RETURN,
	GUARD_TO_PLAYER,
	ESCORT_PLAYER,
	PLAYER_ON_BED,
	GUARD_LEAVE_END_ROOM,
	DOCTOR_APPROACH,
	ANESTHESIA_SPAM,
	ANESTHESIA_MINIGAME,
	DOCTOR_SHOUT,
	FIGHT_WIN,
	PUT_DOCTOR_ON_BED,
	EPILOGUE,
	DONE,
}

var state := SequenceState.IDLE
var dialogue_lines: Array[String] = []
var dialogue_index := 0
const GUARD_START_DIALOGUE_INDEX := 1 # "Other Guy: ... kidnapped us ..."
var to_guy_path: Array[Vector2] = [
	Vector2(1360, 400),
	Vector2(1700, 400),
	Vector2(1800, 400),
]
var out_path: Array[Vector2] = [
	Vector2(1700, 400),
	Vector2(1360, 400),
	Vector2(1360, -1800),
]
var escort_player_path: Array[Vector2] = [
	Vector2(1360, 400),
	Vector2(1360, -3100),
	Vector2(2960, -3100),
	Vector2(2960, -4920),
	Vector2(3920, -4920),
]
var guard_leave_end_room_path: Array[Vector2] = [
	Vector2(3320, -4920),
]
var path_index := 0
var escorting := false
var guard_frames: SpriteFrames
var guard_facing := "south"
var other_guy_frames: SpriteFrames
var other_guy_facing := "south"
var doctor_frames: SpriteFrames
var doctor_facing := "south"
var return_delay_seconds := 5.0
var return_timer := 0.0
var guard_return_phase := 0
var timing_pos := 0.0
var timing_dir := 1.0
var timing_speed := 1.6
var target_center := 0.5
var target_width := 0.18
var required_hits := 5
var current_hits := 0
var shout_timer := 0.0
var shout_duration := 0.9
var fight_timer := 0.0
var fight_duration := 0.8
var player_in_disguise_area := false
var is_disguised := false
var guard_exit_running := false
var doctor_sequence_started := false
var doctor_approach_timer := 0.0
var anesthesia_started := false
var anesthesia_won := false
var anesthesia_elapsed := 0.0
var anesthesia_min_duration := 1.0
var spam_progress := 0.0
var spam_required := 20.8
var spam_decay_per_second := 4.8
var spam_press_gain := 1.0
var has_keycard := false
var key_uses := 0
var keycard_fx_timer := 0.0
var keycard_fx_duration := 3.0
var keycard_fx_active := false
var keycard_fx_intro_duration := 0.35
var keycard_fx_fade_duration := 0.45
var keycard_fx_spin_speed := 1.2
var keycard_fx_final_scale := 1.18
var keycard_fx_icon_final_scale := 1.08
var keycard_fx_layer: CanvasLayer
var keycard_fx_rect: TextureRect
var keycard_fx_label: Label
var keycard_fx_icon: TextureRect
var key_hud_icon: TextureRect
var key_hud_label: Label
var key_hud_fallback_textures: Array[Texture2D] = []
var cue_collected: Array[bool] = []
var cue_notes: Dictionary = {}
var latest_collected_cue_index := 0
var inventory_layer: CanvasLayer
var inventory_panel: Panel
var inventory_slots: Array[TextureRect] = []
var inventory_hover_panel: Panel
var inventory_hover_label: Label
var hovered_inventory_index := -1
var cue_two_pickup: Area2D
var cue_two_sprite: Sprite2D
var cue_two_in_range := false
var cue_three_pickup: Area2D
var cue_three_sprite: Sprite2D
var cue_three_in_range := false
var cue_four_pickup: Area2D
var cue_four_sprite: Sprite2D
var cue_four_in_range := false
var cue_seven_pickup: Area2D
var cue_seven_sprite: Sprite2D
var cue_seven_in_range := false
var cue_eleven_sprite: Sprite2D
var storage_box_area: Area2D
var storage_box_sprite: Sprite2D
var storage_box_in_range := false
var storage_elevator_area: Area2D
var storage_elevator_in_range := false
var upper_elevator_area: Area2D
var upper_elevator_in_range := false
var storage_door_blocker: StaticBody2D
var storage_door_sprite: Sprite2D
var gallery_code_door_blocker: StaticBody2D
var gallery_code_blocker_shape: CollisionShape2D
var gallery_code_lock_icon: Sprite2D
var gallery_code_unlocked := false
var gallery_code_entry_active := false
var gallery_code_buffer := ""
var cell_lock_icon: Sprite2D
var hall_lock_icon: Sprite2D
var end_room_lock_icon: Sprite2D
var pre_surgery_lock_icon: Sprite2D
var storage_lock_icon: Sprite2D
var visibility_fx_layer: CanvasLayer
var visibility_fx_rect: ColorRect
var room_vision_enabled := true
var current_room_index := -1
var pre_surgery_lock_default_layer := 0
var pre_surgery_lock_default_mask := 0
var hall_door_unlocked := false
var end_room_door_unlocked := false
var pre_surgery_unlocked := false
var storage_unlocked := false
var checkpoint_positions: Array[Vector2] = [
	CHECKPOINT_CELL_POSITION,
	CHECKPOINT_DOCTOR_POSITION,
	CHECKPOINT_PRE_SURGERY_POSITION,
	CHECKPOINT_STORAGE_POSITION,
	CHECKPOINT_GALLERY_POSITION,
]
var checkpoint_names: Array[String] = [
	"Cell",
	"Doctor Room",
	"Pre-Surgery Room",
	"Storage Wing",
	"Gallery",
]
var current_checkpoint_index := 0

func _ready() -> void:
	dialogue_ui.layer = 35
	minigame_ui.layer = 35
	dialogue_panel.visible = false
	minigame_ui.visible = false
	disguise_area.monitoring = false
	cue_collected.resize(KEY_USE_MAX)
	for i in range(KEY_USE_MAX):
		cue_collected[i] = false
	_setup_guard_visual()
	_setup_other_guy_visual()
	_setup_doctor_visual()
	_setup_keycard_fx_ui()
	_setup_key_hud_ui()
	_setup_inventory_ui()
	_setup_cue_two_pickup()
	_setup_cue_three_pickup()
	_setup_storage_door()
	_setup_cue_four_pickup()
	_setup_storage_box()
	_setup_elevator_points()
	_setup_gallery_code_door()
	_setup_visibility_fx()
	_setup_door_lock_icons()
	_refresh_door_lock_icons()
	_setup_gallery_interior()
	_setup_cue_seven_pickup()
	_setup_cue_eleven_pickup()
	var pre_lock_body := pre_surgery_door_lock.get_parent() as CollisionObject2D
	if pre_lock_body != null:
		pre_surgery_lock_default_layer = pre_lock_body.collision_layer
		pre_surgery_lock_default_mask = pre_lock_body.collision_mask
	#if music_player.stream is AudioStreamMP3:
		#(music_player.stream as AudioStreamMP3).loop = true
	#if not music_player.playing:
		#music_player.play()
	trigger_area.body_entered.connect(_on_story_trigger_body_entered)
	disguise_area.body_entered.connect(_on_disguise_area_body_entered)
	disguise_area.body_exited.connect(_on_disguise_area_body_exited)
	_restart_from_checkpoint(0)
	_update_visibility_fx()
	call_deferred("_refresh_visibility_next_frame")

func _refresh_visibility_next_frame() -> void:
	_update_visibility_fx()

func _physics_process(delta: float) -> void:
	_update_keycard_fx(delta)
	_update_inventory_visibility()
	_update_visibility_fx()
	_handle_checkpoint_cheat_input()
	match state:
		SequenceState.DIALOGUE:
			if Input.is_action_just_pressed("interact"):
				_advance_dialogue()
		SequenceState.GUARD_TO_GUY:
			if dialogue_panel.visible and Input.is_action_just_pressed("interact"):
				_advance_dialogue()
			_try_unlock_hall_door_on_guard_touch()
			var reached := _move_along_path(guard, to_guy_path, guard_speed, delta)
			if reached:
				escorting = true
				_show_pickup_line("You: What are they doing to you?")
				state = SequenceState.ESCORT_OUT
				path_index = 0
		SequenceState.ESCORT_OUT:
			if dialogue_panel.visible and Input.is_action_just_pressed("interact"):
				_advance_dialogue()
			var reached := _move_along_path(guard, out_path, guard_speed, delta)
			if escorting and other_guy.visible:
				var follow_target := guard.global_position + Vector2(90, 0)
				var previous_position := other_guy.global_position
				other_guy.global_position = other_guy.global_position.move_toward(follow_target, npc_follow_speed * delta)
				_update_other_guy_visual(other_guy.global_position - previous_position)
			if reached:
				_update_other_guy_visual(Vector2.ZERO)
				guard.visible = false
				other_guy.visible = false
				dialogue_panel.visible = false
				state = SequenceState.WAIT_FOR_RETURN
				return_timer = return_delay_seconds
		SequenceState.WAIT_FOR_RETURN:
			return_timer -= delta
			if return_timer <= 0.0:
				_start_guard_return_for_player()
		SequenceState.GUARD_TO_PLAYER:
			_try_unlock_cell_door_on_guard_touch()
			if guard_return_phase == 0:
				var reached_hall := _move_to_point(guard, Vector2(1360, 400), guard_escort_speed, delta)
				if reached_hall:
					guard_return_phase = 1
			else:
				var reached_player := _move_to_point(guard, player.global_position + PLAYER_ESCORT_OFFSET, guard_escort_speed, delta)
				if reached_player or guard.global_position.distance_to(player.global_position) < PLAYER_GRAB_DISTANCE:
					_start_escort_player()
		SequenceState.ESCORT_PLAYER:
			_try_unlock_end_room_door_on_guard_touch()
			var reached_dest := _move_along_path(guard, escort_player_path, guard_escort_speed, delta)
			# Hard-attach player to guard so pickup looks intentional.
			player.global_position = guard.global_position + PLAYER_ESCORT_OFFSET
			if reached_dest:
				player.global_position = BED_POSITION
				path_index = 0
				state = SequenceState.PLAYER_ON_BED
		SequenceState.PLAYER_ON_BED:
			player.global_position = BED_POSITION
			path_index = 0
			guard_exit_running = true
			doctor_sequence_started = false
			doctor_approach_timer = 0.0
			anesthesia_started = false
			anesthesia_won = false
			current_checkpoint_index = 1
			doctor.global_position = BED_POSITION + DOCTOR_TARGET_OFFSET
			_start_anesthesia_spam()
		SequenceState.GUARD_LEAVE_END_ROOM:
			player.global_position = BED_POSITION
			_update_guard_exit(delta)
			if not doctor_sequence_started and guard.global_position.x <= 3360.0:
				doctor_sequence_started = true
				state = SequenceState.DOCTOR_APPROACH
		SequenceState.DOCTOR_APPROACH:
			player.global_position = BED_POSITION
			_update_guard_exit(delta)
			doctor_approach_timer += delta
			var reached_doctor := _move_to_point(doctor, BED_POSITION + DOCTOR_TARGET_OFFSET, doctor_speed, delta)
			if not anesthesia_started and (reached_doctor or doctor_approach_timer >= 1.2):
				doctor.global_position = BED_POSITION + DOCTOR_TARGET_OFFSET
				_start_anesthesia_minigame()
		SequenceState.ANESTHESIA_MINIGAME:
			_update_guard_exit(delta)
			anesthesia_elapsed += delta
			var t := float(Time.get_ticks_msec()) / 1000.0
			var doctor_base := BED_POSITION + DOCTOR_TARGET_OFFSET
			player.global_position = BED_POSITION + Vector2(sin(t * 34.0) * 5.0, cos(t * 25.0) * 2.5)
			doctor.global_position = doctor_base + Vector2(sin(t * 31.0) * -3.0, cos(t * 28.0) * 2.0)
			_update_timing_marker(delta)
			if Input.is_action_just_pressed("interact"):
				_try_timing_hit()
		SequenceState.ANESTHESIA_SPAM:
			_update_guard_exit(delta)
			player.global_position = BED_POSITION
			doctor.global_position = BED_POSITION + DOCTOR_TARGET_OFFSET
			spam_progress -= spam_decay_per_second * delta
			if spam_progress < 0.0:
				_on_anesthesia_failed()
				return
			_refresh_spam_ui()
			if Input.is_action_just_pressed("interact"):
				spam_progress = minf(spam_required, spam_progress + spam_press_gain)
				_refresh_spam_ui()
				if spam_progress >= spam_required:
					_start_anesthesia_minigame()
		SequenceState.DOCTOR_SHOUT:
			player.global_position = BED_POSITION
			doctor.global_position = BED_POSITION + DOCTOR_TARGET_OFFSET
			shout_timer += delta
			if anesthesia_won and shout_timer >= shout_duration:
				dialogue_panel.visible = false
				fight_timer = 0.0
				state = SequenceState.FIGHT_WIN
		SequenceState.FIGHT_WIN:
			fight_timer += delta
			var k: float = minf(1.0, fight_timer / fight_duration)
			player.global_position = BED_POSITION.lerp(PLAYER_BED_SIDE_POSITION, k)
			doctor.global_position = (BED_POSITION + DOCTOR_TARGET_OFFSET).lerp(BED_POSITION + Vector2(120, 0), k)
			if fight_timer >= fight_duration:
				_set_doctor_default_visual()
				fight_timer = 0.0
				state = SequenceState.PUT_DOCTOR_ON_BED
		SequenceState.PUT_DOCTOR_ON_BED:
			player.global_position = PLAYER_BED_SIDE_POSITION
			doctor.global_position = doctor.global_position.move_toward(DOCTOR_BED_POSITION, doctor_speed * delta)
			if doctor.global_position.distance_to(DOCTOR_BED_POSITION) < 4.0:
				doctor.global_position = DOCTOR_BED_POSITION
				dialogue_panel.visible = false
				disguise_area.set_deferred("monitoring", true)
				player.set_physics_process(true)
				state = SequenceState.DONE
		SequenceState.EPILOGUE:
			if Input.is_action_just_pressed("interact"):
				dialogue_panel.visible = false
				state = SequenceState.DONE
		SequenceState.DONE:
			_handle_disguise_interaction()

func _unhandled_input(event: InputEvent) -> void:
	if not gallery_code_entry_active:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		gallery_code_entry_active = false
		gallery_code_buffer = ""
		dialogue_panel.visible = false
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_BACKSPACE:
		if gallery_code_buffer.length() > 0:
			gallery_code_buffer = gallery_code_buffer.substr(0, gallery_code_buffer.length() - 1)
		_refresh_gallery_code_prompt()
		get_viewport().set_input_as_handled()
		return
	if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		_submit_gallery_code()
		get_viewport().set_input_as_handled()
		return
	if key_event.unicode >= 48 and key_event.unicode <= 57 and gallery_code_buffer.length() < GALLERY_CODE_MAX_LEN:
		gallery_code_buffer += String.chr(key_event.unicode)
		_refresh_gallery_code_prompt()
		get_viewport().set_input_as_handled()

func _move_guard_toward(point: Vector2, speed: float, _delta: float) -> bool:
	var to_target := point - guard.global_position
	if to_target.length() < 2.0:
		guard.velocity = Vector2.ZERO
		guard.move_and_slide()
		_update_guard_visual(Vector2.ZERO)
		return true

	guard.velocity = to_target.normalized() * speed
	guard.move_and_slide()
	_update_guard_visual(guard.velocity)
	return guard.global_position.distance_to(point) < 8.0

func _setup_guard_visual() -> void:
	if guard_cube == null:
		return
	guard_frames = SpriteFrames.new()
	for anim in ["idle_south", "idle_north", "idle_east", "idle_west", "walk_south", "walk_north", "walk_east", "walk_west"]:
		guard_frames.add_animation(anim)
	for anim in ["idle_south", "idle_north", "idle_east", "idle_west"]:
		guard_frames.set_animation_loop(anim, true)
		guard_frames.set_animation_speed(anim, 1.0)
	for anim in ["walk_south", "walk_north", "walk_east", "walk_west"]:
		guard_frames.set_animation_loop(anim, true)
		guard_frames.set_animation_speed(anim, 10.0)

	_add_guard_single_frame("idle_south", "%s/rotations/south.png" % KIDNAPPER_PACK_ROOT)
	_add_guard_single_frame("idle_north", "%s/rotations/north.png" % KIDNAPPER_PACK_ROOT)
	_add_guard_single_frame("idle_east", "%s/rotations/east.png" % KIDNAPPER_PACK_ROOT)
	_add_guard_single_frame("idle_west", "%s/rotations/west.png" % KIDNAPPER_PACK_ROOT)
	_add_guard_walk_frames("walk_south", "%s/animations/walk/south" % KIDNAPPER_PACK_ROOT)
	_add_guard_walk_frames("walk_north", "%s/animations/walk/north" % KIDNAPPER_PACK_ROOT)
	_add_guard_walk_frames("walk_east", "%s/animations/walk/east" % KIDNAPPER_PACK_ROOT)
	_add_guard_walk_frames("walk_west", "%s/animations/walk/west" % KIDNAPPER_PACK_ROOT)

	guard_cube.sprite_frames = guard_frames
	guard_cube.play("idle_south")
	guard_cube.stop()

func _add_guard_single_frame(animation: String, path: String) -> void:
	var tex := load(path)
	if tex is Texture2D:
		guard_frames.add_frame(animation, tex)

func _add_guard_walk_frames(animation: String, dir_path: String) -> void:
	for i in range(6):
		var tex := load("%s/frame_%03d.png" % [dir_path, i])
		if tex is Texture2D:
			guard_frames.add_frame(animation, tex)

func _update_guard_visual(motion: Vector2) -> void:
	if guard_cube == null:
		return
	if motion.length_squared() <= 0.0001:
		guard_cube.play("idle_%s" % guard_facing)
		guard_cube.stop()
		return
	if absf(motion.x) > absf(motion.y):
		guard_facing = "east" if motion.x > 0.0 else "west"
	else:
		guard_facing = "south" if motion.y > 0.0 else "north"
	guard_cube.play("walk_%s" % guard_facing)

func _setup_other_guy_visual() -> void:
	if other_guy_cube == null:
		return
	other_guy_frames = SpriteFrames.new()
	for anim in ["idle_south", "idle_north", "idle_east", "idle_west", "walk_south", "walk_north", "walk_east", "walk_west"]:
		other_guy_frames.add_animation(anim)
	for anim in ["idle_south", "idle_north", "idle_east", "idle_west"]:
		other_guy_frames.set_animation_loop(anim, true)
		other_guy_frames.set_animation_speed(anim, 1.0)
	for anim in ["walk_south", "walk_north", "walk_east", "walk_west"]:
		other_guy_frames.set_animation_loop(anim, true)
		other_guy_frames.set_animation_speed(anim, 10.0)

	_add_other_guy_single_frame("idle_south", "%s/rotations/south.png" % VICTIM_PACK_ROOT)
	_add_other_guy_single_frame("idle_north", "%s/rotations/north.png" % VICTIM_PACK_ROOT)
	_add_other_guy_single_frame("idle_east", "%s/rotations/east.png" % VICTIM_PACK_ROOT)
	_add_other_guy_single_frame("idle_west", "%s/rotations/west.png" % VICTIM_PACK_ROOT)
	_add_other_guy_walk_frames("walk_south", "%s/animations/walk/south" % VICTIM_PACK_ROOT)
	_add_other_guy_walk_frames("walk_north", "%s/animations/walk/north" % VICTIM_PACK_ROOT)
	_add_other_guy_walk_frames("walk_east", "%s/animations/walk/east" % VICTIM_PACK_ROOT)
	_add_other_guy_walk_frames("walk_west", "%s/animations/walk/west" % VICTIM_PACK_ROOT)

	other_guy_cube.sprite_frames = other_guy_frames
	other_guy_cube.play("idle_south")
	other_guy_cube.stop()

func _add_other_guy_single_frame(animation: String, path: String) -> void:
	var tex := load(path)
	if tex is Texture2D:
		other_guy_frames.add_frame(animation, tex)

func _add_other_guy_walk_frames(animation: String, dir_path: String) -> void:
	for i in range(6):
		var tex := load("%s/frame_%03d.png" % [dir_path, i])
		if tex is Texture2D:
			other_guy_frames.add_frame(animation, tex)

func _update_other_guy_visual(motion: Vector2) -> void:
	if other_guy_cube == null:
		return
	if motion.length_squared() <= 0.0001:
		other_guy_cube.play("idle_%s" % other_guy_facing)
		other_guy_cube.stop()
		return
	if absf(motion.x) > absf(motion.y):
		other_guy_facing = "east" if motion.x > 0.0 else "west"
	else:
		other_guy_facing = "south" if motion.y > 0.0 else "north"
	other_guy_cube.play("walk_%s" % other_guy_facing)

func _setup_doctor_visual() -> void:
	if doctor_cube == null:
		return
	doctor_frames = SpriteFrames.new()
	for anim in ["idle_south", "idle_north", "idle_east", "idle_west", "walk_south", "walk_north", "walk_east", "walk_west"]:
		doctor_frames.add_animation(anim)
	for anim in ["idle_south", "idle_north", "idle_east", "idle_west"]:
		doctor_frames.set_animation_loop(anim, true)
		doctor_frames.set_animation_speed(anim, 1.0)
	for anim in ["walk_south", "walk_north", "walk_east", "walk_west"]:
		doctor_frames.set_animation_loop(anim, true)
		doctor_frames.set_animation_speed(anim, 10.0)

	_add_doctor_single_frame("idle_south", "%s/rotations/south.png" % DOCTOR_PACK_ROOT)
	_add_doctor_single_frame("idle_north", "%s/rotations/north.png" % DOCTOR_PACK_ROOT)
	_add_doctor_single_frame("idle_east", "%s/rotations/east.png" % DOCTOR_PACK_ROOT)
	_add_doctor_single_frame("idle_west", "%s/rotations/west.png" % DOCTOR_PACK_ROOT)
	_add_doctor_walk_frames("walk_south", "%s/animations/walk/south" % DOCTOR_PACK_ROOT)
	_add_doctor_walk_frames("walk_north", "%s/animations/walk/north" % DOCTOR_PACK_ROOT)
	_add_doctor_walk_frames("walk_east", "%s/animations/walk/east" % DOCTOR_PACK_ROOT)
	_add_doctor_walk_frames("walk_west", "%s/animations/walk/west" % DOCTOR_PACK_ROOT)

	_set_doctor_default_visual()

func _add_doctor_single_frame(animation: String, path: String) -> void:
	var tex := load(path)
	if tex is Texture2D:
		doctor_frames.add_frame(animation, tex)

func _add_doctor_walk_frames(animation: String, dir_path: String) -> void:
	for i in range(6):
		var tex := load("%s/frame_%03d.png" % [dir_path, i])
		if tex is Texture2D:
			doctor_frames.add_frame(animation, tex)

func _set_doctor_default_visual() -> void:
	if doctor_cube == null:
		return
	doctor_cube.sprite_frames = doctor_frames
	doctor_cube.modulate = Color(1, 1, 1, 1)
	doctor_cube.play("idle_south")
	doctor_cube.stop()
	doctor_facing = "south"

func _set_doctor_texture_visual(texture: Texture2D) -> void:
	if doctor_cube == null:
		return
	var frames := SpriteFrames.new()
	frames.add_animation("idle_south")
	frames.set_animation_loop("idle_south", true)
	frames.set_animation_speed("idle_south", 1.0)
	frames.add_frame("idle_south", texture)
	doctor_cube.sprite_frames = frames
	doctor_cube.modulate = Color(1, 1, 1, 1)
	doctor_cube.play("idle_south")
	doctor_cube.stop()

func _update_doctor_visual(motion: Vector2) -> void:
	if doctor_cube == null:
		return
	if doctor_cube.sprite_frames != doctor_frames:
		return
	if motion.length_squared() <= 0.0001:
		doctor_cube.play("idle_%s" % doctor_facing)
		doctor_cube.stop()
		return
	if absf(motion.x) > absf(motion.y):
		doctor_facing = "east" if motion.x > 0.0 else "west"
	else:
		doctor_facing = "south" if motion.y > 0.0 else "north"
	doctor_cube.play("walk_%s" % doctor_facing)

func _move_to_point(actor: Node2D, point: Vector2, speed: float, delta: float) -> bool:
	if actor == guard:
		return _move_guard_toward(point, speed, delta)

	var previous_position := actor.global_position
	actor.global_position = actor.global_position.move_toward(point, speed * delta)
	if actor == doctor:
		_update_doctor_visual(actor.global_position - previous_position)
	return actor.global_position.distance_to(point) < 2.0

func _move_along_path(actor: Node2D, points: Array[Vector2], speed: float, delta: float) -> bool:
	if path_index >= points.size():
		return true

	var target := points[path_index]
	var reached := _move_to_point(actor, target, speed, delta)
	if reached:
		path_index += 1

	return path_index >= points.size()

func _on_story_trigger_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if state != SequenceState.IDLE:
		return

	trigger_area.set_deferred("monitoring", false)
	player.set_physics_process(false)
	_start_dialogue([
		"You: What the hell is going on?",
		"Other Guy: GubaBuba kidnapped us. He's stealing and covering it up.",
		"You: That's impossible. I thought he was a good guy.",
	])

func _start_dialogue(lines: Array[String]) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	state = SequenceState.DIALOGUE
	dialogue_panel.visible = true
	dialogue_label.text = "%s\n\n[Press E]" % dialogue_lines[dialogue_index]

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		dialogue_label.text = "%s\n\n[Press E]" % dialogue_lines[dialogue_index]
		if dialogue_index == GUARD_START_DIALOGUE_INDEX:
			_start_guard_sequence()
		return

	dialogue_panel.visible = false
	player.set_physics_process(true)
	if state == SequenceState.DIALOGUE:
		room_vision_enabled = true
		state = SequenceState.DONE

func _start_guard_sequence() -> void:
	player.set_physics_process(true)
	state = SequenceState.GUARD_TO_GUY
	path_index = 0
	guard.visible = true
	guard.global_position = GUARD_SPAWN_POSITION

func _show_epilogue(line: String) -> void:
	dialogue_panel.visible = true
	dialogue_label.text = "%s\n\n[Press E]" % line
	state = SequenceState.EPILOGUE

func _show_pickup_line(line: String) -> void:
	dialogue_panel.visible = true
	dialogue_label.text = line

func _start_guard_return_for_player() -> void:
	guard.visible = true
	guard.global_position = GUARD_SPAWN_POSITION
	guard_return_phase = 0
	state = SequenceState.GUARD_TO_PLAYER

func _start_escort_player() -> void:
	player.set_physics_process(false)
	player.global_position = guard.global_position + PLAYER_ESCORT_OFFSET
	path_index = 0
	state = SequenceState.ESCORT_PLAYER

func _try_unlock_cell_door_on_guard_touch() -> void:
	if cell_door_lock.disabled:
		return
	if guard.global_position.distance_to(cell_door_lock.global_position) <= CELL_DOOR_TOUCH_DISTANCE:
		cell_door_lock.disabled = true
		if cell_lock_icon != null:
			cell_lock_icon.visible = false
		if cell_door_lintel != null:
			cell_door_lintel.visible = false

func _try_unlock_hall_door_on_guard_touch() -> void:
	if hall_door_unlocked:
		return
	if guard.global_position.distance_to(HALL_DOOR_POSITION) <= CELL_DOOR_TOUCH_DISTANCE:
		hall_door_unlocked = true
		if hall_lock_icon != null:
			hall_lock_icon.visible = false
		if hall_door_lintel != null:
			hall_door_lintel.visible = false

func _try_unlock_end_room_door_on_guard_touch() -> void:
	if end_room_door_unlocked:
		return
	if guard.global_position.distance_to(END_ROOM_DOOR_POSITION) <= CELL_DOOR_TOUCH_DISTANCE:
		end_room_door_unlocked = true
		if end_room_lock_icon != null:
			end_room_lock_icon.visible = false
		if end_room_door_lintel != null:
			end_room_door_lintel.visible = false

func _start_anesthesia_minigame() -> void:
	anesthesia_started = true
	anesthesia_won = false
	anesthesia_elapsed = 0.0
	timing_pos = 0.0
	timing_dir = 1.0
	current_hits = 0
	target_width = 0.18
	_pick_new_target()
	_refresh_hits_label()
	_update_timing_ui()
	timing_line.visible = true
	target_zone.visible = true
	needle.visible = true
	struggle_label.text = "Fight: Press E when marker hits the green zone"
	minigame_ui.visible = true
	state = SequenceState.ANESTHESIA_MINIGAME

func _start_anesthesia_spam() -> void:
	spam_progress = spam_required * 0.5
	timing_line.visible = true
	target_zone.visible = true
	needle.visible = false
	struggle_label.text = "Resist anesthesia: mash E"
	minigame_ui.visible = true
	_refresh_spam_ui()
	state = SequenceState.ANESTHESIA_SPAM

func _update_timing_marker(delta: float) -> void:
	timing_pos += timing_dir * timing_speed * delta
	if timing_pos >= 1.0:
		timing_pos = 1.0
		timing_dir = -1.0
	elif timing_pos <= 0.0:
		timing_pos = 0.0
		timing_dir = 1.0

	_update_timing_ui()

func _try_timing_hit() -> void:
	if anesthesia_elapsed < anesthesia_min_duration:
		return

	var half: float = target_width * 0.5
	var in_zone: bool = absf(timing_pos - target_center) <= half
	if in_zone:
		current_hits += 1
		_refresh_hits_label()
		if current_hits >= required_hits:
			minigame_ui.visible = false
			anesthesia_won = true
			_show_pickup_line("Doctor: YO WHAT ARE YOU DOING?")
			shout_timer = 0.0
			state = SequenceState.DOCTOR_SHOUT
			return
		_pick_new_target()
		_update_timing_ui()
	else:
		current_hits = max(0, current_hits - 1)
		_refresh_hits_label()

func _pick_new_target() -> void:
	var half: float = target_width * 0.5
	target_center = randf_range(0.12 + half, 0.88 - half)

func _update_timing_ui() -> void:
	var width: float = timing_line.size.x
	var marker_x: float = timing_pos * width
	needle.position.x = marker_x - needle.size.x * 0.5
	target_zone.position.x = (target_center - target_width * 0.5) * width
	target_zone.size.x = target_width * width

func _refresh_hits_label() -> void:
	hits_label.text = "Resist: %d/%d" % [current_hits, required_hits]

func _refresh_spam_ui() -> void:
	hits_label.text = "Resist: %d%%" % int(round((spam_progress / spam_required) * 100.0))
	_update_spam_bar_ui()

func _update_spam_bar_ui() -> void:
	var ratio: float = clampf(spam_progress / spam_required, 0.0, 1.0)
	var width: float = timing_line.size.x
	target_zone.position.x = 0.0
	target_zone.size.x = width * ratio
	target_zone.color = Color(0.2 + ratio * 0.2, 0.25 + ratio * 0.6, 0.3, 1.0)

func _update_guard_exit(delta: float) -> void:
	if not guard_exit_running:
		return
	var reached_exit := _move_along_path(guard, guard_leave_end_room_path, guard_speed, delta)
	if reached_exit:
		guard_exit_running = false
		guard.visible = false

func _on_disguise_area_body_entered(body: Node2D) -> void:
	if body != player or state != SequenceState.DONE or is_disguised:
		return
	player_in_disguise_area = true
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to wear doctor clothes."

func _on_disguise_area_body_exited(body: Node2D) -> void:
	if body != player:
		return
	player_in_disguise_area = false
	if not is_disguised:
		dialogue_panel.visible = false

func _handle_disguise_interaction() -> void:
	if _handle_gallery_code_lock_interaction():
		return
	if _handle_cue_two_interaction():
		return
	if _handle_cue_three_interaction():
		return
	if _handle_storage_door_interaction():
		return
	if _handle_storage_elevator_interaction():
		return
	if _handle_upper_elevator_interaction():
		return
	if _handle_cue_four_interaction():
		return
	if _handle_storage_box_interaction():
		return
	if _handle_cue_seven_interaction():
		return
	if _handle_cue_eleven_interaction():
		return

	if not is_disguised and player_in_disguise_area:
		if Input.is_action_just_pressed("interact"):
			_wear_doctor_clothes()
		return

	if has_keycard and not pre_surgery_door_lock.disabled:
		var near_door := player.global_position.distance_to(pre_surgery_door_lock.global_position) <= PRE_SURGERY_UNLOCK_DISTANCE
		if near_door:
			dialogue_panel.visible = true
			dialogue_label.text = "Press E to use Doctor ID (Cue 1) on pre-surgery room."
			if Input.is_action_just_pressed("interact"):
				if _consume_key_use():
					_unlock_pre_surgery_door()
					dialogue_label.text = "Doctor ID accepted. Door unlocked.\n\n[Press E]"
				else:
					dialogue_label.text = "No cue left.\n\n[Press E]"
			return

	if is_disguised and dialogue_panel.visible and Input.is_action_just_pressed("interact"):
		dialogue_panel.visible = false
		return

	if dialogue_panel.visible and not gallery_code_entry_active and Input.is_action_just_pressed("interact"):
		dialogue_panel.visible = false

func _setup_gallery_code_door() -> void:
	gallery_code_door_blocker = get_node_or_null("SecondFloor/GalleryCodeDoorBlocker") as StaticBody2D
	gallery_code_blocker_shape = get_node_or_null("SecondFloor/GalleryCodeDoorBlocker/CollisionShape2D") as CollisionShape2D
	gallery_code_lock_icon = get_node_or_null("SecondFloor/GalleryCodeLockIcon") as Sprite2D
	_update_gallery_code_door()

func _update_gallery_code_door() -> void:
	if gallery_code_door_blocker != null:
		gallery_code_door_blocker.collision_layer = 0 if gallery_code_unlocked else 1
		gallery_code_door_blocker.collision_mask = 0 if gallery_code_unlocked else 1
	if gallery_code_blocker_shape != null:
		gallery_code_blocker_shape.set_deferred("disabled", gallery_code_unlocked)
	if gallery_code_lock_icon != null:
		gallery_code_lock_icon.visible = not gallery_code_unlocked

func _handle_gallery_code_lock_interaction() -> bool:
	if gallery_code_unlocked:
		return false
	var lock_pos := Vector2(-150, -6076)
	if gallery_code_lock_icon != null:
		lock_pos = gallery_code_lock_icon.global_position
	var near_lock := player.global_position.distance_to(lock_pos) <= 150.0
	if gallery_code_entry_active:
		_refresh_gallery_code_prompt()
		return true
	if not near_lock:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to enter gallery door code."
	if Input.is_action_just_pressed("interact"):
		gallery_code_entry_active = true
		gallery_code_buffer = ""
		_refresh_gallery_code_prompt()
	return true

func _refresh_gallery_code_prompt() -> void:
	dialogue_panel.visible = true
	var suffix := "_" if gallery_code_buffer.length() < GALLERY_CODE_MAX_LEN else ""
	dialogue_label.text = "Enter code: %s%s\n[Enter=confirm, Backspace, Esc]" % [gallery_code_buffer, suffix]

func _submit_gallery_code() -> void:
	if gallery_code_buffer == GALLERY_CODE_REQUIRED:
		gallery_code_unlocked = true
		gallery_code_entry_active = false
		gallery_code_buffer = ""
		_update_gallery_code_door()
		dialogue_panel.visible = true
		dialogue_label.text = "Code accepted. Door unlocked.\n\n[Press E]"
		return
	gallery_code_buffer = ""
	dialogue_panel.visible = true
	dialogue_label.text = "Wrong code.\n\nPress E to try again."

func _wear_doctor_clothes() -> void:
	is_disguised = true
	has_keycard = true
	key_uses = CUE_PICKUP_AMOUNT
	_set_cue_collected(1, true)
	_refresh_key_hud()
	player_in_disguise_area = false
	disguise_area.set_deferred("monitoring", false)
	player.set_disguise_visual()
	_set_doctor_texture_visual(PLAYER_BED_TEXTURE)
	_show_keycard_fx_for_cue(1)
	dialogue_panel.visible = false

func _setup_keycard_fx_ui() -> void:
	keycard_fx_layer = CanvasLayer.new()
	keycard_fx_layer.layer = 20
	add_child(keycard_fx_layer)

	keycard_fx_rect = TextureRect.new()
	keycard_fx_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	keycard_fx_rect.visible = false
	keycard_fx_rect.texture = SUNBURST_TEXTURE
	keycard_fx_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	keycard_fx_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	keycard_fx_rect.modulate = Color(1, 1, 1, 0.9)
	keycard_fx_layer.add_child(keycard_fx_rect)

	keycard_fx_label = Label.new()
	keycard_fx_label.text = ""
	keycard_fx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycard_fx_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycard_fx_label.set("theme_override_font_sizes/font_size", 52)
	keycard_fx_label.modulate = Color(1, 1, 1, 1)
	keycard_fx_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	keycard_fx_label.position = Vector2(-420, -40)
	keycard_fx_label.size = Vector2(840, 80)
	keycard_fx_label.visible = false
	keycard_fx_layer.add_child(keycard_fx_label)

	keycard_fx_icon = TextureRect.new()
	keycard_fx_icon.custom_minimum_size = Vector2(280, 280)
	keycard_fx_icon.size = Vector2(280, 280)
	keycard_fx_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	keycard_fx_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	keycard_fx_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	keycard_fx_icon.position = Vector2(-140, -140)
	keycard_fx_icon.visible = false
	keycard_fx_layer.add_child(keycard_fx_icon)

func _show_keycard_fx_for_cue(index_1_based: int) -> void:
	keycard_fx_active = true
	keycard_fx_timer = 0.0
	keycard_fx_rect.visible = true
	keycard_fx_label.visible = false
	keycard_fx_rect.rotation = 0.0
	keycard_fx_rect.scale = Vector2.ZERO
	keycard_fx_rect.position = Vector2.ZERO
	keycard_fx_rect.pivot_offset = get_viewport_rect().size * 0.5
	if keycard_fx_icon != null:
		keycard_fx_icon.texture = _get_key_texture_for_uses(index_1_based)
		keycard_fx_icon.visible = true
		keycard_fx_icon.scale = Vector2.ZERO
		keycard_fx_icon.rotation = 0.0
		keycard_fx_icon.pivot_offset = keycard_fx_icon.size * 0.5

func _update_keycard_fx(delta: float) -> void:
	if not keycard_fx_active:
		return
	keycard_fx_timer += delta
	var intro_t: float = clampf(keycard_fx_timer / keycard_fx_intro_duration, 0.0, 1.0)
	var intro_ease: float = 1.0 - pow(1.0 - intro_t, 3.0)
	var fade_start: float = maxf(0.0, keycard_fx_duration - keycard_fx_fade_duration)
	var fade_t: float = clampf((keycard_fx_timer - fade_start) / keycard_fx_fade_duration, 0.0, 1.0)
	var fade_alpha: float = 1.0 - fade_t
	keycard_fx_rect.rotation += delta * keycard_fx_spin_speed
	keycard_fx_rect.scale = Vector2.ONE * lerpf(0.0, keycard_fx_final_scale, intro_ease)
	keycard_fx_rect.modulate.a = (0.72 + 0.12 * sin(keycard_fx_timer * 6.0)) * intro_ease * fade_alpha
	if keycard_fx_icon != null and keycard_fx_icon.visible:
		keycard_fx_icon.scale = Vector2.ONE * lerpf(0.0, keycard_fx_icon_final_scale, intro_ease)
		keycard_fx_icon.modulate.a = intro_ease * fade_alpha
	if keycard_fx_timer >= keycard_fx_duration:
		keycard_fx_active = false
		keycard_fx_rect.visible = false
		keycard_fx_label.visible = false
		if keycard_fx_icon != null:
			keycard_fx_icon.visible = false

func _unlock_pre_surgery_door() -> void:
	if pre_surgery_unlocked:
		return
	pre_surgery_unlocked = true
	current_checkpoint_index = 2
	pre_surgery_door_lock.disabled = true
	pre_surgery_door_lock.set_deferred("disabled", true)
	var lock_body := pre_surgery_door_lock.get_parent() as CollisionObject2D
	if lock_body != null:
		lock_body.collision_layer = 0
		lock_body.collision_mask = 0
	pre_surgery_door_lintel.visible = false
	if pre_surgery_lock_icon != null:
		pre_surgery_lock_icon.visible = false

func _lock_pre_surgery_door() -> void:
	pre_surgery_unlocked = false
	pre_surgery_door_lock.disabled = false
	pre_surgery_door_lock.set_deferred("disabled", false)
	var lock_body := pre_surgery_door_lock.get_parent() as CollisionObject2D
	if lock_body != null:
		lock_body.collision_layer = pre_surgery_lock_default_layer
		lock_body.collision_mask = pre_surgery_lock_default_mask
	pre_surgery_door_lintel.visible = false
	if pre_surgery_lock_icon != null:
		pre_surgery_lock_icon.visible = true

func _setup_key_hud_ui() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 30
	add_child(hud)

	var panel := Panel.new()
	panel.position = Vector2(22, 22)
	panel.size = Vector2(238, 84)
	hud.add_child(panel)

	key_hud_icon = TextureRect.new()
	key_hud_icon.position = Vector2(10, 10)
	key_hud_icon.size = Vector2(64, 64)
	key_hud_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key_hud_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(key_hud_icon)

	key_hud_label = Label.new()
	key_hud_label.position = Vector2(82, 10)
	key_hud_label.size = Vector2(146, 64)
	key_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_hud_label.text = "Cues: 0/11"
	panel.add_child(key_hud_label)

	for i in range(KEY_USE_MAX):
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.14, 0.14, 0.14, 0.92))
		var accent := Color(0.95, 0.82, 0.22, 1.0)
		for x in range(8, 56):
			img.set_pixel(x, 30, accent)
		for y in range(22, 38):
			img.set_pixel(8, y, accent)
			img.set_pixel(18, y, accent)
		key_hud_fallback_textures.append(ImageTexture.create_from_image(img))

	_refresh_key_hud()

func _setup_inventory_ui() -> void:
	inventory_layer = CanvasLayer.new()
	inventory_layer.layer = 40
	add_child(inventory_layer)

	inventory_panel = Panel.new()
	inventory_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	inventory_panel.offset_left = 220
	inventory_panel.offset_right = -220
	inventory_panel.offset_bottom = -14
	inventory_panel.offset_top = -88
	inventory_layer.add_child(inventory_panel)

	var row := HBoxContainer.new()
	row.position = Vector2(14, 12)
	row.size = Vector2(952, 50)
	row.add_theme_constant_override("separation", 8)
	inventory_panel.add_child(row)

	for i in range(KEY_USE_MAX):
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(48, 48)
		slot.size = Vector2(48, 48)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.mouse_entered.connect(_on_inventory_slot_mouse_entered.bind(i + 1))
		slot.mouse_exited.connect(_on_inventory_slot_mouse_exited)
		slot.modulate = Color(0.35, 0.35, 0.35, 0.85)
		row.add_child(slot)
		inventory_slots.append(slot)

	inventory_hover_panel = Panel.new()
	inventory_hover_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	inventory_hover_panel.offset_left = 120
	inventory_hover_panel.offset_right = -120
	inventory_hover_panel.offset_top = 70
	inventory_hover_panel.offset_bottom = 330
	inventory_hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tip_style := StyleBoxFlat.new()
	tip_style.bg_color = Color(0.04, 0.04, 0.06, 0.92)
	tip_style.border_color = Color(0.86, 0.67, 0.15, 0.9)
	tip_style.border_width_left = 2
	tip_style.border_width_top = 2
	tip_style.border_width_right = 2
	tip_style.border_width_bottom = 2
	tip_style.corner_radius_top_left = 10
	tip_style.corner_radius_top_right = 10
	tip_style.corner_radius_bottom_left = 10
	tip_style.corner_radius_bottom_right = 10
	inventory_hover_panel.add_theme_stylebox_override("panel", tip_style)
	inventory_hover_panel.visible = false
	inventory_layer.add_child(inventory_hover_panel)

	inventory_hover_label = Label.new()
	inventory_hover_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inventory_hover_label.offset_left = 22
	inventory_hover_label.offset_right = -22
	inventory_hover_label.offset_top = 16
	inventory_hover_label.offset_bottom = -16
	inventory_hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_hover_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_hover_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	inventory_hover_label.add_theme_font_size_override("font_size", 28)
	inventory_hover_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	inventory_hover_label.text = ""
	inventory_hover_panel.add_child(inventory_hover_label)

	_refresh_inventory_ui()
	_update_inventory_visibility()

func _update_inventory_visibility() -> void:
	if inventory_panel == null:
		return
	var show_hover := hovered_inventory_index > 0
	# Inventory should always remain visible above gameplay shadows.
	inventory_panel.visible = true
	if inventory_hover_panel != null:
		inventory_hover_panel.visible = show_hover

func _refresh_inventory_ui() -> void:
	for i in range(inventory_slots.size()):
		var slot := inventory_slots[i]
		if i < cue_collected.size() and cue_collected[i]:
			slot.texture = _get_key_texture_for_uses(i + 1)
			slot.modulate = Color(1, 1, 1, 1)
			slot.visible = true
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			slot.texture = null
			slot.visible = false
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hovered_inventory_index > 0:
		var idx := hovered_inventory_index - 1
		if idx < 0 or idx >= cue_collected.size() or not cue_collected[idx]:
			_on_inventory_slot_mouse_exited()

func _set_cue_collected(index_1_based: int, collected: bool) -> void:
	var idx := index_1_based - 1
	if idx < 0 or idx >= cue_collected.size():
		return
	cue_collected[idx] = collected
	if collected and not cue_notes.has(index_1_based):
		cue_notes[index_1_based] = _get_default_cue_note(index_1_based)
	if collected:
		latest_collected_cue_index = index_1_based
	elif latest_collected_cue_index == index_1_based:
		latest_collected_cue_index = 0
		for i in range(cue_collected.size() - 1, -1, -1):
			if cue_collected[i]:
				latest_collected_cue_index = i + 1
				break
	_refresh_inventory_ui()
	_refresh_key_hud()

func _on_inventory_slot_mouse_entered(index_1_based: int) -> void:
	var idx := index_1_based - 1
	if idx < 0 or idx >= cue_collected.size() or not cue_collected[idx]:
		return
	hovered_inventory_index = index_1_based
	_apply_inventory_hover_text(_get_cue_note(index_1_based))
	if inventory_hover_panel != null:
		inventory_hover_panel.visible = true

func _on_inventory_slot_mouse_exited() -> void:
	hovered_inventory_index = -1
	if inventory_hover_panel != null:
		inventory_hover_panel.visible = false

func _get_cue_note(index_1_based: int) -> String:
	if cue_notes.has(index_1_based):
		return String(cue_notes[index_1_based])
	return _get_default_cue_note(index_1_based)

func _get_default_cue_note(index_1_based: int) -> String:
	match index_1_based:
		1:
			return "Cue 1 (Doctor ID): Security ID taken from the doctor. Opens restricted hospital doors."
		2:
			return "Cue 2 (Staff Room Record): People are listed as 'material' with a price tag."
		3:
			return "Cue 3 (Blue Card): Access card used to unlock the storage door."
		4:
			return "Cue 4 (Crowbar): Tool used to force open sealed crates and boxes."
		5:
			return CUE_FIVE_INVOICE_TEXT
		7:
			return CUE_SEVEN_STATUE_TEXT
		11:
			return CUE_ELEVEN_CHARITY_TEXT
		_:
			return "Cue %d: Collected evidence." % index_1_based

func _apply_inventory_hover_text(text: String) -> void:
	if inventory_hover_label == null or inventory_hover_panel == null:
		return
	inventory_hover_label.text = text
	var line_count := text.count("\n") + 1
	var font_size := 32
	if line_count >= 7:
		font_size = 22
	elif line_count >= 5:
		font_size = 26
	inventory_hover_label.add_theme_font_size_override("font_size", font_size)
	var target_height := clampi(int(round(line_count * (font_size * 1.45) + 48.0)), 220, 520)
	inventory_hover_panel.offset_top = 70
	inventory_hover_panel.offset_bottom = 70 + target_height

func _get_collected_cue_count() -> int:
	var count := 0
	for i in range(cue_collected.size()):
		if cue_collected[i]:
			count += 1
	return count

func _setup_cue_two_pickup() -> void:
	cue_two_pickup = null
	cue_two_sprite = null
	cue_two_in_range = false
	_update_cue_two_visibility()

func _update_cue_two_visibility() -> void:
	var already_collected := cue_collected.size() > 1 and cue_collected[1]
	if cue_two_pickup != null:
		cue_two_pickup.monitoring = not already_collected
		cue_two_pickup.monitorable = not already_collected
	if cue_two_sprite != null:
		cue_two_sprite.visible = not already_collected
	if already_collected:
		cue_two_in_range = false

func _on_cue_two_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if cue_collected.size() > 1 and cue_collected[1]:
		return
	cue_two_in_range = true

func _on_cue_two_body_exited(body: Node2D) -> void:
	if body != player:
		return
	cue_two_in_range = false

func _handle_cue_two_interaction() -> bool:
	if cue_collected.size() <= 1 or cue_collected[1]:
		return false
	var near_cue := player.global_position.distance_to(CUE_TWO_PICKUP_POSITION) <= 80.0
	if not near_cue:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to pick up Cue 2."
	if Input.is_action_just_pressed("interact"):
		_set_cue_collected(2, true)
		_update_cue_two_visibility()
		_show_keycard_fx_for_cue(2)
		dialogue_panel.visible = true
		dialogue_label.text = "Evidence (Staff Room): People are recorded as 'material' with a price tag.\n\n[Press E]"
	return true

func _setup_cue_three_pickup() -> void:
	cue_three_pickup = null
	cue_three_sprite = null
	cue_three_in_range = false
	_update_cue_three_visibility()

func _update_cue_three_visibility() -> void:
	var already_collected := cue_collected.size() > 2 and cue_collected[2]
	if cue_three_pickup != null:
		cue_three_pickup.monitoring = not already_collected
		cue_three_pickup.monitorable = not already_collected
	if cue_three_sprite != null:
		cue_three_sprite.visible = not already_collected
	if already_collected:
		cue_three_in_range = false

func _on_cue_three_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if cue_collected.size() > 2 and cue_collected[2]:
		return
	cue_three_in_range = true

func _on_cue_three_body_exited(body: Node2D) -> void:
	if body != player:
		return
	cue_three_in_range = false

func _handle_cue_three_interaction() -> bool:
	if cue_collected.size() <= 2 or cue_collected[2]:
		return false
	var near_cue := player.global_position.distance_to(CUE_THREE_PICKUP_POSITION) <= 80.0
	if not near_cue:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to pick up Cue 3 (Blue Card)."
	if Input.is_action_just_pressed("interact"):
		_set_cue_collected(3, true)
		current_checkpoint_index = 3
		_update_cue_three_visibility()
		_show_keycard_fx_for_cue(3)
		dialogue_panel.visible = true
		dialogue_label.text = "Evidence: Blue access card found in Staff Room.\n\n[Press E]"
	return true

func _setup_storage_door() -> void:
	storage_door_blocker = StaticBody2D.new()
	storage_door_blocker.name = "StorageDoorBlocker"
	storage_door_blocker.global_position = STORAGE_DOOR_POSITION
	add_child(storage_door_blocker)

	var blocker_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 180)
	blocker_shape.shape = rect
	storage_door_blocker.add_child(blocker_shape)

	storage_door_sprite = Sprite2D.new()
	var img := Image.create(18, 90, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.22, 0.24, 0.95))
	for y in range(0, 90):
		img.set_pixel(4, y, Color(0.82, 0.68, 0.2, 1.0))
		img.set_pixel(13, y, Color(0.82, 0.68, 0.2, 1.0))
	storage_door_sprite.texture = ImageTexture.create_from_image(img)
	storage_door_sprite.z_index = 4
	storage_door_blocker.add_child(storage_door_sprite)
	_update_storage_door_visibility()

func _setup_door_lock_icons() -> void:
	var lock_texture := LOCK_ICON_TEXTURE

	cell_lock_icon = Sprite2D.new()
	cell_lock_icon.texture = lock_texture
	cell_lock_icon.position = cell_door_lock.global_position
	cell_lock_icon.scale = Vector2(0.126, 0.126)
	cell_lock_icon.z_index = 20
	add_child(cell_lock_icon)

	hall_lock_icon = Sprite2D.new()
	hall_lock_icon.texture = lock_texture
	hall_lock_icon.position = HALL_DOOR_POSITION
	hall_lock_icon.scale = Vector2(0.126, 0.126)
	hall_lock_icon.z_index = 20
	add_child(hall_lock_icon)

	end_room_lock_icon = Sprite2D.new()
	end_room_lock_icon.texture = lock_texture
	end_room_lock_icon.position = END_ROOM_DOOR_POSITION
	end_room_lock_icon.scale = Vector2(0.126, 0.126)
	end_room_lock_icon.z_index = 20
	add_child(end_room_lock_icon)

	pre_surgery_lock_icon = Sprite2D.new()
	pre_surgery_lock_icon.texture = lock_texture
	pre_surgery_lock_icon.position = pre_surgery_door_lock.global_position
	pre_surgery_lock_icon.scale = Vector2(0.126, 0.126)
	pre_surgery_lock_icon.z_index = 20
	add_child(pre_surgery_lock_icon)

	storage_lock_icon = Sprite2D.new()
	storage_lock_icon.texture = lock_texture
	storage_lock_icon.position = STORAGE_DOOR_POSITION
	storage_lock_icon.scale = Vector2(0.126, 0.126)
	storage_lock_icon.z_index = 20
	add_child(storage_lock_icon)

func _update_storage_door_visibility() -> void:
	if storage_door_blocker != null:
		storage_door_blocker.collision_layer = 1 if not storage_unlocked else 0
		storage_door_blocker.collision_mask = 1 if not storage_unlocked else 0
	if storage_door_sprite != null:
		storage_door_sprite.visible = false
	if storage_lock_icon != null:
		storage_lock_icon.visible = not storage_unlocked
	_update_cue_four_visibility()
	_update_storage_box_visibility()

func _refresh_door_lock_icons() -> void:
	if cell_lock_icon != null:
		cell_lock_icon.visible = not cell_door_lock.disabled
	if cell_door_lintel != null:
		cell_door_lintel.visible = not cell_door_lock.disabled
	if hall_lock_icon != null:
		hall_lock_icon.visible = not hall_door_unlocked
	if hall_door_lintel != null:
		hall_door_lintel.visible = not hall_door_unlocked
	if end_room_lock_icon != null:
		end_room_lock_icon.visible = not end_room_door_unlocked
	if end_room_door_lintel != null:
		end_room_door_lintel.visible = not end_room_door_unlocked
	if pre_surgery_lock_icon != null:
		pre_surgery_lock_icon.visible = not pre_surgery_unlocked
	if pre_surgery_door_lintel != null:
		pre_surgery_door_lintel.visible = not pre_surgery_unlocked
	if storage_lock_icon != null:
		storage_lock_icon.visible = not storage_unlocked

func _handle_storage_door_interaction() -> bool:
	if storage_unlocked:
		return false
	var to_door := player.global_position - STORAGE_DOOR_POSITION
	var near_door := absf(to_door.x) <= STORAGE_DOOR_INTERACT_HALF_WIDTH and absf(to_door.y) <= STORAGE_DOOR_INTERACT_HALF_HEIGHT
	if not near_door:
		return false
	dialogue_panel.visible = true
	if cue_collected.size() > 2 and cue_collected[2]:
		dialogue_label.text = "Press E to use Blue Card (Cue 3) on Storage door."
		if Input.is_action_just_pressed("interact"):
			storage_unlocked = true
			_update_storage_door_visibility()
			dialogue_label.text = "Storage unlocked."
	else:
		dialogue_label.text = "Storage door locked. Need Blue Card."
	return true

func _setup_cue_four_pickup() -> void:
	cue_four_pickup = null
	cue_four_sprite = null
	cue_four_in_range = false
	_update_cue_four_visibility()

func _update_cue_four_visibility() -> void:
	var already_collected := cue_collected.size() > 3 and cue_collected[3]
	var visible := storage_unlocked and not already_collected
	if cue_four_pickup != null:
		cue_four_pickup.monitoring = visible
		cue_four_pickup.monitorable = visible
	if cue_four_sprite != null:
		cue_four_sprite.visible = visible
	if not visible:
		cue_four_in_range = false

func _on_cue_four_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if cue_collected.size() > 3 and cue_collected[3]:
		return
	cue_four_in_range = true

func _on_cue_four_body_exited(body: Node2D) -> void:
	if body != player:
		return
	cue_four_in_range = false

func _handle_cue_four_interaction() -> bool:
	if not storage_unlocked:
		return false
	if cue_collected.size() <= 3 or cue_collected[3]:
		return false
	var near_cue := player.global_position.distance_to(STORAGE_CUE_FOUR_POSITION) <= 80.0
	if not near_cue:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to pick up Cue 4 (Crowbar)."
	if Input.is_action_just_pressed("interact"):
		_set_cue_collected(4, true)
		_update_cue_four_visibility()
		_show_keycard_fx_for_cue(4)
		dialogue_panel.visible = true
		dialogue_label.text = "Evidence: Crowbar found in Storage.\n\n[Press E]"
	return true

func _setup_storage_box() -> void:
	storage_box_area = get_node_or_null("StorageRoom/StorageBox") as Area2D
	storage_box_sprite = null
	if storage_box_area != null:
		storage_box_sprite = storage_box_area.get_node_or_null("StorageBoxSprite") as Sprite2D
		if not storage_box_area.body_entered.is_connected(_on_storage_box_body_entered):
			storage_box_area.body_entered.connect(_on_storage_box_body_entered)
		if not storage_box_area.body_exited.is_connected(_on_storage_box_body_exited):
			storage_box_area.body_exited.connect(_on_storage_box_body_exited)
	storage_box_in_range = false
	_update_storage_box_visibility()

func _update_storage_box_visibility() -> void:
	if storage_box_area != null:
		storage_box_area.monitoring = storage_unlocked
		storage_box_area.monitorable = storage_unlocked
	if storage_box_sprite != null:
		storage_box_sprite.visible = storage_unlocked
	if not storage_unlocked:
		storage_box_in_range = false

func _on_storage_box_body_entered(body: Node2D) -> void:
	if body != player:
		return
	storage_box_in_range = true

func _on_storage_box_body_exited(body: Node2D) -> void:
	if body != player:
		return
	storage_box_in_range = false

func _handle_storage_box_interaction() -> bool:
	if not storage_unlocked:
		return false
	if cue_collected.size() <= 4 or cue_collected[4]:
		return false
	var box_pos := STORAGE_BOX_POSITION
	if storage_box_area != null:
		box_pos = storage_box_area.global_position
	var near_box := player.global_position.distance_to(box_pos) <= 96.0
	if not near_box:
		return false
	dialogue_panel.visible = true
	if cue_collected.size() > 3 and cue_collected[3]:
		dialogue_label.text = "Press E to use Crowbar (Cue 4) on the box."
		if Input.is_action_just_pressed("interact"):
			_set_cue_collected(5, true)
			cue_notes[5] = CUE_FIVE_INVOICE_TEXT
			_show_keycard_fx_for_cue(5)
			dialogue_label.text = "%s\n\n[Press E]" % CUE_FIVE_INVOICE_TEXT
	else:
		dialogue_label.text = "Heavy box. You need a crowbar."
	return true

func _setup_elevator_points() -> void:
	storage_elevator_area = get_node_or_null("StorageRoom/StorageElevatorArea") as Area2D
	upper_elevator_area = get_node_or_null("SecondFloor/UpperElevatorArea") as Area2D
	if storage_elevator_area != null:
		if not storage_elevator_area.body_entered.is_connected(_on_storage_elevator_body_entered):
			storage_elevator_area.body_entered.connect(_on_storage_elevator_body_entered)
		if not storage_elevator_area.body_exited.is_connected(_on_storage_elevator_body_exited):
			storage_elevator_area.body_exited.connect(_on_storage_elevator_body_exited)
	if upper_elevator_area != null:
		if not upper_elevator_area.body_entered.is_connected(_on_upper_elevator_body_entered):
			upper_elevator_area.body_entered.connect(_on_upper_elevator_body_entered)
		if not upper_elevator_area.body_exited.is_connected(_on_upper_elevator_body_exited):
			upper_elevator_area.body_exited.connect(_on_upper_elevator_body_exited)

func _on_storage_elevator_body_entered(body: Node2D) -> void:
	if body != player:
		return
	storage_elevator_in_range = true

func _on_storage_elevator_body_exited(body: Node2D) -> void:
	if body != player:
		return
	storage_elevator_in_range = false

func _on_upper_elevator_body_entered(body: Node2D) -> void:
	if body != player:
		return
	upper_elevator_in_range = true

func _on_upper_elevator_body_exited(body: Node2D) -> void:
	if body != player:
		return
	upper_elevator_in_range = false

func _handle_storage_elevator_interaction() -> bool:
	if not storage_unlocked:
		return false
	if not storage_elevator_in_range:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to take elevator to Upper Floor."
	if Input.is_action_just_pressed("interact"):
		var target := _get_elevator_spawn_position(upper_elevator_area, UPPER_ELEVATOR_POSITION)
		player.global_position = target
		storage_elevator_in_range = false
		upper_elevator_in_range = true
		current_checkpoint_index = 4
		dialogue_panel.visible = false
	return true

func _handle_upper_elevator_interaction() -> bool:
	if not upper_elevator_in_range:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to take elevator to Storage."
	if Input.is_action_just_pressed("interact"):
		var target := _get_elevator_spawn_position(storage_elevator_area, STORAGE_ELEVATOR_POSITION)
		player.global_position = target
		upper_elevator_in_range = false
		storage_elevator_in_range = true
		dialogue_panel.visible = false
	return true

func _get_elevator_spawn_position(area: Area2D, fallback: Vector2) -> Vector2:
	if area == null:
		return fallback
	var sprite := area.get_node_or_null("ElevatorSprite") as Node2D
	if sprite != null:
		return sprite.global_position
	return area.global_position

func _setup_visibility_fx() -> void:
	visibility_fx_layer = CanvasLayer.new()
	visibility_fx_layer.layer = 3
	add_child(visibility_fx_layer)

	visibility_fx_rect = ColorRect.new()
	visibility_fx_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform vec2 center_uv = vec2(0.5, 0.5);\nuniform float radius = 0.16;\nuniform float softness = 0.24;\nuniform float dim_alpha = 0.94;\nvoid fragment() {\n\tfloat d = distance(SCREEN_UV, center_uv);\n\tfloat reveal = 1.0 - smoothstep(radius, radius + softness, d);\n\tfloat a = dim_alpha * (1.0 - reveal);\n\tCOLOR = vec4(0.0, 0.0, 0.0, a);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	visibility_fx_rect.material = mat
	visibility_fx_layer.add_child(visibility_fx_rect)

func _update_visibility_fx() -> void:
	if visibility_fx_rect == null:
		return
	visibility_fx_rect.visible = room_vision_enabled and not dialogue_panel.visible and not minigame_ui.visible
	if not visibility_fx_rect.visible:
		return
	var mat := visibility_fx_rect.material as ShaderMaterial
	if mat == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var screen_pos := (get_viewport().get_canvas_transform() * player.global_position).round()
	var center_uv := Vector2(screen_pos.x / viewport_size.x, screen_pos.y / viewport_size.y)
	mat.set_shader_parameter("center_uv", center_uv)

func _get_current_room_world_rect() -> Rect2:
	var p := player.global_position
	var rooms := [
		ROOM_CELL,
		ROOM_HALLWAY,
		ROOM_TURN1,
		ROOM_TURN_VERTICAL,
		ROOM_TURN2,
		ROOM_END,
		ROOM_PRE,
		ROOM_STORAGE,
		ROOM_SECOND_FLOOR,
	]
	if current_room_index >= 0 and current_room_index < rooms.size():
		# Keep current room until player has clearly left it; prevents edge flicker.
		var sticky: Rect2 = rooms[current_room_index].grow(64.0)
		if sticky.has_point(p):
			return rooms[current_room_index]
	for i in range(rooms.size()):
		if rooms[i].has_point(p):
			current_room_index = i
			return rooms[i]
	current_room_index = -1
	return Rect2()

func _setup_cue_seven_pickup() -> void:
	cue_seven_pickup = null
	cue_seven_sprite = null
	cue_seven_in_range = false
	_update_cue_seven_visibility()

func _setup_cue_eleven_pickup() -> void:
	cue_eleven_sprite = get_node_or_null("SecondFloor/GalleryCue11") as Sprite2D
	_update_cue_eleven_visibility()

func _update_cue_eleven_visibility() -> void:
	if cue_eleven_sprite == null:
		return
	var collected := cue_collected.size() > 10 and cue_collected[10]
	cue_eleven_sprite.visible = not collected

func _handle_cue_eleven_interaction() -> bool:
	if cue_collected.size() <= 10 or cue_collected[10]:
		return false
	if cue_eleven_sprite == null:
		return false
	var near_cue := player.global_position.distance_to(cue_eleven_sprite.global_position) <= 110.0
	if not near_cue:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to inspect Cue 11."
	if Input.is_action_just_pressed("interact"):
		_set_cue_collected(11, true)
		cue_notes[11] = CUE_ELEVEN_CHARITY_TEXT
		_update_cue_eleven_visibility()
		_show_keycard_fx_for_cue(11)
		dialogue_label.text = "%s\n\n[Press E]" % CUE_ELEVEN_CHARITY_TEXT
	return true

func _update_cue_seven_visibility() -> void:
	var already_collected := cue_collected.size() > 6 and cue_collected[6]
	if cue_seven_pickup != null:
		cue_seven_pickup.monitoring = not already_collected
		cue_seven_pickup.monitorable = not already_collected
	if cue_seven_sprite != null:
		cue_seven_sprite.visible = not already_collected
	if already_collected:
		cue_seven_in_range = false

func _on_cue_seven_body_entered(body: Node2D) -> void:
	if body != player:
		return
	if cue_collected.size() > 6 and cue_collected[6]:
		return
	cue_seven_in_range = true

func _on_cue_seven_body_exited(body: Node2D) -> void:
	if body != player:
		return
	cue_seven_in_range = false

func _handle_cue_seven_interaction() -> bool:
	if cue_collected.size() <= 6 or cue_collected[6]:
		return false
	var near_cue := player.global_position.distance_to(GALLERY_STATUE_POSITION) <= 92.0
	if not near_cue:
		return false
	dialogue_panel.visible = true
	dialogue_label.text = "Press E to inspect statue fragment (Cue 7)."
	if Input.is_action_just_pressed("interact"):
		_set_cue_collected(7, true)
		cue_notes[7] = CUE_SEVEN_STATUE_TEXT
		current_checkpoint_index = 4
		_update_cue_seven_visibility()
		_show_keycard_fx_for_cue(7)
		dialogue_label.text = "%s\n\n[Press E]" % CUE_SEVEN_STATUE_TEXT
	return true

func _refresh_key_hud() -> void:
	var found_count := _get_collected_cue_count()
	if key_hud_label != null:
		key_hud_label.text = "Cues: %d/%d" % [found_count, KEY_USE_MAX]
	if key_hud_icon != null:
		if latest_collected_cue_index > 0:
			key_hud_icon.texture = _get_key_texture_for_uses(latest_collected_cue_index)
		else:
			key_hud_icon.texture = null
		key_hud_icon.visible = found_count > 0

func _consume_key_use() -> bool:
	if key_uses <= 0:
		return false
	key_uses -= 1
	_refresh_key_hud()
	return true

func _get_key_texture_for_uses(uses: int) -> Texture2D:
	var clamped := clampi(uses, 1, KEY_USE_MAX)
	var base: String = String(KEY_IMAGE_BASE_NAMES[clamped - 1])
	for ext in KEY_IMAGE_EXTENSIONS:
		var path := "res://%s.%s" % [base, ext]
		if ResourceLoader.exists(path):
			var tex := load(path)
			if tex is Texture2D:
				return tex as Texture2D
	if key_hud_fallback_textures.is_empty():
		return null
	return key_hud_fallback_textures[clamped - 1]

func _on_anesthesia_failed() -> void:
	_restart_from_checkpoint(0)

func _reset_to_checkpoint(index: int) -> void:
	var clamped := clampi(index, 0, checkpoint_positions.size() - 1)
	current_checkpoint_index = clamped
	current_room_index = -1
	player.global_position = checkpoint_positions[clamped]
	guard.visible = false
	guard_exit_running = false
	escorting = false
	path_index = 0
	player_in_disguise_area = false
	storage_elevator_in_range = false
	upper_elevator_in_range = false
	doctor_sequence_started = false
	anesthesia_started = false
	anesthesia_won = false
	spam_progress = spam_required * 0.5
	gallery_code_unlocked = false
	gallery_code_entry_active = false
	gallery_code_buffer = ""
	_update_gallery_code_door()
	call_deferred("_refresh_visibility_next_frame")

func _restart_from_checkpoint(index: int) -> void:
	_reset_to_checkpoint(index)

	player.set_default_visual()

	_set_doctor_default_visual()

	guard.global_position = GUARD_SPAWN_POSITION
	guard.velocity = Vector2.ZERO
	_update_guard_visual(Vector2.ZERO)
	other_guy.visible = true
	other_guy.global_position = Vector2(1800, 400)
	_update_other_guy_visual(Vector2.ZERO)
	doctor.global_position = DOCTOR_START_POSITION

	keycard_fx_active = false
	keycard_fx_rect.visible = false
	keycard_fx_label.visible = false
	if keycard_fx_icon != null:
		keycard_fx_icon.visible = false

	if index == 0:
		# Full story reset (cell start).
		room_vision_enabled = true
		has_keycard = false
		key_uses = 0
		cue_notes.clear()
		hovered_inventory_index = -1
		latest_collected_cue_index = 0
		for i in range(cue_collected.size()):
			cue_collected[i] = false
		_refresh_inventory_ui()
		_update_cue_two_visibility()
		_update_cue_three_visibility()
		_update_cue_seven_visibility()
		_update_cue_eleven_visibility()
		storage_unlocked = false
		_update_storage_door_visibility()
		hall_door_unlocked = false
		end_room_door_unlocked = false
		is_disguised = false
		player_in_disguise_area = false
		guard_exit_running = false
		pre_surgery_unlocked = false
		_lock_pre_surgery_door()
		cell_door_lock.disabled = false
		trigger_area.set_deferred("monitoring", true)
		dialogue_panel.visible = false
		minigame_ui.visible = false
		player.set_physics_process(true)
		state = SequenceState.IDLE
		_refresh_key_hud()
		_refresh_door_lock_icons()
		return

	if index == 1:
		# Doctor checkpoint restart.
		room_vision_enabled = true
		has_keycard = false
		key_uses = 0
		cue_notes.clear()
		hovered_inventory_index = -1
		latest_collected_cue_index = 0
		for i in range(cue_collected.size()):
			cue_collected[i] = false
		_refresh_inventory_ui()
		_update_cue_two_visibility()
		_update_cue_three_visibility()
		_update_cue_seven_visibility()
		_update_cue_eleven_visibility()
		storage_unlocked = false
		_update_storage_door_visibility()
		hall_door_unlocked = true
		end_room_door_unlocked = true
		is_disguised = false
		player_in_disguise_area = false
		_lock_pre_surgery_door()
		cell_door_lock.disabled = true
		trigger_area.set_deferred("monitoring", false)
		player.global_position = BED_POSITION
		doctor.global_position = BED_POSITION + DOCTOR_TARGET_OFFSET
		dialogue_panel.visible = false
		minigame_ui.visible = false
		player.set_physics_process(true)
		_start_anesthesia_spam()
		_refresh_key_hud()
		_refresh_door_lock_icons()
		return

	if index == 2:
		# Pre-surgery checkpoint restart.
		room_vision_enabled = true
		has_keycard = true
		key_uses = 0
		cue_notes.clear()
		hovered_inventory_index = -1
		latest_collected_cue_index = 0
		for i in range(cue_collected.size()):
			cue_collected[i] = false
		_set_cue_collected(1, true)
		_refresh_inventory_ui()
		_update_cue_two_visibility()
		_update_cue_three_visibility()
		_update_cue_seven_visibility()
		_update_cue_eleven_visibility()
		storage_unlocked = false
		_update_storage_door_visibility()
		hall_door_unlocked = true
		end_room_door_unlocked = true
		is_disguised = true
		player_in_disguise_area = false
		cell_door_lock.disabled = true
		trigger_area.set_deferred("monitoring", false)
		player.set_disguise_visual()
		_set_doctor_texture_visual(PLAYER_BED_TEXTURE)
		_unlock_pre_surgery_door()
		dialogue_panel.visible = false
		minigame_ui.visible = false
		player.set_physics_process(true)
		state = SequenceState.DONE
		_refresh_key_hud()
		_refresh_door_lock_icons()
		return

	if index == 3:
		# Storage checkpoint restart (after Cue 3).
		room_vision_enabled = true
		has_keycard = true
		key_uses = 0
		cue_notes.clear()
		hovered_inventory_index = -1
		latest_collected_cue_index = 0
		for i in range(cue_collected.size()):
			cue_collected[i] = false
		_set_cue_collected(1, true)
		_set_cue_collected(2, true)
		_set_cue_collected(3, true)
		_refresh_inventory_ui()
		_update_cue_two_visibility()
		_update_cue_three_visibility()
		_update_cue_seven_visibility()
		_update_cue_eleven_visibility()
		storage_unlocked = true
		_update_storage_door_visibility()
		hall_door_unlocked = true
		end_room_door_unlocked = true
		is_disguised = true
		player_in_disguise_area = false
		cell_door_lock.disabled = true
		trigger_area.set_deferred("monitoring", false)
		player.set_disguise_visual()
		_set_doctor_texture_visual(PLAYER_BED_TEXTURE)
		_unlock_pre_surgery_door()
		dialogue_panel.visible = false
		minigame_ui.visible = false
		player.set_physics_process(true)
		state = SequenceState.DONE
		_refresh_key_hud()
		_refresh_door_lock_icons()
		return

	# Gallery checkpoint restart (after Cue 7).
	room_vision_enabled = true
	has_keycard = true
	key_uses = 0
	cue_notes.clear()
	hovered_inventory_index = -1
	latest_collected_cue_index = 0
	for i in range(cue_collected.size()):
		cue_collected[i] = false
	_set_cue_collected(1, true)
	_set_cue_collected(2, true)
	_set_cue_collected(3, true)
	_set_cue_collected(4, true)
	_set_cue_collected(5, true)
	_set_cue_collected(7, true)
	cue_notes[5] = CUE_FIVE_INVOICE_TEXT
	cue_notes[7] = CUE_SEVEN_STATUE_TEXT
	_refresh_inventory_ui()
	_update_cue_two_visibility()
	_update_cue_three_visibility()
	_update_cue_seven_visibility()
	_update_cue_eleven_visibility()
	storage_unlocked = true
	_update_storage_door_visibility()
	hall_door_unlocked = true
	end_room_door_unlocked = true
	is_disguised = true
	player_in_disguise_area = false
	cell_door_lock.disabled = true
	trigger_area.set_deferred("monitoring", false)
	player.set_disguise_visual()
	_set_doctor_texture_visual(PLAYER_BED_TEXTURE)
	_unlock_pre_surgery_door()
	dialogue_panel.visible = false
	minigame_ui.visible = false
	player.set_physics_process(true)
	state = SequenceState.DONE
	_refresh_key_hud()
	_refresh_door_lock_icons()

func _handle_checkpoint_cheat_input() -> void:
	if not Input.is_physical_key_pressed(KEY_SHIFT):
		return

	var direction := 0
	if Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_down"):
		direction = 1
	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up"):
		direction = -1

	if direction == 0:
		return

	var next_index := current_checkpoint_index + direction
	if next_index < 0:
		next_index = checkpoint_positions.size() - 1
	elif next_index >= checkpoint_positions.size():
		next_index = 0

	_restart_from_checkpoint(next_index)
	dialogue_panel.visible = true
	dialogue_label.text = "Cheat checkpoint: %s\n\n[Press E]" % checkpoint_names[current_checkpoint_index]
