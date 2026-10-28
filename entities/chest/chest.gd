extends StaticBody2D
class_name Chest

enum ChestType { SOULS, ITEM, SPELL }

@export var chest_id: String = "chest_fase1_01"
@export var type: ChestType = ChestType.SOULS

@export var souls_amount: int = 10
@export var item_data: Resource = null
@export var spell_data: SpellData = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_opened: bool = false

func _ready() -> void:
	if GameManager.defeated_enemies.has(chest_id):
		is_opened = true
		_play_open_animation_instant()

func interact(_player: Seiji) -> void:
	if is_opened:
		print("O baú já está vazio.")
		return
	is_opened = true
	GameManager.register_defeated_enemy(chest_id)
	_grant_reward()
	if animated_sprite and animated_sprite.sprite_frames.has_animation("abrir"):
		animated_sprite.play("abrir")

func _grant_reward() -> void:
	match type:
		ChestType.SOULS:
			GameManager.add_souls(souls_amount)
			print("Você abriu o baú e encontrou ", souls_amount, " Almas!")
		ChestType.ITEM:
			if item_data is ItemData:
				GameManager.add_item(item_data, 1)
				print("Você encontrou: ", item_data.item_name, "!")
			else:
				print("O baú continha um item, mas está nulo!")
		ChestType.SPELL:
			if spell_data:
				GameManager.unlock_spell(spell_data)
				print("Você aprendeu uma nova magia: ", spell_data.spell_name, "!")
			else:
				print("O baú continha uma magia, mas está nulo!")

func _play_open_animation_instant() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("aberto"):
		animated_sprite.play("aberto")
	elif animated_sprite and animated_sprite.sprite_frames.has_animation("abrir"):
		animated_sprite.play("abrir")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("abrir") - 1
