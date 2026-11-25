extends Control
class_name IntroCutscene

@onready var cutscene_art: TextureRect = $CutsceneArt
@onready var dialog_panel: NinePatchRect = $DialogPanel
@onready var speaker_label: Label = $DialogPanel/DialogLabel
@onready var dialog_text: RichTextLabel = $DialogPanel/DialogText
@onready var anim_player: AnimationPlayer = $AnimationPlayer

const FIRST_LEVEL_PATH: String = "res://levels/floresta/floresta.tscn"
const ART_SCROLL: String = "res://cutscenes/intro_cutscene/inicial-1.png"
const ART_HONDEN: String = "res://cutscenes/intro_cutscene/inicial-2.png"

const ART_FADE_IN: float = 0.8 
const ART_FADE_OUT: float = 0.3

var cutscene_steps: Array[Dictionary] = [
	{
		"speaker": "",
		"text": "Após o falecimento do seu avô, Seiji Mikage herdou o templo de sua família, passado por gerações.",
		"art": ART_SCROLL
	},
	{
		"speaker": "",
		"text": "No entanto, a notícia vinha com um aviso: o templo tinha sido tomado por yokais!",
		"art": ART_SCROLL
	},
	{
		"speaker": "",
		"text": "Agora, era responsabilidade de Seiji tomá-lo de volta...",
		"art": ART_HONDEN
	}
]
var current_step_index: int = -1
var is_typing: bool = false
var is_finishing: bool = false
var type_tween: Tween
var art_tween: Tween
var current_art_path: String = ""

func _ready() -> void:
	get_tree().paused = false
	dialog_text.bbcode_enabled = true
	cutscene_art.modulate.a = 0.0
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
	if step.has("art"):
		_show_art(step["art"])
	if step.has("anim") and anim_player and anim_player.has_animation(step["anim"]):
		anim_player.play(step["anim"])
	var full_text: String = step.get("text", "")
	_start_typing(full_text)

func _show_art(path: String) -> void:
	if path == current_art_path:
		return
	current_art_path = path
	if art_tween and art_tween.is_valid():
		art_tween.kill()
	art_tween = create_tween()
	if cutscene_art.texture != null and cutscene_art.modulate.a > 0.0:
		art_tween.tween_property(cutscene_art, "modulate:a", 0.0, ART_FADE_OUT)
	art_tween.tween_callback(_set_art_texture.bind(path))
	if path != "":
		art_tween.tween_property(cutscene_art, "modulate:a", 1.0, ART_FADE_IN)
 
func _set_art_texture(path: String) -> void:
	if path != "" and ResourceLoader.exists(path):
		cutscene_art.texture = load(path)
	else:
		if path != "":
			push_warning("nao encotroui arte: " + path)
		cutscene_art.texture = null

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
	if art_tween and art_tween.is_valid():
		art_tween.kill()
	if anim_player:
		anim_player.stop()
	SceneTransition.fade_to_battle(FIRST_LEVEL_PATH)
