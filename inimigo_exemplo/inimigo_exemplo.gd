extends CharacterBody2D
class_name Enemy

@export var stats: CharacterStats

func _ready() -> void:
	# Duplica o recurso para que este inimigo tenha HP/Status próprios 
	# e não compartilhe alterações com outros inimigos do mesmo tipo.
	if stats:
		stats = stats.duplicate()
		stats.initialize()
		
		# Conecta sinais para feedback visual ou logs
		stats.status_paralyzed.connect(_on_status_paralyzed)

func _on_status_paralyzed() -> void:
	print(stats.character_name, " travou devido à paralisia!")
