extends Resource
class_name EnemyData

@export var enemy_name: String = "Inimigo"
@export var stats: CharacterStats
@export var sprite_frames: SpriteFrames
@export var battle_sprite_scale: Vector2 = Vector2(1, 1)
@export var souls_reward: int = 10
@export var coins_reward: int = 10
@export var spells: Array[SpellData] = []
