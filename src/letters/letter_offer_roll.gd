class_name LetterOfferRoll
extends RefCounted
## As 3 letras do menu (017 T1718; mechanics-agent e rules-agent T1700). Lógica pura.
##   - 1 opção continua a palavra do atril (`lexicon.next_letters`); com o atril vazio ou num beco,
##     é a primeira letra de uma palavra que cabe;
##   - as outras 2 vêm do peso base (sem bônus de alvo), diferentes entre si e da certa, cada uma
##     com `other_rare_chance` de ser rara (só vogais);
##   - `forced` (a Traça devolvendo a letra roubada) entra no lugar de uma das sorteadas;
##   - `rare_first` (campeão): a certa é uma vogal rara quando houver vogal entre as úteis;
##   - `useful_count` (Tinta Iluminada, 018): quantas das 3 continuam a palavra (as que faltarem saem
##     pelo sorteio normal).
## Cada item: {"letter": String, "rare": bool, "useful": bool}. A ordem na tela é embaralhada.

const VOWELS := "AEIOU"
const OPTIONS := 3


static func roll(atril: Atril, lexicon: Lexicon, drop: DropTuning, menu: LetterMenuTuning,
		rng: RandomNumberGenerator, unlocked: Array[StringName], forced: String = "",
		rare_first: bool = false, useful_count: int = 1) -> Array[Dictionary]:
	var useful: PackedStringArray = _available(lexicon.next_letters(atril.text(), atril.capacity), lexicon, unlocked)
	if useful.is_empty():
		useful = _available(lexicon.next_letters("", atril.capacity), lexicon, unlocked)
	var out: Array[Dictionary] = []
	var taken := PackedStringArray()
	if not useful.is_empty():
		var pool: PackedStringArray = useful
		if rare_first:
			var vowels := PackedStringArray()
			for ch: String in useful:
				if VOWELS.contains(ch):
					vowels.append(ch)
			if not vowels.is_empty():
				pool = vowels
		var sure: String = pool[rng.randi_range(0, pool.size() - 1)]
		var sure_rare: bool = VOWELS.contains(sure) and (rare_first or rng.randf() < drop.rare_chance)
		out.append({"letter": sure, "rare": sure_rare, "useful": true})
		taken.append(sure)
	# Iluminura: mais opções que continuam a palavra, sem repetir.
	var extra_pool: PackedStringArray = useful.duplicate()
	while out.size() < mini(useful_count, OPTIONS) and not extra_pool.is_empty():
		var ch: String = extra_pool[rng.randi_range(0, extra_pool.size() - 1)]
		extra_pool.remove_at(extra_pool.find(ch))
		if taken.has(ch):
			continue
		out.append({"letter": ch, "rare": VOWELS.contains(ch) and rng.randf() < drop.rare_chance, "useful": true})
		taken.append(ch)
	if forced != "" and not taken.has(forced):
		out.append({"letter": forced, "rare": false, "useful": useful.has(forced)})
		taken.append(forced)
	while out.size() < OPTIONS:
		var ch: String = _weighted(lexicon, drop, rng, unlocked, taken)
		if ch == "":
			break
		out.append({"letter": ch, "rare": VOWELS.contains(ch) and rng.randf() < menu.other_rare_chance, "useful": useful.has(ch)})
		taken.append(ch)
	# Embaralha (Fisher–Yates com o RNG das letras: a sonda repete com a mesma seed).
	for i: int in range(out.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Dictionary = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


static func _available(letters: PackedStringArray, lexicon: Lexicon, unlocked: Array[StringName]) -> PackedStringArray:
	var out := PackedStringArray()
	for ch: String in letters:
		var gate: StringName = lexicon.data.gated_letters.get(ch, &"")
		if gate == &"" or unlocked.has(gate):
			out.append(ch)
	return out


## Sorteio pelo peso base, sem as letras já tiradas nem as trancadas. "" se nada sobrar.
static func _weighted(lexicon: Lexicon, drop: DropTuning, rng: RandomNumberGenerator,
		unlocked: Array[StringName], taken: PackedStringArray) -> String:
	var letters: PackedStringArray = _available(lexicon.data.alphabet, lexicon, unlocked)
	var total: float = 0.0
	for ch: String in letters:
		if not taken.has(ch):
			total += drop.base_weights.get(ch, 1.0)
	if total <= 0.0:
		return ""
	var pick: float = rng.randf() * total
	for ch: String in letters:
		if taken.has(ch):
			continue
		pick -= drop.base_weights.get(ch, 1.0)
		if pick < 0.0:
			return ch
	for ch: String in letters:
		if not taken.has(ch):
			return ch
	return ""
