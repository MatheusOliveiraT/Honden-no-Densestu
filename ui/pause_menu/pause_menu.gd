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

func _setup_button_focus_effects() -> void:
	var buttons = [btn_new_game, btn_save, btn_continue, btn_config, btn_quit, slot1_btn, slot2_btn, slot3_btn, btn_back]
	for btn in buttons:
		if is_instance_valid(btn):
			original_button_texts[btn] = btn.text
			btn.focus_mode = Control.FOCUS_ALL
			btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			btn.add_theme_font_size_override("font_size", 16)
			btn.mouse_entered.connect(func(): btn.grab_focus())
			btn.focus_entered.connect(func():
				btn.text = "> " + original_button_texts[btn]
				btn.add_theme_color_override("font_color", Color.YELLOW)
				btn.add_theme_color_override("font_focus_color", Color.YELLOW)
				btn.add_theme_color_override("font_hover_color", Color.YELLOW)
				btn.add_theme_color_override("font_hover_pressed_color", Color.YELLOW)
			)
			btn.focus_exited.connect(func():
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
			if info.get("exists", false):
				var date_str = info.get("save_date", "Sem Data")
				var souls = info.get("total_souls", 0)
				label_text = "Slot " + str(slot_idx) + " [" + date_str + "] - " + str(souls) + " Almas"
			else:
				label_text = "Slot " + str(slot_idx) + " - [ Vazio ]"
			original_button_texts[btn] = label_text
			btn.text = label_text

func _handle_slot_click(slot_index: int) -> void:
	if current_slot_mode == SlotMode.SAVE:
		GameManager.save_game(slot_index)
		_update_slot_buttons_info()
		await get_tree().process_frame
		var slot_buttons = [slot1_btn, slot2_btn, slot3_btn]
		if slot_index - 1 < slot_buttons.size() and is_instance_valid(slot_buttons[slot_index - 1]):
			slot_buttons[slot_index - 1].grab_focus()
	else:
		GameManager.disable_all_overworld_enemies()
		toggle_pause_menu()
		GameManager.load_game(slot_index)
