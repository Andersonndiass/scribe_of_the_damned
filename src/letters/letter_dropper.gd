class_name LetterDropper
extends RefCounted
## Sorteio ponderado de letras (FR-013). Lógica pura e determinística para uma dada seed.
##   peso = base_weights[letra] (+ target_bonus se continua uma palavra que cabe no atril)
##   letra "trancada" (gated_letters) tem peso 0 até a palavra que a libera ser desbloqueada.
## target_add: Lentes do Copista somam no bônus (003); target_mul: LUMEN multiplica o total (002 FR-207).
## Sem continuação possível (atril em beco sem saída ou palavra completa), os alvos passam a ser
## as primeiras letras das palavras que cabem.

const VOWELS := "AEIOU"


## Retorna {"letter": String, "rare": bool, "target": bool}.
func roll(atril: Atril, lexicon: Lexicon, tuning: DropTuning, rng: RandomNumberGenerator,
		unlocked: Array[StringName], target_mul: float = 1.0, target_add: float = 0.0) -> Dictionary:
	var targets: PackedStringArray = lexicon.next_letters(atril.text(), atril.capacity)
	if targets.is_empty():
		targets = lexicon.next_letters("", atril.capacity)

	var letters: PackedStringArray = lexicon.data.alphabet
	var weights := PackedFloat32Array()
	weights.resize(letters.size())
	var total: float = 0.0
	for i: int in letters.size():
		var ch: String = letters[i]
		var w: float = 0.0
		if _is_available(ch, lexicon, unlocked):
			w = tuning.base_weights.get(ch, 1.0)
			if targets.has(ch):
				w += (tuning.target_bonus + target_add) * target_mul
		weights[i] = w
		total += w

	var pick: float = rng.randf() * total
	var chosen: String = letters[letters.size() - 1]
	for i: int in letters.size():
		pick -= weights[i]
		if pick < 0.0 and weights[i] > 0.0:
			chosen = letters[i]
			break

	var rare: bool = VOWELS.contains(chosen) and rng.randf() < tuning.rare_chance
	return {"letter": chosen, "rare": rare, "target": targets.has(chosen)}


func _is_available(ch: String, lexicon: Lexicon, unlocked: Array[StringName]) -> bool:
	var gate: StringName = lexicon.data.gated_letters.get(ch, &"")
	return gate == &"" or unlocked.has(gate)
