extends CanvasLayer
class_name PauseMenu

# --- CONTAINER PRINCIPAL DA UI ---
@onready var main_container: Control = $CenterContainer

# --- REFERÊNCIAS DOS NÓS DO MENU PRINCIPAL ---
@onready var btn_new_game: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnNewGame
@onready var btn_save: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnSave
@onready var btn_continue: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnContinue
@onready var btn_config: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnConfig
@onready var btn_quit: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnQuit

# --- REFERÊNCIAS DO MODAL DE SLOTS ---
@onready var slots_panel: CanvasLayer = $SlotsPanel
@onready var panel_label: Label = $SlotsPanel/SlotsControl/NinePatchRect/PanelLabel
@onready var slot1_btn: Button = $SlotsPanel/SlotsControl/NinePatchRect/SlotsVBox/Slot1Button
@onready var slot2_btn: Button = $SlotsPanel/SlotsControl/NinePatchRect/SlotsVBox/Slot2Button
@onready var slot3_btn: Button = $SlotsPanel/SlotsControl/NinePatchRect/SlotsVBox/Slot3Button
@onready var btn_back: Button = $SlotsPanel/SlotsControl/NinePatchRect/SlotsVBox/BtnBack

enum SlotMode { SAVE, LOAD }
var current_slot_mode: SlotMode = SlotMode.SAVE

var is_open: bool = false
var original_button_texts: Dictionary = {}

const CONTROLS_POPUP: PackedScene = preload("res://ui/components/ControlsPopup.tscn")

func _ready() -> void:
	add_to_group("PauseMenu")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if main_container: main_container.hide()
	if slots_panel: slots_panel.hide()
	_setup_button_focus_effects()
	_connect_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if slots_panel and slots_panel.visible:
			_close_slots_panel()
		else:
			toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_open = !is_open
	if is_open:
		if main_container: main_container.show()
		get_tree().paused = true
		await get_tree().process_frame
		if is_instance_valid(btn_new_game):
			btn_new_game.grab_focus()
	else:
		if main_container: main_container.hide()
		if slots_panel: slots_panel.hide()
		get_tree().paused = false

func hide_for_screenshot() -> void:
	if main_container: main_container.hide()
	if slots_panel: slots_panel.hide()

func restore_after_screenshot() -> void:
	if main_container: main_container.show()
	if slots_panel: slots_panel.show()

func _setup_button_focus_effects() -> void:
	var buttons = [btn_new_game, btn_save, btn_continue, btn_config, btn_quit, slot1_btn, slot2_btn, slot3_btn, btn_back]
	for btn in buttons:
		if is_instance_valid(btn):
			btn.focus_mode = Control.FOCUS_ALL
			btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			btn.add_theme_font_size_override("font_size", 16)
			btn.mouse_entered.connect(func(): btn.grab_focus())
			btn.focus_entered.connect(func():
				var inner_label: Label = btn.get_node_or_null("HBoxContainer/Label")
				if inner_label:
					if not original_button_texts.has(inner_label):
						original_button_texts[inner_label] = inner_label.text
					inner_label.text = "> " + original_button_texts[inner_label]
					inner_label.add_theme_color_override("font_color", Color.YELLOW)
				else:
					if not original_button_texts.has(btn):
						original_button_texts[btn] = btn.text
					btn.text = "> " + original_button_texts[btn]
					btn.add_theme_color_override("font_color", Color.YELLOW)
					btn.add_theme_color_override("font_focus_color", Color.YELLOW)
					btn.add_theme_color_override("font_hover_color", Color.YELLOW)
					btn.add_theme_color_override("font_hover_pressed_color", Color.YELLOW)
			)
			btn.focus_exited.connect(func():
				var inner_label: Label = btn.get_node_or_null("HBoxContainer/Label")
				if inner_label:
					if original_button_texts.has(inner_label):
						inner_label.text = original_button_texts[inner_label]
					inner_label.remove_theme_color_override("font_color")
				else:
					if original_button_texts.has(btn):
						btn.text = original_button_texts[btn]
					btn.remove_theme_color_override("font_color")
					btn.remove_theme_color_override("font_focus_color")
					btn.remove_theme_color_override("font_hover_color")
					btn.remove_theme_color_override("font_hover_pressed_color")
			)

func _connect_buttons() -> void:
	if btn_new_game: btn_new_game.pressed.connect(_on_new_game_pressed)
	if btn_save: btn_save.pressed.connect(_on_save_pressed)
	if btn_continue: btn_continue.pressed.connect(_on_continue_pressed)
	if btn_config: btn_config.pressed.connect(_on_config_pressed)
	if btn_quit: btn_quit.pressed.connect(_on_quit_pressed)
	if slot1_btn: slot1_btn.pressed.connect(func(): _handle_slot_click(1))
	if slot2_btn: slot2_btn.pressed.connect(func(): _handle_slot_click(2))
	if slot3_btn: slot3_btn.pressed.connect(func(): _handle_slot_click(3))
	if btn_back: btn_back.pressed.connect(_close_slots_panel)

func _on_new_game_pressed() -> void:
	_show_confirmation_dialog(
		"Iniciar novo jogo?\n[color=red]O progresso atual não salvo será perdido![/color]",
		func(): _start_new_game(),
		btn_new_game
	)

func _start_new_game() -> void:
	GameManager.disable_all_overworld_enemies()
	toggle_pause_menu()
	GameManager.current_enemy_data = null
	GameManager.current_enemy_party_data.clear()
	GameManager.total_souls = 0
	GameManager.total_coins = 0
	GameManager.current_hp = -1
	GameManager.current_mp = -1
	GameManager.inventory.clear()
	GameManager.owned_equipments.clear()
	GameManager.equipped_weapon = null
	GameManager.equipped_armor = null
	GameManager.defeated_enemy_id = ""
	GameManager.defeated_enemies.clear()
	GameManager.returning_from_battle = false
	GameManager.player_map_position = Vector2.ZERO
	SceneTransition.fade_to_battle("res://levels/floresta.tscn")

func _on_save_pressed() -> void:
	current_slot_mode = SlotMode.SAVE
	if panel_label: panel_label.text = "Salvar Jogo"
	_open_slots_panel()

func _on_continue_pressed() -> void:
	current_slot_mode = SlotMode.LOAD
	if panel_label: panel_label.text = "Carregar Jogo"
	_open_slots_panel()

func _on_config_pressed() -> void:
	var popup := CONTROLS_POPUP.instantiate()
	get_tree().root.add_child(popup)
	popup.tree_exited.connect(func():
		if is_instance_valid(btn_config):
			btn_config.grab_focus()
	)

func _on_quit_pressed() -> void:
	toggle_pause_menu()
	get_tree().quit()

func _open_slots_panel() -> void:
	_update_slot_buttons_info()
	if slots_panel: slots_panel.show()
	await get_tree().process_frame
	if is_instance_valid(slot1_btn):
		slot1_btn.grab_focus()

func _close_slots_panel() -> void:
	if slots_panel: slots_panel.hide()
	await get_tree().process_frame
	var return_target = btn_save if current_slot_mode == SlotMode.SAVE else btn_continue
	if is_instance_valid(return_target):
		return_target.grab_focus()

func _update_slot_buttons_info() -> void:
	var slot_buttons = [slot1_btn, slot2_btn, slot3_btn]
	for i in range(slot_buttons.size()):
		var slot_idx = i + 1
		var btn = slot_buttons[i]
		if is_instance_valid(btn):
			var info = GameManager.get_slot_info(slot_idx)
			var label_text = ""
			var tex_rect: TextureRect = btn.get_node_or_null("HBoxContainer/Icon")
			var inner_label: Label = btn.get_node_or_null("HBoxContainer/Label")
			if info.get("exists", false):
				var date_str = info.get("save_date", "Sem Data")
				label_text = "Slot " + str(slot_idx) + " [" + date_str + "]"
				var thumb = GameManager.get_slot_thumbnail(slot_idx)
				if tex_rect and thumb:
					tex_rect.texture = thumb
					tex_rect.show()
				elif tex_rect:
					tex_rect.hide()
			else:
				label_text = "Slot " + str(slot_idx) + " - [ Vazio ]"
				if tex_rect:
					tex_rect.hide()
			if inner_label:
				original_button_texts[inner_label] = label_text
				if btn.has_focus():
					inner_label.text = "> " + label_text
				else:
					inner_label.text = label_text
			else:
				original_button_texts[btn] = label_text
				if btn.has_focus():
					btn.text = "> " + label_text
				else:
					btn.text = label_text

func _handle_slot_click(slot_index: int) -> void:
	var info = GameManager.get_slot_info(slot_index)
	var slot_buttons = [slot1_btn, slot2_btn, slot3_btn]
	var current_btn = slot_buttons[slot_index - 1] if slot_index - 1 < slot_buttons.size() else null
	if current_slot_mode == SlotMode.SAVE:
		if info.get("exists", false):
			_show_confirmation_dialog(
				"Sobrescrever o Slot " + str(slot_index) + "?",
				func(): _execute_save(slot_index),
				current_btn
			)
		else:
			_execute_save(slot_index)
	else:
		if info.get("exists", false):
			_show_confirmation_dialog(
				"Carregar Slot " + str(slot_index) + "?\n[color=red]O progresso atual não salvo será perdido![/color]",
				func(): _execute_load(slot_index),
				current_btn
			)
		else:
			GameManager.load_game(slot_index)

func _execute_save(slot_index: int) -> void:
	await GameManager.save_game(slot_index)
	_update_slot_buttons_info()
	var slot_buttons = [slot1_btn, slot2_btn, slot3_btn]
	if slot_index - 1 < slot_buttons.size() and is_instance_valid(slot_buttons[slot_index - 1]):
		var clicked_btn = slot_buttons[slot_index - 1]
		var tex_rect: TextureRect = clicked_btn.get_node_or_null("HBoxContainer/Icon")
		if tex_rect:
			tex_rect.texture = GameManager.get_slot_thumbnail(slot_index)
			tex_rect.show()
		clicked_btn.grab_focus()

func _execute_load(slot_index: int) -> void:
	GameManager.disable_all_overworld_enemies()
	toggle_pause_menu()
	GameManager.load_game(slot_index)

func _show_confirmation_dialog(message_text: String, on_confirm: Callable, return_focus_node: Control = null) -> void:
	var canvas = CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.layer = 150
	var viewport_size = get_viewport().get_visible_rect().size
	var root_control = Control.new()
	root_control.custom_minimum_size = viewport_size
	root_control.size = viewport_size
	canvas.add_child(root_control)
	var center_container = CenterContainer.new()
	center_container.custom_minimum_size = viewport_size
	center_container.size = viewport_size
	root_control.add_child(center_container)
	var panel = NinePatchRect.new()
	panel.texture = load("res://ui/textures/menu-5.png")
	panel.patch_margin_left = 8
	panel.patch_margin_top = 8
	panel.patch_margin_right = 8
	panel.patch_margin_bottom = 8
	panel.custom_minimum_size = Vector2(260, 110)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center_container.add_child(panel)
	var margin = MarginContainer.new()
	margin.custom_minimum_size = Vector2(260, 110)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[center]" + message_text + "[/center]"
	label.fit_content = true
	label.scroll_active = false
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.custom_minimum_size = Vector2(236, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 16)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(hbox)
	var button_style = load("res://ui/button_theme.tres") as StyleBox
	var btn_yes = Button.new()
	btn_yes.text = "Sim"
	btn_yes.focus_mode = Control.FOCUS_ALL
	btn_yes.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn_yes.custom_minimum_size = Vector2(64, 24)
	var btn_no = Button.new()
	btn_no.text = "Não"
	btn_no.focus_mode = Control.FOCUS_ALL
	btn_no.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn_no.custom_minimum_size = Vector2(64, 24)
	hbox.add_child(btn_yes)
	hbox.add_child(btn_no)
	for btn in [btn_yes, btn_no]:
		if button_style:
			btn.add_theme_stylebox_override("normal", button_style)
			btn.add_theme_stylebox_override("pressed", button_style)
			btn.add_theme_stylebox_override("hover", button_style)
			btn.add_theme_stylebox_override("disabled", button_style)
			btn.add_theme_stylebox_override("focus", button_style)
		var orig = btn.text
		btn.mouse_entered.connect(func(): btn.grab_focus())
		btn.focus_entered.connect(func():
			btn.text = "> " + orig
			btn.add_theme_color_override("font_color", Color.YELLOW)
			btn.add_theme_color_override("font_focus_color", Color.YELLOW)
			btn.add_theme_color_override("font_hover_color", Color.YELLOW)
		)
		btn.focus_exited.connect(func():
			btn.text = orig
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_focus_color")
			btn.remove_theme_color_override("font_hover_color")
		)
	btn_yes.pressed.connect(func():
		canvas.queue_free()
		on_confirm.call()
	)
	btn_no.pressed.connect(func():
		canvas.queue_free()
		if is_instance_valid(return_focus_node):
			return_focus_node.grab_focus()
	)
	get_tree().root.add_child(canvas)
	await get_tree().process_frame
	btn_no.grab_focus()
