extends CanvasLayer
class_name ControlsPopup

@onready var rows: VBoxContainer = %Linhas
@onready var btn_close: Button = %Fechar

const FONT_SIZE := 16
const COLOR_KEYS := Color.YELLOW

#açoes godot
const FRIENDLY := {
	"cima": "Mover para cima",
	"baixo": "Mover para baixo",
	"esquerda": "Mover para a esquerda",
	"direita": "Mover para a direita",
	"correr": "Correr (segurar)",
	"interagir": "Interagir",
	"inventario": "Abrir inventário",
	"menu": "Menu de pausa",
	"ui_accept": "Confirmar",
	"ui_cancel": "Voltar / cancelar",
}

# esse n ta no menu da godot
const EXTRA := [
	["X / Botão direito", "Equipar skill (na aba Skills)"],
]

const MOUSE_NAMES := {
	MOUSE_BUTTON_LEFT: "Clique esquerdo",
	MOUSE_BUTTON_RIGHT: "Botão direito",
	MOUSE_BUTTON_MIDDLE: "Clique do meio",
}

const SHOW_GAMEPAD := true   # false esconde os controles de joystick

const JOY_BUTTON_NAMES := {
	JOY_BUTTON_A: "Pad A",
	JOY_BUTTON_B: "Pad B",
	JOY_BUTTON_X: "Pad X",
	JOY_BUTTON_Y: "Pad Y",
	JOY_BUTTON_BACK: "Pad Select",
	JOY_BUTTON_START: "Pad Start",
	JOY_BUTTON_LEFT_STICK: "Pad L3",
	JOY_BUTTON_RIGHT_STICK: "Pad R3",
	JOY_BUTTON_LEFT_SHOULDER: "Pad LB",
	JOY_BUTTON_RIGHT_SHOULDER: "Pad RB",
	JOY_BUTTON_DPAD_UP: "Pad Cima",
	JOY_BUTTON_DPAD_DOWN: "Pad Baixo",
	JOY_BUTTON_DPAD_LEFT: "Pad Esq",
	JOY_BUTTON_DPAD_RIGHT: "Pad Dir",
}

const JOY_AXIS_NAMES := {
	JOY_AXIS_LEFT_X: ["Analog Esq", "Analog Dir"],
	JOY_AXIS_LEFT_Y: ["Analog Cima", "Analog Baixo"],
	JOY_AXIS_RIGHT_X: ["Analog2 Esq", "Analog2 Dir"],
	JOY_AXIS_RIGHT_Y: ["Analog2 Cima", "Analog2 Baixo"],
	JOY_AXIS_TRIGGER_LEFT: ["LT", "LT"],
	JOY_AXIS_TRIGGER_RIGHT: ["RT", "RT"],
}

func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_rows()
	_style_close_button()
	btn_close.pressed.connect(queue_free)
	btn_close.grab_focus()
	for prop in ["focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom", "focus_next", "focus_previous"]:
		btn_close.set(prop, btn_close.get_path())

func _build_rows() -> void:
	var shown := {}
	for action in FRIENDLY:
		if InputMap.has_action(action):
			_add_row(FRIENDLY[action], _keys_for(action))
			shown[action] = true
	for action in InputMap.get_actions():
		if shown.has(action) or str(action).begins_with("ui_"):
			continue
		_add_row(str(action).capitalize(), _keys_for(action))
	for e in EXTRA:
		_add_row(e[1], e[0])

func _keys_for(action: StringName) -> String:
	var parts: Array[String] = []
	# busca os inputs configurados na godot
	for ev in InputMap.action_get_events(action):
		var t := ""
		# teclado: wasd, x i etc
		if ev is InputEventKey:
			var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			t = OS.get_keycode_string(code)
		elif ev is InputEventMouseButton:
			t = MOUSE_NAMES.get(ev.button_index, "Mouse " + str(ev.button_index))
		elif SHOW_GAMEPAD and ev is InputEventJoypadButton:
			t = JOY_BUTTON_NAMES.get(ev.button_index, "Pad " + str(ev.button_index))
		elif SHOW_GAMEPAD and ev is InputEventJoypadMotion:
			var par: Array = JOY_AXIS_NAMES.get(ev.axis, ["Eixo " + str(ev.axis), "Eixo " + str(ev.axis)])
			t = par[0] if ev.axis_value < 0.0 else par[1]
		else:
			continue
		if t != "" and not parts.has(t):
			parts.append(t)
	return " / ".join(parts)

func _add_row(desc: String, keys: String) -> void:
	if keys == "":
		return
	var row := HBoxContainer.new()
	var l_desc := Label.new()
	l_desc.text = desc
	l_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_desc.add_theme_font_size_override("font_size", FONT_SIZE)
	var l_keys := Label.new()
	l_keys.text = keys
	l_keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l_keys.add_theme_font_size_override("font_size", FONT_SIZE)
	l_keys.add_theme_color_override("font_color", COLOR_KEYS)
	row.add_child(l_desc)
	row.add_child(l_keys)
	rows.add_child(row)

func _style_close_button() -> void:
	var vazio := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		btn_close.add_theme_stylebox_override(estado, vazio)
	btn_close.text = "> Fechar"
	btn_close.add_theme_font_size_override("font_size", FONT_SIZE)
	for cor in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		btn_close.add_theme_color_override(cor, Color.YELLOW)

func _input(event: InputEvent) -> void:
	# esq fecha popup
	if event.is_action_pressed("ui_cancel") or (InputMap.has_action("menu") and event.is_action_pressed("menu")):
		get_viewport().set_input_as_handled()
		queue_free()
