extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.color.a = 0.0
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)

func fade_to_battle(target_scene_path: String) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	await tween.finished
	
	get_tree().change_scene_to_file(target_scene_path)
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "color:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
