extends CharacterBody2D
class_name OverworldEnemy

@export var enemy_id: String = "enemy_01"
@export var enemy_data: EnemyData
@export var speed: float = 50.0
@export var is_ghost: bool = false

@onready var interaction_area: Area2D = $InteractionArea
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var detection_area: Area2D
var target_player: CharacterBody2D = null

func _ready() -> void:
	if GameManager.is_enemy_defeated(enemy_id):
		queue_free()
		return
	if enemy_data and enemy_data.sprite_frames:
		animated_sprite.sprite_frames = enemy_data.sprite_frames
		_play_default_idle_animation()
	_setup_ghost_collision()
	interaction_area.body_entered.connect(_on_body_entered)
	_setup_detection_area()

func _physics_process(_delta: float) -> void:
	if is_instance_valid(target_player):
		var direction = (target_player.global_position - global_position).normalized()
		velocity = direction * speed
		_update_walk_animation(direction)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_play_default_idle_animation()

func _update_walk_animation(direction: Vector2) -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	var frames = animated_sprite.sprite_frames
	if frames.has_animation("andando"):
		animated_sprite.play("andando")
		animated_sprite.rotation = direction.angle() - (PI / 2)
		return
	animated_sprite.rotation = 0.0
	animated_sprite.flip_h = false
	if abs(direction.x) > abs(direction.y):
		if frames.has_animation("andando_lado"):
			animated_sprite.play("andando_lado")
			animated_sprite.flip_h = direction.x < 0
	else:
		if direction.y > 0 and frames.has_animation("andando_baixo"):
			animated_sprite.play("andando_baixo")
		elif direction.y < 0 and frames.has_animation("andando_cima"):
			animated_sprite.play("andando_cima")

func _play_default_idle_animation() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	animated_sprite.rotation = 0.0
	var frames = animated_sprite.sprite_frames
	if frames.has_animation("idle"):
		animated_sprite.play("idle")
	elif frames.has_animation("andando_baixo"):
		animated_sprite.play("andando_baixo")
		animated_sprite.stop()
	elif frames.has_animation("em_batalha"):
		animated_sprite.play("em_batalha")

func _setup_ghost_collision() -> void:
	if is_ghost or (enemy_data and "yuurei" in enemy_data.enemy_name.to_lower()):
		set_collision_mask_value(1, false)

func _setup_detection_area() -> void:
	detection_area = get_node_or_null("DetectionArea")
	if not detection_area:
		detection_area = Area2D.new()
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 125.0
		shape.shape = circle
		detection_area.add_child(shape)
		add_child(detection_area)
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)

func _on_detection_entered(body: Node2D) -> void:
	if body is Seiji:
		target_player = body

func _on_detection_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null

func _on_body_entered(body: Node2D) -> void:
	if body is Seiji:
		if enemy_data == null or GameManager.is_transitioning:
			return
		GameManager.is_transitioning = true
		target_player = null
		velocity = Vector2.ZERO
		interaction_area.set_deferred("monitoring", false)
		GameManager.player_map_position = body.global_position
		GameManager.returning_from_battle = true
		GameManager.defeated_enemy_id = enemy_id
		GameManager.current_map_scene_path = get_tree().current_scene.scene_file_path
		GameManager.current_enemy_party_data = EncounterManager.generate_encounter(
			enemy_data,
			GameManager.current_level
		)
		if body.has_method("set_in_battle"):
			body.set_in_battle(true)
		SceneTransition.fade_to_battle("res://battle/battle_scene.tscn")
