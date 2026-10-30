extends CanvasLayer
class_name InventoryMenu

enum TabType { ITEMS, EQUIPMENTS, SPELLS }
var current_tab: TabType = TabType.ITEMS

@onready var panel: Panel = $Panel
@onready var item_list_container: VBoxContainer = $Panel/ScrollContainer/ItemListContainer
@onready var description_label: Label = $Panel/DescriptionLabel

var tab_bar_container: HBoxContainer
var action_menu_container: VBoxContainer

var selected_item: ItemData = null
var selected_equipment: EquipmentData = null
var selected_spell: SpellData = null

var is_open: bool = false
var is_busy: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	panel.hide()
	_create_tab_bar()
	_create_action_menu_container()

func _create_tab_bar() -> void:
	tab_bar_container = HBoxContainer.new()
	tab_bar_container.position = Vector2(8, 6)
	tab_bar_container.size = Vector2(224, 16)
	tab_bar_container.add_theme_constant_override("separation", 2)
	panel.add_child(tab_bar_container)

func _create_action_menu_container() -> void:
	action_menu_container = VBoxContainer.new()
	action_menu_container.position = Vector2(130, 60)
	action_menu_container.size = Vector2(100, 60)
	action_menu_container.add_theme_constant_override("separation", 2)
	panel.add_child(action_menu_container)
	action_menu_container.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario") and not is_busy:
		toggle_menu()

func toggle_menu() -> void:
	is_open = !is_open
	if is_open:
		panel.show()
		show()
		get_tree().paused = true
		_render_tab_buttons()
		_refresh_current_tab()
	else:
		_close_sub_menu()
		panel.hide()
		hide()
		get_tree().paused = false

func _render_tab_buttons() -> void:
	_clear_container(tab_bar_container)
	var tabs = [
		{"type": TabType.ITEMS, "label": "Itens"},
		{"type": TabType.EQUIPMENTS, "label": "Equips"},
		{"type": TabType.SPELLS, "label": "Magias"}
	]
	var active_tab_btn: Button = null
	for tab_info in tabs:
		var tab_type = tab_info["type"]
		var btn = _create_pixel_button(tab_info["label"])
		btn.focus_entered.connect(func():
			if current_tab != tab_type and not is_busy:
				current_tab = tab_type
				_refresh_current_tab(false)
		)
		btn.pressed.connect(func():
			_focus_first_item_in_list()
		)
		tab_bar_container.add_child(btn)
		if tab_type == current_tab:
			active_tab_btn = btn
	await get_tree().process_frame
	if is_instance_valid(active_tab_btn):
		active_tab_btn.grab_focus()

func _refresh_current_tab(auto_focus_list: bool = true) -> void:
	_close_sub_menu()
	_clear_container(item_list_container)
	match current_tab:
		TabType.ITEMS:
			_render_items_tab(auto_focus_list)
		TabType.EQUIPMENTS:
			_render_equipments_tab(auto_focus_list)
		TabType.SPELLS:
			_render_spells_tab(auto_focus_list)

func _render_items_tab(auto_focus_list: bool) -> void:
	description_label.text = "Selecione um item..."
	if GameManager.inventory.is_empty():
		_add_empty_label("Sem consumíveis")
		return
	var first_btn: Button = null
	for item in GameManager.inventory.keys():
		var count = GameManager.inventory[item]
		var btn = _create_pixel_button(item.item_name + " x" + str(count))
		btn.focus_entered.connect(func():
			if not action_menu_container.visible:
				description_label.text = item.description
		)
		btn.pressed.connect(func(): _open_item_actions(item, btn))
		item_list_container.add_child(btn)
		if first_btn == null: first_btn = btn
	if auto_focus_list:
		_focus_element(first_btn)

func _open_item_actions(item: ItemData, origin_btn: Button) -> void:
	selected_item = item
	_clear_container(action_menu_container)
	description_label.text = item.description
	var btn_use = _create_pixel_button("Usar")
	btn_use.pressed.connect(func(): _use_selected_item())
	action_menu_container.add_child(btn_use)
	var btn_drop = _create_pixel_button("Descartar")
	btn_drop.pressed.connect(func(): _drop_selected_item())
	action_menu_container.add_child(btn_drop)
	_add_back_button(origin_btn)
	action_menu_container.show()
	_focus_element(btn_use)

func _use_selected_item() -> void:
	if not selected_item or is_busy: return
	var player = get_tree().get_first_node_in_group("Players")
	if player and "stats" in player and player.stats:
		is_busy = true
		var msg = selected_item.use(player.stats)
		description_label.text = msg
		GameManager.remove_item(selected_item, 1)
		GameManager.save_stats_to_game_manager(player.stats)
		_close_sub_menu()
		await get_tree().create_timer(2.0).timeout
		is_busy = false
		_refresh_current_tab(true)

func _drop_selected_item() -> void:
	if not selected_item or is_busy: return
	is_busy = true
	var item_name = selected_item.item_name
	GameManager.remove_item(selected_item, 1)
	description_label.text = item_name + " foi descartado."
	_close_sub_menu()
	await get_tree().create_timer(1.5).timeout
	is_busy = false
	_refresh_current_tab(true)

func _render_equipments_tab(auto_focus_list: bool) -> void:
	description_label.text = "Selecione um equipamento..."
	if GameManager.owned_equipments.is_empty():
		_add_empty_label("Sem equipamentos")
		return
	var first_btn: Button = null
	for equip in GameManager.owned_equipments:
		var is_equipped = (GameManager.equipped_weapon == equip or GameManager.equipped_armor == equip)
		var label_text = ("[E] " if is_equipped else "") + equip.item_name
		var btn = _create_pixel_button(label_text)
		btn.focus_entered.connect(func():
			if not action_menu_container.visible:
				description_label.text = equip.description + "\nAtk: +" + str(equip.attack_bonus) + " Def: +" + str(equip.defense_bonus)
		)
		btn.pressed.connect(func(): _open_equipment_actions(equip, btn))
		item_list_container.add_child(btn)
		if first_btn == null: first_btn = btn
	if auto_focus_list:
		_focus_element(first_btn)

func _open_equipment_actions(equip: EquipmentData, origin_btn: Button) -> void:
	selected_equipment = equip
	_clear_container(action_menu_container)
	description_label.text = equip.description
	var is_equipped = (GameManager.equipped_weapon == equip or GameManager.equipped_armor == equip)
	var player = get_tree().get_first_node_in_group("Players")
	if is_equipped:
		var btn_unequip = _create_pixel_button("Desequipar")
		btn_unequip.pressed.connect(func():
			if player and "stats" in player:
				GameManager.unequip_slot(equip.slot, player.stats)
			_close_sub_menu()
			_refresh_current_tab(true)
		)
		action_menu_container.add_child(btn_unequip)
	else:
		var btn_equip = _create_pixel_button("Equipar")
		btn_equip.pressed.connect(func():
			if player and "stats" in player:
				GameManager.equip_item(equip, player.stats)
			_close_sub_menu()
			_refresh_current_tab(true)
		)
		action_menu_container.add_child(btn_equip)
	_add_back_button(origin_btn)
	action_menu_container.show()
	_focus_element(action_menu_container.get_child(0))

func _render_spells_tab(auto_focus_list: bool, target_focus_index: int = 0) -> void:
	description_label.text = "Equipe até 4 magias (" + str(GameManager.equipped_spells.size()) + "/4)..."
	if GameManager.unlocked_spells.is_empty():
		_add_empty_label("Nenhuma magia")
		return
	var spell_buttons: Array[Button] = []
	for i in range(GameManager.unlocked_spells.size()):
		var spell = GameManager.unlocked_spells[i]
		var is_equipped = GameManager.equipped_spells.has(spell)
		var label_text = ("[E] " if is_equipped else "") + spell.spell_name + " (" + str(spell.mp_cost) + " MP)"
		var btn = _create_pixel_button(label_text)
		btn.focus_entered.connect(func():
			if not action_menu_container.visible:
				description_label.text = spell.description
		)
		btn.pressed.connect(func(): _toggle_spell_equip(spell, i))
		item_list_container.add_child(btn)
		spell_buttons.append(btn)
	if auto_focus_list or target_focus_index >= 0:
		var index_to_focus = clamp(target_focus_index, 0, spell_buttons.size() - 1)
		if not spell_buttons.is_empty():
			_focus_element(spell_buttons[index_to_focus])

func _toggle_spell_equip(spell: SpellData, clicked_index: int) -> void:
	var msg_feedback = ""
	if GameManager.equipped_spells.has(spell):
		GameManager.unequip_spell(spell)
		msg_feedback = spell.spell_name + " removida das magias ativas."
	else:
		if GameManager.equipped_spells.size() >= 4:
			description_label.text = "Limite atingido! Desequipe uma magia primeiro."
			return
		GameManager.equip_spell(spell)
		msg_feedback = spell.spell_name + " equipada com sucesso!"
	_close_sub_menu()
	_clear_container(item_list_container)
	_render_spells_tab(false, clicked_index)
	description_label.text = msg_feedback

func _focus_first_item_in_list() -> void:
	if item_list_container.get_child_count() > 0:
		var first_child = item_list_container.get_child(0)
		if first_child is Button:
			first_child.grab_focus()

func _add_back_button(origin_btn: Button) -> void:
	var btn_back = _create_pixel_button("<- Voltar")
	btn_back.pressed.connect(func():
		_close_sub_menu()
		if is_instance_valid(origin_btn):
			origin_btn.grab_focus()
	)
	action_menu_container.add_child(btn_back)

func _add_empty_label(text_msg: String) -> void:
	var empty_lbl = Label.new()
	empty_lbl.text = text_msg
	empty_lbl.add_theme_font_size_override("font_size", 8)
	item_list_container.add_child(empty_lbl)

func _focus_element(btn: Button) -> void:
	await get_tree().process_frame
	if is_instance_valid(btn):
		btn.grab_focus()

func _close_sub_menu() -> void:
	if action_menu_container:
		_clear_container(action_menu_container)
		action_menu_container.hide()

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

func _create_pixel_button(btn_text: String) -> Button:
	var btn = Button.new()
	btn.text = btn_text
	btn.custom_minimum_size = Vector2(0, 14)
	btn.add_theme_font_size_override("font_size", 8)
	return btn
