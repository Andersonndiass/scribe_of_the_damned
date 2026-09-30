class_name RunStats
extends RefCounted
## Números do escriba na partida (003 FR-309). A base é o PlayerData; os itens da loja mexem
## nos valores com teto (ShopItemData). Zera a cada partida (GameState.start_run).
## Sem item comprado, todo valor é igual ao do PlayerData: quem lia a base continua igual.

var base: PlayerData

var _value: Dictionary[StringName, float] = {}
var _buys: Dictionary[StringName, int] = {}

## RunStats neutro para PlayerData que não é o da partida (testes, cenas isoladas).
static var _neutral: Dictionary = {}


func _init(p_base: PlayerData) -> void:
	base = p_base
	_value = {
		&"move_speed": base.move_speed,
		&"attack_interval": base.attack_interval,
		&"magnet_radius": base.magnet_radius,
		&"atril_capacity": float(base.atril_capacity),
		&"max_candles": float(base.start_candles),
		&"target_bonus_add": 0.0,
		&"double_letter_chance": 0.0,
		&"heresy_stun_mul": 1.0,
		&"gold_mul": 1.0,
		# 016: bênção Tinta Consagrada (só dano das palavras; a cura não usa).
		&"word_damage_mul": 1.0,
		# 017: Pena de Ganso — cadência de todas as armas (intervalo × isto).
		&"weapon_interval_mul": 1.0,
	}


## O RunStats da partida se `data` é o personagem dela; senão um neutro (valores da base).
static func of(data: PlayerData) -> RunStats:
	if GameState.run_stats != null and GameState.run_stats.base == data:
		return GameState.run_stats
	var key: int = data.get_instance_id()
	if not _neutral.has(key):
		_neutral[key] = RunStats.new(data)
	return _neutral[key]


func has_stat(stat: StringName) -> bool:
	return _value.has(stat)


func value(stat: StringName) -> float:
	return _value.get(stat, 0.0)


func int_value(stat: StringName) -> int:
	return roundi(value(stat))


func buys_of(id: StringName) -> int:
	return _buys.get(id, 0)


## O campo do item já está no teto?
func is_capped(item: StatUpgradeData) -> bool:
	var v: float = value(item.stat)
	if item.mode == &"mul" and item.amount < 1.0:
		return v <= item.cap + 0.0001
	return v >= item.cap - 0.0001


## Pode aparecer na loja? (compra única já feita ou teto sem uso depois dele → não)
func can_offer(item: ShopItemData) -> bool:
	if item.kind != &"item":
		return true
	if item.max_buys > 0 and buys_of(item.id) >= item.max_buys:
		return false
	return not is_capped(item) or item.after_cap != &""


## Aplica a melhoria (respeitando o teto). Retorna true se o valor mudou. Sem stat (só cura),
## só conta a vez.
func apply(item: StatUpgradeData) -> bool:
	_buys[item.id] = buys_of(item.id) + 1
	if item.stat == &"":
		return false
	var before: float = value(item.stat)
	var v: float = before
	match item.mode:
		&"percent":
			v += _base_of(item.stat) * item.amount
		&"mul":
			v *= item.amount
		_:
			v += item.amount
	if item.mode == &"mul" and item.amount < 1.0:
		v = maxf(v, item.cap)
	elif item.cap > 0.0:
		v = minf(v, item.cap)
	_value[item.stat] = v
	return not is_equal_approx(v, before)


func _base_of(stat: StringName) -> float:
	match stat:
		&"move_speed":
			return base.move_speed
		&"attack_interval":
			return base.attack_interval
		&"magnet_radius":
			return base.magnet_radius
		&"atril_capacity":
			return float(base.atril_capacity)
		&"max_candles":
			return float(base.start_candles)
	return 1.0
