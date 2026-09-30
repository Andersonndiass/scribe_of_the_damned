class_name Arsenal
extends Node
## Armas do escriba (017 FR-1701..FR-1707; mechanics-agent T1700). Substitui o AutoAttack: só a
## arma ativa ataca; teclas 1/2 trocam; cada arma guarda a própria recarga (continua correndo
## guardada, até ficar pronta — trocar não reinicia nem vira exploit); a arma nova espera o
## "saque" antes de atacar. Os números vêm do WeaponData do nível do espaço.

signal fired(target: Vector2)
## O Crucifixo começou a antecipação (o disparo sai depois de `WeaponData.windup`).
signal windup_started(slot: int)

@export var origin: Node2D
@export var tuning: ArsenalTuning = preload("res://data/weapons/arsenal_tuning.tres")
var data: PlayerData
var projectiles: PlayerProjectileManager
var enabled: bool = true
## Inventário usado (padrão: o da partida em GameState).
var loadout: Loadout

## Folga da soma de frames na antecipação (0,2 s = 12 frames, não 13).
const WINDUP_EPS := 0.0001

var _timers := PackedFloat32Array()
## Antecipação em curso por espaço (< 0 = nenhuma).
var _windup := PackedFloat32Array()
var _draw_left: float = 0.0
## Raio da Bíblia (um só: só a arma ativa ataca).
var beam: BeamWeapon


func _ready() -> void:
	if origin == null:
		origin = get_parent() as Node2D
	_timers.resize(tuning.slots)
	_windup.resize(tuning.slots)
	_windup.fill(-1.0)
	beam = BeamWeapon.new()
	beam.name = "Beam"
	add_child(beam)


func current() -> Loadout:
	return loadout if loadout != null else GameState.loadout


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not event.is_pressed() or event.is_echo():
		return
	for i: int in 2:
		if event.is_action(StringName("weapon_%d" % (i + 1))):
			if switch_to(i):
				get_viewport().set_input_as_handled()
			return


## Troca a arma ativa (1/2). Falso se o espaço está vazio ou já é o ativo.
func switch_to(i: int) -> bool:
	var lo: Loadout = current()
	if lo == null or not lo.set_active(i):
		return false
	_draw_left = tuning.swap_draw_time
	EventBus.weapon_switched.emit(i, lo.weapon(i))
	return true


func interval_of(slot: WeaponSlot) -> float:
	var mul: float = RunStats.of(data).value(&"weapon_interval_mul") if data != null else 1.0
	return maxf(slot.stats().interval * mul, 0.01)


func _physics_process(delta: float) -> void:
	var lo: Loadout = current()
	if not enabled or projectiles == null or lo == null:
		if beam != null:
			beam.release()
		return
	if _timers.size() < lo.slots.size():
		_timers.resize(lo.slots.size())
		_windup.resize(lo.slots.size())
		_windup.fill(-1.0)
	_draw_left = maxf(0.0, _draw_left - delta)
	var beaming: bool = false
	for i: int in lo.slots.size():
		var slot: WeaponSlot = lo.slots[i]
		if slot == null:
			continue
		var interval: float = interval_of(slot)
		if i != lo.active or _draw_left > 0.0:
			_timers[i] = minf(_timers[i] + delta, interval)  # guardada: fica pronta e espera
			_windup[i] = -1.0  # antecipação cancelada sem gastar a recarga
			continue
		if slot.weapon.pattern == &"beam":
			_hold_beam(slot, interval)
			beaming = true
			continue
		_timers[i] += delta
		if slot.weapon.windup > 0.0:
			_tick_windup(i, slot, interval, delta)
			continue
		while _timers[i] >= interval:
			_timers[i] -= interval
			_fire(slot)
	if not beaming:
		beam.release()


## Arma com antecipação (Crucifixo): pronta e com alvo, começa a subir; o disparo sai no fim.
## Sem alvo no fim, espera pronta (não gasta a recarga).
func _tick_windup(i: int, slot: WeaponSlot, interval: float, delta: float) -> void:
	if _windup[i] < 0.0:
		_timers[i] = minf(_timers[i], interval)
		if _timers[i] < interval:
			return
		var from: Vector2 = origin.global_position + slot.weapon.muzzle
		if EnemyQuery.nearest(from, slot.stats().range) == Vector2.INF:
			return
		_windup[i] = slot.weapon.windup
		windup_started.emit(i)
		return
	_windup[i] -= delta
	if _windup[i] > WINDUP_EPS:
		return
	_windup[i] = -1.0
	if _fire(slot):
		_timers[i] = maxf(_timers[i] - interval, 0.0)  # a antecipação conta dentro do intervalo


func _hold_beam(slot: WeaponSlot, interval: float) -> void:
	var w: WeaponData = slot.weapon
	var from: Vector2 = origin.global_position + w.muzzle
	var facing: Variant = origin.get(&"facing")
	var dir: Vector2 = Aim.direction(from, facing if facing is Vector2 else Vector2.RIGHT)
	beam.hold(from, Aim.snapped(dir, w.aim_steps), slot.stats(), w, interval)


func _fire(slot: WeaponSlot) -> bool:
	match slot.weapon.pattern:
		&"burst":
			return _fire_burst(slot)
	return false


## Rajada (Pena, Crucifixo): `count` projéteis nos N inimigos mais próximos; com menos alvos, os
## que sobram vão nos mesmos. Sem alvo, não dispara (FR-002).
func _fire_burst(slot: WeaponSlot) -> bool:
	var w: WeaponData = slot.weapon
	var s: WeaponLevelData = slot.stats()
	var from: Vector2 = origin.global_position + w.muzzle
	var targets: PackedVector2Array = EnemyQuery.nearest_list(from, s.range, s.count)
	if targets.is_empty():
		return false
	var radius: float = s.width / 2.0 if s.width > 0.0 else PlayerProjectileManager.HIT_RADIUS
	var any: bool = false
	for k: int in s.count:
		var t: Vector2 = targets[k % targets.size()]
		if projectiles.fire(from, t - from, s.speed, s.damage, s.range * w.travel_mul,
				w.projectile_kind, radius, s.pierce, w.hit_freeze):
			any = true
	if any:
		fired.emit(targets[0])
		if w.fire_shake_px > 0.0:
			EventBus.shake_requested.emit(w.fire_shake_px, w.fire_shake_time)
	return any
