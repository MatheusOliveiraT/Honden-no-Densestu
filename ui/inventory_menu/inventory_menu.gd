extends CanvasLayer
class_name InventoryMenu

@onready var panel: Panel = $Panel
@onready var item_list_container: VBoxContainer = $Panel/ScrollContainer/ItemListContainer
@onready var description_label: Label = $Panel/DescriptionLabel

@onready var label_alma: Label = %label_almas
@onready var label_moeda: Label = %label_moedas

var is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # jogo pausado
	hide()
	panel.hide()
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		toggle_menu()

func toggle_menu() -> void:
	is_open = !is_open
	if is_open:
		_refresh_inventory()
		_refresh_currencies()
		panel.show()
		show()
		get_tree().paused = true
	else:
		panel.hide()
		hide()
		get_tree().paused = false

func _refresh_currencies() -> void:
	if label_alma and "almas" in GameManager:
		label_alma.text = str(GameManager.almas)
	if label_moeda and "moedas" in GameManager:
		label_moeda.text = str(GameManager.moedas)

func _refresh_inventory() -> void:
	for child in item_list_container.get_children():
		child.queue_free()
	description_label.text = "Selecione um item..."
	if GameManager.inventory.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Inventário Vazio"
		empty_lbl.add_theme_font_size_override("font_size", 8)
		item_list_container.add_child(empty_lbl)
		return
	for item in GameManager.inventory.keys():
		var count = GameManager.inventory[item]
		var btn = Button.new()
		btn.text = item.item_name + " x" + str(count)
		btn.custom_minimum_size = Vector2(0, 14)
		btn.add_theme_font_size_override("font_size", 8)
		btn.focus_entered.connect(func(): description_label.text = item.description)
		btn.pressed.connect(func(): _use_item(item))
		item_list_container.add_child(btn)

func _use_item(item: ItemData) -> void:
	var player = get_tree().get_first_node_in_group("Players")
	if player and "stats" in player and player.stats:
		var msg = item.use(player.stats)
		description_label.text = msg
		GameManager.remove_item(item, 1)
		GameManager.save_stats_to_game_manager(player.stats)
		await get_tree().create_timer(1).timeout
		_refresh_inventory()
