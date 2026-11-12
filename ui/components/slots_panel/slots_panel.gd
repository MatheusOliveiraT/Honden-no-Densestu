extends CanvasLayer
class_name SlotsPanel

signal slot_selected(slot_index: int, mode: SlotMode)
signal closed

enum SlotMode { SAVE, LOAD }

@onready var panel_label: Label = $SlotsControl/NinePatchRect/PanelLabel
@onready var slot1_btn: Button = $SlotsControl/NinePatchRect/SlotsVBox/Slot1Button
@onready var slot2_btn: Button = $SlotsControl/NinePatchRect/SlotsVBox/Slot2Button
@onready var slot3_btn: Button = $SlotsControl/NinePatchRect/SlotsVBox/Slot3Button
@onready var btn_back: Button = $SlotsControl/NinePatchRect/SlotsVBox/BtnBack

@export var require_confirmation: bool = false

var current_mode: SlotMode = SlotMode.LOAD
var original_button_texts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_setup_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		close()

func open(mode: SlotMode) -> void:
	current_mode = mode
	if panel_label:
		panel_label.text = "Salvar Jogo" if mode == SlotMode.SAVE else "Carregar Jogo"
	refresh_slots()
	show()
	await get_tree().process_frame
	if is_instance_valid(slot1_btn):
		slot1_btn.grab_focus()

func close() -> void:
	hide()
	closed.emit()

func get_slot_button(slot_index: int) -> Button:
	var buttons = [slot1_btn, slot2_btn, slot3_btn]
	if slot_index >= 1 and slot_index <= buttons.size():
		return buttons[slot_index - 1]
	return null

func refresh_slots() -> void:
	var slot_buttons = [slot1_btn, slot2_btn, slot3_btn]
	for i in range(slot_buttons.size()):
		var slot_idx = i + 1
		var btn = slot_buttons[i]
		if not is_instance_valid(btn):
			continue
		var info = GameManager.get_slot_info(slot_idx)
		var tex_rect: TextureRect = btn.get_node_or_null("HBoxContainer/Icon")
		var inner_label: Label = btn.get_node_or_null("HBoxContainer/Label")
		var label_text := ""
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
			inner_label.add_theme_font_size_override("font_size", 16)
			original_button_texts[inner_label] = label_text
			inner_label.text = ("> " + label_text) if btn.has_focus() else label_text
		else:
			original_button_texts[btn] = label_text
			btn.text = ("> " + label_text) if btn.has_focus() else label_text

func _setup_buttons() -> void:
	var button_style = load("res://ui/button_theme.tres") as StyleBox
	var buttons = [slot1_btn, slot2_btn, slot3_btn, btn_back]
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
		btn.focus_entered.connect(func(): _apply_focus_style(btn, true))
		btn.focus_exited.connect(func(): _apply_focus_style(btn, false))
	if slot1_btn: slot1_btn.pressed.connect(func(): _on_slot_pressed(1))
	if slot2_btn: slot2_btn.pressed.connect(func(): _on_slot_pressed(2))
	if slot3_btn: slot3_btn.pressed.connect(func(): _on_slot_pressed(3))
	if btn_back: btn_back.pressed.connect(close)

func _apply_focus_style(btn: Button, focused: bool) -> void:
	var inner_label: Label = btn.get_node_or_null("HBoxContainer/Label")
	if inner_label:
		if not original_button_texts.has(inner_label):
			original_button_texts[inner_label] = inner_label.text
		inner_label.text = ("> " if focused else "") + original_button_texts[inner_label]
		if focused:
			inner_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			inner_label.remove_theme_color_override("font_color")
	else:
		if not original_button_texts.has(btn):
			original_button_texts[btn] = btn.text
		btn.text = ("> " if focused else "") + original_button_texts[btn]
		if focused:
			btn.add_theme_color_override("font_color", Color.YELLOW)
			btn.add_theme_color_override("font_focus_color", Color.YELLOW)
			btn.add_theme_color_override("font_hover_color", Color.YELLOW)
			btn.add_theme_color_override("font_hover_pressed_color", Color.YELLOW)
		else:
			btn.remove_theme_color_override("font_color")
			btn.remove_theme_color_override("font_focus_color")
			btn.remove_theme_color_override("font_hover_color")
			btn.remove_theme_color_override("font_hover_pressed_color")

func _on_slot_pressed(slot_index: int) -> void:
	var info = GameManager.get_slot_info(slot_index)
	var btn = get_slot_button(slot_index)
	if require_confirmation and info.get("exists", false):
		var msg := ""
		if current_mode == SlotMode.SAVE:
			msg = "Sobrescrever o Slot " + str(slot_index) + "?"
		else:
			msg = "Carregar Slot " + str(slot_index) + "?\n[color=red]O progresso atual não salvo será perdido![/color]"
			
		_show_confirmation_dialog(msg, func():
			slot_selected.emit(slot_index, current_mode)
		, btn)
	else:
		slot_selected.emit(slot_index, current_mode)

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
			for state in ["normal", "pressed", "hover", "disabled", "focus"]:
				btn.add_theme_stylebox_override(state, button_style)
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
