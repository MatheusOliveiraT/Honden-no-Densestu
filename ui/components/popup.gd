extends Control
class_name ConfirmPopup

signal answered(yes: bool)

@onready var caixa: PanelContainer = %PanelContainer
@onready var message: Label = %Mensagem
@onready var btn_yes: Button = %Sim
@onready var btn_no: Button = %Nao

var _done := false

func _ready() -> void:
	caixa.visible = false
	btn_yes.pressed.connect(_answer.bind(true))
	btn_no.pressed.connect(_answer.bind(false))
	for b in [btn_yes, btn_no]:
		b.focus_mode = Control.FOCUS_ALL
		b.mouse_entered.connect(b.grab_focus)
		b.focus_entered.connect(_paint.bind(b, true))
		b.focus_exited.connect(_paint.bind(b, false))
		b.focus_neighbor_top = b.get_path()
		b.focus_neighbor_bottom = b.get_path()
	btn_yes.focus_neighbor_left = btn_yes.get_path()
	btn_yes.focus_neighbor_right = btn_no.get_path()
	btn_no.focus_neighbor_left = btn_yes.get_path()
	btn_no.focus_neighbor_right = btn_no.get_path()
	_paint(btn_yes, false)
	_paint(btn_no, false)

func open(text: String, near: Control) -> void:
	message.text = text
	caixa.reset_size()
	await get_tree().process_frame 
	var vp := get_viewport_rect().size
	var pos := near.global_position + Vector2(near.size.x * 0.4, near.size.y * 0.5)
	pos.x = clampf(pos.x, 0.0, vp.x - caixa.size.x)
	pos.y = clampf(pos.y, 0.0, vp.y - caixa.size.y)
	caixa.global_position = pos
	caixa.visible = true
	btn_yes.grab_focus()

func _paint(b: Button, focused: bool) -> void:
	var base := "Sim" if b == btn_yes else "Não"
	if focused:
		b.text = "> " + base
		b.add_theme_color_override("font_color", Color.YELLOW)
		b.add_theme_color_override("font_focus_color", Color.YELLOW)
		b.add_theme_color_override("font_hover_color", Color.YELLOW)
	else:
		b.text = base
		b.remove_theme_color_override("font_color")
		b.remove_theme_color_override("font_focus_color")
		b.remove_theme_color_override("font_hover_color")

func _unhandled_input(event: InputEvent) -> void:
	# esq fecha popup
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		_answer(false)
		get_viewport().set_input_as_handled()

func _answer(yes: bool) -> void:
	if _done: return
	_done = true
	answered.emit(yes)
	queue_free()
