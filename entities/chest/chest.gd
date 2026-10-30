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
		GameManager.show_message_box("O baú já está vazio.")
		return
	is_opened = true
	GameManager.register_defeated_enemy(chest_id)
	_grant_reward()
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("abrir"):
		animated_sprite.play("abrir")

func _grant_reward() -> void:
	match type:
		ChestType.SOULS:
			GameManager.add_souls(souls_amount)
			var msg = "Você abriu o baú e encontrou:\n[color=cyan]+ " + str(souls_amount) + " Almas![/color]"
			GameManager.show_message_box(msg)
		ChestType.ITEM:
			if item_data is ItemData:
				GameManager.add_item(item_data, 1)
			else:
				GameManager.show_message_box("O baú continha um item, mas estava vazio!")
				
		ChestType.SPELL:
			if spell_data:
				GameManager.unlock_spell(spell_data)
			else:
				GameManager.show_message_box("O baú continha um pergaminho antigo ilegível...")

func _play_open_animation_instant() -> void:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	if animated_sprite.sprite_frames.has_animation("aberto"):
		animated_sprite.play("aberto")
	elif animated_sprite.sprite_frames.has_animation("abrir"):
		animated_sprite.play("abrir")
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count("abrir") - 1
