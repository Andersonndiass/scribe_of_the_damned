class_name ScreenRouter
extends Node
## Raiz do jogo (007 FR-712, T703): troca as telas (Splash, Menu, Personagem, Capítulo, Jogo…) e
## hospeda a partida (`main.tscn`), marcada com a meta "app" — é assim que o Main sabe que é o
## jogo de verdade (loja com tela, R reinicia). Os atalhos de debug do web e da linha de comando
## (`?stress`, `?roster`) trocam a cena direto; `?boss`, `?shop`, `?unlock=all`, `?atril=N` pulam os
## menus e vão para a partida.
## Transição (animation-agent): Bayer INK cobre e descobre; 100+100 ms entre menus, 200+200 ms
## entrando e saindo do jogo; a entrada fica travada durante a transição.

const SCREENS: Dictionary = {
	&"splash": "res://src/ui/screens/splash_screen.tscn",
	&"menu": "res://src/ui/screens/menu_screen.tscn",
	&"character": "res://src/ui/screens/character_screen.tscn",
	&"chapter": "res://src/ui/screens/chapter_screen.tscn",
	&"credits": "res://src/ui/screens/credits_screen.tscn",
	&"options": "res://src/ui/screens/options_screen.tscn",
	&"codex": "res://src/ui/screens/codex_screen.tscn",
	&"game": "res://src/main/main.tscn",
	&"cutscene": "res://src/cutscenes/cutscene_screen.tscn",
}
const DEBUG_SCENES: Dictionary = {
	"stress": "res://src/debug/stress_scene.tscn",
	"roster": "res://src/debug/roster_scene.tscn",
}
## Argumentos que pulam os menus direto para a partida.
const SKIP_TO_GAME: PackedStringArray = ["boss", "shop", "unlock=all", "atril="]
const FIRST_SCREEN := &"splash"
const FADE_MENU := 0.1
const FADE_GAME := 0.2
const FADE_LAYER := 100
const FADE_SHADER := preload("res://src/app/bayer_fade.gdshader")

var current: Node = null
var current_name: StringName = &""
var transitioning: bool = false

var _fade: ColorRect
var _fade_mat: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fade()
	EventBus.game_restart_requested.connect(func() -> void: request(&"game"))
	EventBus.screen_requested.connect(request)
	var args: String = debug_args()
	for key: String in DEBUG_SCENES:
		if args.contains(key):
			get_tree().change_scene_to_file.call_deferred(DEBUG_SCENES[key])
			return
	var cs: RegExMatch = RegEx.create_from_string("cutscene=(c\\d_\\d\\d)").search(args)
	if cs != null:
		GameState.cutscene_queue.clear()
		GameState.cutscene_queue.append(StringName(cs.get_string(1)))
		GameState.after_cutscene = &"menu"
		goto(&"cutscene")
		return
	for key: String in SKIP_TO_GAME:
		if args.contains(key):
			goto(&"game")
			return
	goto(FIRST_SCREEN)


## Troca com a transição (o que as telas pedem).
func request(screen: StringName) -> void:
	if transitioning or not SCREENS.has(screen):
		return
	transitioning = true
	var half: float = FADE_GAME if screen == &"game" or current_name == &"game" else FADE_MENU
	await _fade_to(1.0, half)
	goto(screen)
	await _fade_to(0.0, half)
	transitioning = false


## Troca na hora para a tela `screen` (a anterior sai da árvore).
func goto(screen: StringName) -> void:
	if current != null:
		remove_child(current)
		current.queue_free()
	get_tree().paused = false
	TimeScale.reset()
	var scene: PackedScene = load(SCREENS[screen])
	current = scene.instantiate()
	if screen == &"game":
		current.set_meta(&"app", true)
	current_name = screen
	add_child(current)
	EventBus.screen_changed.emit(screen)


func _input(event: InputEvent) -> void:
	_fullscreen_input(event)
	# Entrada travada durante a transição.
	if transitioning and not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


## Tela cheia (pedido do autor, 2026-10-02): o jogo abre em tela cheia (project.godot) e F11
## alterna. No navegador só dá para pedir tela cheia dentro de um clique ou tecla: o primeiro
## pedido sai na primeira entrada do jogador.
var _web_fullscreen_asked: bool = false


func _fullscreen_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"fullscreen", false):
		var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return
	if OS.has_feature("web") and not _web_fullscreen_asked and event.is_pressed() 			and (event is InputEventKey or event is InputEventMouseButton):
		_web_fullscreen_asked = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _fade_to(target: float, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(func(v: float) -> void: _fade_mat.set_shader_parameter(&"level", v),
		1.0 - target, target, duration)
	await tween.finished


func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = FADE_LAYER
	add_child(layer)
	_fade = ColorRect.new()
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_mat = ShaderMaterial.new()
	_fade_mat.shader = FADE_SHADER
	_fade_mat.set_shader_parameter(&"ink", Palette.INK)
	_fade_mat.set_shader_parameter(&"level", 0.0)
	_fade.material = _fade_mat
	layer.add_child(_fade)


## Argumentos de debug: linha de comando (depois de --) e, no web, a query da URL.
static func debug_args() -> String:
	var asked: String = " ".join(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		if search is String:
			asked += " " + (search as String)
	return asked
