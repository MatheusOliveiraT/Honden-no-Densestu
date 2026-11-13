extends Control
class_name BattleStatusHeader

@onready var name_label: Label = %Nome
@onready var hp_value: Label = %label_hp
@onready var mp_value: Label = %label_mp
@onready var hp_bar: ProgressBar = %barra_hp
@onready var mp_bar: ProgressBar = %barra_mp

const COLOR_NORMAL := Color.WHITE
const COLOR_LOW := Color.RED
const LOW_HP_RATIO := 0.25
const BAR_TIME := 0.25

var _stats: CharacterStats
var _last := Vector4i(-1, -1, -1, -1)  # x = HP, y = HP máx, z = MP, w = MP máx
var _tweens := {}

func bind(stats: CharacterStats) -> void:
	_stats = stats
	name_label.text = stats.character_name
	_last = Vector4i(-1, -1, -1, -1)
	_refresh(true)

func _process(_delta: float) -> void:
	if _stats:
		_refresh(false)

func _refresh(instant: bool) -> void:
	var now := Vector4i(_stats.current_hp, _stats.max_hp, _stats.current_mp, _stats.max_mp)
	if now == _last:
		return
	_last = now
	hp_value.text = "%d/%d" % [now.x, now.y]
	mp_value.text = "%d/%d" % [now.z, now.w]
	var low := now.y > 0 and float(now.x) / float(now.y) <= LOW_HP_RATIO
	hp_value.add_theme_color_override("font_color", COLOR_LOW if low else COLOR_NORMAL)
	hp_bar.max_value = now.y
	mp_bar.max_value = now.w
	_animate(hp_bar, now.x, instant)
	_animate(mp_bar, now.z, instant)

func _animate(bar: ProgressBar, target: float, instant: bool) -> void:
	if _tweens.has(bar) and _tweens[bar].is_valid():
		_tweens[bar].kill()
	if instant:
		bar.value = target
		return
	var tw := create_tween()
	tw.tween_property(bar, "value", target, BAR_TIME)
	_tweens[bar] = tw
