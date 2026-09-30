class_name RunUpgrade
extends RefCounted
## Aplica uma melhoria (carta da loja ou bênção) no RunStats e nos sistemas vivos (016 FR-1612):
## atril, velas máximas e a cura em dados. Usado pela loja e pelo level-up.


static func apply(item: StatUpgradeData, player: Player, letter_field: LetterField) -> void:
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
