extends Node2D

@onready var map_layer: TileMapLayer = $Mapa
@onready var wall_layer: TileMapLayer = $pedras
@onready var camera: Camera2D = $YSortWorld/Seiji/Camera2D

func _ready() -> void:
	var full_bounds := _calculate_combined_bounds()
	_setup_camera_limits(full_bounds)
	_create_map_boundaries(full_bounds)

func _calculate_combined_bounds() -> Rect2:
	var tile_size: Vector2 = Vector2(map_layer.tile_set.tile_size)
	var map_rect := map_layer.get_used_rect()
	var total_rect := Rect2(
		map_layer.global_position + Vector2(map_rect.position) * tile_size,
		Vector2(map_rect.size) * tile_size
	)
	if wall_layer and wall_layer.get_used_rect().has_area():
		var wall_rect := wall_layer.get_used_rect()
		var wall_tile_size := Vector2(wall_layer.tile_set.tile_size)
		var wall_pixel_rect := Rect2(
			wall_layer.global_position + Vector2(wall_rect.position) * wall_tile_size,
			Vector2(wall_rect.size) * wall_tile_size
		)
		total_rect = total_rect.merge(wall_pixel_rect)
	return total_rect

func _setup_camera_limits(bounds: Rect2) -> void:
	if not camera:
		return
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)

func _create_map_boundaries(bounds: Rect2) -> void:
	var border_body := StaticBody2D.new()
	border_body.name = "MapBoundaries"
	add_child(border_body)
	var borders := [
		{ "pos": Vector2(0, bounds.position.y), "normal": Vector2.DOWN },
		{ "pos": Vector2(0, bounds.end.y), "normal": Vector2.UP },
		{ "pos": Vector2(bounds.position.x, 0), "normal": Vector2.RIGHT },
		{ "pos": Vector2(bounds.end.x, 0), "normal": Vector2.LEFT }  
	]
	for b in borders:
		var col := CollisionShape2D.new()
		var shape := WorldBoundaryShape2D.new()
		shape.normal = b["normal"]
		col.shape = shape
		col.position = b["pos"]
		border_body.add_child(col)
