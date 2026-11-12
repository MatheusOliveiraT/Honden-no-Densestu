extends Control
class_name MainMenu

@onready var btn_new_game: Button = $CenterContainer/VBoxContainer/MenuBox/ButtonsContainer/BtnNewGame
@onready var btn_continue: Button = $CenterContainer/VBoxContainer/MenuBox/ButtonsContainer/BtnContinue
@onready var btn_config: Button = $CenterContainer/VBoxContainer/MenuBox/ButtonsContainer/BtnConfig
@onready var btn_quit: Button = $CenterContainer/VBoxContainer/MenuBox/ButtonsContainer/BtnQuit
@onready var slots_panel: SlotsPanel = $SlotsPanel

var original_button_texts: Dictionary = {}

const CONTROLS_POPUP: PackedScene = preload("res://ui/components/ControlsPopup.tscn")
const INTRO_CUTSCENE_PATH: String = "res://cutscenes/intro_cutscene/intro_cutscene.tscn"

func _ready() -> void:
	get_tree().paused = false
	if slots_panel:
		slots_panel.require_confirmation = false
		slots_panel.slot_selected.connect(_on_slot_selected)
		slots_panel.closed.connect(_on_slots_panel_closed)
	_setup_button_focus_effects()
	_connect_buttons()
	_update_continue_button_state()
	await get_tree().process_frame
	if is_instance_valid(btn_new_game):
		btn_new_game.grab_focus()

func _update_continue_button_state() -> void:
	var any_save_exists := false
	for i in range(1, 4):
		if GameManager.get_slot_info(i).get("exists", false):
			any_save_exists = true
			break
	if is_instance_valid(btn_continue):
		btn_continue.disabled = not any_save_exists

func _setup_button_focus_effects() -> void:
	var button_style = load("res://ui/button_theme.tres") as StyleBox
	var buttons = [btn_new_game, btn_continue, btn_config, btn_quit]
	for btn in buttons:
		if is_instance_valid(btn):
			btn.focus_mode = Control.FOCUS_ALL
			btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			btn.add_theme_font_size_override("font_size", 16)
			if button_style:
				for state in ["normal", "pressed", "hover", "disabled", "focus"]:
					btn.add_theme_stylebox_override(state, button_style)
			btn.mouse_entered.connect(func():
				if not btn.disabled:
					btn.grab_focus()
			)
			btn.focus_entered.connect(func():
				if not original_button_texts.has(btn):
					original_button_texts[btn] = btn.text
				btn.text = "> " + original_button_texts[btn]
				btn.add_theme_color_override("font_color", Color.YELLOW)
				btn.add_theme_color_override("font_focus_color", Color.YELLOW)
				btn.add_theme_color_override("font_hover_color", Color.YELLOW)
				btn.add_theme_color_override("font_hover_pressed_color", Color.YELLOW)
			)
			btn.focus_exited.connect(func():
				if original_button_texts.has(btn):
					btn.text = original_button_texts[btn]
				btn.remove_theme_color_override("font_color")
				btn.remove_theme_color_override("font_focus_color")
				btn.remove_theme_color_override("font_hover_color")
				btn.remove_theme_color_override("font_hover_pressed_color")
			)

func _connect_buttons() -> void:
	if btn_new_game: btn_new_game.pressed.connect(_on_new_game_pressed)
	if btn_continue: btn_continue.pressed.connect(func(): slots_panel.open(SlotsPanel.SlotMode.LOAD))
	if btn_config: btn_config.pressed.connect(_on_config_pressed)
	if btn_quit: btn_quit.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
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
	GameManager.current_map_scene_path = "res://levels/floresta/floresta.tscn"
	SceneTransition.fade_to_battle(INTRO_CUTSCENE_PATH)

func _on_config_pressed() -> void:
	var popup := CONTROLS_POPUP.instantiate()
	get_tree().root.add_child(popup)
	popup.tree_exited.connect(func():
		if is_instance_valid(btn_config):
			btn_config.grab_focus()
	)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_slots_panel_closed() -> void:
	await get_tree().process_frame
	if is_instance_valid(btn_continue) and not btn_continue.disabled:
		btn_continue.grab_focus()
	elif is_instance_valid(btn_new_game):
		btn_new_game.grab_focus()

func _on_slot_selected(slot_index: int, _mode: SlotsPanel.SlotMode) -> void:
	GameManager.load_game(slot_index)
