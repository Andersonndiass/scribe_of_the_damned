class_name Arsenal
extends Node
## Armas do escriba (017 FR-1701..FR-1707; mechanics-agent T1700). Substitui o AutoAttack: só a
## arma ativa ataca; teclas 1/2 trocam; cada arma guarda a própria recarga (continua correndo
## guardada, até ficar pronta — trocar não reinicia nem vira exploit); a arma nova espera o
## "saque" antes de atacar. Os números vêm do WeaponData do nível do espaço.

signal fired(target: Vector2)

@export var origin: Node2D
@export var tuning: ArsenalTuning = preload("res://data/weapons/arsenal_tuning.tres")
var data: PlayerData
var projectiles: PlayerProjectileManager
var enabled: bool = true
## Inventário usado (padrão: o da partida em GameState).
var loadout: Loadout

var _timers := PackedFloat32Array()
var _draw_left: float = 0.0


func _ready() -> void:
	if origin == null:
		origin = get_parent() as Node2D
	_timers.resize(tuning.slots)


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
		return
	if _timers.size() < lo.slots.size():
		_timers.resize(lo.slots.size())
	_draw_left = maxf(0.0, _draw_left - delta)
	for i: int in lo.slots.size():
		var slot: WeaponSlot = lo.slots[i]
		if slot == null:
			continue
		var interval: float = interval_of(slot)
		if i != lo.active or _draw_left > 0.0:
			_timers[i] = minf(_timers[i] + delta, interval)  # guardada: fica pronta e espera
			continue
		_timers[i] += delta
		while _timers[i] >= interval:
			_timers[i] -= interval
			_fire(slot)


func _fire(slot: WeaponSlot) -> void:
	match slot.weapon.pattern:
		&"burst":
			_fire_burst(slot)


## Rajada (Pena, Crucifixo): `count` projéteis nos N inimigos mais próximos; com menos alvos, os
## que sobram vão nos mesmos. Sem alvo, não dispara (FR-002).
func _fire_burst(slot: WeaponSlot) -> void:
	var w: WeaponData = slot.weapon
	var s: WeaponLevelData = slot.stats()
	var from: Vector2 = origin.global_position + w.muzzle
	var targets: PackedVector2Array = EnemyQuery.nearest_list(from, s.range, s.count)
	if targets.is_empty():
		return
	var any: bool = false
	for k: int in s.count:
		var t: Vector2 = targets[k % targets.size()]
		if projectiles.fire(from, t - from, s.speed, s.damage, s.range * w.travel_mul):
			any = true
	if any:
		fired.emit(targets[0])
