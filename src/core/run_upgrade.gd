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
		&"passive_level":
			level_repulse()
		&"potion_level":
			if GameState.potions != null:
				GameState.potions.level_up(b.target)


## Compra (nível 1) ou selo (+1) do ímã reverso, até o teto.
static func level_repulse() -> bool:
	if GameState.repulse_level >= GameState.repulse.max_level():
		return false
	GameState.repulse_level += 1
	EventBus.passive_leveled.emit(GameState.repulse.id, GameState.repulse_level)
	return true


## Compra de arma na loja (FR-1702): preenche o espaço vazio ou substitui a ativa.
static func equip_weapon(w: WeaponData) -> void:
	var lo: Loadout = GameState.loadout
	if lo == null:
		return
	var slot: int = lo.equip(w)
	EventBus.weapon_equipped.emit(slot, w, lo.slots[slot].level)
