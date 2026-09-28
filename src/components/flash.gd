class_name Flash
extends Node
## Pisca o CanvasItem alvo em CHALK por 60ms via shader (art bible §4: flash é shader, não frame).

const SHADER := preload("res://assets/shaders/hit_flash.gdshader")

@export var target: CanvasItem
@export var duration: float = 0.06

var _material: ShaderMaterial
var _time_left: float = 0.0


func _ready() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter(&"flash_color", Palette.CHALK)
	_material.set_shader_parameter(&"flash_amount", 0.0)
	target.material = _material
	set_process(false)


func play() -> void:
	_time_left = duration
	_material.set_shader_parameter(&"flash_amount", 1.0)
	set_process(true)


## VAPOR: escriba oculto em xadrez (dithering, Princípio VII).
func set_dither_hidden(on: bool) -> void:
	_material.set_shader_parameter(&"dither_hide", 1.0 if on else 0.0)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_material.set_shader_parameter(&"flash_amount", 0.0)
		set_process(false)
