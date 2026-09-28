extends Miracle
## FIDES — escudo que absorve o próximo golpe (002 FR-206). Usa: charges.
## Dura até ser consumido ou até o fim da onda (o PlayerBuffs cuida disso); reconjurar renova.
## Visual (design-agent): arco GOLD_LIGHT de 1 px sobre a cabeça enquanto houver carga; ao
## absorver, anel CHALK de 2 px abrindo de r 8 a r 20 em 0.2 s.

const HEAD := Vector2(0, -22)
const ARC_RADIUS := 10.0
const ARC_FROM := deg_to_rad(200.0)
const ARC_TO := deg_to_rad(340.0)
const POP_TIME := 0.2
const POP_FROM := 8.0
const POP_TO := 20.0

var _player: Player
var _pop_left: float = -1.0


func _on_start() -> void:
	_pop_left = -1.0
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player != null:
		_player.buffs.apply_fides(word.charges)
	if not EventBus.shield_broken.is_connected(_on_broken):
		EventBus.shield_broken.connect(_on_broken)
	_follow()
	queue_redraw()


func _on_broken(_pos: Vector2) -> void:
	_pop_left = POP_TIME


func _process(delta: float) -> void:
	_follow()
	if _pop_left >= 0.0:
		_pop_left -= delta
		if _pop_left < 0.0:
			_end()
			return
	elif _player == null or not _player.buffs.has_shield():
		_end()
		return
	queue_redraw()


func _follow() -> void:
	if _player != null:
		global_position = _player.global_position.round()


func _end() -> void:
	if EventBus.shield_broken.is_connected(_on_broken):
		EventBus.shield_broken.disconnect(_on_broken)
	finish()


func _draw() -> void:
	if _pop_left >= 0.0:
		var k: float = 1.0 - _pop_left / POP_TIME
		draw_arc(HEAD, lerpf(POP_FROM, POP_TO, k), 0.0, TAU, 32, Palette.CHALK, 2.0, false)
		return
	draw_arc(HEAD, ARC_RADIUS, ARC_FROM, ARC_TO, 12, Palette.GOLD_LIGHT, 1.0, false)
