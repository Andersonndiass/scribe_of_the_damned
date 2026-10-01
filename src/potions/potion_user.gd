class_name PotionUser
extends Node
## Quem bebe (018 T1808; mechanics-agent T1801). Teclas 3–6 = `potion_1..4` na ordem do
## PotionTuning. FSM: OFF (fora da onda, loja, morto) → READY → (beber) GAP (`use_gap`) → READY.
## Recusa não gasta carga e emite `potion_refused(id, motivo)`. Efeitos contam tempo de jogo.
## Pausa e selos já não entregam input (o nó é pausável).

enum Phase { OFF, READY, GAP }

const ACTIONS: Array[StringName] = [&"potion_1", &"potion_2", &"potion_3", &"potion_4"]

var player: Player
var phase: Phase = Phase.OFF
var gap_left: float = 0.0
var circle: RefugeCircle


func _ready() -> void:
	if player == null:
		player = get_parent() as Player
	EventBus.wave_started.connect(func(_i: int, _d: float) -> void: _turn_on())
	EventBus.boss_spawned.connect(func(_b: BossData) -> void: _turn_on())
	EventBus.wave_ended.connect(func(_i: int) -> void: _turn_off())
	EventBus.shop_opened.connect(func(_w: int) -> void: _turn_off())
	EventBus.player_died.connect(_turn_off)
	EventBus.heresy_committed.connect(_on_heresy)
	# Desenho do círculo: na camada de efeitos do Main (abaixo dos inimigos), se houver.
	circle = RefugeCircle.new()
	circle.name = "RefugeCircle"
	var host: Node = player.get_parent().get_parent().get_node_or_null(^"FxLayer") if player != null and player.get_parent() != null and player.get_parent().get_parent() != null else null
	if host != null:
		host.add_child.call_deferred(circle)
	else:
		add_child(circle)


func belt() -> PotionBelt:
	return GameState.potions


func _turn_on() -> void:
	if phase == Phase.OFF:
		phase = Phase.READY


## Fim de onda, loja e morte: encerra os efeitos (motivo `wave_end`).
func _turn_off() -> void:
	phase = Phase.OFF
	gap_left = 0.0
	var b: PotionBelt = belt()
	if b == null:
		return
	for id: StringName in b.left.keys():
		b.left.erase(id)
		EventBus.potion_effect_ended.emit(id, &"wave_end")
	RefugeZones.clear()


## Heresia dentro do círculo apaga o círculo (D-094 item 5; a perdoada não chega aqui).
func _on_heresy(pos: Vector2) -> void:
	if not RefugeZones.contains(pos):
		return
	RefugeZones.clear()
	if belt() != null and belt().left.has(&"holy_water"):
		belt().left.erase(&"holy_water")
	EventBus.potion_effect_ended.emit(&"holy_water", &"heresy")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	for i: int in ACTIONS.size():
		if event.is_action(ACTIONS[i]):
			drink(i)
			get_viewport().set_input_as_handled()
			return


## Bebe a poção da tecla `index` (0..3). Falso = recusada (sem gastar).
func drink(index: int) -> bool:
	var b: PotionBelt = belt()
	if b == null or index < 0 or index >= b.tuning.order.size():
		return false
	var p: PotionData = b.tuning.order[index]
	var why: StringName = _refusal(p)
	if why != &"":
		EventBus.potion_refused.emit(p.id, why)
		return false
	if not _apply(p):
		EventBus.potion_refused.emit(p.id, &"menu_busy")
		return false
	b.consume(p.id)
	phase = Phase.GAP
	gap_left = b.tuning.use_gap
	EventBus.potion_drunk.emit(p.id, b.level(p.id), b.charges(p.id))
	return true


## Motivo da recusa, ou &"" se pode beber (ordem do mechanics-agent).
func _refusal(p: PotionData) -> StringName:
	if phase == Phase.GAP:
		return &"gap"
	if phase != Phase.READY or player == null or not player.vitals.is_alive():
		return &"blocked"
	if GameState.letter_menu_open or GameState.levelup_beam:
		return &"blocked"
	if player.machine.current != null and player.machine.current.name == &"Stunned":
		return &"stunned"
	if belt().charges(p.id) <= 0:
		return &"empty"
	if p.effect == &"heal" and player.vitals.candles >= player.vitals.max_candles:
		return &"full"
	if p.effect == &"illumination":
		var field: LetterField = get_tree().get_first_node_in_group(&"letter_field") as LetterField
		if field == null or not field.menu.can_open_now():
			return &"menu_busy"
	return &""


## O efeito do nível atual. Falso = não deu para aplicar (não gasta).
func _apply(p: PotionData) -> bool:
	var b: PotionBelt = belt()
	var s: PotionLevelData = b.stats(p.id)
	match p.effect:
		&"heal":
			player.heal(s.heal)
			if s.iframes > 0.0:
				player.vitals.grant_iframes_for(s.iframes)
		&"fervor":
			b.fervor_slot = GameState.loadout.active if GameState.loadout != null else -1
			b.fervor_mul = s.interval_mul
			b.left[p.id] = s.duration
		&"refuge":
			b.left[p.id] = s.duration
			RefugeZones.open(player.global_position, s.radius)  # beber de novo recentraliza
			var em := EnemyQuery.provider as EnemyManager
			if em != null:
				em.expel_from_refuge()
		&"illumination":
			var field: LetterField = get_tree().get_first_node_in_group(&"letter_field") as LetterField
			return field != null and field.menu.open_now(s.useful_options)
	return true


func _physics_process(delta: float) -> void:
	if phase == Phase.GAP:
		gap_left -= delta
		if gap_left <= 0.0:
			phase = Phase.READY
	var b: PotionBelt = belt()
	if b == null or b.left.is_empty():
		return
	for id: StringName in b.left.keys():
		b.left[id] -= delta
		if b.left[id] <= 0.0:
			b.left.erase(id)
			if id == &"holy_water":
				RefugeZones.clear()
			EventBus.potion_effect_ended.emit(id, &"timeout")
