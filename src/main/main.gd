extends Node2D
## Cena principal: monta arena, mundo e pools, e inicia a partida.

const TELEGRAPH_SCENE := preload("res://src/enemies/spawn_telegraph.tscn")
const DISSOLVE_SCENE := preload("res://src/enemies/dissolve_fx.tscn")
const LETTER_SCENE := preload("res://src/letters/letter.tscn")
const GOLD_SCENE := preload("res://src/letters/gold_ink.tscn")
## Até ~8 campeões × 5 gotas no chão ao mesmo tempo (excedente some: D-037).
const GOLD_PREWARM := 40
const TELEGRAPH_PREWARM := 64
## Cobre uma MORTIS na capacidade máxima do EnemyManager (visual; excedente é pulado).
const DISSOLVE_PREWARM := EnemyManager.CAPACITY
const LETTER_PREWARM := 150
## Instâncias de cada milagre em paralelo (conjurar é limitado pela coleta de letras).
const MIRACLE_PREWARM := 4

const STRESS_SCENE := "res://src/debug/stress_scene.tscn"
const ROSTER_SCENE := "res://src/debug/roster_scene.tscn"
@export var player_data: PlayerData
## Sequência de ondas do capítulo (005 FR-513). O chefe entra depois da última (006).
@export var chapter: ChapterData
## Pausa entre ondas (a loja entra aqui na feature 003).
@export var between_waves: float = 3.0

@onready var player_projectiles: PlayerProjectileManager = $PlayerProjectiles
@onready var telegraph_layer: Node2D = $TelegraphLayer
@onready var fx_layer: Node2D = $FxLayer
@onready var wave_director: WaveDirector = $WaveDirector
@onready var letter_field: LetterField = $World/LetterField
@onready var miracle_layer: Node2D = $MiracleLayer
@onready var overlays: MinimalOverlays = $Overlays

var _next_wave_in: float = -1.0
## Índice (0-based) da onda atual no capítulo.
var wave_slot: int = 0


func _ready() -> void:
	var debug_scene: String = _debug_scene_requested()
	if debug_scene != "":
		get_tree().change_scene_to_file.call_deferred(debug_scene)
		return
	GameState.start_run(player_data)
	($World/Player as Player).auto_attack.projectiles = player_projectiles
	PoolManager.register(SpawnTelegraph.POOL_KEY, TELEGRAPH_SCENE, TELEGRAPH_PREWARM, telegraph_layer)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, DISSOLVE_PREWARM, fx_layer)
	PoolManager.register(Letter.POOL_KEY, LETTER_SCENE, LETTER_PREWARM, letter_field)
	PoolManager.register(GoldInk.POOL_KEY, GOLD_SCENE, GOLD_PREWARM, $World/GoldInkField)
	for word: WordData in letter_field.lexicon_data.words:
		if word.miracle_scene != null:
			PoolManager.register(word.id, word.miracle_scene, MIRACLE_PREWARM, miracle_layer)
	for combo: ComboData in ($Caster as Caster).combos:
		# Vapor e o fogo da Flamma ficam abaixo das letras do chão (design-agent, 002).
		var layer: Node2D = fx_layer if combo.draw_below_world else miracle_layer
		PoolManager.register(combo.id, combo.miracle_scene, MIRACLE_PREWARM, layer)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.player_died.connect(func() -> void: _next_wave_in = -1.0)
	overlays.restart_requested.connect(_restart)
	start_wave(0)


## Começa a onda `slot` (0-based) do capítulo. Usado também pela sonda de balanceamento.
func start_wave(slot: int) -> void:
	wave_slot = clampi(slot, 0, chapter.waves.size() - 1)
	_next_wave_in = -1.0
	wave_director.start(chapter.waves[wave_slot], wave_slot + 1)


func _on_wave_ended(_index: int) -> void:
	if wave_slot >= chapter.waves.size() - 1:
		EventBus.chapter_completed.emit(chapter.chapter)
		return
	_next_wave_in = between_waves


func _process(delta: float) -> void:
	if _next_wave_in > 0.0:
		_next_wave_in -= delta
		if _next_wave_in <= 0.0:
			start_wave(wave_slot + 1)


## Debug: cena pedida na linha de comando ("stress", "roster") ou na URL (?stress, ?roster).
## Só vale quando o Main é a cena inicial.
func _debug_scene_requested() -> String:
	if has_meta(&"stress") or get_tree().current_scene != self:
		return ""
	var asked: String = " ".join(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		if search is String:
			asked += " " + (search as String)
	if asked.contains("stress"):
		return STRESS_SCENE
	if asked.contains("roster"):
		return ROSTER_SCENE
	return ""


func _restart() -> void:
	# Só recarrega quando o Main é a cena do jogo (nos testes ele é filho do runner do GUT).
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()


func _exit_tree() -> void:
	PoolManager.clear_all()
