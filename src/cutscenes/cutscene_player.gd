class_name CutscenePlayer
extends CanvasLayer
## Toca uma cutscene (008 FR-802b, FR-804–FR-806b, T811). Monta o palco a partir do roteiro
## (atores criados no load, nunca durante a cena), toca a `Animation` do builder num
## AnimationPlayer avançado à mão (tempo real: o hit-stop não desacelera) e dispara os cues.
## Espaço/Enter/clique completa o texto e, completo, pula para o fim da fala; segurar Esc
## (`skip_hold`) pula a cena. Pular = mesmo estado final: trilhas no valor final, marcas pendentes
## em ordem e `cutscene_finished` sempre por último — também com roteiro quebrado (fail-open).
## FSM: IDLE → READY → PLAYING → FINISHING → IDLE.

enum Phase { IDLE, READY, PLAYING, FINISHING }

const LAYER := 30
const ANIM := &"cutscene"
const TUNING_PATH := "res://data/tuning/cutscene.tres"

@export var tuning: CutsceneTuning

var state: Phase = Phase.IDLE
var cutscene_id: StringName = &""
var build: CutsceneBuilder.Result = null
## Índice do próximo cue a disparar (o cursor só anda para frente).
var next_cue: int = 0
## Segundos segurando Esc (zera ao soltar).
var skip_progress: float = 0.0
var skipped: bool = false
## Marcas disparadas nesta cena, em ordem (testes e depuração).
var marks_fired: Array[StringName] = []

var stage: Node2D
var band: CutsceneBand
var player: AnimationPlayer
var _layers: Dictionary = {}


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _ready() -> void:
	if tuning == null:
		tuning = load(TUNING_PATH)
	stage = Node2D.new()
	stage.name = "Stage"
	add_child(stage)
	for l: String in CutsceneScript.LAYERS:
		var n := Node2D.new()
		n.name = l
		stage.add_child(n)
		_layers[l] = n
	band = CutsceneBand.new()
	band.name = "Band"
	band.cutscene = self
	add_child(band)
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	# O root_node padrão ("..") é este nó: as trilhas `Stage/...` e o `_cue` resolvem aqui.
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	add_child(player)


## Prepara a cena `id` (lê, valida, monta o palco e a animação). Falha = a cena termina na hora ao
## tocar (o jogo nunca trava).
func load_cutscene(id: StringName) -> bool:
	var s: CutsceneScript = CutsceneScript.load_file(CutsceneScript.DIR + String(id) + ".json")
	return load_script(s, id)


## Prepara um roteiro já lido (os testes montam roteiros na hora).
func load_script(s: CutsceneScript, id: StringName = &"") -> bool:
	_clear()
	cutscene_id = id if id != &"" else s.id
	if not s.errors.is_empty():
		for e: String in s.errors:
			push_error("Cutscene: " + e)
		build = null
		state = Phase.READY
		return false
	build = CutsceneBuilder.build(s)
	stage.scale = Vector2.ONE * s.stage_scale
	_build_stage(s)
	var lib := AnimationLibrary.new()
	lib.add_animation(ANIM, build.animation)
	if player.has_animation_library(&""):
		player.remove_animation_library(&"")
	player.add_animation_library(&"", lib)
	state = Phase.READY
	return true


func play() -> void:
	if state != Phase.READY:
		return
	visible = true
	skipped = false
	skip_progress = 0.0
	next_cue = 0
	marks_fired.clear()
	state = Phase.PLAYING
	EventBus.cutscene_started.emit(cutscene_id)
	if build == null:
		_finish()
		return
	player.play(ANIM)
	player.seek(0.0, true)
	_advance_time(0.0)


func is_playing() -> bool:
	return state == Phase.PLAYING


func current_time() -> float:
	return player.current_animation_position if build != null and player.has_animation(ANIM) else 0.0


func _process(delta: float) -> void:
	if state != Phase.PLAYING:
		return
	# Tempo real: o hit-stop (Engine.time_scale) não desacelera a cena.
	var real: float = delta / maxf(Engine.time_scale, 0.001)
	var holding: bool = Input.is_action_pressed(&"pause")
	skip_progress = skip_progress + real if holding else 0.0
	band.update_skip(real, holding, minf(skip_progress / tuning.skip_hold, 1.0), tuning.skip_show_after,
		tuning.skip_hold, tuning.skip_drain)
	if skip_progress >= tuning.skip_hold:
		skip()
		return
	tick(real)


## Avança a cena `dt` segundos (o _process chama; os testes também).
func tick(dt: float) -> void:
	if state != Phase.PLAYING:
		return
	band.tick(dt, tuning.chars_per_second)
	_advance_time(dt)


func _advance_time(dt: float) -> void:
	player.advance(dt)
	if state == Phase.PLAYING and current_time() >= build.animation.length - 0.0001:
		_flush_to(build.animation.length)
		_finish()


func _input(event: InputEvent) -> void:
	if state == Phase.IDLE:
		return
	# A entrada é da cena: o Esc não abre a Pausa por baixo (FR-806b).
	get_viewport().set_input_as_handled()
	if state != Phase.PLAYING or not event.is_pressed() or event.is_echo():
		return
	var click: bool = event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action(&"cast") or event.is_action(&"shop_next") or event.is_action(&"ui_accept"):
		advance()


## Espaço: completa o texto; com o texto completo, pula para o fim da fala.
func advance() -> void:
	if state != Phase.PLAYING:
		return
	if band.typing():
		band.complete()
	elif band.has_line():
		var end: float = CutsceneBuilder.snap(float(band.line["end"]))
		player.seek(end, true)
		_flush_to(end)
		_advance_time(0.0)


## Pula a cena inteira: trilhas no valor final, marcas pendentes em ordem, fim por último.
func skip() -> void:
	if state != Phase.PLAYING:
		return
	skipped = true
	AudioManager.stop_line_voice()
	EventBus.cutscene_skipped.emit(cutscene_id)
	if build != null:
		player.seek(build.animation.length, true)
		_flush_to(build.animation.length)
	_finish()


## Chamado pela trilha de método: dispara todos os cues pendentes até `index`.
func _cue(index: int) -> void:
	if build == null:
		return
	while next_cue <= index and next_cue < build.cues.size():
		_fire(build.cues[next_cue], false)
		next_cue += 1


## Dispara os cues até o tempo `t` que ficaram para trás num seek: marcas em ordem; falas e sons
## do trecho pulado são descartados (a legenda e a faixa ficam no estado certo).
func _flush_to(t: float) -> void:
	if build == null:
		return
	var frame: int = CutsceneScript.frame_of(t)
	while next_cue < build.cues.size() and build.cues[next_cue]["frame"] <= frame:
		_fire(build.cues[next_cue], true)
		next_cue += 1


func _fire(cue: Dictionary, skipping: bool) -> void:
	var p: Dictionary = cue["payload"]
	match cue["kind"]:
		&"line_start":
			if not skipping:
				band.show_line(p)
				AudioManager.play_line_voice(str(p["key"]))
		&"line_end":
			if band.line == p:
				band.hide_line()
		&"caption_on":
			band.show_caption(p)
		&"caption_off":
			if band.caption == p:
				band.hide_caption()
		&"sound":
			if not skipping:
				AudioManager.play(StringName(str(p["id"])), true)
		&"mark":
			var mark := StringName(str(p["id"]))
			marks_fired.append(mark)
			EventBus.cutscene_mark_reached.emit(cutscene_id, mark)


func _finish() -> void:
	if state == Phase.FINISHING or state == Phase.IDLE:
		return
	state = Phase.FINISHING
	player.stop(true)
	band.hide_line()
	band.hide_caption()
	visible = false
	state = Phase.IDLE
	EventBus.cutscene_finished.emit(cutscene_id, skipped)


func _clear() -> void:
	for l: Node2D in _layers.values():
		for c: Node in l.get_children():
			l.remove_child(c)
			c.queue_free()


## Cria os atores do roteiro nas camadas, com os valores iniciais.
func _build_stage(s: CutsceneScript) -> void:
	for name: String in s.actors:
		var a: Dictionary = s.actors[name]
		var node: Node2D = _make_actor(a)
		node.name = name
		(_layers[str(a["layer"])] as Node2D).add_child(node)
		var init: Dictionary = a.get("init", {})
		for prop: String in init:
			node.set_indexed(NodePath(prop), CutsceneScript.convert_value(prop, init[prop]))


func _make_actor(a: Dictionary) -> Node2D:
	var src: String = a["src"]
	match str(a["kind"]):
		"sprite":
			var sp := Sprite2D.new()
			sp.texture = load(src)
			return sp
		"frames":
			var an := AnimatedSprite2D.new()
			var res: Resource = load(src)
			an.sprite_frames = res if res is SpriteFrames else res.get(&"sprite_frames")
			var names: PackedStringArray = an.sprite_frames.get_animation_names()
			if not names.is_empty():
				an.play(names[0])
			return an
	# "fx": uma cena (.tscn) ou um script de desenho (.gd, CutsceneFx).
	var loaded: Resource = load(src)
	if loaded is Script:
		return (loaded as Script).new()
	return (loaded as PackedScene).instantiate()
