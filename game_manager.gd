extends Node

# Controle de posição e cena
var player_map_position: Vector2 = Vector2.ZERO
var returning_from_battle: bool = false
var defeated_enemy_id: String = ""

# --- PERSISTÊNCIA DE STATUS DO JOGADOR ---
var current_hp: int = -1
var current_mp: int = -1

var current_enemy_data: EnemyData

func sync_stats_from_game_manager(stats: CharacterStats) -> void:
	if current_hp <= 0 or current_mp < 0:
		current_hp = stats.max_hp
		current_mp = stats.max_mp
	stats.current_hp = current_hp
	stats.current_mp = current_mp

func save_stats_to_game_manager(stats: CharacterStats) -> void:
	current_hp = stats.current_hp
	current_mp = stats.current_mp
