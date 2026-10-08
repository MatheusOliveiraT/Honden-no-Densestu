extends Node
class_name BattleManager

var log_label: RichTextLabel
var log_scroll: ScrollContainer

enum BattleState { START, TURN_CHECK, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }
var current_state: BattleState = BattleState.START

var turn_queue: Array[Node] = []
var current_character: Node = null

@onready var player_party: Array[Node] = get_tree().get_nodes_in_group("Players")
@onready var enemy_party: Array[Node] = get_tree().get_nodes_in_group("Enemies")

# --- ELEMENTOS DE UI VIA CÓDIGO ---
var ui_canvas: CanvasLayer
var main_action_container: VBoxContainer
var sub_menu_container: VBoxContainer

# Controle de estado de defesa temporária
var defending_characters: Array[Node] = []

func _ready() -> void:
	_create_temp_ui()
	start_battle()

func _create_temp_ui() -> void:
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	
	# 1. Painel de Log de Texto (no topo da tela)
	log_scroll = ScrollContainer.new()
	log_scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	log_scroll.position = Vector2(20, 20)
	log_scroll.size = Vector2(600, 150)
	ui_canvas.add_child(log_scroll)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.fit_content = true
	log_label.custom_minimum_size = Vector2(580, 0)
	log_scroll.add_child(log_label)
	
	# 2. Menu Principal (Atacar, Magia, Item, Defender)
	main_action_container = VBoxContainer.new()
	main_action_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	main_action_container.position = Vector2(50, -200)
	main_action_container.size = Vector2(200, 150)
	ui_canvas.add_child(main_action_container)
	main_action_container.hide()
	
	# 3. Sub-Menu (Lista de Inimigos / Magias / Itens)
	sub_menu_container = VBoxContainer.new()
	sub_menu_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	sub_menu_container.position = Vector2(270, -200)
	sub_menu_container.size = Vector2(250, 150)
	ui_canvas.add_child(sub_menu_container)
	sub_menu_container.hide()

func log_msg(text: String) -> void:
	# Imprime no console de debug da Godot
	print(text)
	
	if log_label:
		# Adiciona o texto no label
		log_label.append_text(text + "\n")
		
		# Aguarda 1 frame para que a Godot recalcule o tamanho do texto no container
		await get_tree().process_frame
		
		# Ajusta a barra de rolagem vertical para o valor máximo (final do log)
		if log_scroll:
			var v_scroll = log_scroll.get_v_scroll_bar()
			v_scroll.value = v_scroll.max_value

func start_battle() -> void:
	current_state = BattleState.START
	log_msg("[b][color=yellow]=== INÍCIO DA BATALHA ===[/color][/b]")
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
	_hide_all_ui()
	
	if turn_queue.is_empty():
		generate_turn_queue()
		if turn_queue.is_empty():
			check_battle_end()
			return
			
	current_character = turn_queue.pop_front()
	if current_character.stats.current_hp <= 0:
		process_next_turn()
		return
		
	# Reseta a defesa se o personagem defender no turno anterior
	if current_character in defending_characters:
		defending_characters.erase(current_character)
		
	log_msg("\n--- Vez de: " + current_character.stats.character_name + " ---")
	current_character.stats.process_turn_statuses()
	
	if current_character.stats.current_hp <= 0:
		log_msg(current_character.stats.character_name + " sucumbiu aos efeitos de status.")
		check_battle_end()
		return
		
	if not current_character.stats.can_take_action():
		log_msg(current_character.stats.character_name + " está paralisado e perdeu o turno!")
		await get_tree().create_timer(1.0).timeout
		process_next_turn()
		return
		
	if current_character in player_party:
		current_state = BattleState.PLAYER_TURN
		enable_player_ui()
	else:
		current_state = BattleState.ENEMY_TURN
		execute_enemy_ai()

# --- INTERFACE E AÇÕES DO JOGADOR ---

func enable_player_ui() -> void:
	_clear_container(main_action_container)
	_clear_container(sub_menu_container)
	sub_menu_container.hide()
	
	# 1. Botão ATACAR
	var btn_attack = Button.new()
	btn_attack.text = "⚔️ Atacar"
	btn_attack.pressed.connect(_show_target_selection)
	main_action_container.add_child(btn_attack)
	
	# 2. Botão MAGIA
	var btn_magic = Button.new()
	btn_magic.text = "🪄 Magia (" + str(current_character.stats.current_mp) + " MP)"
	btn_magic.pressed.connect(_show_magic_menu)
	main_action_container.add_child(btn_magic)
	
	# 3. Botão ITEM
	var btn_item = Button.new()
	btn_item.text = "🧪 Item"
	btn_item.pressed.connect(_show_item_menu)
	main_action_container.add_child(btn_item)
	
	# 4. Botão DEFENDER
	var btn_defend = Button.new()
	btn_defend.text = "🛡️ Defender"
	btn_defend.pressed.connect(_player_choose_defend)
	main_action_container.add_child(btn_defend)
	
	main_action_container.show()

# Sub-menu 1: Seleção de Alvo para Ataque
func _show_target_selection() -> void:
	_clear_container(sub_menu_container)
	var valid_enemies = enemy_party.filter(func(e): return e.stats.current_hp > 0)
	
	for enemy in valid_enemies:
		var btn = Button.new()
		btn.text = enemy.stats.character_name + " (HP: " + str(enemy.stats.current_hp) + ")"
		btn.pressed.connect(func(): player_choose_attack(enemy))
		sub_menu_container.add_child(btn)
		
	_add_back_button()
	sub_menu_container.show()

# Sub-menu 2: Seleção de Magias
func _show_magic_menu() -> void:
	_clear_container(sub_menu_container)
	
	# Exemplo de magia: Bola de Fogo (Custa 15 MP)
	var btn_fireball = Button.new()
	btn_fireball.text = "Bola de Fogo (15 MP)"
	btn_fireball.disabled = current_character.stats.current_mp < 15
	btn_fireball.pressed.connect(func(): _select_magic_target("Bola de Fogo", 15, 25))
	sub_menu_container.add_child(btn_fireball)
	
	# Exemplo de magia: Cura (Custa 10 MP)
	var btn_heal = Button.new()
	btn_heal.text = "Cura (10 MP)"
	btn_heal.disabled = current_character.stats.current_mp < 10
	btn_heal.pressed.connect(func(): _cast_heal(10, 30))
	sub_menu_container.add_child(btn_heal)
	
	_add_back_button()
	sub_menu_container.show()

# Sub-menu de Alvos para Magia de Ataque
func _select_magic_target(spell_name: String, mp_cost: int, damage: int) -> void:
	_clear_container(sub_menu_container)
	var valid_enemies = enemy_party.filter(func(e): return e.stats.current_hp > 0)
	
	for enemy in valid_enemies:
		var btn = Button.new()
		btn.text = "Usar " + spell_name + " em " + enemy.stats.character_name
		btn.pressed.connect(func():
			current_character.stats.current_mp -= mp_cost
			log_msg(current_character.stats.character_name + " usou " + spell_name + " em " + enemy.stats.character_name + " causando " + str(damage) + " de dano!")
			enemy.stats.current_hp = max(0, enemy.stats.current_hp - damage)
			end_character_turn()
		)
		sub_menu_container.add_child(btn)
		
	_add_back_button()

# Magia de Cura direcionada a si mesmo ou ao grupo
func _cast_heal(mp_cost: int, heal_amount: int) -> void:
	current_character.stats.current_mp -= mp_cost
	current_character.stats.heal(heal_amount)
	log_msg(current_character.stats.character_name + " usou Cura e recuperou " + str(heal_amount) + " de HP!")
	end_character_turn()

# Sub-menu 3: Seleção de Itens
func _show_item_menu() -> void:
	_clear_container(sub_menu_container)
	
	# Exemplo: Porção de HP
	var btn_potion = Button.new()
	btn_potion.text = "Pção de Vida (+50 HP)"
	btn_potion.pressed.connect(func():
		current_character.stats.heal(50)
		log_msg(current_character.stats.character_name + " usou uma Poção de Vida e recuperou 50 de HP!")
		end_character_turn()
	)
	sub_menu_container.add_child(btn_potion)
	
	_add_back_button()
	sub_menu_container.show()

# Ação Defender
func _player_choose_defend() -> void:
	defending_characters.append(current_character)
	log_msg(current_character.stats.character_name + " assumiu postura defensiva (+50% de Defesa neste turno)!")
	end_character_turn()

# Botão Voltar para o Sub-Menu
func _add_back_button() -> void:
	var btn_back = Button.new()
	btn_back.text = "⬅️ Voltar"
	btn_back.pressed.connect(func(): sub_menu_container.hide())
	sub_menu_container.add_child(btn_back)

# --- EXECUÇÃO DE ATAQUES E CÁLCULO DE DANO ---

func player_choose_attack(target: Node) -> void:
	if current_state != BattleState.PLAYER_TURN: return
	_hide_all_ui()
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
	var def_value = defender.stats.get_current_defense()
	
	# Se o alvo estiver defendendo, dobra a defesa dele temporariamente
	if defender in defending_characters:
		def_value = int(def_value * 1.5) + 5
		
	var damage = max(1, atk_value - def_value)
	defender.stats.current_hp = max(0, defender.stats.current_hp - damage)
	
	log_msg(attacker.stats.character_name + " ataca " + defender.stats.character_name + " causando [color=red]" + str(damage) + " de dano![/color]")
	log_msg(defender.stats.character_name + " ficou com " + str(defender.stats.current_hp) + " de HP.")

func end_character_turn() -> void:
	_hide_all_ui()
	if check_battle_end():
		return
	current_state = BattleState.TURN_CHECK
	process_next_turn()

func check_battle_end() -> bool:
	var players_alive = player_party.any(func(p): return p.stats.current_hp > 0)
	var enemies_alive = enemy_party.any(func(e): return e.stats.current_hp > 0)
	
	if not enemies_alive:
		current_state = BattleState.WIN
		_hide_all_ui()
		log_msg("\n[b][color=green]=== VITÓRIA! Todos os inimigos foram derrotados. ===[/color][/b]")
		return true
	elif not players_alive:
		current_state = BattleState.LOSE
		_hide_all_ui()
		log_msg("\n[b][color=red]=== DERROTA! A sua equipe caiu em combate. ===[/color][/b]")
		return true
	return false

# --- UTILITÁRIOS DE UI ---

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _hide_all_ui() -> void:
	if main_action_container: main_action_container.hide()
	if sub_menu_container: sub_menu_container.hide()
