extends Node

var player_map_position: Vector2 = Vector2.ZERO
var returning_from_battle: bool = false
var current_map_scene_path: String = "res://levels/floresta.tscn"

var defeated_enemy_id: String = ""
var defeated_enemies: Array[String] = []

var current_hp: int = -1
var current_mp: int = -1

var total_souls: int = 0

var current_enemy_data: EnemyData

var current_level: int = 1 

var current_enemy_party_data: Array[EnemyData] = []

var unlocked_spells: Array[SpellData] = []
var equipped_spells: Array[SpellData] = []

var inventory: Dictionary = {}

func _ready() -> void:
	_init_default_spells()

func _init_default_spells() -> void:
	var cura = SpellData.new()
	cura.id = "cura"
	cura.spell_name = "Cura"
	cura.mp_cost = 10
	cura.type = SpellData.SpellType.HEAL
	cura.base_value = 30
	cura.applies_status = false
	unlock_spell(cura, false)
	equip_spell(cura)

func add_item(item: ItemData, amount: int = 1) -> void:
	if inventory.has(item):
		inventory[item] += amount
	else:
		inventory[item] = amount
	var msg = "Você obteve:\n[color=yellow]" + item.item_name + " x" + str(amount) + "[/color]"
	show_message_box(msg)

func remove_item(item: ItemData, amount: int = 1) -> bool:
	if inventory.has(item) and inventory[item] >= amount:
		inventory[item] -= amount
		if inventory[item] <= 0:
			inventory.erase(item)
		return true
	return false

func unlock_spell(spell: SpellData, show_notification: bool = true) -> void:
	if not unlocked_spells.has(spell):
		unlocked_spells.append(spell)
		if show_notification:
			var msg = "Nova magia desbloqueada!\n[color=cyan]" + spell.spell_name + "[/color]"
			show_message_box(msg)

func show_message_box(text: String) -> void:
	if not get_tree() or not get_tree().root:
		return
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(180, 40)
	panel.position = Vector2(102, 160)
	canvas.add_child(panel)
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[center]" + text + "[/center]"
	label.fit_content = true
	label.position = Vector2(5, 6)
	label.size = Vector2(170, 28)
	label.add_theme_font_size_override("normal_font_size", 8)
	label.add_theme_font_size_override("bold_font_size", 8)
	panel.add_child(label)
	get_tree().root.add_child.call_deferred(canvas)
	panel.modulate.a = 0.0
	await get_tree().process_frame
	if is_instance_valid(canvas):
		var tween = canvas.create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)
		tween.tween_interval(2.0)
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.finished.connect(func(): canvas.queue_free())

func equip_spell(spell: SpellData) -> bool:
	if equipped_spells.size() < 4 and not equipped_spells.has(spell):
		equipped_spells.append(spell)
		return true
	return false

func unequip_spell(spell: SpellData) -> void:
	equipped_spells.erase(spell)

func register_defeated_enemy(enemy_id: String) -> void:
	if enemy_id != "" and not defeated_enemies.has(enemy_id):
		defeated_enemies.append(enemy_id)
	defeated_enemy_id = enemy_id

func is_enemy_defeated(enemy_id: String) -> bool:
	return defeated_enemies.has(enemy_id) or defeated_enemy_id == enemy_id

func add_souls(amount: int) -> void:
	total_souls += amount

func spend_souls(amount: int) -> bool:
	if total_souls >= amount:
		total_souls -= amount
		return true
	return false

func sync_stats_from_game_manager(stats: CharacterStats) -> void:
	if current_hp == -1 or current_mp == -1:
		current_hp = stats.max_hp
		current_mp = stats.max_mp
	stats.current_hp = current_hp
	stats.current_mp = current_mp

func save_stats_to_game_manager(stats: CharacterStats) -> void:
	current_hp = stats.current_hp
	current_mp = stats.current_mp
