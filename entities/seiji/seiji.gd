class_name Seiji
extends CharacterBody2D

@export var stats: CharacterStats 
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 100.0

var is_in_battle: bool = false
var _last_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	if get_tree().current_scene and get_tree().current_scene.name != "BattleScene":
		if GameManager.returning_from_battle and GameManager.player_map_position != Vector2.ZERO:
			call_deferred("_restore_map_position")

func _restore_map_position() -> void:
	global_position = GameManager.player_map_position
	GameManager.returning_from_battle = false
	set_in_battle(false)

func _physics_process(delta: float) -> void:
	if is_in_battle:
		velocity = Vector2.ZERO
		if _animated_sprite and _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation("em_batalha"):
			_animated_sprite.play("em_batalha")
		return
		
	_move_into_direction(delta)
	_animate()
	move_and_slide()

func set_in_battle(active: bool) -> void:
	is_in_battle = active
	
	if not _animated_sprite:
		_animated_sprite = get_node_or_null("AnimatedSprite2D")
		
	if active and _animated_sprite:
		velocity = Vector2.ZERO
		if _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation("em_batalha"):
			_animated_sprite.play("em_batalha")

func _move_into_direction(_delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_direction != Vector2.ZERO:
		_last_direction = input_direction
	velocity = input_direction * speed

func _animate() -> void:
	if velocity != Vector2.ZERO:
		if abs(velocity.x) > abs(velocity.y):
			_animated_sprite.play("andando_lado")
		elif velocity.y > 0:
			_animated_sprite.play("andando_baixo")
		else:
			_animated_sprite.play("andando_cima")
	else:
		if abs(_last_direction.x) > abs(_last_direction.y):
			_animated_sprite.play("idle_lado")
		elif _last_direction.y > 0:
			_animated_sprite.play("idle_baixo")
		else:
			_animated_sprite.play("idle_cima")

	var facing_x: float = velocity.x if velocity.x != 0 else _last_direction.x
	if facing_x != 0:
		_animated_sprite.flip_h = facing_x < 0
