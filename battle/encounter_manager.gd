class_name EncounterManager

const ENEMIES = {
	"tsuchinoko": "res://entities/enemies/tsuchinoko/tsuchinoko_data.tres",
	"kappa": "res://entities/enemies/kappa/kappa_data.tres",
	"yuurei": "res://entities/enemies/yuurei/yuurei_data.tres",
	"rokurokubi": "res://entities/enemies/rokurokubi/rokurokubi_data.tres"
}

const LEVEL_POOL = {
	1: ["tsuchinoko", "kappa"],
	2: ["tsuchinoko", "kappa"],
	3: ["tsuchinoko", "kappa", "yuurei"],
	4: ["tsuchinoko", "kappa", "yuurei", "rokurokubi"],
	6: ["kappa", "yuurei", "rokurokubi"],
	7: ["yuurei", "rokurokubi"]
}

static func generate_encounter(leader_data: EnemyData, level: int) -> Array[EnemyData]:
	var party: Array[EnemyData] = []
	party.append(leader_data)
	# 60% chance de vir 1 inimigo, 30% chance de vir 2, 10% chance de vir 3
	var rand_val = randf()
	var total_enemies = 1
	if rand_val > 0.90:
		total_enemies = 3
	elif rand_val > 0.60:
		total_enemies = 2
	if total_enemies == 1:
		return party
	var available_pool: Array = LEVEL_POOL.get(level, ["kappa"]).duplicate()
	for i in range(total_enemies - 1):
		var random_enemy_key = available_pool.pick_random()
		var enemy_res = load(ENEMIES[random_enemy_key]) as EnemyData
		if enemy_res:
			party.append(enemy_res)
	return party
