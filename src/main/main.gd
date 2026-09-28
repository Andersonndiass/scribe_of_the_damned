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
## Sem a loja (shop_auto_close): pausa entre ondas, como antes da 003.
@export var between_waves: float = 3.0
## Testes e sonda: a loja abre e fecha sozinha (sem tela, sem pausar a árvore).
@export var shop_auto_close: bool = false

@onready var player_projectiles: PlayerProjectileManager = $PlayerProjectiles
@onready var telegraph_layer: Node2D = $TelegraphLayer
@onready var fx_layer: Node2D = $FxLayer
@onready var wave_director: WaveDirector = $WaveDirector
@onready var letter_field: LetterField = $World/LetterField
@onready var miracle_layer: Node2D = $MiracleLayer
@onready var overlays: MinimalOverlays = $Overlays
@onready var shop: Shop = $Shop

## Contagem até a loja abrir depois do fim da onda (a tinta que sobrou voa antes).
var _shop_in: float = -1.0
## Índice (0-based) da onda atual no capítulo.
var wave_slot: int = 0


func _ready() -> void:
	var debug_scene: String = _debug_scene_requested()
	if debug_scene != "":
		get_tree().change_scene_to_file.call_deferred(debug_scene)
		return
	GameState.start_run(player_data)
	# Fora do jogo de verdade (testes, sonda, stress) a loja não pausa a árvore: abre e fecha
	# sozinha. O teste da tela da loja liga a loja de verdade com a meta "shop_manual".
	if get_tree().current_scene != self and not has_meta(&"shop_manual"):
		shop_auto_close = true
	# Sem a tela da loja na cena, não há como sair dela: fecha sozinha.
	if not has_node("ShopScreen"):
		shop_auto_close = true
	var args: String = _debug_args()
	if args.contains("unlock=all"):
		_unlock_all_words()
	var atril_arg: RegExMatch = RegEx.create_from_string("atril=([0-9])").search(args)
	if atril_arg != null:
		# Debug (002 Fase 4): atril 7–8 para testar as Grandes Orações antes da loja (003).
		letter_field.atril.set_capacity(int(atril_arg.get_string(1)))
		letter_field.emit_atril()
	($World/Player as Player).auto_attack.projectiles = player_projectiles
	shop.player = $World/Player
	shop.letter_field = letter_field
	EventBus.shop_closed.connect(_on_shop_closed)
	PoolManager.register(SpawnTelegraph.POOL_KEY, TELEGRAPH_SCENE, TELEGRAPH_PREWARM, telegraph_layer)
	PoolManager.register(DissolveFx.POOL_KEY, DISSOLVE_SCENE, DISSOLVE_PREWARM, fx_layer)
	PoolManager.register(Letter.POOL_KEY, LETTER_SCENE, LETTER_PREWARM, letter_field)
	PoolManager.register(GoldInk.POOL_KEY, GOLD_SCENE, GOLD_PREWARM, $World/GoldInkField)
	for word: WordData in letter_field.lexicon_data.words:
		if word.miracle_scene != null:
			var word_layer: Node2D = fx_layer if word.draw_below_world else miracle_layer
			PoolManager.register(word.id, word.miracle_scene, MIRACLE_PREWARM, word_layer)
	for combo: ComboData in ($Caster as Caster).combos:
		# Vapor e o fogo da Flamma ficam abaixo das letras do chão (design-agent, 002).
		var layer: Node2D = fx_layer if combo.draw_below_world else miracle_layer
		PoolManager.register(combo.id, combo.miracle_scene, MIRACLE_PREWARM, layer)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.player_died.connect(func() -> void: _shop_in = -1.0)
	overlays.restart_requested.connect(_restart)
	start_wave(0)


## Começa a onda `slot` (0-based) do capítulo. Usado também pela sonda de balanceamento.
func start_wave(slot: int) -> void:
	wave_slot = clampi(slot, 0, chapter.waves.size() - 1)
	_shop_in = -1.0
	wave_director.start(chapter.waves[wave_slot], wave_slot + 1)


func _on_wave_ended(_index: int) -> void:
	# Dízimo (003 FR-312, D-058): tinta fixa por onda concluída, com o ×tinta da Bolsa.
	var got: int = GameState.add_gold(shop.tuning.wave_clear_ink)
	EventBus.gold_ink_collected.emit(got, GameState.gold_ink)
	# A loja abre também depois da última onda, antes do chefe (FR-302b).
	_shop_in = between_waves if shop_auto_close else shop.tuning.open_delay


func _open_shop() -> void:
	_shop_in = -1.0
	shop.open(wave_slot + 1)
	if shop_auto_close:
		shop.close()
	else:
		get_tree().paused = true


func _on_shop_closed() -> void:
	get_tree().paused = false
	if wave_slot >= chapter.waves.size() - 1:
		# Até a 006 existir, fechar a loja da última onda conclui o capítulo.
		EventBus.chapter_completed.emit(chapter.chapter)
		return
	start_wave(wave_slot + 1)


func _process(delta: float) -> void:
	if _shop_in > 0.0:
		_shop_in -= delta
		if _shop_in <= 0.0:
			_open_shop()


## Debug: cena pedida na linha de comando ("stress", "roster") ou na URL (?stress, ?roster).
## Só vale quando o Main é a cena inicial.
func _debug_scene_requested() -> String:
	if has_meta(&"stress") or get_tree().current_scene != self:
		return ""
	var asked: String = _debug_args()
	if asked.contains("stress"):
		return STRESS_SCENE
	if asked.contains("roster"):
		return ROSTER_SCENE
	return ""


## Argumentos de debug: linha de comando (depois de --) e, no web, a query da URL.
func _debug_args() -> String:
	var asked: String = " ".join(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		var search: Variant = JavaScriptBridge.eval("window.location.search", true)
		if search is String:
			asked += " " + (search as String)
	return asked


## Debug (002 T222, FR-211): ?unlock=all / -- unlock=all libera todos os apócrifos para playtest.
func _unlock_all_words() -> void:
	for word: WordData in letter_field.lexicon_data.words:
		if word.requires_unlock:
			GameState.unlock_word(word)


func _restart() -> void:
	# Só recarrega quando o Main é a cena do jogo (nos testes ele é filho do runner do GUT).
	if get_tree().current_scene == self:
		get_tree().reload_current_scene()


func _exit_tree() -> void:
	PoolManager.clear_all()
