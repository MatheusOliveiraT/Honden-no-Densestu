extends CharacterBody2D
class_name OverworldEnemy

@export var enemy_id: String = "enemy_01"    
@export var enemy_data: EnemyData            

@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if GameManager.is_enemy_defeated(enemy_id):
		queue_free()
		return

	if enemy_data and enemy_data.sprite_frames:
		animated_sprite.sprite_frames = enemy_data.sprite_frames
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		elif animated_sprite.sprite_frames.has_animation("em_batalha"):
			animated_sprite.play("em_batalha")

	interaction_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Seiji:
		GameManager.player_map_position = body.global_position
		GameManager.returning_from_battle = true
		GameManager.defeated_enemy_id = enemy_id
		GameManager.current_enemy_party_data = EncounterManager.generate_encounter(
			enemy_data, 
			GameManager.current_level
		)
		if body.has_method("set_in_battle"):
			body.set_in_battle(true)
		SceneTransition.fade_to_battle("res://battle/battle_scene.tscn")
