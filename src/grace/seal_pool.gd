class_name SealPool
extends RefCounted
## Os 3 selos do level-up na 017 (T1729; rules-agent T1700 §5; mechanics-agent): cada selo sorteia
## um tipo pelos pesos do GraceTuning — nível da arma ativa, nível da arma guardada, bênção de
## status ou nível do ímã reverso — e o tipo sem nada a oferecer sai do sorteio. D-098 (T1830): o
## selo de arma sobe 1 posto de um atributo sorteado entre os livres; até os 3 selos podem ser da
## mesma arma, nunca o mesmo atributo 2×; pelo menos 1 selo de arma quando houver o que subir.
## Sem nada, a reserva.
## Usa o RNG que receber (o da Graça).

const ACTIVE := &"weapon_active"
const RESERVE := &"weapon_reserve"
const STATUS := &"status"
const PASSIVE := &"passive"
const POTION := &"potion"


static func draw(tuning: GraceTuning, stats: RunStats, loadout: Loadout, repulse_level: int,
		repulse_max: int, rng: RandomNumberGenerator, potions: PotionBelt = null) -> Array[BlessingData]:
	if potions == null:
		potions = GameState.potions
	# 018: selo de poção = +1 nível de uma poção já comprada (D-094 item 2); 1 por oferta.
	var potion_ids: Array[StringName] = []
	if potions != null:
		potion_ids = potions.levelable_ids()
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
	var free := {ACTIVE: _free(loadout, active), RESERVE: _free(loadout, reserve)}
	var slot_of := {ACTIVE: active, RESERVE: reserve}
	var passive_ok: bool = repulse_level > 0 and repulse_level < repulse_max
	var out: Array[BlessingData] = []
	while out.size() < tuning.choices:
		var kinds: Array[StringName] = []
		var weights := PackedFloat32Array()
		if not (free[ACTIVE] as Array).is_empty():
			kinds.append(ACTIVE)
			weights.append(tuning.seal_weapon_active)
		if not (free[RESERVE] as Array).is_empty():
			kinds.append(RESERVE)
			weights.append(tuning.seal_weapon_reserve)
		if not status_pool.is_empty():
			kinds.append(STATUS)
			weights.append(tuning.seal_status)
		if passive_ok:
			kinds.append(PASSIVE)
			weights.append(tuning.seal_passive)
		if not potion_ids.is_empty():
			kinds.append(POTION)
			weights.append(tuning.seal_potion)
		if kinds.is_empty():
			break
		var kind: StringName = _weighted(kinds, weights, rng)
		match kind:
			ACTIVE, RESERVE:
				out.append(_pick_weapon_seal(loadout, slot_of[kind], free[kind], rng))
			PASSIVE:
				out.append(passive_seal(repulse_level))
				passive_ok = false
			POTION:
				out.append(potion_seal(potion_ids[rng.randi_range(0, potion_ids.size() - 1)]))
				potion_ids.clear()
			_:
				var picked: Array[BlessingData] = BlessingOffer.draw(status_pool, stats, rng, 1, null)
				out.append(picked[0])
				status_pool.erase(picked[0])
	# Garantia: com arma para subir e nenhum selo de arma, o último vira a arma (a ativa primeiro).
	var has_weapon: bool = out.any(func(b: BlessingData) -> bool: return b.kind == &"weapon_level")
	if not has_weapon and not out.is_empty():
		var k: StringName = ACTIVE if not (free[ACTIVE] as Array).is_empty() else RESERVE
		if not (free[k] as Array).is_empty():
			out[out.size() - 1] = _pick_weapon_seal(loadout, slot_of[k], free[k], rng)
	if out.is_empty() and tuning.fallback != null:
		out.append(tuning.fallback)
	return out


## Atributos livres da arma do espaço `slot` (vazio se não há arma ou nada a subir).
static func _free(loadout: Loadout, slot: int) -> Array[WeaponUpgradeData]:
	if loadout == null or slot < 0 or slot >= loadout.slots.size() or loadout.slots[slot] == null:
		return []
	return loadout.slots[slot].free_upgrades()


## Sorteia um atributo livre e o tira da lista (nunca 2× na mesma oferta).
static func _pick_weapon_seal(loadout: Loadout, slot: int, pool: Array, rng: RandomNumberGenerator) -> BlessingData:
	var u: WeaponUpgradeData = pool[rng.randi_range(0, pool.size() - 1)]
	pool.erase(u)
	return weapon_seal(loadout, slot, u)


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


## Selo "+1 posto em `u`" da arma do espaço `slot` (D-098): ícone da arma, o atributo como nome e,
## embaixo, a arma com o valor de agora e o próximo ("PENA 0,80S > 0,71S").
static func weapon_seal(loadout: Loadout, slot: int, u: WeaponUpgradeData) -> BlessingData:
	var s: WeaponSlot = loadout.slots[slot]
	var w: WeaponData = s.weapon
	var b := BlessingData.new()
	b.id = StringName("weapon_level_%s_%s" % [w.id, u.id])
	b.kind = &"weapon_level"
	b.slot = slot
	b.target = u.id
	b.icon = w.icon
	b.display_name = u.label
	var now: WeaponLevelData = s.stats()
	var next: WeaponLevelData = s.preview(u.id)
	b.short_desc = "%s %s" % [TranslationServer.translate(w.display_name), u.describe(now, next)]  # reserva (testes, log)
	b.subtitle = w.display_name
	b.value_now = u.format_value(now.get(u.display_field))
	b.value_next = u.format_value(next.get(u.display_field))
	return b


## Selo "+1 nível" de uma poção comprada (ícone e nome da poção; sem GOLD).
static func potion_seal(id: StringName) -> BlessingData:
	var p: PotionData = GameState.potion_tuning.by_id(id)
	var b := BlessingData.new()
	b.id = StringName("potion_level_%s" % id)
	b.kind = &"potion_level"
	b.target = id
	b.icon = p.shop_icon
	b.display_name = p.display_name
	b.short_desc = "SEAL_POTION_LEVEL_DESC"
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
