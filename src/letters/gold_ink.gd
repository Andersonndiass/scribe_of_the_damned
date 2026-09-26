class_name GoldInk
extends Node2D
## Gota de tinta dourada (ficha 15, 6×8). Só visual; a lógica fica no GoldInkField (laço único).

const POOL_KEY := &"gold_ink"
const TEXTURE := preload("res://assets/placeholders/itm_gota_dourada.tres")

var magnet_speed: float = 0.0
var homing: bool = false


func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = TEXTURE
	add_child(s)


func start(pos: Vector2) -> void:
	global_position = pos
	magnet_speed = 0.0
	homing = false
