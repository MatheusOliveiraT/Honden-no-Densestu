extends CanvasLayer
class_name SettingsMenu

@onready var master_slider: HSlider = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/MasterHBox/MasterSlider
@onready var master_value: Label = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/MasterHBox/MasterValue

@onready var bgm_slider: HSlider = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/BGMHBox/BGMSlider
@onready var bgm_value: Label = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/BGMHBox/BGMValue

@onready var sfx_slider: HSlider = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/SFXHBox/SFXSlider
@onready var sfx_value: Label = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/SFXHBox/SFXValue

@onready var btn_display_mode: Button = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/DisplayHBox/BtnDisplayMode
@onready var btn_controls: Button = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/CtrlBackHBox/BtnControls
@onready var btn_back: Button = $CenterContainer/NinePatchRect/MarginContainer/VBoxContainer/CtrlBackHBox/BtnBack

enum DisplayOption { WINDOWED, FULLSCREEN, BORDERLESS }
var current_display_option: DisplayOption = DisplayOption.WINDOWED

const CONTROLS_POPUP: PackedScene = preload("res://ui/components/ControlsPopup.tscn")
const SETTINGS_PATH: String = "user://settings.cfg"

var original_button_texts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_styles_and_focus()
	_load_current_values()
	_connect_signals()
	await get_tree().process_frame
	if is_instance_valid(master_slider):
		master_slider.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_close_settings()

func _load_current_values() -> void:
	var m_vol := AudioManager.get_bus_volume("Master")
	var b_vol := AudioManager.get_bus_volume("BGM")
	var s_vol := AudioManager.get_bus_volume("SFX")
	master_slider.value = m_vol
	bgm_slider.value = b_vol
	sfx_slider.value = s_vol
	master_value.text = "%d%%" % roundi(m_vol * 100.0)
	bgm_value.text = "%d%%" % roundi(b_vol * 100.0)
	sfx_value.text = "%d%%" % roundi(s_vol * 100.0)
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		current_display_option = config.get_value("video", "display_mode", DisplayOption.WINDOWED)
	else:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			current_display_option = DisplayOption.FULLSCREEN
		elif DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
			current_display_option = DisplayOption.BORDERLESS
		else:
			current_display_option = DisplayOption.WINDOWED
	_update_display_button_label()

func _connect_signals() -> void:
	master_slider.value_changed.connect(func(val: float):
		AudioManager.set_bus_volume("Master", val)
		master_value.text = "%d%%" % roundi(val * 100.0)
	)
	bgm_slider.value_changed.connect(func(val: float):
		AudioManager.set_bus_volume("BGM", val)
		bgm_value.text = "%d%%" % roundi(val * 100.0)
	)
	sfx_slider.value_changed.connect(func(val: float):
		AudioManager.set_bus_volume("SFX", val)
		sfx_value.text = "%d%%" % roundi(val * 100.0)
	)
	btn_display_mode.pressed.connect(_cycle_display_mode)
	btn_controls.pressed.connect(_on_controls_pressed)
	btn_back.pressed.connect(_close_settings)

func _cycle_display_mode() -> void:
	current_display_option = ((current_display_option + 1) % 3) as DisplayOption
	apply_display_mode(current_display_option)
	_update_display_button_label()

static func apply_display_mode(option: DisplayOption) -> void:
	match option:
		DisplayOption.WINDOWED:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayOption.FULLSCREEN:
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayOption.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen_id := DisplayServer.window_get_current_screen()
			DisplayServer.window_set_position(DisplayServer.screen_get_position(screen_id))
			DisplayServer.window_set_size(DisplayServer.screen_get_size(screen_id))

func _update_display_button_label() -> void:
	var mode_name := ""
	match current_display_option:
		DisplayOption.WINDOWED: mode_name = "Janela"
		DisplayOption.FULLSCREEN: mode_name = "Tela Cheia"
		DisplayOption.BORDERLESS: mode_name = "Sem Bordas"
	original_button_texts[btn_display_mode] = mode_name
	btn_display_mode.text = ("> " + mode_name) if btn_display_mode.has_focus() else mode_name

func _on_controls_pressed() -> void:
	var popup := CONTROLS_POPUP.instantiate()
	get_tree().root.add_child(popup)
	popup.tree_exited.connect(func():
		if is_instance_valid(btn_controls):
			btn_controls.grab_focus()
	)

func _save_all_settings() -> void:
	AudioManager.save_audio_settings()
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("video", "display_mode", current_display_option)
	config.save(SETTINGS_PATH)

func _close_settings() -> void:
	_save_all_settings()
	queue_free()

func _setup_styles_and_focus() -> void:
	var button_style = load("res://ui/button_theme.tres") as StyleBox
	var buttons = [btn_display_mode, btn_controls, btn_back]
	for btn in buttons:
		if not is_instance_valid(btn):
			continue
		btn.focus_mode = Control.FOCUS_ALL
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		btn.add_theme_font_size_override("font_size", 16)
		if button_style:
			for state in ["normal", "pressed", "hover", "disabled", "focus"]:
				btn.add_theme_stylebox_override(state, button_style)
		btn.mouse_entered.connect(func(): btn.grab_focus())
		btn.focus_entered.connect(func():
			if not original_button_texts.has(btn):
				original_button_texts[btn] = btn.text
			btn.text = "> " + original_button_texts[btn]
			btn.add_theme_color_override("font_color", Color.YELLOW)
			btn.add_theme_color_override("font_focus_color", Color.YELLOW)
			btn.add_theme_color_override("font_hover_color", Color.YELLOW)
		)
		btn.focus_exited.connect(func():
			if original_button_texts.has(btn):
				btn.text = original_button_texts[btn]
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_focus_color")
			btn.remove_theme_color_override("font_hover_color")
		)
	for slider in [master_slider, bgm_slider, sfx_slider]:
		if is_instance_valid(slider):
			slider.focus_mode = Control.FOCUS_ALL
			slider.mouse_entered.connect(func(): slider.grab_focus())
