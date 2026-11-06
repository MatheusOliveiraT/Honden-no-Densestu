class_name Seiji
extends CharacterBody2D

@export var stats: CharacterStats 
@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var speed: float = 100.0
@export var run_speed: float = 150.0 

var is_in_battle: bool = false
var _last_direction: Vector2 = Vector2.DOWN

@onready var interaction_detector: Area2D = $InteractionDetector

func _ready() -> void:
	if stats:
		stats.initialize()
		stats.equipped_weapon = GameManager.equipped_weapon
		stats.equipped_armor = GameManager.equipped_armor
	if get_tree().current_scene and get_tree().current_scene.name != "BattleScene":
		if GameManager.returning_from_battle and GameManager.player_map_position != Vector2.ZERO:
			call_deferred("_restore_map_position")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and not is_in_battle:
		_try_interact()

func _try_interact() -> void:
	if not interaction_detector: return
	var bodies = interaction_detector.get_overlapping_bodies()
	var areas = interaction_detector.get_overlapping_areas()
	
	var targets = bodies + areas
	for target in targets:
		if target.has_method("interact"):
			target.interact(self)
			break

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
	var input_direction: Vector2 = Input.get_vector("esquerda", "direita", "cima", "baixo")
	if input_direction != Vector2.ZERO:
		_last_direction = input_direction
	var is_running: bool = Input.is_action_pressed("correr")
	var current_speed: float = run_speed if is_running else speed
	velocity = input_direction * current_speed

func _animate() -> void:
	if velocity != Vector2.ZERO:
		var is_running: bool = Input.is_action_pressed("correr")
		_animated_sprite.speed_scale = 1.5 if is_running else 1.0
		if abs(velocity.x) > abs(velocity.y):
			_animated_sprite.play("andando_lado")
		elif velocity.y > 0:
			_animated_sprite.play("andando_baixo")
		else:
			_animated_sprite.play("andando_cima")
	else:
		_animated_sprite.speed_scale = 1.0
		if abs(_last_direction.x) > abs(_last_direction.y):
			_animated_sprite.play("idle_lado")
		elif _last_direction.y > 0:
			_animated_sprite.play("idle_baixo")
		else:
			_animated_sprite.play("idle_cima")
	var facing_x: float = velocity.x if velocity.x != 0 else _last_direction.x
	if facing_x != 0:
		_animated_sprite.flip_h = facing_x < 0
