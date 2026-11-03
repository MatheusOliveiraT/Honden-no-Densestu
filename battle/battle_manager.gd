extends Node
class_name BattleManager

var log_label: RichTextLabel
var log_scroll: ScrollContainer

enum BattleState { START, TURN_CHECK, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }
var current_state: BattleState = BattleState.START

var turn_queue: Array[Node] = []
var current_character: Node = null

@export var player_scene: PackedScene

@onready var player_spawn: Marker2D = $"../SpawnPositions/PlayerSpawn"
@export var enemy_spawns: Array[Marker2D] = []

var player_party: Array[Node] = []
var enemy_party: Array[Node] = []

var ui_canvas: CanvasLayer
var main_action_container: VBoxContainer
var sub_menu_container: VBoxContainer

var defending_characters: Array[Node] = []

func _ready() -> void:
	_create_temp_ui()
	await _spawn_combatants()
	start_battle()

func _spawn_combatants() -> void:
	if enemy_spawns.is_empty():
		var spawns_container = get_node_or_null("../SpawnPositions")
		if spawns_container:
			for spawn_node in spawns_container.get_children():
				if spawn_node is Marker2D and "EnemySpawn" in spawn_node.name:
					enemy_spawns.append(spawn_node)
		enemy_spawns.sort_custom(func(a, b): return a.name < b.name)
		
	if player_scene and player_spawn:
		var player_instance = player_scene.instantiate()
		player_party.append(player_instance)
		player_instance.add_to_group("Players")
		get_parent().add_child.call_deferred(player_instance)
		
	var party_data = GameManager.current_enemy_party_data
	if party_data.is_empty() and GameManager.current_enemy_data:
		party_data.append(GameManager.current_enemy_data)
		
	for i in range(party_data.size()):
		var data = party_data[i]
		var enemy_instance = BattleEnemy.new()
		var sprite = AnimatedSprite2D.new()
		sprite.sprite_frames = data.sprite_frames
		sprite.scale = data.battle_sprite_scale
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		enemy_instance.add_child(sprite)
		if data.stats:
			enemy_instance.stats = data.stats.duplicate()
		enemy_instance.set("enemy_data", data)
		enemy_party.append(enemy_instance)
		enemy_instance.add_to_group("Enemies")
		get_parent().add_child.call_deferred(enemy_instance)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("em_batalha"):
			sprite.play("em_batalha")
			
	await get_tree().process_frame
	
	for player in player_party:
		if is_instance_valid(player) and player_spawn:
			player.global_position = player_spawn.global_position.round()
			player.set_physics_process(false)
			if player.has_method("set_in_battle"):
				player.set_in_battle(true)
				
	for i in range(enemy_party.size()):
		if is_instance_valid(enemy_party[i]):
			if i < enemy_spawns.size() and enemy_spawns[i] != null:
				enemy_party[i].global_position = enemy_spawns[i].global_position.round()
			elif not enemy_spawns.is_empty() and enemy_spawns[0] != null:
				enemy_party[i].global_position = (enemy_spawns[0].global_position + Vector2(i * 32, 0)).round()

func _create_temp_ui() -> void:
	ui_canvas = CanvasLayer.new()
	ui_canvas.layer = 50
	add_child(ui_canvas)
	
	# LOG DE BATALHA COM TAMANHO E POSIÇÃO EM PIXELS INTEIROS
	log_scroll = ScrollContainer.new()
	log_scroll.position = Vector2(8, 6).round()
	log_scroll.size = Vector2(368, 52).round()
	log_scroll.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ui_canvas.add_child(log_scroll)

	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.fit_content = true
	log_label.custom_minimum_size = Vector2(350, 0)
	log_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# FONTE 16PX NATIVA COM RESPIRO VERTICAL ENTRE LINHAS
	log_label.add_theme_font_size_override("normal_font_size", 16)
	log_label.add_theme_font_size_override("bold_font_size", 16)
	log_label.add_theme_constant_override("line_separation", 2)
	log_scroll.add_child(label_or_log())

	# MENUS DE AÇÃO COM TAMANHOS ADEQUADOS À FONTE 16PX
	main_action_container = VBoxContainer.new()
	main_action_container.position = Vector2(8, 120).round()
	main_action_container.size = Vector2(110, 88).round()
	main_action_container.add_theme_constant_override("separation", 2)
	ui_canvas.add_child(main_action_container)
	main_action_container.hide()
	
	sub_menu_container = VBoxContainer.new()
	sub_menu_container.position = Vector2(124, 120).round()
	sub_menu_container.size = Vector2(160, 88).round()
	sub_menu_container.add_theme_constant_override("separation", 2)
	ui_canvas.add_child(sub_menu_container)
	sub_menu_container.hide()

func label_or_log() -> RichTextLabel:
	return log_label

func log_msg(text: String) -> void:
	if log_label:
		log_label.append_text(text + "\n")
		await get_tree().process_frame
		if log_scroll:
			var v_scroll = log_scroll.get_v_scroll_bar()
			v_scroll.value = v_scroll.max_value

func start_battle() -> void:
	current_state = BattleState.START
	log_msg("[b][color=yellow]=== INÍCIO DA BATALHA ===[/color][/b]")
	for player in player_party:
		if "stats" in player and player.stats: 
			player.stats.initialize()
	for enemy in enemy_party:
		if "stats" in enemy and enemy.stats: 
			enemy.stats.initialize()
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
			await check_battle_end()
			return
	current_character = turn_queue.pop_front()
	if current_character.stats.current_hp <= 0:
		process_next_turn()
		return
	if current_character in defending_characters:
		defending_characters.erase(current_character)
	log_msg("\n--- Vez de: " + current_character.stats.character_name + " ---")
	current_character.stats.process_turn_statuses()
	if current_character.stats.current_hp <= 0:
		log_msg(current_character.stats.character_name + " sucumbiu aos efeitos de status.")
		_play_combatant_animation(current_character, "derrotado")
		await check_battle_end()
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

func enable_player_ui() -> void:
	_clear_container(main_action_container)
	_clear_container(sub_menu_container)
	sub_menu_container.hide()
	
	var btn_attack = _create_pixel_button("Atacar")
	btn_attack.pressed.connect(_show_target_selection)
	main_action_container.add_child(btn_attack)
	
	var btn_magic = _create_pixel_button("Magia (" + str(current_character.stats.current_mp) + " MP)")
	btn_magic.pressed.connect(_show_magic_menu)
	main_action_container.add_child(btn_magic)
	
	var btn_item = _create_pixel_button("Item")
	btn_item.pressed.connect(_show_item_menu)
	main_action_container.add_child(btn_item)
	
	var btn_defend = _create_pixel_button("Defender")
	btn_defend.pressed.connect(_player_choose_defend)
	main_action_container.add_child(btn_defend)
	
	main_action_container.show()
	_focus_element(btn_attack)

func _show_target_selection() -> void:
	_clear_container(sub_menu_container)
	var valid_enemies = enemy_party.filter(func(e): return e.stats.current_hp > 0)
	var first_btn: Button = null
	
	for enemy in valid_enemies:
		var btn = _create_pixel_button(enemy.stats.character_name + " (" + str(enemy.stats.current_hp) + " HP)")
		btn.pressed.connect(func(): player_choose_attack(enemy))
		sub_menu_container.add_child(btn)
		if first_btn == null: first_btn = btn
		
	_add_back_button(main_action_container.get_child(0))
	sub_menu_container.show()
	_focus_element(first_btn)

func _show_magic_menu() -> void:
	_clear_container(sub_menu_container)
	var spells = GameManager.equipped_spells
	var first_btn: Button = null
	
	if spells.is_empty():
		var btn_empty = _create_pixel_button("Sem magias")
		btn_empty.disabled = true
		sub_menu_container.add_child(btn_empty)
		first_btn = btn_empty
	else:
		for spell in spells:
			var btn = _create_pixel_button(spell.spell_name + " (" + str(spell.mp_cost) + " MP)")
			btn.disabled = current_character.stats.current_mp < spell.mp_cost
			btn.pressed.connect(func(): _on_spell_selected(spell))
			sub_menu_container.add_child(btn)
			if first_btn == null: first_btn = btn
			
	_add_back_button(main_action_container.get_child(1))
	sub_menu_container.show()
	_focus_element(first_btn)

func _on_spell_selected(spell: SpellData) -> void:
	if spell.type == SpellData.SpellType.HEAL or spell.type == SpellData.SpellType.BUFF:
		_cast_spell(spell, current_character)
	else:
		_select_spell_target(spell)

func _select_spell_target(spell: SpellData) -> void:
	_clear_container(sub_menu_container)
	var valid_enemies = enemy_party.filter(func(e): return e.stats.current_hp > 0)
	var first_btn: Button = null
	
	for enemy in valid_enemies:
		var btn = _create_pixel_button(spell.spell_name + " -> " + enemy.stats.character_name)
		btn.pressed.connect(func(): _cast_spell(spell, enemy))
		sub_menu_container.add_child(btn)
		if first_btn == null: first_btn = btn
		
	_add_back_button(sub_menu_container.get_child(0))
	sub_menu_container.show()
	_focus_element(first_btn)

func _cast_spell(spell: SpellData, target: Node) -> void:
	_hide_all_ui()
	current_character.stats.current_mp -= spell.mp_cost
	match spell.type:
		SpellData.SpellType.HEAL:
			target.stats.heal(spell.base_value)
			log_msg(current_character.stats.character_name + " usou " + spell.spell_name + " e recuperou " + str(spell.base_value) + " HP!")
		SpellData.SpellType.DAMAGE:
			log_msg(current_character.stats.character_name + " usou " + spell.spell_name + " em " + target.stats.character_name + "!")
			await _apply_damage_and_animate(target, spell.base_value)
		SpellData.SpellType.BUFF, SpellData.SpellType.DEBUFF:
			log_msg(current_character.stats.character_name + " usou " + spell.spell_name + " em " + target.stats.character_name + "!")
	if spell.applies_status and "stats" in target and target.stats:
		target.stats.apply_status(spell.status_type, spell.status_duration, spell.status_potency)
		log_msg("Efeito de status aplicado a " + target.stats.character_name + "!")
	end_character_turn()

func _show_item_menu() -> void:
	_clear_container(sub_menu_container)
	var first_btn: Button = null
	
	if GameManager.inventory.is_empty():
		var btn_empty = _create_pixel_button("Sem itens")
		btn_empty.disabled = true
		sub_menu_container.add_child(btn_empty)
		first_btn = btn_empty
	else:
		for item in GameManager.inventory.keys():
			var count = GameManager.inventory[item]
			var btn = _create_pixel_button(item.item_name + " x" + str(count))
			btn.pressed.connect(func():
				_use_item_in_battle(item)
			)
			sub_menu_container.add_child(btn)
			if first_btn == null: first_btn = btn
			
	_add_back_button(main_action_container.get_child(2))
	sub_menu_container.show()
	_focus_element(first_btn)

func _use_item_in_battle(item: ItemData) -> void:
	if GameManager.remove_item(item, 1):
		var msg = item.use(current_character.stats)
		log_msg(msg)
		end_character_turn()

func _player_choose_defend() -> void:
	defending_characters.append(current_character)
	log_msg(current_character.stats.character_name + " assumiu postura defensiva!")
	end_character_turn()

func _add_back_button(return_target: Button = null) -> void:
	var btn_back = _create_pixel_button("<- Voltar")
	btn_back.pressed.connect(func(): 
		sub_menu_container.hide()
		if is_instance_valid(return_target):
			return_target.grab_focus()
		elif main_action_container.visible and main_action_container.get_child_count() > 0:
			main_action_container.get_child(0).grab_focus()
	)
	sub_menu_container.add_child(btn_back)

func _create_pixel_button(btn_text: String) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(0, 16)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_font_size_override("font_size", 16)
	return btn

func _focus_element(btn: Button) -> void:
	await get_tree().process_frame
	if is_instance_valid(btn) and not btn.disabled:
		btn.grab_focus()

func player_choose_attack(target: Node) -> void:
	if current_state != BattleState.PLAYER_TURN: return
	_hide_all_ui()
	await execute_attack(current_character, target)
	end_character_turn()

func execute_enemy_ai() -> void:
	await get_tree().create_timer(1.0).timeout
	var valid_player_targets = player_party.filter(func(p): return p.stats.current_hp > 0)
	if valid_player_targets.is_empty():
		end_character_turn()
		return
	var player_target = valid_player_targets.pick_random()
	var enemy_data: EnemyData = current_character.get("enemy_data")
	var spells: Array[SpellData] = []
	if enemy_data and not enemy_data.spells.is_empty():
		spells = enemy_data.spells
	var heal_spells = spells.filter(func(s): return s.type == SpellData.SpellType.HEAL and current_character.stats.current_mp >= s.mp_cost)
	var offensive_spells = spells.filter(func(s): return s.type != SpellData.SpellType.HEAL and current_character.stats.current_mp >= s.mp_cost)
	if not heal_spells.is_empty():
		var injured_allies = enemy_party.filter(
			func(e): return e.stats.current_hp > 0 and (float(e.stats.current_hp) / float(e.stats.max_hp)) < 0.5
		)
		if not injured_allies.is_empty():
			injured_allies.sort_custom(
				func(a, b): return (float(a.stats.current_hp) / a.stats.max_hp) < (float(b.stats.current_hp) / b.stats.max_hp)
			)
			var target_to_heal = injured_allies[0]
			var chosen_heal_spell = heal_spells.pick_random()
			await _enemy_cast_spell(chosen_heal_spell, target_to_heal)
			end_character_turn()
			return
	if not offensive_spells.is_empty() and randf() < 0.5:
		var chosen_offensive_spell = offensive_spells.pick_random()
		await _enemy_cast_spell(chosen_offensive_spell, player_target)
		end_character_turn()
		return
	await execute_attack(current_character, player_target)
	end_character_turn()
	
func _enemy_cast_spell(spell: SpellData, target: Node) -> void:
	current_character.stats.current_mp -= spell.mp_cost
	match spell.type:
		SpellData.SpellType.HEAL:
			var ally_target = enemy_party.filter(func(e): return e.stats.current_hp > 0).pick_random()
			ally_target.stats.heal(spell.base_value)
			log_msg(current_character.stats.character_name + " usou [color=magenta]" + spell.spell_name + "[/color] em " + ally_target.stats.character_name + "!")
		SpellData.SpellType.DAMAGE:
			log_msg(current_character.stats.character_name + " usou [color=magenta]" + spell.spell_name + "[/color] em " + target.stats.character_name + "!")
			await _apply_damage_and_animate(target, spell.base_value)
		SpellData.SpellType.BUFF:
			current_character.stats.apply_status(spell.status_type, spell.status_duration, spell.status_potency)
			log_msg(current_character.stats.character_name + " usou [color=magenta]" + spell.spell_name + "[/color]!")
		SpellData.SpellType.DEBUFF:
			log_msg(current_character.stats.character_name + " usou [color=magenta]" + spell.spell_name + "[/color] em " + target.stats.character_name + "!")
	if spell.applies_status and "stats" in target and target.stats:
		target.stats.apply_status(spell.status_type, spell.status_duration, spell.status_potency)
		log_msg("Efeito [color=yellow]" + spell.spell_name + "[/color] afetou " + target.stats.character_name + "!")

func execute_attack(attacker: Node, defender: Node) -> void:
	var atk_value = attacker.stats.get_current_attack()
	var def_value = defender.stats.get_current_defense()
	if defender in defending_characters:
		def_value = int(def_value * 1.5) + 5
	var damage = max(1, atk_value - def_value)
	log_msg(attacker.stats.character_name + " ataca " + defender.stats.character_name + " causando [color=red]" + str(damage) + " de dano![/color]")
	await _apply_damage_and_animate(defender, damage)
	log_msg(defender.stats.character_name + " ficou com " + str(defender.stats.current_hp) + " de HP.")

func _apply_damage_and_animate(target: Node, damage: int) -> void:
	target.stats.current_hp = max(0, target.stats.current_hp - damage)
	_play_combatant_animation(target, "levou_dano")
	await get_tree().create_timer(0.6).timeout
	if target.stats.current_hp <= 0:
		_play_combatant_animation(target, "levou_dano")
	else:
		_play_combatant_animation(target, "em_batalha")

func _play_combatant_animation(combatant: Node, anim_name: String) -> void:
	if not is_instance_valid(combatant): return
	var sprite: AnimatedSprite2D = combatant.get_node_or_null("AnimatedSprite2D")
	if not sprite:
		for child in combatant.get_children():
			if child is AnimatedSprite2D:
				sprite = child
				break
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func end_character_turn() -> void:
	_hide_all_ui()
	if await check_battle_end():
		return
	current_state = BattleState.TURN_CHECK
	process_next_turn()

func check_battle_end() -> bool:
	if player_party.is_empty() or enemy_party.is_empty():
		return false
	var players_alive = player_party.any(func(p): return "stats" in p and p.stats and p.stats.current_hp > 0)
	var enemies_alive = enemy_party.any(func(e): return "stats" in e and e.stats and e.stats.current_hp > 0)
	if not enemies_alive or not players_alive:
		for player in player_party:
			if "stats" in player and player.stats:
				GameManager.save_stats_to_game_manager(player.stats)
		if not enemies_alive:
			current_state = BattleState.WIN
			_hide_all_ui()
			log_msg("\n[b][color=green]=== VITÓRIA! ===[/color][/b]")
			var total_earned_souls: int = 0
			var total_earned_coins: int = 0
			for i in range(enemy_party.size()):
				var enemy = enemy_party[i]
				var data: EnemyData = enemy.get("enemy_data")
				if not data and i < GameManager.current_enemy_party_data.size():
					data = GameManager.current_enemy_party_data[i]
				if not data:
					data = GameManager.current_enemy_data
				if data:
					total_earned_souls += data.souls_reward
					total_earned_coins += data.coins_reward
			if total_earned_souls > 0 or total_earned_coins > 0:
				GameManager.add_souls(total_earned_souls)
				GameManager.add_coins(total_earned_coins)
				log_msg("[color=cyan]+ " + str(total_earned_souls) + " Almas e + " + str(total_earned_coins) + " Moedas![/color]")
			else:
				log_msg("[color=yellow]Nenhuma recompensa obtida.[/color]")
			if GameManager.defeated_enemy_id != "":
				GameManager.register_defeated_enemy(GameManager.defeated_enemy_id)
			await get_tree().create_timer(1.5).timeout
			SceneTransition.fade_to_battle(GameManager.current_map_scene_path)
		else:
			current_state = BattleState.LOSE
			_hide_all_ui()
			log_msg("\n[b][color=red]=== DERROTA! ===[/color][/b]")
		return true
	return false

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _hide_all_ui() -> void:
	if main_action_container: main_action_container.hide()
	if sub_menu_container: sub_menu_container.hide()
