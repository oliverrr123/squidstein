extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var player_cube: CanvasItem = $Player/PlaceholderCube
@onready var trigger_area: Area2D = $StoryTrigger
@onready var guard: CharacterBody2D = $Guard
@onready var other_guy: Node2D = $OtherGuy
@onready var doctor: Node2D = $Doctor
@onready var doctor_cube: CanvasItem = $Doctor/DoctorCube
@onready var disguise_area: Area2D = $DoctorDisguiseArea
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
const DOCTOR_DISGUISE_TEXTURE := preload("res://doc.png")

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

func _ready() -> void:
	guard.visible = false
	guard.position = GUARD_SPAWN_POSITION
	cell_door_lock.disabled = false
	dialogue_panel.visible = false
	minigame_ui.visible = false
	disguise_area.monitoring = false
	#if music_player.stream is AudioStreamMP3:
		#(music_player.stream as AudioStreamMP3).loop = true
	#if not music_player.playing:
		#music_player.play()
	trigger_area.body_entered.connect(_on_story_trigger_body_entered)
	disguise_area.body_entered.connect(_on_disguise_area_body_entered)
	disguise_area.body_exited.connect(_on_disguise_area_body_exited)

func _physics_process(delta: float) -> void:
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
			spam_progress = maxf(0.0, spam_progress - spam_decay_per_second * delta)
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
				doctor_cube.modulate = Color(0.55, 0.55, 0.6, 1.0)
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
	spam_progress = 0.0
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

	if is_disguised and dialogue_panel.visible and Input.is_action_just_pressed("interact"):
		dialogue_panel.visible = false

func _wear_doctor_clothes() -> void:
	is_disguised = true
	player_in_disguise_area = false
	disguise_area.set_deferred("monitoring", false)
	var player_sprite := player_cube as Sprite2D
	if player_sprite != null:
		player_sprite.texture = DOCTOR_DISGUISE_TEXTURE
		player_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		player_cube.modulate = Color(0.95, 0.95, 1.0, 1.0)
	dialogue_panel.visible = true
	dialogue_label.text = "You put on the doctor's clothes.\n\n[Press E]"
