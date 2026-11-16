extends CanvasLayer
class_name ShopUI

@onready var title_label: Label = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/HeaderHBox/TitleLabel
@onready var currency_label: Label = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/HeaderHBox/CurrencyLabel
@onready var btn_tab1: Button = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/TabHBox/BtnTab1
@onready var btn_tab2: Button = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/TabHBox/BtnTab2
@onready var items_list: VBoxContainer = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/ScrollContainer/ItemsList
@onready var description_label: RichTextLabel = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var btn_close: Button = $CenterContainer/MainPanel/MarginContainer/VBoxContainer/BtnClose

enum Mode { COINS, SOULS }
var current_mode: Mode = Mode.COINS
var current_tab: int = 0

var stock_items: Array[ItemData] = []
var stock_equipments: Array[EquipmentData] = []
var stock_spells: Array[SpellData] = []

var button_style: StyleBox = preload("res://ui/button_theme.tres")
var original_texts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	description_label.bbcode_enabled = true
	_style_button(btn_tab1)
	_style_button(btn_tab2)
	_style_button(btn_close)
	btn_tab1.pressed.connect(func(): _switch_tab(0))
	btn_tab2.pressed.connect(func(): _switch_tab(1))
	btn_close.pressed.connect(_close_shop)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_close_shop()

func open_coins_shop(title: String, items: Array[ItemData], equips: Array[EquipmentData]) -> void:
	current_mode = Mode.COINS
	title_label.text = title
	stock_items = items
	stock_equipments = equips
	_set_btn_base_text(btn_tab1, "Itens")
	_set_btn_base_text(btn_tab2, "Equipamentos")
	_switch_tab(0)

func open_souls_shop(title: String, spells: Array[SpellData]) -> void:
	current_mode = Mode.SOULS
	title_label.text = title
	stock_spells = spells
	_set_btn_base_text(btn_tab1, "Melhorar Equip.")
	_set_btn_base_text(btn_tab2, "Magias")
	_switch_tab(0)

func _switch_tab(tab_idx: int) -> void:
	current_tab = tab_idx
	_refresh_currency()
	_populate_list()
	await get_tree().process_frame
	if items_list.get_child_count() > 0:
		var first_btn := items_list.get_child(0) as Control
		if is_instance_valid(first_btn):
			first_btn.grab_focus()
	else:
		btn_close.grab_focus()

func _refresh_currency() -> void:
	if current_mode == Mode.COINS:
		currency_label.text = "Moedas: " + str(GameManager.total_coins)
	else:
		currency_label.text = "Almas: " + str(GameManager.total_souls)

func _populate_list() -> void:
	for child in items_list.get_children():
		child.queue_free()
	description_label.text = ""
	if current_mode == Mode.COINS:
		if current_tab == 0:
			_build_coins_items_list()
		else:
			_build_coins_equipments_list()
	else:
		if current_tab == 0:
			_build_souls_upgrade_list()
		else:
			_build_souls_spells_list()

func _build_coins_items_list() -> void:
	for item in stock_items:
		var price: int = item.buy_price if "buy_price" in item else 25
		var owned_qty: int = GameManager.inventory.get(item, 0)
		var label := "%s - %d Moedas (Possui: %d)" % [item.item_name, price, owned_qty]
		var desc: String = item.description if "description" in item else ""
		var btn := _create_entry_button(label, desc)
		btn.pressed.connect(func():
			if GameManager.spend_coins(price):
				GameManager.add_item(item, 1)
				_refresh_currency()
				_populate_list()
			else:
				GameManager.show_message_box("[color=red]Moedas insuficientes![/color]")
		)

func _build_coins_equipments_list() -> void:
	for equip in stock_equipments:
		var price: int = equip.buy_price if "buy_price" in equip else 100
		var already_owned := false
		for owned in GameManager.owned_equipments:
			if owned.get_source_path() == equip.resource_path:
				already_owned = true
				break
		var label := "%s - %s" % [equip.get_display_name(), "[Comprado]" if already_owned else str(price) + " Moedas"]
		var desc: String = equip.description if "description" in equip else ""
		var btn := _create_entry_button(label, desc)
		btn.disabled = already_owned
		btn.pressed.connect(func():
			if GameManager.spend_coins(price):
				var instance := equip.duplicate() as EquipmentData
				instance.source_path = equip.resource_path
				GameManager.add_equipment(instance)
				_refresh_currency()
				_populate_list()
			else:
				GameManager.show_message_box("[color=red]Moedas insuficientes![/color]")
		)

func _build_souls_upgrade_list() -> void:
	for equip in GameManager.owned_equipments:
		var can_up: bool = equip.can_upgrade()
		var cost: int = equip.get_upgrade_cost() if can_up else 0
		var status := ("LV %d -> %d Almas" % [equip.level, cost]) if can_up else "LV MAX"
		var label := "%s [%s]" % [equip.item_name, status]
		var desc := "Nível atual: %d" % equip.level
		var btn := _create_entry_button(label, desc)
		btn.disabled = not can_up
		btn.pressed.connect(func():
			if GameManager.upgrade_equipment(equip):
				_refresh_currency()
				_populate_list()
		)
		
func _build_souls_spells_list() -> void:
	for spell in stock_spells:
		var cost: int = spell.soul_cost if "soul_cost" in spell else 100
		var unlocked: bool = GameManager.unlocked_spells.has(spell)
		var label := "%s - %s" % [spell.spell_name, "[Aprendida]" if unlocked else str(cost) + " Almas"]
		var desc: String = spell.description if "description" in spell else ""
		var btn := _create_entry_button(label, desc)
		btn.disabled = unlocked
		btn.pressed.connect(func():
			if GameManager.spend_souls(cost):
				GameManager.unlock_spell(spell, true)
				_refresh_currency()
				_populate_list()
			else:
				GameManager.show_message_box("[color=red]Almas insuficientes![/color]")
		)

func _create_entry_button(text_str: String, desc_str: String) -> Button:
	var btn := Button.new()
	btn.text = text_str
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn)
	btn.focus_entered.connect(func():
		description_label.text = desc_str
	)
	items_list.add_child(btn)
	return btn

func _set_btn_base_text(btn: Button, text_str: String) -> void:
	original_texts[btn] = text_str
	btn.text = ("> " + text_str) if btn.has_focus() else text_str

func _style_button(btn: Button) -> void:
	btn.focus_mode = Control.FOCUS_ALL
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_font_size_override("font_size", 14)
	if button_style:
		for state in ["normal", "pressed", "hover", "disabled", "focus"]:
			btn.add_theme_stylebox_override(state, button_style)
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			btn.grab_focus()
	)
	btn.focus_entered.connect(func():
		if not original_texts.has(btn):
			original_texts[btn] = btn.text
		btn.text = "> " + original_texts[btn]
		btn.add_theme_color_override("font_color", Color.YELLOW)
		btn.add_theme_color_override("font_focus_color", Color.YELLOW)
		btn.add_theme_color_override("font_hover_color", Color.YELLOW)
	)
	btn.focus_exited.connect(func():
		if original_texts.has(btn):
			btn.text = original_texts[btn]
		btn.remove_theme_color_override("font_color")
		btn.remove_theme_color_override("font_focus_color")
		btn.remove_theme_color_override("font_hover_color")
	)

func _close_shop() -> void:
	get_tree().paused = false
	queue_free()
