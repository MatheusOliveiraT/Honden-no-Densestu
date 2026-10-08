extends CharacterBody2D

@export var stats: CharacterStats 

func _ready() -> void:
	if stats:
		stats.initialize()
		print("=== TESTE INICIADO ===")
		print("Personagem: ", stats.character_name, " | HP: ", stats.current_hp, "/", stats.max_hp)
		print("Teclas de teste: [1] Dar Dano | [2] Aplicar Veneno | [3] Aplicar Paralisia | [Enter] Passar Turno")
		stats.status_paralyzed.connect(_on_character_paralyzed)

func _input(event: InputEvent) -> void:
	if not stats: return
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		match event.keycode:
			KEY_1:
				print("\n--- Recebendo 30 de dano bruto ---")
				stats.take_damage(30)
				print("HP Atual: ", stats.current_hp)
			KEY_2:
				print("\n--- Aplicando VENENO (5 turnos, 10 de dano) ---")
				stats.apply_status(CharacterStats.StatusType.POISON, 5, 10)
			KEY_3:
				print("\n--- Aplicando PARALISIA (3 turnos, 50% de chance) ---")
				stats.apply_status(CharacterStats.StatusType.PARALIZE, 3, 50)
			KEY_ENTER:
				print("\n=== AVANÇANDO TURNO ===")
				stats.process_turn_statuses()
				print("HP após efeitos: ", stats.current_hp)
				if stats.current_hp > 0:
					if stats.can_take_action():
						print("-> [AÇÃO LIBERADA] O personagem pode agir normalmente neste turno.")
					else:
						print("-> [TURNO PULADO] O personagem não conseguiu se mover!")
				else:
					print("-> [MORREU] O personagem ficou sem vida.")

func _on_character_paralyzed() -> void:
	print("! (Sinal disparado: O status de paralisia foi ativado com sucesso!)")
