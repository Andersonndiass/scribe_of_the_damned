extends Node
## Estado da partida em runtime (data-model, "Estado em tempo de execução"). Autoload "GameState".
## Os números do escriba na partida vêm do `run_stats` (003).

var candles: int = 3
var max_candles: int = 8
var atril_capacity: int = 5
var wave_index: int = 0
## Tinta dourada da partida (005 FR-512); zera a cada partida (D-018).
var gold_ink: int = 0
var unlocked_words: Array[StringName] = []
var rng := RandomNumberGenerator.new()
const GRACE_SEED_SALT := 0x5EA1
## Números do escriba com os itens da loja (003 FR-309). Recriado a cada partida.
var run_stats: RunStats = null
## Graça da partida (016): zera no start_run, continua entre as ondas e na loja.
var grace_tuning: GraceTuning = preload("res://data/tuning/grace.tres")
var grace: GraceLedger = null
## Inventário de armas da partida (017), zerado no start_run.
var loadout: Loadout = null
## 017: ímã reverso (0 = não comprado; 1..5 = nível, subindo pelos selos).
var repulse_level: int = 0
var repulse: RepulseData = preload("res://data/weapons/reverse_magnet.tres")
## Sorteios da 016 (selos, pingo de cera): separados do `rng` das letras para não mudar a sequência.
var grace_rng := RandomNumberGenerator.new()
## Fração de tinta acumulada pelo ×tinta da Bolsa do Esmoler (a gota é inteira).
var gold_fraction: float = 0.0
## Screen shake ligado (D-047 6B; a tela de Opções, 007, muda). Vale entre partidas.
var shake_enabled: bool = true
## Mirar as palavras direcionais com o mouse (D-067; ligado por padrão; Opções na 007).
var aim_with_mouse: bool = true
## 017: menu da letra aberto (o escriba fica parado; Espaço e setas são do menu).
var letter_menu_open: bool = false
## Multiplicador de chance de letra da onda atual (WaveData.letter_drop_mul).
var letter_drop_mul: float = 1.0
## Onde está o cursor no mundo; Vector2.INF = sem mouse nesta sessão (mira = direção do escriba).
var aim_point: Vector2 = Vector2.INF
## Alto contraste (007, D-066): quem desenha consulta; variação dentro da paleta travada.
var high_contrast: bool = false
## Escolhas das telas de Personagem e Capítulo (007); vazio = o padrão da cena do jogo.
var picked_character: StringName = &""
## Cutscenes a tocar na rota "cutscene" e a tela que vem depois (008 FR-807).
var cutscene_queue: Array[StringName] = []
var after_cutscene: StringName = &"game"
var picked_chapter: ChapterData = null


## Registro da partida (007: Game Over e Vitória).
var _rec_wave: int = 0
var _rec_time: float = 0.0
var _rec_words: int = 0
var _rec_kills: int = 0
var _rec_ink: int = 0
var _rec_boss_start: float = -1.0
var _rec_boss_time: float = 0.0


func _ready() -> void:
	EventBus.wave_started.connect(func(i: int, _d: float) -> void: _rec_wave = maxi(_rec_wave, i))
	EventBus.word_cast.connect(func(_w: WordData, _p: float, _o: Vector2, _d: Vector2) -> void: _rec_words += 1)
	EventBus.enemy_killed.connect(func(_s: int, _d: EnemyData, _p: Vector2) -> void: _rec_kills += 1)
	EventBus.gold_ink_collected.connect(func(a: int, _t: int) -> void: _rec_ink += a)
	EventBus.boss_spawned.connect(func(_b: BossData) -> void: _rec_boss_start = _rec_time)
	EventBus.boss_defeated.connect(func(_b: BossData) -> void:
		if _rec_boss_start >= 0.0:
			_rec_boss_time = _rec_time - _rec_boss_start
			_rec_boss_start = -1.0)


func _process(delta: float) -> void:
	tick_run(delta)


## Soma tempo de partida (a árvore pausada não conta: GameState pausa junto).
func tick_run(delta: float) -> void:
	_rec_time += delta


## Estatísticas da partida: wave, time (s), words, kills, ink, boss_time (s).
func run_record() -> Dictionary:
	var boss_time: float = _rec_boss_time
	if _rec_boss_start >= 0.0:
		boss_time = _rec_time - _rec_boss_start
	return {"wave": _rec_wave, "time": _rec_time, "words": _rec_words, "kills": _rec_kills,
		"ink": _rec_ink, "boss_time": boss_time}


## Reinicia a partida a partir dos dados do personagem.
func start_run(player: PlayerData, seed_value: int = -1) -> void:
	candles = player.start_candles
	# Máximo ATUAL da partida = velas iniciais; o teto absoluto (8) só se alcança por upgrades (D-010).
	max_candles = player.start_candles
	atril_capacity = player.atril_capacity
	wave_index = 0
	letter_drop_mul = 1.0
	letter_menu_open = false
	repulse_level = 0
	gold_ink = 0
	gold_fraction = 0.0
	_rec_wave = 0
	_rec_time = 0.0
	_rec_words = 0
	_rec_kills = 0
	_rec_ink = 0
	_rec_boss_start = -1.0
	_rec_boss_time = 0.0
	run_stats = RunStats.new(player)
	var codex: Node = get_node_or_null(^"/root/Codex")
	if codex != null:
		codex.call(&"begin_run")  # a Vitória lista só as entradas novas desta partida
	unlocked_words.clear()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	grace = GraceLedger.new(grace_tuning)
	loadout = Loadout.new(2, player.start_weapon)
	# Derivado da semente sem consumir o `rng` (a sequência de letras continua a mesma).
	grace_rng.seed = rng.seed ^ GRACE_SEED_SALT


## Soma tinta dourada com o ×tinta da partida (Bolsa do Esmoler, 003). Retorna quanto entrou.
func add_gold(raw: int) -> int:
	var mul: float = run_stats.value(&"gold_mul") if run_stats != null else 1.0
	var total: float = float(raw) * mul + gold_fraction
	var whole: int = int(floor(total + 0.0001))
	gold_fraction = total - float(whole)
	gold_ink += whole
	return whole


func is_word_unlocked(word_id: StringName) -> bool:
	return unlocked_words.has(word_id)


## Palavra conhecida = não exige desbloqueio ou já foi desbloqueada (002 FR-201).
func is_word_known(word: WordData) -> bool:
	return not word.requires_unlock or unlocked_words.has(word.id)


## Desbloqueia um apócrifo (a loja da 003 chama). VERBUM libera o B no drop (D-015).
func unlock_word(word: WordData) -> void:
	if unlocked_words.has(word.id):
		return
	unlocked_words.append(word.id)
	EventBus.word_unlocked.emit(word)
