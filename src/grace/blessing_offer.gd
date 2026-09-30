class_name BlessingOffer
extends RefCounted
## Sorteio dos selos (016 FR-1608): até `count` bênçãos distintas, só as que ainda não chegaram no
## teto, por peso; sem nenhuma, a reserva. Usa o RNG que receber (o da Graça), nunca o das letras.


static func draw(blessings: Array[BlessingData], stats: RunStats, rng: RandomNumberGenerator,
		count: int, fallback: BlessingData) -> Array[BlessingData]:
	var pool: Array[BlessingData] = []
	for b: BlessingData in blessings:
		if b.stat == &"" or not stats.is_capped(b):
			pool.append(b)
	var out: Array[BlessingData] = []
	while out.size() < count and not pool.is_empty():
		var total: float = 0.0
		for b: BlessingData in pool:
			total += b.weight
		var roll: float = rng.randf() * total
		var pick: int = pool.size() - 1
		for i: int in pool.size():
			roll -= pool[i].weight
			if roll < 0.0:
				pick = i
				break
		out.append(pool[pick])
		pool.remove_at(pick)
	if out.is_empty() and fallback != null:
		out.append(fallback)
	return out
