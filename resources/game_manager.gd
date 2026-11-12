extends Node

var player_map_position: Vector2 = Vector2.ZERO
var returning_from_battle: bool = false
var current_map_scene_path: String = "res://levels/floresta/floresta.tscn"

var defeated_enemy_id: String = ""
var defeated_enemies: Array[String] = []

var current_hp: int = -1
var current_mp: int = -1

var total_souls: int = 0
var total_coins: int = 0

var current_enemy_data: EnemyData

var current_level: int = 1

var current_enemy_party_data: Array[EnemyData] = []

var unlocked_spells: Array[SpellData] = []
var equipped_spells: Array[SpellData] = []

var inventory: Dictionary = {}

var owned_equipments: Array[EquipmentData] = []
var equipped_weapon: EquipmentData = null
var equipped_armor: EquipmentData = null

var is_transitioning: bool = false

func _ready() -> void:
	_init_default_spells()

func _init_default_spells() -> void:
	var cura := load("res://resources/spells/cura.tres") as SpellData
	unlock_spell(cura, false)
	equip_spell(cura)

func disable_all_overworld_enemies() -> void:
	is_transitioning = true
	var enemies = get_tree().get_nodes_in_group("Enemies")
	for enemy in enemies:
		if enemy is OverworldEnemy:
			enemy.set_physics_process(false)
			if is_instance_valid(enemy.interaction_area):
				enemy.interaction_area.set_deferred("monitoring", false)
				enemy.interaction_area.set_deferred("monitorable", false)

func add_equipment(equip: EquipmentData) -> void:
	if not owned_equipments.has(equip):
		owned_equipments.append(equip)
	show_message_box("Equipamento obtido:\n[color=yellow]" + equip.get_display_name() + "[/color]")

func equip_item(equip: EquipmentData, stats: CharacterStats) -> void:
	match equip.slot:
		EquipmentData.EquipmentSlot.WEAPON:
			equipped_weapon = equip
			stats.equipped_weapon = equip
		EquipmentData.EquipmentSlot.ARMOR:
			equipped_armor = equip
			stats.equipped_armor = equip
	show_message_box("[color=green]" + equip.get_display_name() + "[/color] equipado!")

func unequip_slot(slot: EquipmentData.EquipmentSlot, stats: CharacterStats) -> void:
	var removed: EquipmentData = null
	match slot:
		EquipmentData.EquipmentSlot.WEAPON:
			removed = equipped_weapon
			equipped_weapon = null
			stats.equipped_weapon = null
		EquipmentData.EquipmentSlot.ARMOR:
			removed = equipped_armor
			equipped_armor = null
			stats.equipped_armor = null
	if removed:
		show_message_box("[color=green]" + removed.get_display_name() + "[/color] desequipado!")
	else:
		show_message_box("Equipamento removido.")

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
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.layer = 100
	var panel = NinePatchRect.new()
	panel.texture = load("res://ui/textures/menu-5.png")
	panel.patch_margin_left = 8
	panel.patch_margin_top = 8
	panel.patch_margin_right = 8
	panel.patch_margin_bottom = 8
	panel.custom_minimum_size = Vector2(220, 52)
	panel.position = Vector2(82, 146).round()
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.add_child(panel)
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[center]" + text + "[/center]"
	label.fit_content = true
	label.position = Vector2(5, 6)
	label.size = Vector2(210, 40)
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label.add_theme_constant_override("line_separation", 4)
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

func add_coins(amount: int) -> void:
	total_coins += amount

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
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

func upgrade_equipment(equip: EquipmentData, stats: CharacterStats = null) -> bool:
	if not equip or not equip.can_upgrade():
		show_message_box("Equipamento já está no nível máximo!")
		return false
	var cost = equip.get_upgrade_cost()
	if spend_souls(cost):
		equip.upgrade()
		show_message_box("[color=yellow]" + equip.item_name + "[/color] melhorado para [color=cyan]LV " + str(equip.level) + "[/color]!")
		if stats:
			save_stats_to_game_manager(stats)
		return true
	else:
		show_message_box("Almas insuficientes! (Requer: " + str(cost) + " Almas)")
		return false

func get_save_path(slot_index: int) -> String:
	return "user://save_slot_" + str(slot_index) + ".json"

func get_save_image_path(slot_index: int) -> String:
	return "user://save_slot_" + str(slot_index) + ".png"

func _capture_and_save_screenshot(slot_index: int) -> void:
	var pause_menu = get_tree().get_first_node_in_group("PauseMenu") as PauseMenu
	if not pause_menu:
		pause_menu = get_tree().root.get_node_or_null("PauseMenu") as PauseMenu
	if pause_menu and pause_menu.has_method("hide_for_screenshot"):
		pause_menu.hide_for_screenshot()
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = get_tree().root.get_viewport().get_texture().get_image()
	if pause_menu and pause_menu.has_method("restore_after_screenshot"):
		pause_menu.restore_after_screenshot()
	img.save_png(get_save_image_path(slot_index))
	await get_tree().process_frame

func get_slot_thumbnail(slot_index: int) -> Texture2D:
	var path = get_save_image_path(slot_index)
	if FileAccess.file_exists(path):
		var img = Image.load_from_file(path)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func save_game(slot_index: int = 1) -> void:
	await _capture_and_save_screenshot(slot_index)
	var player = get_tree().get_first_node_in_group("Players")
	if player:
		player_map_position = player.global_position
	var inventory_serialized: Dictionary = {}
	for item in inventory.keys():
		if item is ItemData and item.resource_path != "":
			inventory_serialized[item.resource_path] = inventory[item]
	var owned_equipments_serialized: Array = []
	for equip in owned_equipments:
		var p: String = equip.get_source_path()
		if p != "":
			owned_equipments_serialized.append({
				"path": p,
				"level": equip.level
			})
	var unlocked_spells_serialized: Array[String] = []
	for spell in unlocked_spells:
		if spell is SpellData and spell.resource_path != "":
			unlocked_spells_serialized.append(spell.resource_path)
	var equipped_spells_serialized: Array[String] = []
	for spell in equipped_spells:
		if spell is SpellData and spell.resource_path != "":
			equipped_spells_serialized.append(spell.resource_path)
	var datetime = Time.get_datetime_dict_from_system()
	var formatted_date = "%04d/%02d/%02d %02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute
	]
	var save_data: Dictionary = {
		"save_date": formatted_date,
		"current_map_scene_path": current_map_scene_path,
		"player_position_x": player_map_position.x,
		"player_position_y": player_map_position.y,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"total_souls": total_souls,
		"total_coins": total_coins,
		"current_level": current_level,
		"defeated_enemies": defeated_enemies,
		"inventory": inventory_serialized,
		"owned_equipments": owned_equipments_serialized,
		"equipped_weapon_path": equipped_weapon.get_source_path() if equipped_weapon else "",
		"equipped_armor_path": equipped_armor.get_source_path() if equipped_armor else "",
		"unlocked_spells": unlocked_spells_serialized,
		"equipped_spells": equipped_spells_serialized
	}
	var path = get_save_path(slot_index)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		
func load_game(slot_index: int = 1) -> bool:
	var path = get_save_path(slot_index)
	if not FileAccess.file_exists(path):
		show_message_box("[color=red]Slot " + str(slot_index) + " vazio![/color]")
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return false
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) != OK: return false
	var save_data: Dictionary = json.data
	current_map_scene_path = save_data.get("current_map_scene_path", "res://levels/floresta/floresta.tscn")
	player_map_position = Vector2(save_data.get("player_position_x", 0.0), save_data.get("player_position_y", 0.0))
	current_hp = save_data.get("current_hp", -1)
	current_mp = save_data.get("current_mp", -1)
	total_souls = save_data.get("total_souls", 0)
	total_coins = save_data.get("total_coins", 0)
	current_level = save_data.get("current_level", 1)
	var def_enemies = save_data.get("defeated_enemies", [])
	defeated_enemies.clear()
	for enemy_id in def_enemies:
		defeated_enemies.append(str(enemy_id))
	inventory.clear()
	var inv_data: Dictionary = save_data.get("inventory", {})
	for res_path in inv_data.keys():
		if ResourceLoader.exists(res_path):
			var item_res = load(res_path) as ItemData
			if item_res: inventory[item_res] = int(inv_data[res_path])
	owned_equipments.clear()
	equipped_weapon = null
	equipped_armor = null
	var eq_data: Array = save_data.get("owned_equipments", [])
	for eq_info in eq_data:
		var res_path = eq_info.get("path", "")
		if ResourceLoader.exists(res_path):
			var eq_res := (load(res_path) as EquipmentData).duplicate() as EquipmentData
			eq_res.source_path = res_path
			eq_res.level = int(eq_info.get("level", 1))
			owned_equipments.append(eq_res)
	var eq_w_path = save_data.get("equipped_weapon_path", "")
	if eq_w_path != "":
		for eq in owned_equipments:
			if eq.get_source_path() == eq_w_path:
				equipped_weapon = eq
				break
	var eq_a_path = save_data.get("equipped_armor_path", "")
	if eq_a_path != "":
		for eq in owned_equipments:
			if eq.get_source_path() == eq_a_path:
				equipped_armor = eq
				break
	unlocked_spells.clear()
	for s_path in save_data.get("unlocked_spells", []):
		if ResourceLoader.exists(s_path):
			var spell_res = load(s_path) as SpellData
			if spell_res: unlocked_spells.append(spell_res)
	equipped_spells.clear()
	for s_path in save_data.get("equipped_spells", []):
		if ResourceLoader.exists(s_path):
			var spell_res = load(s_path) as SpellData
			if spell_res: equipped_spells.append(spell_res)
	if unlocked_spells.is_empty():
		_init_default_spells()
	returning_from_battle = true
	get_tree().paused = false
	get_tree().change_scene_to_file(current_map_scene_path)
	is_transitioning = false
	return true

func get_slot_info(slot_index: int) -> Dictionary:
	var path = get_save_path(slot_index)
	if not FileAccess.file_exists(path):
		return {"exists": false}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return {"exists": false}
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {"exists": false}
	file.close()
	var data: Dictionary = json.data
	data["exists"] = true
	return data
