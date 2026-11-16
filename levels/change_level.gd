extends Area2D

@export_file("*.tscn") var next_scene_path: String
@export var target_level_id: int = 1
@export var next_spawn_position: Vector2 = Vector2.ZERO

var _triggered: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if body.is_in_group("Players") or body.name == "Seiji":
		if next_scene_path.is_empty():
			push_warning("ProxLevel: 'next_scene_path' não foi definido no Inspector!")
			return
		_triggered = true
		GameManager.disable_all_overworld_enemies()
		GameManager.current_level = target_level_id
		GameManager.current_map_scene_path = next_scene_path
		GameManager.player_map_position = next_spawn_position
		GameManager.returning_from_battle = (next_spawn_position != Vector2.ZERO)
		SceneTransition.fade_to_battle(next_scene_path)
