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

var _timers := PackedFloat64Array()  # 64 bits: com 32, 1,4 travado vira 1,39999998 < 1,4 e a arma nunca atira
## Antecipação em curso por espaço (< 0 = nenhuma).
var _windup := PackedFloat64Array()
var _draw_left: float = 0.0
## Raio da Bíblia (um só: só a arma ativa ataca).
var beam: BeamWeapon
## Rosário e Turíbulo (017 Fase 5).
var orbit: OrbitWeapon
var swing: SwingTrailWeapon


func _ready() -> void:
	if origin == null:
		origin = get_parent() as Node2D
	_timers.resize(tuning.slots)
	_windup.resize(tuning.slots)
	_windup.fill(-1.0)
	beam = BeamWeapon.new()
	beam.name = "Beam"
	add_child(beam)
	orbit = OrbitWeapon.new()
	orbit.name = "Orbit"
	add_child(orbit)
	swing = SwingTrailWeapon.new()
	swing.name = "Swing"
	add_child(swing)


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
	var lo: Loadout = current()
	return maxf(slot.stats().interval * _slot_mul(lo.slots.find(slot) if lo != null else -1), 0.01)


## Pena de Ganso × Vinho do Fervor (018: só no espaço do momento em que bebeu), com piso.
func _slot_mul(index: int) -> float:
	var mul: float = RunStats.of(data).value(&"weapon_interval_mul") if data != null else 1.0
	if GameState.potions != null:
		mul = maxf(mul * GameState.potions.cadence_mul(index), GameState.potion_tuning.cadence_floor)
	return mul


func _physics_process(delta: float) -> void:
	var lo: Loadout = current()
	if not enabled or projectiles == null or lo == null:
		if beam != null:
			beam.release()
			orbit.release()
			swing.stop_swing()
		return
	if _timers.size() < lo.slots.size():
		_timers.resize(lo.slots.size())
		_windup.resize(lo.slots.size())
		_windup.fill(-1.0)
	_draw_left = maxf(0.0, _draw_left - delta)
	var beaming: bool = false
	var orbiting: bool = false
	var swinging: bool = false
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
		if slot.weapon.pattern == &"orbit":
			orbit.hold(origin.global_position, slot.stats(), slot.weapon, _interval_mul(), delta)
			orbiting = true
			continue
		_timers[i] += delta
		if slot.weapon.pattern == &"swing_trail":
			swinging = true
			_tick_swing(i, slot, interval, delta)
			continue
		if slot.weapon.windup > 0.0:
			_tick_windup(i, slot, interval, delta)
			continue
		while _timers[i] >= interval:
			_timers[i] -= interval
			_fire(slot)
	if not beaming:
		beam.release()
	if not orbiting:
		orbit.release()
	if not swinging and swing.is_swinging():
		swing.stop_swing()  # a cabeça some na troca; o rastro no chão continua
	_update_charge(lo)


func _interval_mul() -> float:
	var lo: Loadout = current()
	return _slot_mul(lo.active if lo != null else -1)


## Turíbulo: pronto e com inimigo ao alcance do balanço, balança para o lado dele; senão espera.
func _tick_swing(i: int, slot: WeaponSlot, interval: float, delta: float) -> void:
	var center: Vector2 = origin.global_position
	if swing.is_swinging():
		swing.swing_tick(center, delta)
		return
	_timers[i] = minf(_timers[i], interval)
	if _timers[i] < interval:
		return
	var s: WeaponLevelData = slot.stats()
	var target: Vector2 = EnemyQuery.nearest(center, s.range + slot.weapon.head_radius)
	if target == Vector2.INF:
		return
	_timers[i] = 0.0
	swing.start_swing(center, target - center, s, slot.weapon, _interval_mul())
	fired.emit(target)
	EventBus.weapon_fired.emit(slot.weapon.id)


## Recarga para o HUD (T1800): rajada = tempo/intervalo; raio e antecipação = pronta; a ativa no
## saque não passa do quanto o saque andou.
func _update_charge(lo: Loadout) -> void:
	for i: int in lo.slots.size():
		var slot: WeaponSlot = lo.slots[i]
		if slot == null:
			continue
		var c: float = clampf(_timers[i] / interval_of(slot), 0.0, 1.0)
		if slot.weapon.pattern == &"beam" or slot.weapon.pattern == &"orbit" or _windup[i] >= 0.0:
			c = 1.0
		if i == lo.active and _draw_left > 0.0 and tuning.swap_draw_time > 0.0:
			c = minf(c, 1.0 - _draw_left / tuning.swap_draw_time)
		slot.charge = c


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
		EventBus.weapon_windup_started.emit(slot.weapon.id)
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
		&"fan":
			return _fire_fan(slot)
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
				w.projectile_kind, radius, s.pierce, w.hit_freeze, s.slow_factor, s.slow_time):
			any = true
	if any:
		fired.emit(targets[0])
		EventBus.weapon_fired.emit(w.id)
		if w.fire_shake_px > 0.0:
			EventBus.shake_requested.emit(w.fire_shake_px, w.fire_shake_time)
	return any


## Aspersório (017 T1738): leque de `count` gotas em `spread_deg` para onde se mira (mouse ou
## movimento); só com inimigo ao alcance. As gotas não atravessam.
func _fire_fan(slot: WeaponSlot) -> bool:
	var w: WeaponData = slot.weapon
	var s: WeaponLevelData = slot.stats()
	var from: Vector2 = origin.global_position + w.muzzle
	if EnemyQuery.nearest(from, s.range) == Vector2.INF:
		return false
	var facing: Variant = origin.get(&"facing")
	var dir: Vector2 = Aim.direction(from, facing if facing is Vector2 else Vector2.RIGHT)
	var spread: float = deg_to_rad(s.spread_deg)
	var radius: float = s.width / 2.0 if s.width > 0.0 else PlayerProjectileManager.HIT_RADIUS
	var any: bool = false
	for k: int in s.count:
		var t: float = 0.5 if s.count == 1 else float(k) / float(s.count - 1)
		var d: Vector2 = dir.rotated(-spread / 2.0 + spread * t)
		if projectiles.fire(from, d, s.speed, s.damage, s.range * w.travel_mul, w.projectile_kind, radius, s.pierce,
				0.0, s.slow_factor, s.slow_time):
			any = true
	if any:
		fired.emit(from + dir * s.range)
		EventBus.weapon_fired.emit(w.id)
	return any
