extends CanvasLayer
class_name PauseMenu

@onready var main_container: Control = $CenterContainer
@onready var btn_new_game: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnNewGame
@onready var btn_save: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/SaveLoadContainer/BtnSave
@onready var btn_continue: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/SaveLoadContainer/BtnContinue
@onready var btn_config: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnConfig
@onready var btn_main_menu: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnMainMenu
@onready var btn_quit: Button = $CenterContainer/VBoxContainer/NinePatchRect/ButtonsContainer/BtnQuit
@onready var slots_panel: SlotsPanel = $SlotsPanel

var is_open: bool = false
var original_button_texts: Dictionary = {}

const CONTROLS_POPUP: PackedScene = preload("res://ui/components/ControlsPopup.tscn")
const MAIN_MENU_PATH: String = "res://ui/main_menu/main_menu.tscn"

func _ready() -> void:
	add_to_group("PauseMenu")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if main_container: main_container.hide()
	if slots_panel:
		slots_panel.require_confirmation = true
		slots_panel.slot_selected.connect(_on_slot_selected)
		slots_panel.closed.connect(_on_slots_panel_closed)
	_setup_button_focus_effects()
	_connect_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if slots_panel and slots_panel.visible:
			return
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
	var buttons = [btn_new_game, btn_save, btn_continue, btn_config, btn_main_menu, btn_quit]
	for btn in buttons:
		if is_instance_valid(btn):
			btn.focus_mode = Control.FOCUS_ALL
			btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			btn.add_theme_font_size_override("font_size", 16)
			btn.mouse_entered.connect(func(): btn.grab_focus())
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
	if btn_save: btn_save.pressed.connect(func(): slots_panel.open(SlotsPanel.SlotMode.SAVE))
	if btn_continue: btn_continue.pressed.connect(func(): slots_panel.open(SlotsPanel.SlotMode.LOAD))
	if btn_config: btn_config.pressed.connect(_on_config_pressed)
	if btn_main_menu: btn_main_menu.pressed.connect(_on_main_menu_pressed)
	if btn_quit: btn_quit.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
	slots_panel._show_confirmation_dialog(
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
	GameManager.current_map_scene_path = "res://levels/floresta/floresta.tscn"
	SceneTransition.fade_to_battle("res://cutscenes/intro_cutscene/intro_cutscene.tscn")

func _on_config_pressed() -> void:
	var popup := CONTROLS_POPUP.instantiate()
	get_tree().root.add_child(popup)
	popup.tree_exited.connect(func():
		if is_instance_valid(btn_config):
			btn_config.grab_focus()
	)

func _on_main_menu_pressed() -> void:
	slots_panel._show_confirmation_dialog(
		"Voltar ao menu principal?\n[color=red]O progresso atual não salvo será perdido![/color]",
		func(): _return_to_main_menu(),
		btn_main_menu
	)

func _return_to_main_menu() -> void:
	GameManager.disable_all_overworld_enemies()
	toggle_pause_menu()
	SceneTransition.fade_to_battle(MAIN_MENU_PATH)

func _on_quit_pressed() -> void:
	slots_panel._show_confirmation_dialog(
		"Sair do jogo?\n[color=red]O progresso atual não salvo será perdido![/color]",
		func():
			toggle_pause_menu()
			get_tree().quit(),
		btn_quit
	)

func _on_slots_panel_closed() -> void:
	await get_tree().process_frame
	var return_target = btn_save if slots_panel.current_mode == SlotsPanel.SlotMode.SAVE else btn_continue
	if is_instance_valid(return_target):
		return_target.grab_focus()

func _on_slot_selected(slot_index: int, mode: SlotsPanel.SlotMode) -> void:
	if mode == SlotsPanel.SlotMode.SAVE:
		await GameManager.save_game(slot_index)
		slots_panel.refresh_slots()
		var clicked_btn = slots_panel.get_slot_button(slot_index)
		if is_instance_valid(clicked_btn):
			clicked_btn.grab_focus()
	else:
		GameManager.disable_all_overworld_enemies()
		toggle_pause_menu()
		GameManager.load_game(slot_index)
