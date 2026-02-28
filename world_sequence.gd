extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var player_cube: CanvasItem = $Player/PlaceholderCube
@onready var trigger_area: Area2D = $StoryTrigger
@onready var guard: CharacterBody2D = $Guard
@onready var other_guy: Node2D = $OtherGuy
@onready var doctor: Node2D = $Doctor
@onready var doctor_cube: CanvasItem = $Doctor/DoctorCube
@onready var disguise_area: Area2D = $DoctorDisguiseArea
@onready var pre_surgery_door_lock: CollisionShape2D = $PreSurgeryDoorLock/CollisionShape2D
@onready var pre_surgery_door_lintel: CanvasItem = $Blockout/EndRoomToPreDoorLintel
@onready var dialogue_panel: Panel = $DialogueUI/Panel
@onready var dialogue_label: Label = $DialogueUI/Panel/DialogueText
@onready var cell_door_lock: CollisionShape2D = $CellDoorLock/CollisionShape2D
@onready var music_player: AudioStreamPlayer = $Music
@onready var minigame_ui: CanvasLayer = $MinigameUI
@onready var struggle_label: Label = $MinigameUI/Panel/PromptLabel
@onready var hits_label: Label = $MinigameUI/Panel/HitsLabel
@onready var timing_line: ColorRect = $MinigameUI/Panel/TimingLine
@onready var target_zone: ColorRect = $MinigameUI/Panel/TimingLine/TargetZone
@onready var needle: ColorRect = $MinigameUI/Panel/TimingLine/Needle

@export var guard_speed := 300.0
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
const DOCTOR_FAINT_TEXTURE := preload("res://doc_switched.png")
const PLAYER_DEFAULT_TEXTURE := preload("res://guy.png")
const DOCTOR_DEFAULT_TEXTURE := preload("res://doc.png")
const PRE_SURGERY_UNLOCK_DISTANCE := 140.0
const CHECKPOINT_CELL_POSITION := Vector2(500, 400)
const CHECKPOINT_DOCTOR_POSITION := Vector2(3920, -4920)
const CHECKPOINT_PRE_SURGERY_POSITION := Vector2(5240, -5080)

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
var spam_required := 26.0
var spam_decay_per_second := 6.0
var spam_press_gain := 1.0
var has_keycard := false
var keycard_fx_timer := 0.0
var keycard_fx_duration := 1.2
var keycard_fx_active := false
var keycard_fx_layer: CanvasLayer
var keycard_fx_rect: ColorRect
var keycard_fx_label: Label
var pre_surgery_unlocked := false
var checkpoint_positions: Array[Vector2] = [
	CHECKPOINT_CELL_POSITION,
	CHECKPOINT_DOCTOR_POSITION,
	CHECKPOINT_PRE_SURGERY_POSITION,
]
var checkpoint_names: Array[String] = [
	"Cell",
	"Doctor Room",
	"Pre-Surgery Room",
]
var current_checkpoint_index := 0

func _ready() -> void:
	dialogue_panel.visible = false
	minigame_ui.visible = false
	disguise_area.monitoring = false
	_setup_keycard_fx_ui()
	#if music_player.stream is AudioStreamMP3:
		#(music_player.stream as AudioStreamMP3).loop = true
	#if not music_player.playing:
		#music_player.play()
	trigger_area.body_entered.connect(_on_story_trigger_body_entered)
	disguise_area.body_entered.connect(_on_disguise_area_body_entered)
	disguise_area.body_exited.connect(_on_disguise_area_body_exited)
	_restart_from_checkpoint(0)

func _physics_process(delta: float) -> void:
	_update_keycard_fx(delta)
	_handle_checkpoint_cheat_input()
	match state:
		SequenceState.DIALOGUE:
			if Input.is_action_just_pressed("interact"):
				_advance_dialogue()
		SequenceState.GUARD_TO_GUY:
			if dialogue_panel.visible and Input.is_action_just_pressed("interact"):
				_advance_dialogue()
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
				other_guy.global_position = other_guy.global_position.move_toward(follow_target, npc_follow_speed * delta)
			if reached:
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
				var reached_hall := _move_to_point(guard, Vector2(1360, 400), guard_speed, delta)
				if reached_hall:
					guard_return_phase = 1
			else:
				var reached_player := _move_to_point(guard, player.global_position + PLAYER_ESCORT_OFFSET, guard_speed, delta)
				if reached_player or guard.global_position.distance_to(player.global_position) < PLAYER_GRAB_DISTANCE:
					_start_escort_player()
		SequenceState.ESCORT_PLAYER:
			var reached_dest := _move_along_path(guard, escort_player_path, guard_speed, delta)
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

func _move_guard_toward(point: Vector2, speed: float, _delta: float) -> bool:
	var to_target := point - guard.global_position
	if to_target.length() < 2.0:
		guard.velocity = Vector2.ZERO
		guard.move_and_slide()
		return true

	guard.velocity = to_target.normalized() * speed
	guard.move_and_slide()
	return guard.global_position.distance_to(point) < 8.0

func _move_to_point(actor: Node2D, point: Vector2, speed: float, delta: float) -> bool:
	if actor == guard:
		return _move_guard_toward(point, speed, delta)

	actor.global_position = actor.global_position.move_toward(point, speed * delta)
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
	if not is_disguised and player_in_disguise_area:
		if Input.is_action_just_pressed("interact"):
			_wear_doctor_clothes()
		return

	if has_keycard and not pre_surgery_door_lock.disabled:
		var near_door := player.global_position.distance_to(pre_surgery_door_lock.global_position) <= PRE_SURGERY_UNLOCK_DISTANCE
		if near_door:
			dialogue_panel.visible = true
			dialogue_label.text = "Press E to use keycard on pre-surgery room."
			if Input.is_action_just_pressed("interact"):
				_unlock_pre_surgery_door()
				dialogue_label.text = "Keycard accepted.\n\n[Press E]"
			return

	if is_disguised and dialogue_panel.visible and Input.is_action_just_pressed("interact"):
		dialogue_panel.visible = false
		return

	if dialogue_panel.visible and Input.is_action_just_pressed("interact"):
		dialogue_panel.visible = false

func _wear_doctor_clothes() -> void:
	is_disguised = true
	has_keycard = true
	player_in_disguise_area = false
	disguise_area.set_deferred("monitoring", false)
	var player_sprite := player_cube as Sprite2D
	if player_sprite != null:
		player_sprite.texture = DOCTOR_DISGUISE_TEXTURE
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		player_cube.modulate = Color(0.95, 0.95, 1.0, 1.0)
	var doctor_sprite := doctor_cube as Sprite2D
	if doctor_sprite != null:
		doctor_sprite.texture = DOCTOR_FAINT_TEXTURE
		doctor_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		doctor_cube.modulate = Color(0.55, 0.55, 0.6, 1.0)
	_show_keycard_fx()
	dialogue_panel.visible = true
	dialogue_label.text = "You put on the doctor's clothes and got a keycard.\n\n[Press E]"

func _setup_keycard_fx_ui() -> void:
	keycard_fx_layer = CanvasLayer.new()
	keycard_fx_layer.layer = 20
	add_child(keycard_fx_layer)

	keycard_fx_rect = ColorRect.new()
	keycard_fx_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	keycard_fx_rect.visible = false
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nuniform float t = 0.0;\nvoid fragment() {\n\tvec2 p = UV - vec2(0.5);\n\tfloat a = atan(p.y, p.x);\n\tfloat r = length(p);\n\tfloat rays = pow(abs(sin(a * 14.0 + t * 8.0)), 5.0);\n\tfloat fade = smoothstep(1.15, 0.08, r);\n\tfloat alpha = rays * fade * 0.6;\n\tvec3 col = mix(vec3(1.0, 0.45, 0.05), vec3(1.0, 0.9, 0.2), rays);\n\tCOLOR = vec4(col, alpha);\n}\n"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	keycard_fx_rect.material = mat
	keycard_fx_layer.add_child(keycard_fx_rect)

	keycard_fx_label = Label.new()
	keycard_fx_label.text = "KEYCARD ACQUIRED"
	keycard_fx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycard_fx_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycard_fx_label.set("theme_override_font_sizes/font_size", 52)
	keycard_fx_label.modulate = Color(1, 1, 1, 1)
	keycard_fx_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	keycard_fx_label.position = Vector2(-420, -40)
	keycard_fx_label.size = Vector2(840, 80)
	keycard_fx_label.visible = false
	keycard_fx_layer.add_child(keycard_fx_label)

func _show_keycard_fx() -> void:
	keycard_fx_active = true
	keycard_fx_timer = 0.0
	keycard_fx_rect.visible = true
	keycard_fx_label.visible = true

func _update_keycard_fx(delta: float) -> void:
	if not keycard_fx_active:
		return
	keycard_fx_timer += delta
	var mat := keycard_fx_rect.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("t", keycard_fx_timer)
	if keycard_fx_timer >= keycard_fx_duration:
		keycard_fx_active = false
		keycard_fx_rect.visible = false
		keycard_fx_label.visible = false

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

func _on_anesthesia_failed() -> void:
	_restart_from_checkpoint(0)

func _reset_to_checkpoint(index: int) -> void:
	var clamped := clampi(index, 0, checkpoint_positions.size() - 1)
	current_checkpoint_index = clamped
	player.global_position = checkpoint_positions[clamped]
	guard.visible = false
	guard_exit_running = false
	escorting = false
	path_index = 0
	player_in_disguise_area = false
	doctor_sequence_started = false
	anesthesia_started = false
	anesthesia_won = false
	spam_progress = spam_required * 0.5

func _restart_from_checkpoint(index: int) -> void:
	_reset_to_checkpoint(index)

	var player_sprite := player_cube as Sprite2D
	if player_sprite != null:
		player_sprite.texture = PLAYER_DEFAULT_TEXTURE
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var doctor_sprite := doctor_cube as Sprite2D
	if doctor_sprite != null:
		doctor_sprite.texture = DOCTOR_DEFAULT_TEXTURE
		doctor_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	guard.global_position = GUARD_SPAWN_POSITION
	guard.velocity = Vector2.ZERO
	other_guy.visible = true
	other_guy.global_position = Vector2(1800, 400)
	doctor.global_position = DOCTOR_START_POSITION

	keycard_fx_active = false
	keycard_fx_rect.visible = false
	keycard_fx_label.visible = false

	if index == 0:
		# Full story reset (cell start).
		has_keycard = false
		is_disguised = false
		player_in_disguise_area = false
		guard_exit_running = false
		pre_surgery_unlocked = false
		pre_surgery_door_lock.disabled = false
		cell_door_lock.disabled = false
		pre_surgery_door_lintel.visible = true
		trigger_area.set_deferred("monitoring", true)
		dialogue_panel.visible = false
		minigame_ui.visible = false
		player.set_physics_process(true)
		state = SequenceState.IDLE
		return

	if index == 1:
		# Doctor checkpoint restart.
		has_keycard = false
		is_disguised = false
		player_in_disguise_area = false
		pre_surgery_unlocked = false
		pre_surgery_door_lock.disabled = false
		pre_surgery_door_lintel.visible = true
		cell_door_lock.disabled = true
		trigger_area.set_deferred("monitoring", false)
		player.global_position = BED_POSITION
		doctor.global_position = BED_POSITION + DOCTOR_TARGET_OFFSET
		dialogue_panel.visible = false
		minigame_ui.visible = false
		player.set_physics_process(true)
		_start_anesthesia_spam()
		return

	# Pre-surgery checkpoint restart.
	has_keycard = true
	is_disguised = true
	player_in_disguise_area = false
	cell_door_lock.disabled = true
	trigger_area.set_deferred("monitoring", false)
	var player_sprite2 := player_cube as Sprite2D
	if player_sprite2 != null:
		player_sprite2.texture = DOCTOR_DISGUISE_TEXTURE
		player_sprite2.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var doctor_sprite2 := doctor_cube as Sprite2D
	if doctor_sprite2 != null:
		doctor_sprite2.texture = DOCTOR_FAINT_TEXTURE
		doctor_sprite2.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_unlock_pre_surgery_door()
	dialogue_panel.visible = false
	minigame_ui.visible = false
	player.set_physics_process(true)
	state = SequenceState.DONE

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
