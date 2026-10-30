extends Resource
class_name EquipmentData

enum EquipmentSlot { WEAPON, ARMOR, ACCESSORY }

@export var id: String = "espada_ferro"
@export var item_name: String = "Espada de Ferro"
@export_multiline var description: String = "Uma espada simples que aumenta o ataque."
@export var texture: Texture2D

@export var slot: EquipmentSlot = EquipmentSlot.WEAPON
@export var attack_bonus: int = 5
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0
@export var cost_in_souls: int = 50
