extends GutTest
## T1614 Fluxo da Graça na cena real (016 FR-1601, FR-1605..FR-1610; SC-1602; mechanics-agent):
## a Graça vem das mortes e das palavras; subir de nível pausa tudo e oferece 3 selos; trava de 0,4 s;
## fila; espera a loja/cutscene; morte e fim do chefe descartam; a Pausa por cima não despausa.
## O Main liga a escolha de verdade com a meta "grace_manual". Espera com timer que ignora a pausa
## (o wait_seconds do GUT pararia junto com a árvore).

const MAIN_SCENE := preload("res://src/main/main.tscn")
const IGNIS := preload("res://data/words/ignis.tres")
const LUX := preload("res://data/words/lux.tres")
const IMP := preload("res://data/enemies/imp.tres")

var _main: Node2D
var _flow: GraceFlow
var _player: Player
var _overlays: GameOverlays
var _shown: Array = []
var _hidden: int = 0
var _gains: Array = []


func before_each() -> void:
	_shown.clear()
	_hidden = 0
	_gains.clear()
	_main = MAIN_SCENE.instantiate()
	_main.set_meta(&"grace_manual", true)
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	(_main.get_node("World/EnemyManager") as EnemyManager).dissolve_all()
	_flow = _main.get_node("GraceFlow")
	_flow.beam_enabled = false  # o feixe (018) tem teste próprio
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_overlays = _main.get_node("Overlays")
	EventBus.seals_shown.connect(_on_shown)
	EventBus.seals_hidden.connect(_on_hidden)
	EventBus.grace_gained.connect(_on_gain)


func after_each() -> void:
	EventBus.seals_shown.disconnect(_on_shown)
	EventBus.seals_hidden.disconnect(_on_hidden)
	EventBus.grace_gained.disconnect(_on_gain)
	get_tree().paused = false
	TimeScale.reset()


func _on_shown(b: Array[BlessingData], _l: int) -> void:
	_shown.append(b.size())


func _on_hidden() -> void:
	_hidden += 1


func _on_gain(amount: int, source: StringName, _p: Vector2) -> void:
	_gains.append([amount, source])


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


func _cast(word: WordData) -> void:
	EventBus.word_cast.emit(word, 1.0, Vector2.ZERO, Vector2.RIGHT)


## IGNIS = 5 letras × 10 = 50: sobe para o nível 2 (custa 16) e não chega ao 3 (16 + 40).
func _level_up() -> void:
	_cast(IGNIS)
	await _wait(0.05)


func _to_choosing() -> void:
	await _level_up()
	await _wait(_flow.tuning.announce_time + 0.05)


# --- Feixe do nível (018 D-095) --------------------------------------------------------------

func test_level_up_beam_slows_time_then_opens_the_seals() -> void:
	_flow.beam_enabled = true
	await _level_up()
	assert_eq(_flow.phase, GraceFlow.Phase.BEAM, "feixe antes dos selos")
	assert_true(GameState.levelup_beam)
	assert_false(get_tree().paused, "câmera lenta, não pausa")
	await _wait(0.2)
	assert_almost_eq(TimeScale.factor_product(), 0.2, 0.001, "câmera lenta ×0,2")
	var menu: LetterMenu = (_main.get_node("World/LetterField") as LetterField).menu
	assert_false(menu._can_open(), "o menu da letra espera o feixe")
	assert_eq(_shown.size(), 0)
	await _wait(_flow.tuning.levelup_slow_time)
	assert_eq(_shown.size(), 1, "os selos aparecem depois dos 2,5 s")
	assert_true(get_tree().paused)
	assert_false(GameState.levelup_beam)
	assert_almost_eq(TimeScale.factor_product(), 1.0, 0.001, "a câmera lenta sai")


# --- Graça ---------------------------------------------------------------------------------

func test_grace_from_words_kills_combos_and_the_verbum_echo() -> void:
	_cast(LUX)
	assert_eq(_gains[-1], [30, &"word"], "10 por letra (017)")
	EventBus.enemy_killed.emit(0, IMP, Vector2.ZERO)
	assert_eq(_gains[-1], [IMP.grace, &"kill"])
	EventBus.champion_killed.emit(IMP, Vector2.ZERO)
	assert_eq(_gains[-1][0], roundi(IMP.grace * (_flow.tuning.champion_mul - 1.0)), "campeão × 5 no total")
	_cast(LUX)
	EventBus.combo_cast.emit(load("res://data/combos/vapor.tres"), 1.0)
	assert_eq(_gains[-1], [15, &"combo"], "a 2ª palavra vale × 1,5")
	var before: int = _gains.size()
	EventBus.verbum_echoed.emit(LUX)
	_cast(LUX)  # o eco repete a palavra; não conta de novo
	assert_eq(_gains.size(), before + 1)
	assert_eq(_gains[-1], [60, &"word"], "o eco vale as 6 letras de VERBUM (10 cada)")


# --- Subir de nível ------------------------------------------------------------------------

func test_level_up_pauses_everything_and_offers_three_seals() -> void:
	var em: EnemyManager = _main.get_node("World/EnemyManager")
	em.spawn(IMP, Vector2(100, 100))
	await _level_up()
	assert_true(get_tree().paused, "o jogo pausa (FR-1606)")
	assert_eq(_flow.phase, GraceFlow.Phase.ANNOUNCING)
	assert_eq(_shown, [3], "3 selos")
	var before: Vector2 = em.positions[0]
	var timer_left: float = (_main.get_node("WaveDirector") as WaveDirector).elapsed
	await _wait(0.3)
	assert_eq(em.positions[0], before, "inimigos parados")
	assert_eq((_main.get_node("WaveDirector") as WaveDirector).elapsed, timer_left, "cronômetro parado")


func test_the_guard_blocks_early_picks_then_the_blessing_applies() -> void:
	await _to_choosing()
	assert_eq(_flow.phase, GraceFlow.Phase.CHOOSING)
	assert_false(_flow.pick(0), "trava de 0,4 s")
	await _wait(_flow.tuning.pick_guard + 0.05)
	var b: BlessingData = _flow.offer[0]
	var before: int = GameState.run_stats.buys_of(b.id)
	assert_true(_flow.pick(0))
	assert_eq(GameState.run_stats.buys_of(b.id), before + 1, "aplicou a bênção")
	assert_eq(_flow.phase, GraceFlow.Phase.STAMPING)
	assert_true(get_tree().paused, "o carimbo ainda é com o jogo parado")
	await _wait(_flow.tuning.stamp_time + 0.05)
	assert_false(get_tree().paused, "o jogo volta")
	assert_eq(_flow.phase, GraceFlow.Phase.IDLE)
	assert_eq(_hidden, 1)
	assert_gt(_player.vitals.iframes_left, 0.3, "invulnerável por 0,5 s")


func test_queued_levels_show_one_offer_after_another_without_unpausing() -> void:
	_cast(IGNIS)
	_cast(IGNIS)  # 50 + 50 = 100: passa 16 + 40 e não chega a 120: 2 níveis (018)
	assert_eq(GameState.grace.pending, 2)
	await _wait(0.05)
	await _wait(_flow.tuning.announce_time + _flow.tuning.pick_guard + 0.1)
	assert_true(_flow.pick(1))
	await _wait(_flow.tuning.stamp_time + 0.05)
	assert_true(get_tree().paused, "a fila não despausa")
	assert_eq(_shown.size(), 2, "segunda oferta")
	await _wait(_flow.tuning.announce_time + _flow.tuning.pick_guard + 0.1)
	assert_true(_flow.pick(0))
	await _wait(_flow.tuning.stamp_time + 0.05)
	assert_false(get_tree().paused)
	assert_eq(GameState.grace.pending, 0)


func test_a_level_waits_for_another_pause() -> void:
	get_tree().paused = true  # loja, cutscene ou Pausa
	_cast(IGNIS)
	await _wait(0.2)
	assert_eq(_flow.phase, GraceFlow.Phase.ARMED, "espera")
	assert_eq(_shown.size(), 0)
	get_tree().paused = false
	await _wait(0.05)
	assert_eq(_flow.phase, GraceFlow.Phase.ANNOUNCING, "abre quando o jogo volta")


func test_death_in_the_same_frame_discards_the_seals() -> void:
	_cast(IGNIS)
	_player.vitals.candles = 0
	EventBus.player_died.emit()
	await _wait(0.1)
	assert_eq(_flow.phase, GraceFlow.Phase.DEAD)
	assert_eq(_shown.size(), 0)
	assert_eq(GameState.grace.pending, 0)


func test_pause_menu_over_the_seals_keeps_the_game_paused() -> void:
	await _to_choosing()
	_overlays.toggle_pause()
	await _wait(_flow.tuning.pick_guard + 0.05)
	assert_false(_flow.pick(0), "com a Pausa aberta não escolhe")
	_overlays.toggle_pause()
	assert_true(get_tree().paused, "fechar a Pausa não despausa por baixo dos selos")
	assert_false(_flow.pick(0), "a trava recomeça ao voltar")
	await _wait(_flow.tuning.pick_guard + 0.05)
	assert_true(_flow.pick(0))


func test_no_seal_after_the_boss_dies() -> void:
	EventBus.boss_defeated.emit(load("res://data/bosses/asmodeus.tres"))
	_cast(IGNIS)
	await _wait(0.1)
	assert_eq(_flow.phase, GraceFlow.Phase.SEALED)
	assert_eq(_shown.size(), 0)
	assert_false(get_tree().paused)


func test_hitstop_does_not_freeze_the_announce() -> void:
	await _level_up()
	TimeScale.set_factor(&"hitstop", 0.0)
	await _wait(_flow.tuning.announce_time + 0.1)
	assert_eq(_flow.phase, GraceFlow.Phase.CHOOSING, "relógio real")
	TimeScale.reset()
