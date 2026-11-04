extends CanvasLayer
class_name InventoryMenuHub

enum TabType { GERAL, ITENS, SKILLS, EQUIP }
var current_tab: TabType = TabType.GERAL

@onready var main_control: Control = $Control

@onready var painel_geral: MarginContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral
@onready var painel_itens: MarginContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelItens
@onready var painel_skills: MarginContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelSkills
@onready var painel_equip: MarginContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelEquip

@onready var item_list_container: VBoxContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelItens/ScrollContainer/ItemList
@onready var skill_list_container: VBoxContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelSkills/ScrollContainer/SkillList
@onready var equip_list_container: VBoxContainer = $Control/CenterContainer/HBoxContainer/esquerda/PainelEquip/ScrollContainer/EquipList

@onready var label_hp_atual: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/SEIJI/INFOseiji/HBoxContainer/label_hp
@onready var label_hp_max: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/SEIJI/INFOseiji/HBoxContainer/label_hp3

@onready var label_mp_atual: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/SEIJI/INFOseiji/HBoxContainer2/label_mp4
@onready var label_mp_max: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/SEIJI/INFOseiji/HBoxContainer2/label_mp6

@onready var label_nome_arma: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/MarginContainer/INFOarma/HBoxContainer2/label_nome_arma
@onready var label_lvl_arma: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/MarginContainer/INFOarma/HBoxContainer2/label_lvl_arma

@onready var label_nome_armadura: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/MarginContainer/INFOarmadura/HBoxContainer2/label_nome_armadura
@onready var label_lvl_armadura: Label = $Control/CenterContainer/HBoxContainer/esquerda/PainelGeral/VBoxContainer/MarginContainer/INFOarmadura/HBoxContainer2/label_lvl_armadura

@onready var btn_general: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Geral
@onready var btn_itens: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Itens
@onready var btn_skills: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Skills
@onready var btn_equip: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Equip
@onready var btn_exit: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Exit

@onready var label_almas: Label = %label_almas
@onready var label_moedas: Label = %label_moedas

var is_open: bool = false
var original_button_texts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	if main_control: main_control.hide()
	_setup_button_focus_effects()
	_connect_buttons()

func _setup_button_focus_effects() -> void:
	var buttons = [btn_general, btn_itens, btn_skills, btn_equip, btn_exit]
	for btn in buttons:
		if is_instance_valid(btn):
			original_button_texts[btn] = btn.text
			btn.focus_mode = Control.FOCUS_ALL
			btn.mouse_entered.connect(func(): btn.grab_focus())
			btn.focus_entered.connect(func():
				btn.text = "> " + original_button_texts[btn]
				btn.add_theme_color_override("font_color", Color.YELLOW)
				btn.add_theme_color_override("font_focus_color", Color.YELLOW)
				btn.add_theme_color_override("font_hover_color", Color.YELLOW)
				btn.add_theme_color_override("font_hover_pressed_color", Color.YELLOW)
				if btn == btn_general: _switch_tab(TabType.GERAL, false)
				elif btn == btn_itens: _switch_tab(TabType.ITENS, false)
				elif btn == btn_skills: _switch_tab(TabType.SKILLS, false)
				elif btn == btn_equip: _switch_tab(TabType.EQUIP, false)
			)
			btn.focus_exited.connect(func():
				btn.text = original_button_texts[btn]
				btn.remove_theme_color_override("font_color")
				btn.remove_theme_color_override("font_focus_color")
				btn.remove_theme_color_override("font_hover_color")
				btn.remove_theme_color_override("font_hover_pressed_color")
			)

func _connect_buttons() -> void:
	if btn_general: btn_general.pressed.connect(_on_general_pressed)
	if btn_itens: btn_itens.pressed.connect(_on_itens_pressed)
	if btn_skills: btn_skills.pressed.connect(_on_skills_pressed)
	if btn_equip: btn_equip.pressed.connect(_on_equip_pressed)
	if btn_exit: btn_exit.pressed.connect(_on_exit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		toggle_menu()
		get_viewport().set_input_as_handled()
	if is_open and (event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel")):
		toggle_menu()
		get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	is_open = !is_open
	if is_open:
		_update_player_stats()
		_update_currencies()
		_switch_tab(TabType.GERAL, false)
		show()
		if main_control: main_control.show()
		get_tree().paused = true
		await get_tree().process_frame
		if is_instance_valid(btn_general):
			btn_general.grab_focus()
	else:
		if main_control: main_control.hide()
		hide()
		get_tree().paused = false

func _switch_tab(tab: TabType, auto_focus_list: bool = false) -> void:
	current_tab = tab
	if painel_geral: painel_geral.hide()
	if painel_itens: painel_itens.hide()
	if painel_skills: painel_skills.hide()
	if painel_equip: painel_equip.hide()
	match current_tab:
		TabType.GERAL:
			if painel_geral: painel_geral.show()
			_update_player_stats()
		TabType.ITENS:
			if painel_itens: painel_itens.show()
			_render_items_list(0, auto_focus_list)
		TabType.SKILLS:
			if painel_skills: painel_skills.show()
			_render_skills_list(0, auto_focus_list)
		TabType.EQUIP:
			if painel_equip: painel_equip.show()
			_render_equip_list(0, auto_focus_list)

func _render_items_list(target_index: int = 0, should_focus: bool = false) -> void:
	if not item_list_container: return
	_clear_container(item_list_container)
	if GameManager.inventory.is_empty():
		_add_empty_label(item_list_container, "Sem itens consumíveis.")
		if should_focus and is_instance_valid(btn_itens):
			btn_itens.grab_focus()
		return
	var items = GameManager.inventory.keys()
	var created_buttons: Array[Button] = []
	for i in range(items.size()):
		var item = items[i]
		var count = GameManager.inventory[item]
		var btn = _create_pixel_button(item.item_name + " x" + str(count))
		btn.pressed.connect(func():
			var player = get_tree().get_first_node_in_group("Players")
			if player and "stats" in player and player.stats:
				var msg = item.use(player.stats)
				GameManager.remove_item(item, 1)
				GameManager.show_message_box(msg)
				_update_currencies()
				_render_items_list(i, true)
		)
		item_list_container.add_child(btn)
		created_buttons.append(btn)
	if should_focus:
		_restore_list_focus(created_buttons, target_index)

func _render_skills_list(target_index: int = 0, should_focus: bool = false) -> void:
	if not skill_list_container: return
	_clear_container(skill_list_container)
	if GameManager.unlocked_spells.is_empty():
		_add_empty_label(skill_list_container, "Nenhuma magia desbloqueada.")
		if should_focus and is_instance_valid(btn_skills):
			btn_skills.grab_focus()
		return
	var created_buttons: Array[Button] = []
	for i in range(GameManager.unlocked_spells.size()):
		var spell = GameManager.unlocked_spells[i]
		var is_equipped = GameManager.equipped_spells.has(spell)
		var label_text = ("[E] " if is_equipped else "") + spell.spell_name + " (" + str(spell.mp_cost) + " MP)"
		var btn = _create_pixel_button(label_text)
		btn.pressed.connect(func():
			if GameManager.equipped_spells.has(spell):
				GameManager.unequip_spell(spell)
			else:
				GameManager.equip_spell(spell)
			_render_skills_list(i, true)
		)
		skill_list_container.add_child(btn)
		created_buttons.append(btn)
	if should_focus:
		_restore_list_focus(created_buttons, target_index)

func _render_equip_list(target_index: int = 0, should_focus: bool = false) -> void:
	if not equip_list_container: return
	_clear_container(equip_list_container)
	if GameManager.owned_equipments.is_empty():
		_add_empty_label(equip_list_container, "Sem equipamentos.")
		if should_focus and is_instance_valid(btn_equip):
			btn_equip.grab_focus()
		return
	var created_buttons: Array[Button] = []
	for i in range(GameManager.owned_equipments.size()):
		var equip = GameManager.owned_equipments[i]
		var is_equipped = (GameManager.equipped_weapon == equip or GameManager.equipped_armor == equip)
		var label_text = ("[E] " if is_equipped else "") + equip.item_name + " LV " + str(equip.level)
		var btn = _create_pixel_button(label_text)
		btn.pressed.connect(func():
			var player = get_tree().get_first_node_in_group("Players")
			if player and "stats" in player:
				if is_equipped:
					GameManager.unequip_slot(equip.slot, player.stats)
				else:
					GameManager.equip_item(equip, player.stats)
				_render_equip_list(i, true)
		)
		equip_list_container.add_child(btn)
		created_buttons.append(btn)
	if should_focus:
		_restore_list_focus(created_buttons, target_index)

func _restore_list_focus(buttons: Array[Button], target_index: int) -> void:
	if buttons.is_empty(): return
	var safe_index = clamp(target_index, 0, buttons.size() - 1)
	await get_tree().process_frame
	if is_instance_valid(buttons[safe_index]):
		buttons[safe_index].grab_focus()

func _update_player_stats() -> void:
	var player = get_tree().get_first_node_in_group("Players")
	var stats: CharacterStats = null
	if player and "stats" in player and player.stats:
		stats = player.stats
	elif "player_stats" in GameManager:
		stats = GameManager.player_stats
	if stats:
		if label_hp_atual: label_hp_atual.text = str(stats.current_hp)
		if label_hp_max: label_hp_max.text = str(stats.max_hp)
		if label_mp_atual: label_mp_atual.text = str(stats.current_mp)
		if label_mp_max: label_mp_max.text = str(stats.max_mp)
	if label_lvl_arma and label_nome_arma: 
		if GameManager.equipped_weapon != null:
			label_nome_arma.text = GameManager.equipped_weapon.item_name + " - LV "
			label_lvl_arma.text = str(GameManager.equipped_weapon.level)
		else:
			label_nome_arma.text = "N/A."
			label_lvl_arma.text = ""
	if label_lvl_armadura and label_nome_armadura:
		if GameManager.equipped_armor != null:
			label_nome_armadura.text = GameManager.equipped_armor.item_name + " - LV "
			label_lvl_armadura.text = str(GameManager.equipped_armor.level)
		else:
			label_nome_armadura.text = "N/A."
			label_lvl_armadura.text = ""

func _update_currencies() -> void:
	if label_almas:
		if "total_souls" in GameManager: label_almas.text = str(GameManager.total_souls)
	if label_moedas:
		if "total_coins" in GameManager: label_moedas.text = str(GameManager.total_coins)

func _on_general_pressed() -> void:
	_switch_tab(TabType.GERAL, false)

func _on_itens_pressed() -> void:
	_switch_tab(TabType.ITENS, true)

func _on_skills_pressed() -> void:
	_switch_tab(TabType.SKILLS, true)

func _on_equip_pressed() -> void:
	_switch_tab(TabType.EQUIP, true)

func _on_exit_pressed() -> void:
	toggle_menu()

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _add_empty_label(container: Container, text_msg: String) -> void:
	var empty_lbl = Label.new()
	empty_lbl.text = text_msg
	empty_lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	empty_lbl.add_theme_font_size_override("font_size", 16)
	container.add_child(empty_lbl)

func _create_pixel_button(btn_text: String) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(0, 16)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_font_size_override("font_size", 16)
	return btn
