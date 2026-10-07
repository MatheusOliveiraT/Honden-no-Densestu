extends Node
class_name BattleManager

enum BattleState { START, TURN_CHECK, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }
var current_state: BattleState = BattleState.START

var turn_queue: Array[Node] = []
var current_character: Node = null

@onready var player_party: Array[Node] = get_tree().get_nodes_in_group("Players")
@onready var enemy_party: Array[Node] = get_tree().get_nodes_in_group("Enemies")

func _ready() -> void:
	start_battle()

func start_battle() -> void:
	current_state = BattleState.START
	print("=== INÍCIO DA BATALHA ===")
	for player in player_party:
		if player.stats: player.stats.initialize()
	for enemy in enemy_party:
		if enemy.stats: enemy.stats.initialize()
	generate_turn_queue()
	current_state = BattleState.TURN_CHECK
	process_next_turn()

func generate_turn_queue() -> void:
	turn_queue.clear()
	for player in player_party:
		if player.stats and player.stats.current_hp > 0:
			turn_queue.append(player)
	for enemy in enemy_party:
		if enemy.stats and enemy.stats.current_hp > 0:
			turn_queue.append(enemy)
	turn_queue.sort_custom(func(a, b): return a.stats.get_current_speed() > b.stats.get_current_speed())

func process_next_turn() -> void:
	if turn_queue.is_empty():
		generate_turn_queue()
		if turn_queue.is_empty():
			check_battle_end()
			return
	current_character = turn_queue.pop_front()
	if current_character.stats.current_hp <= 0:
		process_next_turn()
		return
	print("\n--- Vez de: ", current_character.stats.character_name, " ---")
	current_character.stats.process_turn_statuses()
	if current_character.stats.current_hp <= 0:
		print(current_character.stats.character_name, " sucumbiu aos efeitos de status.")
		check_battle_end()
		return
	if not current_character.stats.can_take_action():
		print(current_character.stats.character_name, " está paralisado e perdeu o turno!")
		await get_tree().create_timer(1.0).timeout
		process_next_turn()
		return
	if current_character in player_party:
		current_state = BattleState.PLAYER_TURN
		enable_player_ui()
	else:
		current_state = BattleState.ENEMY_TURN
		execute_enemy_ai()

func enable_player_ui() -> void:
	print("Aguardando comando do Jogador... (Atacar / Defender / Item)")

func player_choose_attack(target: Node) -> void:
	if current_state != BattleState.PLAYER_TURN: return
	execute_attack(current_character, target)
	end_character_turn()

func execute_enemy_ai() -> void:
	await get_tree().create_timer(1.0).timeout
	var valid_targets = player_party.filter(func(p): return p.stats.current_hp > 0)
	if not valid_targets.is_empty():
		var target = valid_targets.pick_random()
		execute_attack(current_character, target)
	end_character_turn()

func execute_attack(attacker: Node, defender: Node) -> void:
	var atk_value = attacker.stats.get_current_attack()
	print(attacker.stats.character_name, " ataca ", defender.stats.character_name, " com força ", atk_value)
	defender.stats.take_damage(atk_value)
	print(defender.stats.character_name, " ficou com ", defender.stats.current_hp, " de HP.")

func end_character_turn() -> void:
	if check_battle_end():
		return
	current_state = BattleState.TURN_CHECK
	process_next_turn()

func check_battle_end() -> bool:
	var players_alive = player_party.any(func(p): return p.stats.current_hp > 0)
	var enemies_alive = enemy_party.any(func(e): return e.stats.current_hp > 0)
	if not enemies_alive:
		current_state = BattleState.WIN
		print("\n=== VITÓRIA! Todos os inimigos foram derrotados. ===")
		return true
	elif not players_alive:
		current_state = BattleState.LOSE
		print("\n=== DERROTA! A sua equipe caiu em combate. ===")
		return true
	return false
