extends Resource
class_name ItemData

enum ItemType { HEAL_HP, HEAL_MP, HEAL_BOTH, REMOVE_STATUS }

@export var id: String = "pocao_hp_p"
@export var item_name: String = "Poção de Vida (P)"
@export var display_name: String = ""
@export_multiline var description: String = "Recupera 10 de HP."
@export var texture: Texture2D

@export var type: ItemType = ItemType.HEAL_HP
@export var value: int = 10
@export var cost_in_coins: int = 10

@export var status_to_remove: CharacterStats.StatusType = CharacterStats.StatusType.POISON

func get_display_name() -> String:
	return display_name if display_name != "" else item_name

func use(target_stats: CharacterStats) -> String:
	var nome := get_display_name()
	match type:
		ItemType.HEAL_HP:
			target_stats.heal(value)
			return target_stats.character_name + " usou " + nome + " e recuperou " + str(value) + " HP!"
		ItemType.HEAL_MP:
			target_stats.heal_mana(value)
			return target_stats.character_name + " usou " + nome + " e recuperou " + str(value) + " MP!"
		ItemType.HEAL_BOTH:
			target_stats.heal(value)
			target_stats.heal_mana(value)
			return target_stats.character_name + " usou " + nome + " e recuperou " + str(value) + " de HP e MP!"
		ItemType.REMOVE_STATUS:
			var removed = false
			for status in target_stats.active_statuses:
				if status.type == status_to_remove:
					target_stats.active_statuses.erase(status)
					removed = true
					break
			if removed:
				return target_stats.character_name + " usou " + nome + " e curou o efeito negativo!"
			else:
				return target_stats.character_name + " usou " + nome + ", mas não surtiu efeito."
	return ""
