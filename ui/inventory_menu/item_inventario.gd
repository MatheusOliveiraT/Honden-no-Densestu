extends Button
class_name ItemRow

@onready var cursor: Label = %Cursor
@onready var icon_rect: TextureRect = %TextureRect
@onready var name_label: Label = %Nome
@onready var count_label: Label = %Label

const COLOR_FOCUS := Color.YELLOW

func _ready() -> void:
	for l in [cursor, name_label, count_label]:
		l.add_theme_font_size_override("font_size", 16)
	focus_mode = Control.FOCUS_ALL
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cursor.modulate.a = 0.0  # espaço
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(grab_focus)

func setup(display_name: String, icon_tex: Texture2D, count: int = -1, extra_text: String = "") -> void:
	name_label.text = display_name
	icon_rect.texture = icon_tex
	icon_rect.visible = icon_tex != null
	if extra_text != "":
		count_label.text = extra_text
	elif count >= 0:
		count_label.text = ": %d" % count
	else:
		count_label.text = ""	
	#modulate = Color.WHITE

func _on_focus(focused: bool) -> void:
	cursor.modulate.a = 1.0 if focused else 0.0
	var c := COLOR_FOCUS if focused else Color.WHITE
	name_label.add_theme_color_override("font_color", c)
	count_label.add_theme_color_override("font_color", c)
