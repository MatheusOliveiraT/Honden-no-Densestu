extends Control
class_name IntroCutscene

@onready var cutscene_art: TextureRect = $CutsceneArt
@onready var dialog_panel: NinePatchRect = $DialogPanel
@onready var speaker_label: Label = $DialogPanel/DialogLabel
@onready var dialog_text: RichTextLabel = $DialogPanel/DialogText
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const FIRST_LEVEL_PATH: String = "res://levels/floresta/floresta.tscn"

var cutscene_steps: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "Há muito tempo, a floresta antiga guardava segredos esquecidos...",
		"art": "",
		"anim": ""
	},
	{
		"speaker": "Seiji",
		"text": "Finalmente cheguei. Preciso tomar cuidado por aqui.",
	},
	{
		"speaker": "Voz Misteriosa",
		"text": "[color=cyan]Quem ousa entrar nestas terras?[/color]",
		"art": ""
	},
	{
		"speaker": "",
		"text": "E assim começa a jornada..."
	}
]
var current_step_index: int = -1
var is_typing: bool = false
var is_finishing: bool = false
var type_tween: Tween

func _ready() -> void:
	get_tree().paused = false
	dialog_text.bbcode_enabled = true
	_next_step()

func _unhandled_input(event: InputEvent) -> void:
	if is_finishing:
		return
	if event.is_action_pressed("menu"):
		_finish_cutscene()
		return
	if event.is_action_pressed("interagir"):
		if is_typing:
			_complete_typing()
		else:
			_next_step()

func _next_step() -> void:
	current_step_index += 1
	if current_step_index >= cutscene_steps.size():
		_finish_cutscene()
		return
		
	var step: Dictionary = cutscene_steps[current_step_index]
	var speaker: String = step.get("speaker", "")
	if speaker.is_empty():
		speaker_label.text = ""
		speaker_label.hide()
	else:
		speaker_label.text = speaker
		speaker_label.show()
	if step.has("art") and step["art"] is Texture2D:
		cutscene_art.texture = step["art"]
	if step.has("anim") and anim_player and anim_player.has_animation(step["anim"]):
		anim_player.play(step["anim"])
	var full_text: String = step.get("text", "")
	_start_typing(full_text)

func _start_typing(text: String) -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
		
	dialog_text.text = text
	dialog_text.visible_ratio = 0.0
	is_typing = true
	var plain_length := dialog_text.get_parsed_text().length()
	var duration := maxf(0.2, plain_length / 35.0)
	type_tween = create_tween()
	type_tween.tween_property(dialog_text, "visible_ratio", 1.0, duration)
	type_tween.finished.connect(func():
		is_typing = false
	)

func _complete_typing() -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	dialog_text.visible_ratio = 1.0
	is_typing = false

func _finish_cutscene() -> void:
	if is_finishing:
		return
	is_finishing = true
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	if anim_player:
		anim_player.stop()
	SceneTransition.fade_to_battle(FIRST_LEVEL_PATH)
