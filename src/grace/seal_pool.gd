class_name SealPool
extends RefCounted
## Os 3 selos do level-up na 017 (T1729; rules-agent T1700 §5; mechanics-agent): cada selo sorteia
## um tipo pelos pesos do GraceTuning — nível da arma ativa, nível da arma guardada, bênção de
## status ou nível do ímã reverso — e o tipo sem nada a oferecer sai do sorteio. No máximo 1 selo
## por espaço de arma; pelo menos 1 selo de arma quando houver arma para subir. Sem nada, a reserva.
## Usa o RNG que receber (o da Graça).

const ACTIVE := &"weapon_active"
const RESERVE := &"weapon_reserve"
const STATUS := &"status"
const PASSIVE := &"passive"


static func draw(tuning: GraceTuning, stats: RunStats, loadout: Loadout, repulse_level: int,
		repulse_max: int, rng: RandomNumberGenerator) -> Array[BlessingData]:
	var status_pool: Array[BlessingData] = []
	for b: BlessingData in tuning.blessings:
		if b.stat == &"" or not stats.is_capped(b):
			status_pool.append(b)
	var active: int = loadout.active if loadout != null else -1
	var reserve: int = -1
	if loadout != null:
		for i: int in loadout.slots.size():
			if i != active and loadout.slots[i] != null:
				reserve = i
	var weapon_ok := {ACTIVE: _can_level(loadout, active), RESERVE: _can_level(loadout, reserve)}
	var passive_ok: bool = repulse_level > 0 and repulse_level < repulse_max
	var out: Array[BlessingData] = []
	while out.size() < tuning.choices:
		var kinds: Array[StringName] = []
		var weights := PackedFloat32Array()
		if weapon_ok[ACTIVE]:
			kinds.append(ACTIVE)
			weights.append(tuning.seal_weapon_active)
		if weapon_ok[RESERVE]:
			kinds.append(RESERVE)
			weights.append(tuning.seal_weapon_reserve)
		if not status_pool.is_empty():
			kinds.append(STATUS)
			weights.append(tuning.seal_status)
		if passive_ok:
			kinds.append(PASSIVE)
			weights.append(tuning.seal_passive)
		if kinds.is_empty():
			break
		match _weighted(kinds, weights, rng):
			ACTIVE:
				out.append(weapon_seal(loadout, active))
				weapon_ok[ACTIVE] = false
			RESERVE:
				out.append(weapon_seal(loadout, reserve))
				weapon_ok[RESERVE] = false
			PASSIVE:
				out.append(passive_seal(repulse_level))
				passive_ok = false
			_:
				var picked: Array[BlessingData] = BlessingOffer.draw(status_pool, stats, rng, 1, null)
				out.append(picked[0])
				status_pool.erase(picked[0])
	# Garantia: com arma para subir e nenhum selo de arma, o último vira a arma (a ativa primeiro).
	var has_weapon: bool = out.any(func(b: BlessingData) -> bool: return b.kind == &"weapon_level")
	if not has_weapon and not out.is_empty():
		var slot: int = active if weapon_ok[ACTIVE] else (reserve if weapon_ok[RESERVE] else -1)
		if slot >= 0:
			out[out.size() - 1] = weapon_seal(loadout, slot)
	if out.is_empty() and tuning.fallback != null:
		out.append(tuning.fallback)
	return out


static func _can_level(loadout: Loadout, slot: int) -> bool:
	return loadout != null and slot >= 0 and slot < loadout.slots.size() \
		and loadout.slots[slot] != null and loadout.slots[slot].can_level()


static func _weighted(kinds: Array[StringName], weights: PackedFloat32Array, rng: RandomNumberGenerator) -> StringName:
	var total: float = 0.0
	for w: float in weights:
		total += w
	var roll: float = rng.randf() * total
	for i: int in kinds.size():
		roll -= weights[i]
		if roll < 0.0:
			return kinds[i]
	return kinds[kinds.size() - 1]


## Selo "+1 nível" da arma do espaço `slot` (ícone e nome da arma).
static func weapon_seal(loadout: Loadout, slot: int) -> BlessingData:
	var w: WeaponData = loadout.slots[slot].weapon
	var b := BlessingData.new()
	b.id = StringName("weapon_level_%s" % w.id)
	b.kind = &"weapon_level"
	b.slot = slot
	b.icon = w.icon
	b.display_name = w.display_name
	b.short_desc = "SEAL_WEAPON_LEVEL_DESC"
	return b


## Selo "+1 nível" do ímã reverso.
static func passive_seal(_level: int) -> BlessingData:
	var b := BlessingData.new()
	b.id = &"passive_level_reverse_magnet"
	b.kind = &"passive_level"
	b.icon = load("res://assets/placeholders/itm_reverse_magnet.tres")
	b.display_name = "ITEM_REVERSE_MAGNET"
	b.short_desc = "SEAL_PASSIVE_LEVEL_DESC"
	return b
