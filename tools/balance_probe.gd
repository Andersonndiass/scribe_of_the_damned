extends SceneTree
## Sonda de balanceamento (ferramenta de desenvolvimento, não entra no build).
## Roda a cena principal com um bot que foge do inimigo mais próximo e mede a onda 1.
## Uso: godot --headless --path . -s tools/balance_probe.gd -- [still]
##   still = o bot fica parado (pior caso). move = foge. cast = foge, busca letras e conjura.
##   god = jogador invencível (2B, D-047): mede o FLUXO DE LETRAS da onda inteira, sem depender de o
##         bot sobreviver. Imprime uma linha FLOW com letras/min, letras-alvo/min, comidas, coletadas,
##         palavras e heresias.
##   chapter = joga as 9 ondas seguidas, com a loja no meio (fecha sozinha), até o fim do capítulo.
##   boss = luta direto contra o chefe do capítulo (o Main lê o mesmo argumento); com god mede o
##          tempo até matar (006 T621, SC-608). Linha BOSS. Combina com unlock=all e atril=N.
##   obstacles=off = sem as peças da página (004 T413, comparação A/B). stage=N = página no estágio N
##         desde o começo. Imprime uma linha ARENA com STUCK: % das amostras (a cada 0,5 s) em que um
##         inimigo que anda QUER andar (velocidade ≥ 30% da dele), está encostado numa peça e não saiu
##         do lugar (≤ 2 px). Monge parado atirando e Gárgula preparando o dash não contam.
##   target=F magnet=F dropall=F = números de letras em memória (D-082).
##   kite = 018 T1819: o bot mantém distância = 0,8 × alcance da arma ativa (não os 70 px fixos).
##   potions = o bot bebe poções (Óleo com 1 vela, Vinho pronto, Água Benta cercado, Iluminura com
##         palavra começada). Linhas POTIONS e RHYTHM (palavras/min, menus/min por onda, níveis,
##         tinta, compras, gasto em poções, letras da Iluminura).
##   react=F acerto=F = menu da letra (017 T1728): o bot escolhe depois de F s (padrão 0,8) e acerta
##         a letra que continua a palavra com chance F (padrão 0,9, a do rules-agent). Linha LETTERS.
##   only_waves = no modo chapter, termina no fim da onda 9 (sem a luta do chefe; a sonda do chefe
##         trava na fase 3, D-081; o nome não pode conter "boss": o Main abriria direto no chefe).
##   grace = liga a Graça (016) com escolha automática, sem pausar. Imprime uma linha GRACE: níveis
##         por onda, % da Graça vinda de palavras, 1º nível (s) e as bênçãos escolhidas.
##   buy = em cada loja o bot compra as cartas mais baratas que couberem na tinta (003 T320, SC-306).
##         Imprime uma linha SHOP com compras, tinta ganha e o que comprou.

const MAIN := "res://src/main/main.tscn"
const TIME_SCALE := 4.0

var _kills: int = 0
var _hits: int = 0
var _died_at: float = -1.0
var _ended: bool = false
var _time: float = 0.0
var _still: bool = false
var _cast_mode: bool = false
var _field: Node
var _caster: Node
var _casts: Dictionary = {}
var _dropped: int = 0
var _collected: String = ""
var _main: Node
var _player: Node2D
var _manager: Node  # sem tipo: EnemyManager depende de autoloads
var _max_alive: int = 0
var _limit: float = 65.0
var _wave_slot: int = -1
var _shots: int = 0
var _god: bool = false
var _targets: int = 0
var _eaten: int = 0
## 017 T1728: menu da letra.
var _react: float = 0.8
## 018 T1819.
var _kite: bool = false
var _potion_bot: bool = false
var _drunk: Dictionary = {}
var _potion_ink: int = 0
var _menus_by_wave: Dictionary = {}
var _words_total: int = 0
var _illum_menus: int = 0
var _weapon_lvls: Dictionary = {}
## T1830 L3/L4: instantes (s) de cada palavra conjurada.
var _word_times: PackedFloat32Array = []
var _hit_chance: float = 0.9
var _lost: int = 0
var _overflow: int = 0
var _menu_rng := RandomNumberGenerator.new()
var _heresies: int = 0
var _purges: int = 0
var _chapter: bool = false
var _chapter_done: bool = false
var _shop_bot: bool = false
var _bought: PackedStringArray = []
var _ink_earned: int = 0
var _visits: int = 0
var _boss_mode: bool = false
var _boss_done: float = -1.0
var _boss_hp: int = -1
var _boss_phase: int = 0
var _obstacles: bool = true
var _stage: int = -1
var _stuck: int = 0
var _stuck_max: int = 0
var _samples: int = 0
var _sample_in: float = 0.0
var _last_pos := PackedVector2Array()
const STUCK_EVERY := 0.5
const STUCK_MOVE := 2.0
const STUCK_TOUCH := 1.5
const STUCK_INTENT := 0.3
var _grace_on: bool = false
var _g_word: int = 0
var _g_kill: int = 0
var _g_first_up: float = -1.0
var _g_ups_by_wave: Dictionary = {}
var _g_picks: PackedStringArray = []
## 017 T1716: `weapons=bible,crucifix` põe as armas nos espaços, `wlevel=N` o nível; `swap` troca
## de arma a cada SWAP_EVERY s. A Bíblia mira sozinha no inimigo mais próximo (mira "de mouse").
var _weapons_arg: String = ""
var _wlevel: int = 0
var _swap: bool = false
var _swap_in: float = 0.0
var _swaps: int = 0
var _weapons_set: bool = false
const SWAP_EVERY := 5.0
## Raios do inimigo em volta do escriba que contam como "chegou".
const STUCK_NEAR_PLAYER := 5.0


func _initialize() -> void:
	_still = OS.get_cmdline_user_args().has("still")
	_cast_mode = OS.get_cmdline_user_args().has("cast")
	_god = OS.get_cmdline_user_args().has("god")
	_chapter = OS.get_cmdline_user_args().has("chapter")
	_shop_bot = OS.get_cmdline_user_args().has("buy")
	_boss_mode = OS.get_cmdline_user_args().has("boss")
	# Overrides só em memória, para simular propostas sem tocar nos .tres: hp=N drop=F
	var imp: Resource = load("res://data/enemies/imp.tres")
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("hp="):
			imp.set("max_hp", int(arg.substr(3)))
		elif arg.begins_with("drop="):
			imp.set("letter_drop_chance", float(arg.substr(5)))
		# D-082 (ritmo das palavras): target=F bônus da letra-alvo · life=F segundos da letra no
		# chão · magnet=F raio do ímã · dropall=F multiplica o drop de letra de todos os inimigos.
		elif arg.begins_with("target="):
			(load("res://data/tuning/drop_tuning.tres") as Resource).set("target_bonus", float(arg.substr(7)))
		elif arg == "kite":
			_kite = true
		elif arg == "potions":
			_potion_bot = true
		elif arg.begins_with("react="):
			_react = float(arg.substr(6))
		elif arg.begins_with("acerto="):
			_hit_chance = float(arg.substr(7))
		elif arg.begins_with("magnet="):
			(load("res://data/player/anselmo.tres") as Resource).set("magnet_radius", float(arg.substr(7)))
		elif arg.begins_with("dropall="):
			for f: String in DirAccess.get_files_at("res://data/enemies/"):
				if f.ends_with(".tres"):
					var e: Resource = load("res://data/enemies/" + f)
					e.set("letter_drop_chance", minf(1.0, float(e.get("letter_drop_chance")) * float(arg.substr(8))))
		elif arg == "obstacles=off":
			_obstacles = false
		elif arg.begins_with("stage="):
			_stage = int(arg.substr(6))
	_main = (load(MAIN) as PackedScene).instantiate()
	_grace_on = OS.get_cmdline_user_args().has("grace")
	if _grace_on:
		_main.set_meta(&"grace_auto", true)
	if not _obstacles:
		# Só em memória: o capítulo fica sem a página de obstáculos (004 T413).
		(_main.get("chapter") as Resource).set("arena", null)
	_main.set("shop_auto_close", true)  # sem tela: a loja abre e fecha sozinha (003)
	root.add_child(_main)
	_player = _main.get_node("World/Player")
	_manager = _main.get_node("World/EnemyManager")
	_field = _main.get_node("World/LetterField")
	_caster = _main.get_node("Caster")
	# wave=N: joga só a onda N do capítulo (T533).
	_limit = 65.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("wave="):
			_wave_slot = int(arg.substr(5)) - 1
		elif arg.begins_with("weapons="):
			_weapons_arg = arg.substr(8)
		elif arg.begins_with("wlevel="):
			_wlevel = int(arg.substr(7))
		elif arg == "swap":
			_swap = true
	var bus: Node = root.get_node("EventBus")
	bus.enemy_killed.connect(func(_s: int, _d: Resource, _p: Vector2) -> void: _kills += 1)
	bus.player_damaged.connect(func(_a: int, _c: int) -> void: _hits += 1)
	bus.player_died.connect(func() -> void: _died_at = _time)
	var only_waves: bool = OS.get_cmdline_user_args().has("only_waves")
	bus.wave_ended.connect(func(i: int) -> void:
		_ended = not _chapter
		if _chapter and only_waves and i >= 9:
			_chapter_done = true)
	bus.chapter_completed.connect(func(_c: int) -> void: _chapter_done = true)
	bus.gold_ink_collected.connect(func(a: int, _t: int) -> void: _ink_earned += a)
	bus.grace_gained.connect(func(a: int, src: StringName, _p: Vector2) -> void:
		if src == &"word" or src == &"combo":
			_g_word += a
		else:
			_g_kill += a)
	bus.grace_leveled.connect(func(_l: int, _q: int) -> void:
		if _g_first_up < 0.0:
			_g_first_up = _time
		var w: int = GameState_wave()
		_g_ups_by_wave[w] = int(_g_ups_by_wave.get(w, 0)) + 1)
	bus.blessing_chosen.connect(func(b: Resource, _l: int) -> void: _g_picks.append(String(b.get("id"))))
	bus.shop_opened.connect(func(_w: int) -> void: _on_shop_opened())
	bus.boss_damaged.connect(func(hp: int, _m: int) -> void: _boss_hp = hp)
	bus.boss_phase_changed.connect(func(i: int) -> void:
		_boss_phase = i
		print("BOSS fase %d aos %.2f min" % [i + 1, _time / 60.0]))
	bus.boss_defeated.connect(func(_b: Resource) -> void: _boss_done = _time)
	if _boss_mode:
		_limit = 12.0 * 60.0
	if _chapter:
		_limit = 20.0 * 60.0
		bus.wave_started.connect(func(i: int, _d: float) -> void:
			print("CHAPTER onda %d começou (t=%.1fmin, tinta=%d)" % [i, _time / 60.0, int(root.get_node("GameState").get("gold_ink"))]))
	bus.letter_menu_opened.connect(func(_o: Array) -> void:
		_dropped += 1
		_targets += 1
		var w: int = GameState_wave()
		_menus_by_wave[w] = int(_menus_by_wave.get(w, 0)) + 1)
	bus.potion_drunk.connect(func(id: StringName, _l: int, _c: int) -> void:
		_drunk[id] = int(_drunk.get(id, 0)) + 1
		if id == &"illumination":
			_illum_menus += 1)
	bus.potion_bought.connect(func(_id: StringName, price: int) -> void: _potion_ink += price)
	bus.wave_started.connect(func(i: int, _d: float) -> void:
		var lo: RefCounted = root.get_node("GameState").get("loadout")
		if lo != null and lo.call("active_slot") != null:
			_weapon_lvls[i] = int(lo.call("active_slot").get("level")))
	bus.letter_lost.connect(func() -> void: _lost += 1)
	bus.letter_offer_dropped.connect(func() -> void: _overflow += 1)
	bus.letter_eaten.connect(func(_l: String, _p: Vector2) -> void: _eaten += 1)
	bus.heresy_committed.connect(func(_p: Vector2) -> void: _heresies += 1)
	bus.atril_purged.connect(func(_l: PackedStringArray, _p: Vector2) -> void: _purges += 1)
	bus.letter_collected.connect(func(l: String, _r: bool) -> void: _collected += l)
	bus.word_cast.connect(func(w: Resource, _pw: float, _o: Vector2, _d: Vector2) -> void:
		_casts[w.get("latin")] = _casts.get(w.get("latin"), 0) + 1
		_words_total += 1
		_word_times.append(_time))
	_player.get_node("Arsenal").fired.connect(func(_t: Vector2) -> void: _shots += 1)
	root.get_node("TimeScale").call("set_base", TIME_SCALE)
	Engine.physics_ticks_per_second = 60


func _physics_process(delta: float) -> bool:
	if _stage >= 0:
		root.get_node("EventBus").emit_signal(&"page_stage_changed", _stage, _stage, false)
		_stage = -1
	_sample_stuck(delta)
	if _wave_slot >= 0:
		# Aplicado no 1º frame: no _initialize o Main ainda não rodou o _ready.
		_manager.call("dissolve_all")
		_main.call("start_wave", _wave_slot)
		var chapter: Resource = _main.get("chapter")
		_limit = float((chapter.get("waves") as Array)[_wave_slot].get("duration")) + 2.0
		_wave_slot = -1
		_time = 0.0
		return false
	_time += delta
	_drive_weapons(delta)
	_answer_menu()
	_drink_potions()
	if _god:
		(_player.get("vitals") as RefCounted).set("iframes_left", 1.0e6)
	_max_alive = maxi(_max_alive, _manager.get("count"))
	if not _still:
		_steer()
	if _cast_mode:
		# Só conjura com a palavra VÁLIDA: apertar Espaço antes disso é heresia (FR-019).
		# (Até 2026-09-26 o bot conjurava todo frame e cometia heresia sem parar: medições de
		# palavras por onda feitas antes disso estão contaminadas.)
		var atril: RefCounted = _field.get("atril")
		var st: int = atril.call("state", _field.get("lexicon"))
		if st == 3:  # Atril.Status.VALID
			var boss: Node2D = _main.get_node_or_null("World/Boss")
			if boss != null and bool(boss.get("fighting")):
				# Palavras direcionais (LUX, FLAMMA…) saem para onde o escriba olha: mira o chefe.
				_player.set("facing", (boss.global_position - _player.global_position).normalized())
			_caster.call("cast")
		elif st in [1, 4]:  # FILL / FULL_REJECT: beco sem saída → purge
			_caster.call("purge")
	if _boss_mode and int(_time) % 30 == 0 and int(_time - delta) % 30 != 0:
		var b: Node = _main.get_node_or_null("World/Boss")
		print("BOSS t=%.0fs hp=%d estado=%s pausado=%s palavras=%s" % [_time, _boss_hp, b.call("state_name") if b != null else "-", paused, _casts])
	if _boss_mode and (_boss_done >= 0.0 or _died_at >= 0.0 or _time > _limit):
		print("BOSS resultado venceu=%s tempo=%.2fmin hp_restante=%d fase=%d conjurações=%s" % [
			_boss_done >= 0.0, (_boss_done if _boss_done >= 0.0 else _time) / 60.0, _boss_hp, _boss_phase + 1, _casts])
		return true
	if _boss_mode and (_boss_done >= 0.0 or _died_at >= 0.0 or _time > _limit):
		_print_arena()
	if _ended or _chapter_done or _died_at >= 0.0 or _time > _limit:
		_print_arena()
		if _chapter:
			print("SHOP visitas=%d compras=%d tinta_ganha=%d tinta_sobrando=%d capítulo_completo=%s tempo=%.1fmin compradas=%s" % [
				_visits, _bought.size(), _ink_earned, int(root.get_node("GameState").get("gold_ink")), _chapter_done,
				_time / 60.0, ", ".join(_bought)])
		print("PROBE onda=%d still=%s tempo=%.1fs mortes=%d golpes_sofridos=%d morreu_em=%s max_vivos=%d onda_terminou=%s tiros=%d conjurações=%s letras_caídas=%d coletadas=%s" % [
			GameState_wave(), _still, _time, _kills, _hits, ("%.1fs" % _died_at) if _died_at >= 0.0 else "não", _max_alive, _ended, _shots, _casts, _dropped, _collected])
		_print_weapons()
		_print_rhythm()
		var mins: float = maxf(_time / 60.0, 0.001)
		print("LETTERS menus=%d menus/min=%.1f perdidas=%d fila_cheia=%d coletadas=%d react=%.2f acerto=%.2f" % [
			_dropped, _dropped / mins, _lost, _overflow, _collected.length(), _react, _hit_chance])
		if _god:
			var minutes: float = maxf(_time / 60.0, 0.001)
			var words: int = 0
			for k: String in _casts:
				words += int(_casts[k])
			print("FLOW onda=%d min=%.2f letras/min=%.1f alvo/min=%.1f comidas=%d coletadas/min=%.1f palavras=%d palavras/min=%.2f heresias=%d purges=%d mortes/min=%.1f" % [
				GameState_wave(), minutes, _dropped / minutes, _targets / minutes, _eaten,
				_collected.length() / minutes, words, words / minutes, _heresies, _purges, _kills / minutes])
		return true
	return false


## Loja (003 T320): compra, a cada visita, as cartas mais baratas que couberem na tinta.
func _on_shop_opened() -> void:
	_visits += 1
	if not _shop_bot:
		return
	var shop: Node = _main.get_node("Shop")
	var offer: RefCounted = shop.get("offer")
	var gs: Node = root.get_node("GameState")
	var budget_start: int = int(gs.get("gold_ink"))
	while true:
		var best: int = -1
		var prices: PackedInt32Array = offer.get("prices")
		var cards: Array = offer.get("cards")
		var full: bool = bool(gs.get("loadout").call("is_full"))
		for i: int in cards.size():
			if cards[i] == null or not bool(shop.call("can_afford", i)):
				continue
			if String((cards[i] as Resource).get("kind")) == "weapon" and full:
				continue  # não troca a arma que já tem
			if best < 0 or prices[i] < prices[best]:
				best = i
		if best < 0 or not bool(shop.call("buy", best)):
			break
		_bought.append(String((cards[best] as Resource).get("id")))
	if not _potion_bot:
		return
	# Poções com o que sobrou, no máximo 40% da tinta que havia ao abrir a loja.
	var spent: int = 0
	for i: int in [0, 2, 1, 3]:
		while spent + int(shop.call("potion_price", i)) <= int(0.4 * budget_start) and bool(shop.call("buy_potion", i)):
			spent += int(shop.call("potion_price", i))


func GameState_wave() -> int:
	return int(root.get_node("GameState").get("wave_index"))


func _steer() -> void:
	for a: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(a)
	var p: Vector2 = _player.global_position
	var flee := Vector2.ZERO
	var keep: float = 70.0
	if _kite:
		var slot: RefCounted = root.get_node("GameState").get("loadout").call("active_slot")
		if slot != null:
			keep = maxf(40.0, 0.8 * float((slot.call("stats") as Resource).get("range")))
	var positions: PackedVector2Array = _manager.get("positions")
	for i: int in int(_manager.get("count")):
		var away: Vector2 = p - positions[i]
		var d: float = away.length()
		if d < keep and d > 0.01:
			flee += away / d * (keep - d)
	# Evita as bordas puxando para o centro.
	flee += (Vector2(320, 180) - p) * 0.15
	if flee.x < -2.0:
		Input.action_press(&"move_left")
	elif flee.x > 2.0:
		Input.action_press(&"move_right")
	if flee.y < -2.0:
		Input.action_press(&"move_up")
	elif flee.y > 2.0:
		Input.action_press(&"move_down")


## STUCK (004 T413): amostra a cada 0,5 s os inimigos que andam, encostados numa peça e parados.
func _sample_stuck(delta: float) -> void:
	_sample_in -= delta
	if _sample_in > 0.0:
		return
	_sample_in = STUCK_EVERY
	var n: int = int(_manager.get("count"))
	var positions: PackedVector2Array = _manager.get("positions")
	var radius_of: PackedFloat32Array = _manager.get("radius_of")
	var stun_left: PackedFloat32Array = _manager.get("stun_left")
	var velocities: PackedVector2Array = _manager.get("velocities")
	var data_of: Array = _manager.get("data_of")
	var now := 0
	for i: int in n:
		var d: Resource = data_of[i]
		if i >= _last_pos.size() or bool(d.get("flying")) or stun_left[i] > 0.0:
			continue
		if velocities[i].length() < float(d.get("move_speed")) * STUCK_INTENT:
			continue
		# Colado no escriba não é travado: já chegou (amontoado em volta dele perto de uma peça).
		if positions[i].distance_to(_player.global_position) <= radius_of[i] * STUCK_NEAR_PLAYER:
			continue
		_samples += 1
		if ObstacleQuery.map != null and not ObstacleQuery.map.is_free(positions[i], radius_of[i] + STUCK_TOUCH) and positions[i].distance_to(_last_pos[i]) <= STUCK_MOVE:
			now += 1
			if OS.get_cmdline_user_args().has("stuck_log") and _stuck + now < 60:
				print("STUCK_AT %s r=%.1f id=%s v=%s jogador=%s" % [positions[i].round(), radius_of[i], d.get("id"), velocities[i].round(), _player.global_position.round()])
	_stuck += now
	_stuck_max = maxi(_stuck_max, now)
	_last_pos = positions.slice(0, n)


func _print_grace() -> void:
	if not _grace_on:
		return
	var total: int = maxi(1, _g_word + _g_kill)
	var ups: PackedStringArray = []
	for w: int in range(1, 10):
		if _g_ups_by_wave.has(w):
			ups.append("%d:%d" % [w, int(_g_ups_by_wave[w])])
	var grace: RefCounted = root.get_node("GameState").get("grace")
	print("GRACE nível=%d total=%d palavras=%.0f%% 1º_nível=%s subidas={%s} escolhas=%s" % [
		int(grace.get("level")) if grace != null else 1, _g_word + _g_kill, 100.0 * _g_word / total,
		("%.1fs" % _g_first_up) if _g_first_up >= 0.0 else "-", " ".join(ups), ",".join(_g_picks)])


func _print_arena() -> void:
	_print_grace()
	print("ARENA obstáculos=%s estágio=%d STUCK=%.2f%% (%d de %d amostras, pico %d)" % [
		"on" if _obstacles else "off", int((_main.get_node("Arena") as Node).get("degradation_stage")),
		100.0 * _stuck / maxf(1.0, _samples), _stuck, _samples, _stuck_max])


## 017 T1716: armas da linha de comando, troca periódica e a mira da Bíblia no mais próximo.
func _drive_weapons(delta: float) -> void:
	var gs: Node = root.get_node("GameState")
	var lo: RefCounted = gs.get("loadout")
	if lo == null:
		return
	var arsenal: Node = _player.get_node("Arsenal")
	if not _weapons_set:
		_weapons_set = true
		var slots: Array = lo.get("slots")
		var ids: PackedStringArray = _weapons_arg.split(",", false)
		for i: int in mini(ids.size(), slots.size()):
			for w: Resource in (arsenal.get("tuning") as Resource).get("weapons"):
				if String(w.get("id")) == ids[i]:
					slots[i] = load("res://src/weapons/weapon_slot.gd").new(w)
		if _wlevel > 0:
			for slot: RefCounted in slots:
				if slot != null:
					slot.set("level", clampi(_wlevel, 1, int((slot.get("weapon") as Resource).call("max_level"))))
	if _swap:
		_swap_in -= delta
		if _swap_in <= 0.0:
			_swap_in = SWAP_EVERY
			if arsenal.call("switch_to", 1 - int(lo.get("active"))):
				_swaps += 1
	if _weapons_arg == "":
		return  # sem armas pedidas, a sonda mira como sempre (direção do escriba)
	# A Bíblia é mirada: o bot aponta o "mouse" para o inimigo mais próximo do escriba.
	var near: Vector2 = _manager.call("query_nearest", _player.global_position, 400.0)
	gs.set("aim_with_mouse", true)
	gs.set("aim_point", near if near != Vector2.INF else Vector2.INF)


func _print_weapons() -> void:
	var lo: RefCounted = root.get_node("GameState").get("loadout")
	if lo == null:
		return
	var names: PackedStringArray = []
	for slot: RefCounted in lo.get("slots"):
		if slot != null:
			names.append("%s:%d" % [String((slot.get("weapon") as Resource).get("id")), int(slot.get("level"))])
	var beam: Object = _player.get_node("Arsenal").get("beam")
	var beam_hits: int = int((beam.get("zone") as RefCounted).get("hits")) if beam != null else 0
	print("WEAPONS armas=%s trocas=%d tiros=%d toques_do_raio=%d mortes/min=%.1f" % [
		",".join(names), _swaps, _shots, beam_hits, _kills / maxf(_time / 60.0, 0.001)])


## 017 T1728: responde ao menu da letra depois de `_react` s de menu; com `_hit_chance` escolhe a
## letra que continua a palavra, senão uma das outras.
func _answer_menu() -> void:
	if not _cast_mode:
		return
	var menu: Node = _field.get("menu")
	if menu == null or not bool(menu.call("is_open")) or float(menu.get("open_for")) < _react:
		return
	var options: Array = menu.get("options")
	var good := -1
	var bad: Array[int] = []
	for i: int in options.size():
		if bool(options[i]["useful"]) and good < 0:
			good = i
		else:
			bad.append(i)
	var pick: int = good
	if good < 0 or (_menu_rng.randf() >= _hit_chance and not bad.is_empty()):
		pick = bad[_menu_rng.randi_range(0, bad.size() - 1)]
	menu.call("pick", pick)


## 018 T1819: o bot bebe (Óleo com 1 vela, Vinho pronto, Água Benta com 6+ perto, Iluminura com
## palavra começada).
func _drink_potions() -> void:
	if not _potion_bot:
		return
	var user: Object = _player.get("potion_user")
	var belt: RefCounted = root.get_node("GameState").get("potions")
	if user == null or belt == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if int(vitals.get("candles")) <= 1 and int(belt.call("charges", &"oil")) > 0:
		user.call("drink", 0)
		return
	var p: Vector2 = _player.global_position
	var near: int = 0
	var positions: PackedVector2Array = _manager.get("positions")
	for i: int in int(_manager.get("count")):
		if positions[i].distance_to(p) < 40.0:
			near += 1
	if near >= 6 and int(belt.call("charges", &"holy_water")) > 0:
		user.call("drink", 1)
		return
	if int(belt.call("charges", &"wine")) > 0 and not bool(belt.call("active", &"wine")) and int(_manager.get("count")) > 5:
		user.call("drink", 2)
		return
	var atril: RefCounted = _field.get("atril")
	if int(belt.call("charges", &"illumination")) > 0 and int(atril.call("size")) > 0:
		user.call("drink", 3)


func _print_rhythm() -> void:
	var mins: float = maxf(_time / 60.0, 0.001)
	var gs: Node = root.get_node("GameState")
	var waves: PackedStringArray = []
	for w: int in range(1, 10):
		waves.append("%d:%d" % [w, int(_menus_by_wave.get(w, 0))])
	print("RHYTHM palavras/min=%.2f menus_por_onda=[%s] iluminura=%d letras=%d nivel_final=%d nivel_arma_por_onda=%s tinta_ganha=%d tinta_em_pocao=%d compras=%d" % [
		_words_total / mins, ", ".join(waves), _illum_menus, _collected.length(),
		int((gs.get("grace") as RefCounted).get("level")) if gs.get("grace") != null else -1,
		_weapon_lvls, _ink_earned, _potion_ink, _bought.size()])
	print("POTIONS bebidas=%s" % [_drunk])
	var gap: float = 0.0
	var prev: float = 0.0
	for t: float in _word_times:
		gap = maxf(gap, t - prev)
		prev = t
	gap = maxf(gap, _time - prev)
	print("WORDS primeira=%s maior_intervalo=%.0fs" % [("%.0fs" % _word_times[0]) if _word_times.size() > 0 else "nenhuma", gap])
