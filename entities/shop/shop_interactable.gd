extends Area2D
class_name ShopInteractable

enum ShopType { COINS_SHOP, SOULS_SANCTUARY }

@export var shop_type: ShopType = ShopType.COINS_SHOP
@export var shop_title: String = "Mercador"

@export var items_for_sale: Array[ItemData] = []
@export var equipments_for_sale: Array[EquipmentData] = []

@export var spells_for_sale: Array[SpellData] = []

const SHOP_UI_SCENE: PackedScene = preload("res://ui/shop/ShopUI.tscn")

var _player_in_range: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Players") or body.name == "Seiji":
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Players") or body.name == "Seiji":
		_player_in_range = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and not get_tree().paused and event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		_open_shop()

func _open_shop() -> void:
	var shop_ui := SHOP_UI_SCENE.instantiate() as ShopUI
	get_tree().root.add_child(shop_ui)
	if shop_type == ShopType.COINS_SHOP:
		shop_ui.open_coins_shop(shop_title, items_for_sale, equipments_for_sale)
	else:
		shop_ui.open_souls_shop(shop_title, spells_for_sale)
