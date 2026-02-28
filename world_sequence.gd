extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var trigger_area: Area2D = $StoryTrigger
@onready var guard: CharacterBody2D = $Guard
@onready var other_guy: Node2D = $OtherGuy
@onready var dialogue_panel: Panel = $DialogueUI/Panel
@onready var dialogue_label: Label = $DialogueUI/Panel/DialogueText
@onready var cell_door_lock: CollisionShape2D = $CellDoorLock/CollisionShape2D
@onready var music_player: AudioStreamPlayer = $Music

@export var guard_speed := 300.0
@export var npc_follow_speed := 240.0
const GUARD_SPAWN_POSITION := Vector2(1360, -700)
const PLAYER_ESCORT_OFFSET := Vector2(90, 0)
const PLAYER_GRAB_DISTANCE := 110.0
const CELL_DOOR_TOUCH_DISTANCE := 70.0
const BED_POSITION := Vector2(4240, -5080)

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
	Vector2(1360, -3120),
	Vector2(2960, -3120),
	Vector2(2960, -4920),
	Vector2(3920, -4920),
]
var guard_leave_end_room_path: Array[Vector2] = [
	Vector2(3520, -4920),
	Vector2(2960, -4920),
	Vector2(2960, -3200),
	Vector2(2960, -2800),
]
var path_index := 0
var escorting := false
var return_delay_seconds := 5.0
var return_timer := 0.0
var guard_return_phase := 0

func _ready() -> void:
	guard.visible = false
	guard.position = GUARD_SPAWN_POSITION
	cell_door_lock.disabled = false
	dialogue_panel.visible = false
	#if music_player.stream is AudioStreamMP3:
		#(music_player.stream as AudioStreamMP3).loop = true
	#if not music_player.playing:
		#music_player.play()
	trigger_area.body_entered.connect(_on_story_trigger_body_entered)

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
			state = SequenceState.GUARD_LEAVE_END_ROOM
		SequenceState.GUARD_LEAVE_END_ROOM:
			player.global_position = BED_POSITION
			var reached_exit := _move_along_path(guard, guard_leave_end_room_path, guard_speed, delta)
			if reached_exit:
				guard.visible = false
				state = SequenceState.DONE
		SequenceState.EPILOGUE:
			if Input.is_action_just_pressed("interact"):
				dialogue_panel.visible = false
				state = SequenceState.DONE

func _move_guard_toward(point: Vector2, speed: float, delta: float) -> bool:
	var to_target := point - guard.global_position
	if to_target.length() < 2.0:
		guard.velocity = Vector2.ZERO
		guard.move_and_slide()
		return true

	guard.velocity = to_target.normalized() * speed
	guard.move_and_slide()
	return guard.global_position.distance_to(point) < 8.0

func _move_to_point(actor: CharacterBody2D, point: Vector2, speed: float, delta: float) -> bool:
	if actor == guard:
		return _move_guard_toward(point, speed, delta)

	actor.global_position = actor.global_position.move_toward(point, speed * delta)
	return actor.global_position.distance_to(point) < 2.0

func _move_along_path(actor: CharacterBody2D, points: Array[Vector2], speed: float, delta: float) -> bool:
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

	trigger_area.monitoring = false
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
