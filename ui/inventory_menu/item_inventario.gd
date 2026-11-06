extends Button
class_name ItemRow

signal alt_pressed

@onready var cursor: Label = %Cursor
@onready var icon_rect: TextureRect = %TextureRect
@onready var name_label: Label = %Nome
@onready var desc_label: Label = %Descricao
@onready var count_label: Label = %Label

const COLOR_FOCUS := Color.YELLOW
const COLOR_DESC := Color(0.75, 0.75, 0.85)
const HEIGHT_ONE_LINE := 28
const HEIGHT_TWO_LINES := 44

var _has_desc := false

func _ready() -> void:
	for l in [cursor, name_label, count_label]:
		l.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", COLOR_DESC)
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor.modulate.a = 0.0  # espaço
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(grab_focus)
	gui_input.connect(_on_gui_input)

func setup(display_name: String, icon_tex: Texture2D, count: int = -1, extra_text: String = "", desc_text: String = "") -> void:
	name_label.text = display_name
	icon_rect.texture = icon_tex
	icon_rect.visible = icon_tex != null
	if extra_text != "":
		count_label.text = extra_text
	elif count >= 0:
		count_label.text = ": %d" % count
	else:
		count_label.text = ""	
	desc_label.text = desc_text
	desc_label.text = desc_text
	_has_desc = desc_text != ""

func _on_focus(focused: bool) -> void:
	cursor.modulate.a = 1.0 if focused else 0.0
	if focused:
		name_label.add_theme_color_override("font_color", COLOR_FOCUS)
		count_label.add_theme_color_override("font_color", COLOR_FOCUS)
	else:
		name_label.remove_theme_color_override("font_color")
		count_label.remove_theme_color_override("font_color")
	var open := _has_desc and focused
	desc_label.visible = open
	custom_minimum_size.y = HEIGHT_TWO_LINES if open else HEIGHT_ONE_LINE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		alt_pressed.emit()
		accept_event()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X:
		alt_pressed.emit()
		accept_event()
