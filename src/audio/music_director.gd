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

## Modo sections: a faixa audível agora (as outras em silêncio, tocando).
var section: int = 0
var _gain := PackedFloat32Array()
## Modo sections: duração da onda e tempo de jogo dentro dela (pausa e câmera lenta contam).
var _wave_len: float = 0.0
var _wave_t: float = 0.0
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
	if p_data == data and _is_playing():
		return  # a mesma música segue (ex.: Menu → Opções)
	data = p_data
	active_layers = 1
	section = 0
	_wave_len = 0.0
	_wave_t = 0.0
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


func on_wave_started(index: int, duration: float = 0.0) -> void:
	if data != null:
		active_layers = data.layers_for_fraction(data.fraction_for_wave(index))
		_fade_ms = data.fade_ms
		_wave_len = duration
		_wave_t = 0.0
		section = 0


## Fim da onda: a batalha volta à calma (loja e intervalo).
func on_wave_ended() -> void:
	_wave_len = 0.0
	section = 0
	if data != null:
		_fade_ms = data.fade_ms


func on_player_died() -> void:
	active_layers = 1
	section = 0
	_wave_len = 0.0
	if data != null:
		_fade_ms = data.death_fade_ms


func gain_of(i: int) -> float:
	return _gain[i]


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var real_dt: float = float(now - _last_us) / 1_000_000.0 if _last_us > 0 else 0.0
	_last_us = now
	if not get_tree().paused:
		advance_wave(real_dt * Engine.time_scale)
	step(real_dt)


## Modo sections: avança `game_dt` s de onda (tempo de jogo) e sobe de faixa pelo progresso.
## Só sobe dentro da onda (o clímax não volta para a calma antes do fim).
func advance_wave(game_dt: float) -> void:
	if data == null or data.mode != &"sections" or _wave_len <= 0.0:
		return
	_wave_t += game_dt
	section = maxi(section, data.section_for_fraction(_wave_t / _wave_len))


## Avança as rampas de volume por `delta` s (tempo real).
func step(delta: float) -> void:
	if data == null:
		return
	var rate: float = delta * 1000.0 / float(maxi(1, _fade_ms))
	for i: int in MAX_LAYERS:
		var target: float = 1.0 if i < active_layers else 0.0
		if data.mode == &"sections":
			target = 1.0 if i == section else 0.0
		_gain[i] = move_toward(_gain[i], target, rate)
		players[i].volume_db = _db(_gain[i])


func _db(gain: float) -> float:
	var extra: float = data.volume_db if data != null else 0.0
	return maxf(SILENT_DB, linear_to_db(gain) + extra) if gain > 0.0 else SILENT_DB


func _is_playing() -> bool:
	for p: AudioStreamPlayer in players:
		if p.playing:
			return true
	return false
