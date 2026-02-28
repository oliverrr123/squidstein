extends Area2D

@export var target_scene: String = "res://HallScene.tscn"
var player_inside := false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(target_scene)
