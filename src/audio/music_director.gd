class_name MusicDirector
extends Node
## Música em camadas (009 FR-908, FR-909). Os players são criados uma vez, no _ready; todas as
## camadas começam no mesmo frame e nunca param: ligar ou desligar é só a rampa de volume.
## A intensidade vem da onda (fração do capítulo) e volta à base quando o escriba morre.

const MAX_LAYERS := 4
const SILENT_DB := -80.0

var data: MusicData
var players: Array[AudioStreamPlayer] = []
var active_layers: int = 1

var _gain := PackedFloat32Array()
var _fade_ms: int = 700
## Relógio real: a rampa não desacelera no hit-stop (time_scale; animation-agent).
var _last_us: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gain.resize(MAX_LAYERS)
	for i: int in MAX_LAYERS:
		var p := AudioStreamPlayer.new()
		p.bus = &"Music"
		p.volume_db = SILENT_DB
		add_child(p)
		players.append(p)


## Começa a música `p_data` (todas as camadas juntas; só a base audível).
func start(p_data: MusicData) -> void:
	data = p_data
	active_layers = 1
	_fade_ms = data.fade_ms
	for i: int in MAX_LAYERS:
		var p: AudioStreamPlayer = players[i]
		p.stop()
		p.stream = data.layers[i] if i < data.layers.size() else null
		_gain[i] = 1.0 if i == 0 else 0.0
		p.volume_db = _db(_gain[i])
	for p: AudioStreamPlayer in players:
		if p.stream != null:
			p.play()


func stop() -> void:
	data = null
	for p: AudioStreamPlayer in players:
		p.stop()


func on_wave_started(index: int) -> void:
	if data != null:
		active_layers = data.layers_for_fraction(data.fraction_for_wave(index))
		_fade_ms = data.fade_ms


func on_player_died() -> void:
	active_layers = 1
	if data != null:
		_fade_ms = data.death_fade_ms


func gain_of(i: int) -> float:
	return _gain[i]


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var real_dt: float = float(now - _last_us) / 1_000_000.0 if _last_us > 0 else 0.0
	_last_us = now
	step(real_dt)


## Avança as rampas de volume por `delta` s (tempo real).
func step(delta: float) -> void:
	if data == null:
		return
	var rate: float = delta * 1000.0 / float(maxi(1, _fade_ms))
	for i: int in MAX_LAYERS:
		var target: float = 1.0 if i < active_layers else 0.0
		_gain[i] = move_toward(_gain[i], target, rate)
		players[i].volume_db = _db(_gain[i])


func _db(gain: float) -> float:
	return maxf(SILENT_DB, linear_to_db(gain)) if gain > 0.0 else SILENT_DB
