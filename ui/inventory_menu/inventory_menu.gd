extends CanvasLayer
class_name InventoryMenu

@onready var panel: Panel = $Panel
@onready var item_list_container: VBoxContainer = $Panel/ScrollContainer/ItemListContainer
@onready var description_label: Label = $Panel/DescriptionLabel

var action_menu_container: VBoxContainer
var selected_item: ItemData = null
var is_open: bool = false
var is_busy: bool = false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	panel.hide()
	_create_action_menu_container()

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
		_refresh_inventory()
	else:
		_close_sub_menu()
		panel.hide()
		hide()
		get_tree().paused = false

func _refresh_inventory() -> void:
	_close_sub_menu()
	for child in item_list_container.get_children():
		child.queue_free()
	description_label.text = "Selecione um item..."
	if GameManager.inventory.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Inventário Vazio"
		empty_lbl.add_theme_font_size_override("font_size", 8)
		item_list_container.add_child(empty_lbl)
		return
	var first_btn: Button = null
	for item in GameManager.inventory.keys():
		var count = GameManager.inventory[item]
		var btn = _create_pixel_button(item.item_name + " x" + str(count))
		btn.focus_entered.connect(func(): 
			if action_menu_container and not action_menu_container.visible:
				description_label.text = item.description
		)
		btn.pressed.connect(func(): _open_item_actions(item, btn))
		item_list_container.add_child(btn)
		if first_btn == null:
			first_btn = btn
	await get_tree().process_frame
	if is_instance_valid(first_btn):
		first_btn.grab_focus()

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
	var btn_back = _create_pixel_button("<- Voltar")
	btn_back.pressed.connect(func(): 
		_close_sub_menu()
		if is_instance_valid(origin_btn):
			origin_btn.grab_focus()
	)
	action_menu_container.add_child(btn_back)
	action_menu_container.show()
	await get_tree().process_frame
	btn_use.grab_focus()

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
		_refresh_inventory()

func _drop_selected_item() -> void:
	if not selected_item or is_busy: return
	is_busy = true
	var item_name = selected_item.item_name
	GameManager.remove_item(selected_item, 1)
	description_label.text = item_name + " foi descartado."
	_close_sub_menu()
	await get_tree().create_timer(1.5).timeout
	is_busy = false
	_refresh_inventory()

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
