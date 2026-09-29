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

## Debug ?shop: tinta e espera antes de abrir a loja.
const SHOP_DEBUG_INK := 30
const SHOP_DEBUG_DELAY := 0.5
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
@onready var overlays: GameOverlays = $Overlays
@onready var shop: Shop = $Shop
@onready var boss: Boss = $World/Boss

## Contagem até a loja abrir depois do fim da onda (a tinta que sobrou voa antes).
var _shop_in: float = -1.0
## Contagem entre a morte do chefe e o fim do capítulo (006 FR-611).
var _chapter_end_in: float = -1.0
## Índice (0-based) da onda atual no capítulo.
var wave_slot: int = 0
## Cutscenes do chefe e do fim (008 FR-808, FR-809), carregadas ao abrir — nada é criado na onda.
var boss_cutscene: CutscenePlayer
var outro_cutscene: CutscenePlayer


func _ready() -> void:
	var debug_scene: String = _debug_scene_requested()
	if debug_scene != "":
		get_tree().change_scene_to_file.call_deferred(debug_scene)
		return
	# Capítulo escolhido na tela (007). O personagem escolhido entra na 010 (só o Anselmo é livre).
	if has_meta(&"app") and GameState.picked_chapter != null:
		chapter = GameState.picked_chapter
	GameState.start_run(player_data)
	# Fora do jogo de verdade (testes, sonda, stress) a loja não pausa a árvore: abre e fecha
	# sozinha. O teste da tela da loja liga a loja de verdade com a meta "shop_manual".
	if not is_real_game() and not has_meta(&"shop_manual"):
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
	boss.player = $World/Player
	boss.manager = $World/EnemyManager
	boss.letter_field = letter_field
	EventBus.boss_defeated.connect(func(b: BossData) -> void: _chapter_end_in = b.chapter_end_delay)
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
	EventBus.chapter_completed.connect(func(_c: int) -> void:
		if is_real_game():
			_play_outro())
	_prepare_cutscenes(args)
	# Frases curtas na partida (008 FR-815).
	var barks := BarkDirector.new()
	barks.name = "Barks"
	barks.player = $World/Player
	barks.boss = boss
	add_child(barks)
	start_wave(0)
	if args.contains("boss"):
		# Debug (006 FR-615): direto na luta (combina com ?unlock=all&atril=8).
		wave_director.stop()
		start_boss.call_deferred()
	if args.contains("shop"):
		# Debug (003): abre a loja logo no começo, com tinta, para ver a tela sem jogar a onda.
		GameState.gold_ink = SHOP_DEBUG_INK
		wave_director.stop()
		_shop_in = SHOP_DEBUG_DELAY


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
		if chapter.boss != null:
			start_boss()
		else:
			EventBus.chapter_completed.emit(chapter.chapter)
		return
	start_wave(wave_slot + 1)


## Luta contra o chefe do capítulo (006 FR-607): os inimigos que sobraram se dissolvem.
func start_boss() -> void:
	wave_director.stop()
	($World/EnemyManager as EnemyManager).dissolve_all()
	boss.data = chapter.boss
	if boss_cutscene == null:
		boss.start_fight()
		return
	# C1-03: o jogo para, a cena mostra a entrada, e o fim dela solta o chefe já lutando.
	get_tree().paused = true
	boss_cutscene.play()
	await _cutscene_done(boss_cutscene.cutscene_id)
	get_tree().paused = false
	boss.start_fight(true)


## As cenas do capítulo só na partida de verdade (testes, sonda e ?boss seguem direto).
func _prepare_cutscenes(args: String) -> void:
	if not is_real_game() or args.contains("boss") or chapter == null:
		return
	if chapter.boss_cutscene != &"":
		boss_cutscene = CutscenePlayer.new()
		boss_cutscene.name = "BossCutscene"
		add_child(boss_cutscene)
		boss_cutscene.load_cutscene(chapter.boss_cutscene)
	if chapter.outro_cutscene != &"":
		outro_cutscene = CutscenePlayer.new()
		outro_cutscene.name = "OutroCutscene"
		add_child(outro_cutscene)
		outro_cutscene.load_cutscene(chapter.outro_cutscene)


## C1-04 entre o fim do capítulo e a Vitória (nunca por cima do Game Over).
func _play_outro() -> void:
	if outro_cutscene == null or overlays.mode == GameOverlays.Mode.GAME_OVER:
		overlays.show_victory()
		return
	get_tree().paused = true
	outro_cutscene.play()
	await _cutscene_done(outro_cutscene.cutscene_id)
	overlays.show_victory()


func _cutscene_done(id: StringName) -> void:
	while true:
		var args: Array = await EventBus.cutscene_finished
		if args[0] == id:
			return


func _process(delta: float) -> void:
	if _chapter_end_in > 0.0:
		_chapter_end_in -= delta
		if _chapter_end_in <= 0.0:
			EventBus.chapter_completed.emit(chapter.chapter)
	if _shop_in > 0.0:
		_shop_in -= delta
		if _shop_in <= 0.0:
			_open_shop()


## Debug: cena pedida na linha de comando ("stress", "roster") ou na URL (?stress, ?roster).
## Só vale quando o Main é a cena inicial.
func _debug_scene_requested() -> String:
	# Com o roteador (007), é ele quem troca para as cenas de debug.
	if has_meta(&"stress") or has_meta(&"app") or get_tree().current_scene != self:
		return ""
	var asked: String = _debug_args()
	if asked.contains("stress"):
		return STRESS_SCENE
	if asked.contains("roster"):
		return ROSTER_SCENE
	return ""


## Argumentos de debug: linha de comando (depois de --) e, no web, a query da URL.
func _debug_args() -> String:
	return ScreenRouter.debug_args()


## Debug (002 T222, FR-211): ?unlock=all / -- unlock=all libera todos os apócrifos para playtest.
func _unlock_all_words() -> void:
	for word: WordData in letter_field.lexicon_data.words:
		if word.requires_unlock:
			GameState.unlock_word(word)


## É a partida de verdade (hospedada pelo roteador ou aberta como cena), não um teste/sonda/stress.
func is_real_game() -> bool:
	return has_meta(&"app") or get_tree().current_scene == self


func _restart() -> void:
	# Com o roteador (007) o reinício é um pedido; aberto como cena, recarrega. Nos testes, nada.
	if has_meta(&"app"):
		EventBus.game_restart_requested.emit()
	elif get_tree().current_scene == self:
		get_tree().reload_current_scene()


func _exit_tree() -> void:
	PoolManager.clear_all()
