extends Node

var player_map_position: Vector2 = Vector2.ZERO
var returning_from_battle: bool = false

var defeated_enemy_id: String = ""
var defeated_enemies: Array[String] = []

var current_hp: int = -1
var current_mp: int = -1

var total_souls: int = 0

var current_enemy_data: EnemyData

var current_level: int = 1 

var current_enemy_party_data: Array[EnemyData] = []

func register_defeated_enemy(enemy_id: String) -> void:
	if enemy_id != "" and not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)
	defeated_enemy_id = enemy_id

func is_enemy_defeated(enemy_id: String) -> bool:
	return defeated_enemies.has(enemy_id) or defeated_enemy_id == enemy_id

func add_souls(amount: int) -> void:
	total_souls += amount

func spend_souls(amount: int) -> bool:
	if total_souls >= amount:
		total_souls -= amount
		return true
	return false

func sync_stats_from_game_manager(stats: CharacterStats) -> void:
	if current_hp <= 0 or current_mp < 0:
		current_hp = stats.max_hp
		current_mp = stats.max_mp
	stats.current_hp = current_hp
	stats.current_mp = current_mp

func save_stats_to_game_manager(stats: CharacterStats) -> void:
	current_hp = stats.current_hp
	current_mp = stats.current_mp
