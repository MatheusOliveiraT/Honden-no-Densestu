extends Area2D

@export_file("*.tscn") var next_scene_path: String
@export var target_level_id: int = 2

func _on_body_entered(body: Node2D) -> void:
	if body is Seiji:
		GameManager.current_level = target_level_id
		SceneTransition.fade_to_battle(next_scene_path)
