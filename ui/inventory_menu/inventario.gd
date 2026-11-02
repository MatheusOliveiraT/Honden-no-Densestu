extends CanvasLayer
class_name PauseMenuHub

@onready var main_control: Control = $Control

@onready var label_hp_atual: Label = $Control/CenterContainer/HBoxContainer/esquerda/MarginContainer/VBoxContainer/SEIJI/INFOseiji/HBoxContainer/label_hp
@onready var label_hp_max: Label = $Control/CenterContainer/HBoxContainer/esquerda/MarginContainer/VBoxContainer/SEIJI/INFOseiji/HBoxContainer/label_hp3

@onready var label_mp_atual: Label = $Control/CenterContainer/HBoxContainer/esquerda/MarginContainer/VBoxContainer/SEIJI/INFOseiji/HBoxContainer2/label_mp4
@onready var label_mp_max: Label = $Control/CenterContainer/HBoxContainer/esquerda/MarginContainer/VBoxContainer/SEIJI/INFOseiji/HBoxContainer2/label_mp6

@onready var label_lvl_arma: Label = $Control/CenterContainer/HBoxContainer/esquerda/MarginContainer/VBoxContainer/MarginContainer/INFOarma/HBoxContainer2/label_arma

@onready var btn_itens: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Itens
@onready var btn_skills: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Skills
@onready var btn_equip: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Equip
@onready var btn_save: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Save
@onready var btn_exit: Button = $Control/CenterContainer/HBoxContainer/direita/Menu/INFObotoes/Menu/Exit

@onready var label_almas: Label = %label_almas
@onready var label_moedas: Label = %label_moedas

var is_open: bool = false
var original_button_texts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Garante execução mesmo com o jogo pausado
	hide()
	if main_control: main_control.hide()
	_setup_button_focus_effects()
	_connect_buttons()

func _setup_button_focus_effects() -> void:
	var buttons = [btn_itens, btn_skills, btn_equip, btn_save, btn_exit]
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
			)
			btn.focus_exited.connect(func():
				btn.text = original_button_texts[btn]
				btn.remove_theme_color_override("font_color")
				btn.remove_theme_color_override("font_focus_color")
				btn.remove_theme_color_override("font_hover_color")
				btn.remove_theme_color_override("font_hover_pressed_color")
			)

func _connect_buttons() -> void:
	if btn_itens: btn_itens.pressed.connect(_on_itens_pressed)
	if btn_skills: btn_skills.pressed.connect(_on_skills_pressed)
	if btn_equip: btn_equip.pressed.connect(_on_equip_pressed)
	if btn_save: btn_save.pressed.connect(_on_save_pressed)
	if btn_exit: btn_exit.pressed.connect(_on_exit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
		toggle_menu()

func toggle_menu() -> void:
	is_open = !is_open
	if is_open:
		_update_player_stats()
		_update_currencies()
		show()
		if main_control: main_control.show()
		get_tree().paused = true
		await get_tree().process_frame
		if is_instance_valid(btn_itens):
			btn_itens.grab_focus()
	else:
		if main_control: main_control.hide()
		hide()
		get_tree().paused = false

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
	if label_lvl_arma:
		if GameManager.equipped_weapon != null:
			label_lvl_arma.text = str(GameManager.equipped_weapon.attack_bonus)
		else:
			label_lvl_arma.text = "1"

func _update_currencies() -> void:
	if label_almas:
		if "almas" in GameManager: label_almas.text = str(GameManager.almas)
		elif "total_souls" in GameManager: label_almas.text = str(GameManager.total_souls)
	if label_moedas:
		if "moedas" in GameManager: label_moedas.text = str(GameManager.moedas)

func _on_itens_pressed() -> void:
	GameManager.show_message_box("Aba de Itens selecionada.")

func _on_skills_pressed() -> void:
	GameManager.show_message_box("Aba de Magias selecionada.")

func _on_equip_pressed() -> void:
	GameManager.show_message_box("Aba de Equipamentos selecionada.")

func _on_save_pressed() -> void:
	if GameManager.has_method("save_game"):
		GameManager.save_game()
	GameManager.show_message_box("Jogo Salvo!")

func _on_exit_pressed() -> void:
	toggle_menu()
