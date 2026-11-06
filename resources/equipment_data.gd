extends Resource
class_name EquipmentData

enum EquipmentSlot { WEAPON, ARMOR }

@export var id: String = "espada_ferro"
@export var item_name: String = "Espada de Ferro"
@export var display_name: String = ""
@export_multiline var description: String = "Uma espada simples que aumenta o ataque."
@export var texture: Texture2D

@export var slot: EquipmentSlot = EquipmentSlot.WEAPON
@export var base_attack_bonus: int = 5
@export var base_defense_bonus: int = 0
@export var base_speed_bonus: int = 0

@export var level: int = 1
@export var max_level: int = 5
@export var base_soul_upgrade_cost: int = 50
@export var cost_in_coins: int = 50

var source_path: String = ""

func get_source_path() -> String:
	return resource_path if resource_path != "" else source_path

func get_display_name() -> String:
	return display_name if display_name != "" else item_name

func get_current_attack() -> int:
	return base_attack_bonus + ((level - 1) * 3)

func get_current_defense() -> int:
	return base_defense_bonus + ((level - 1) * 2)

func get_current_speed() -> int:
	return base_speed_bonus + (level - 1)

func get_upgrade_cost() -> int:
	return base_soul_upgrade_cost * level

func can_upgrade() -> bool:
	return level < max_level

func upgrade() -> bool:
	if can_upgrade():
		level += 1
		return true
	return false
