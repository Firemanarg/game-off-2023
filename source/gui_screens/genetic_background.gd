extends Node2D


const BlobsCount = 8
const AnimationStatesCount = 2
const MetaballScreenCenter: Vector2 = Vector2(0.89, 0.5)

#var _blobs: Array[Blob] = []
#var _finished_anim_count: int = 0
var animation_stage: int = 0
var _positions: PackedVector2Array = []
var _initial_positions: PackedVector2Array = []
var _final_positions: PackedVector2Array = []
var _percent: float = 0.0
var _anim_duration: float = 2.0

var _radii: PackedFloat32Array = []
var _radius: float = 0.4
var _initial_radius: float = 0.4
var _final_radius: float = 0.4
var _stage_tables: Array[Dictionary] = [
	{
		"get_sign": func(index: int): return 1 if index < BlobsCount / 2.0 else -1,
		"offset": Vector2(0.15, 0),
		"radius": 0.4,
	},
	{
		"get_sign": func(index: int): return 1 if index % 2 == 0 else -1,
		"offset": Vector2(0, 0.15),
		"radius": 0.55,
	},
]
#var _anim_offset: Vector2 = Vector2()
#var _anim_percent: float = 0.0
#var _anim_slowness: float = 50.0
#var _timer: float = 0.0

@onready var metaballs = get_node("CanvasLayer/Metaballs")
@onready var tween: Tween = null


func _ready() -> void:
	_positions.resize(BlobsCount)
	_initial_positions.resize(BlobsCount)
	_final_positions.resize(BlobsCount)
	_radii.resize(BlobsCount)
	_initial_positions.fill(MetaballScreenCenter)
	_positions.fill(MetaballScreenCenter)
	_positions.fill(MetaballScreenCenter)
	animation_stage = 0
	_initial_radius = 0.4
	_radii.fill(_initial_radius)
	play_animation()


func _process(delta: float) -> void:
	_update_blobs()


func _physics_process(delta: float) -> void:
	pass


func _update_blobs() -> void:
	for i in BlobsCount:
		_positions[i] = lerp(_initial_positions[i], _final_positions[i], _percent)
	_radius = lerp(_initial_radius, _final_radius, _percent)
	_radii.fill(_radius)
	metaballs.material.set_shader_parameter("positions", _positions)
	metaballs.material.set_shader_parameter("radii", _radii)


func play_animation() -> void:
	if animation_stage < AnimationStatesCount:
		_initial_positions = _positions.duplicate()
		var table: Dictionary = _stage_tables[animation_stage]
		_final_radius = table.radius
		for i in BlobsCount:
			var offset_sign: int = table.get_sign.call(i)
			var new_pos: Vector2 = _initial_positions[i]
			new_pos += table.offset * offset_sign
			_final_positions[i] = new_pos
		_create_tween()
		_percent = 0.0
		tween.tween_property(self, "_percent", 1.0, _anim_duration)


func _get_sign_stage_0(index: int) -> int:
	if index < (BlobsCount / 2.0):
		return 1
	return -1


func _create_tween() -> void:
	tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	tween.finished.connect(_on_tween_finished)


func _on_tween_finished() -> void:
	animation_stage += 1
	if animation_stage < AnimationStatesCount:
		play_animation()
