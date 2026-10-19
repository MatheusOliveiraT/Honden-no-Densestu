extends Resource
class_name CharacterStats

@export var character_name: String = "Entidade"
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var speed: int = 10
@export var attack: int = 15
@export var defense: int = 5

var current_hp: int
var current_mp: int

enum StatusType { POISON, BURN, SLOW, PARALIZE, WEAKNESS, STRENGTH, REGENERATION, RESISTANCE }

class ActiveStatus:
	var type: StatusType
	var duration: int
	var potency: int

	func _init(_type: StatusType, _duration: int, _potency: int):
		type = _type
		duration = _duration
		potency = _potency

var active_statuses: Array[ActiveStatus] = []

signal status_applied(type: StatusType)
signal status_ticked(type: StatusType, damage_or_effect: int)
signal status_expired(type: StatusType)
signal status_paralyzed()

func initialize() -> void:
	active_statuses.clear()
	if character_name == "Herói":
		GameManager.sync_stats_from_game_manager(self)
	else:
		current_hp = max_hp
		current_mp = max_mp

func take_damage(amount: int) -> void:
	var damage_taken = max(1, amount - get_current_defense())
	current_hp = max(0, current_hp - damage_taken)

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)

func heal_mana(amount: int) -> void:
	current_mp = min(max_mp, current_mp + amount)

func apply_status(type: StatusType, duration: int, potency: int) -> void:
	for status in active_statuses:
		if status.type == type:
			status.duration = max(status.duration, duration)
			status.potency = max(status.potency, potency)
			return
	var new_status = ActiveStatus.new(type, duration, potency)
	active_statuses.append(new_status)
	status_applied.emit(type)

func process_turn_statuses() -> void:
	var expired_statuses: Array[ActiveStatus] = []
	for status in active_statuses:
		match status.type:
			StatusType.POISON:
				current_hp = max(0, current_hp - status.potency)
				status_ticked.emit(status.type, status.potency)
			StatusType.BURN:
				var burn_damage = max(1, status.potency - int(get_current_defense() * 0.5))
				current_hp = max(0, current_hp - burn_damage)
				status_ticked.emit(status.type, burn_damage)
			StatusType.REGENERATION:
				current_hp = min(max_hp, current_hp + status.potency)
				status_ticked.emit(status.type, status.potency)
			StatusType.SLOW, StatusType.PARALIZE, StatusType.WEAKNESS, StatusType.STRENGTH, StatusType.RESISTANCE:
				status_ticked.emit(status.type, status.potency)
		status.duration -= 1
		if status.duration <= 0:
			expired_statuses.append(status)
	for status in expired_statuses:
		active_statuses.erase(status)
		status_expired.emit(status.type)

func can_take_action() -> bool:
	for status in active_statuses:
		if status.type == StatusType.PARALIZE:
			if randi() % 100 < status.potency:
				status_paralyzed.emit()
				return false
	return true

func get_current_speed() -> int:
	var final_speed = speed
	for status in active_statuses:
		if status.type == StatusType.SLOW:
			final_speed -= status.potency
	return max(1, final_speed)

func get_current_attack() -> int:
	var final_attack = attack
	for status in active_statuses:
		if status.type == StatusType.STRENGTH:
			final_attack += status.potency
		elif status.type == StatusType.WEAKNESS:
			final_attack -= status.potency
	return max(0, final_attack)

func get_current_defense() -> int:
	var final_defense = defense
	for status in active_statuses:
		if status.type == StatusType.RESISTANCE:
			final_defense += status.potency
	return max(0, final_defense)
