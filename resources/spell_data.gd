extends Resource
class_name SpellData

enum SpellType { DAMAGE, HEAL, BUFF, DEBUFF }

@export var id: String = "cura"
@export var spell_name: String = "Cura"
@export_multiline var description: String = ""
@export var texture: Texture2D
@export var mp_cost: int = 10
@export var type: SpellType = SpellType.HEAL

@export var base_value: int = 10

@export var applies_status: bool = false
@export var status_type: CharacterStats.StatusType = CharacterStats.StatusType.POISON
@export var status_duration: int = 3
@export var status_potency: int = 5

func get_description() -> String:
	if description != "":
		return description
	match type:
		SpellType.HEAL:
			return "Recupera %d HP instantaneamente." % base_value
	return ""
