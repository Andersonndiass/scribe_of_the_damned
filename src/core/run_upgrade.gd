class_name RunUpgrade
extends RefCounted
## Aplica uma melhoria (carta da loja ou bênção) no RunStats e nos sistemas vivos (016 FR-1612):
## atril, velas máximas e a cura em dados. Usado pela loja e pelo level-up.


static func apply(item: StatUpgradeData, player: Player, letter_field: LetterField) -> void:
	var b := item as BlessingData
	if b != null and b.kind != &"stat":
		apply_option(b)
		return
	var stats: RunStats = GameState.run_stats
	stats.apply(item)  # sem stat (reserva), só conta a vez
	match item.stat:
		&"atril_capacity":
			if letter_field != null:
				letter_field.atril.set_capacity(stats.int_value(&"atril_capacity"))
				letter_field.emit_atril()
		&"max_candles":
			if player != null:
				player.vitals.max_candles = stats.int_value(&"max_candles")
	if item.heal_candles > 0 and player != null:
		player.heal(item.heal_candles)


## 017 (T1731): selo de nível de arma ou do ímã reverso.
static func apply_option(b: BlessingData) -> void:
	GameState.run_stats.apply(b)  # sem stat: só conta a escolha, como as bênçãos
	match b.kind:
		&"weapon_level":
			# D-098: o selo sobe 1 posto do atributo `target` da arma do espaço `slot`.
			var lo: Loadout = GameState.loadout
			if b.target == &"":
				push_error("selo de arma sem atributo")
				return
			if lo != null and lo.rank_up(b.slot, b.target):
				var s: WeaponSlot = lo.slots[b.slot]
				EventBus.weapon_leveled.emit(b.slot, s.weapon, s.level, b.target, s.rank(b.target))
		&"relic_level":
			var lo2: Loadout = GameState.loadout
			if lo2 != null and lo2.relic_rank_up(b.slot, b.target):
				var r: RelicSlot = lo2.relic(b.slot)
				EventBus.relic_leveled.emit(b.slot, r.relic, r.level, b.target, r.rank(b.target))
		&"potion_level":
			if GameState.potions != null:
				GameState.potions.level_up(b.target)


## Relíquia comprada (019): no espaço vazio ou no `replace`.
static func equip_relic(r: RelicData, paid: int = 0, replace: int = -1) -> void:
	var lo: Loadout = GameState.loadout
	if lo == null:
		return
	if replace >= 0 and lo.relic(replace) != null:
		EventBus.relic_removed.emit(replace, lo.relic(replace).relic, &"replaced")
	var slot: int = lo.equip_relic(r, replace)
	if slot < 0:
		return
	lo.relic(slot).paid = paid
	EventBus.relic_equipped.emit(slot, r, 1)


static func remove_relic(slot: int, cause: StringName) -> void:
	var lo: Loadout = GameState.loadout
	var gone: RelicSlot = lo.remove_relic(slot) if lo != null else null
	if gone != null:
		EventBus.relic_removed.emit(slot, gone.relic, cause)


static func remove_weapon(slot: int, cause: StringName) -> void:
	var lo: Loadout = GameState.loadout
	var was_active: bool = lo != null and lo.active == slot
	var gone: WeaponSlot = lo.remove_weapon(slot) if lo != null else null
	if gone == null:
		return
	if GameState.potions != null and GameState.potions.fervor_slot == slot:
		GameState.potions.fervor_slot = -1  # o Vinho some com a arma
	EventBus.weapon_removed.emit(slot, gone.weapon, cause)
	if was_active:
		EventBus.weapon_switched.emit(lo.active, lo.weapon(lo.active))


## Compra de arma na loja (FR-1702): preenche o espaço vazio ou substitui a ativa.
static func equip_weapon(w: WeaponData, paid: int = 0) -> void:
	var lo: Loadout = GameState.loadout
	if lo == null:
		return
	var slot: int = lo.equip(w)
	lo.slots[slot].paid = paid
	EventBus.weapon_equipped.emit(slot, w, lo.slots[slot].level)
