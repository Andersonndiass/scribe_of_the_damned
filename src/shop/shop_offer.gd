class_name ShopOffer
extends RefCounted
## Oferta da loja (003 FR-303..FR-308; D-058). Lógica pura: não conhece nós nem a tinta do jogo.
##   Cada visita: `item_slots` itens + 1 vaga de apócrifo não liberado (sem nenhum, vira item).
##   Preço cresce por onda; a carta travada volta na visita seguinte pelo preço antigo.
##   Reroll troca o que não está vendido nem travado; custo sobe dentro da visita.
##   017 (T1733): armas e o ímã reverso que já se tem não aparecem (`owned`); com `weapons_first`
##   (1ª loja com o espaço 2 vazio; rules-agent §7), as vagas de item são armas.

var deck: Array[ShopItemData] = []
var tuning: ShopTuning
var wave: int = 1
var cards: Array[ShopItemData] = []
var prices := PackedInt32Array()

var _sold := PackedByteArray()
var _locked_slot: int = -1
## A travada atravessa visitas: a carta e o preço da visita em que foi travada.
var _locked_item: ShopItemData = null
var _locked_price: int = 0
var _rerolls: int = 0
## ids de armas e passivos que o jogador já tem (não aparecem na oferta).
var _owned: Array[StringName] = []
## D-103 resposta 3a: com espaço de arma vazio, a 1ª vaga de item é arma.
var _guarantee_weapon: bool = false
var _weapons_first: bool = false


func _init(p_deck: Array[ShopItemData], p_tuning: ShopTuning) -> void:
	deck = p_deck
	tuning = p_tuning


func price_of(item: ShopItemData, p_wave: int) -> int:
	return roundi(item.base_price * (1.0 + tuning.price_growth * float(p_wave - 1)))


## Abre a loja depois da onda `p_wave`. A travada (se houver) volta pelo preço antigo.
func open_visit(p_wave: int, stats: RunStats, unlocked: Array[StringName], rng: RandomNumberGenerator,
		owned: Array[StringName] = [], weapons_first: bool = false, guarantee_weapon: bool = false) -> void:
	wave = p_wave
	_owned = owned
	_weapons_first = weapons_first
	_guarantee_weapon = guarantee_weapon
	_rerolls = 0
	var slots: int = tuning.item_slots + (1 if tuning.apocrypha_slot else 0)
	cards.clear()
	cards.resize(slots)
	prices.resize(slots)
	_sold.resize(slots)
	_sold.fill(0)
	_locked_slot = -1
	if _locked_item != null:
		var at: int = slots - 1 if (_locked_item.kind == &"apocrypha" and tuning.apocrypha_slot) else 0
		cards[at] = _locked_item
		prices[at] = _locked_price
		_locked_slot = at
	_fill(stats, unlocked, rng)


func reroll_cost() -> int:
	return tuning.reroll_base + tuning.reroll_step * _rerolls


## Troca as cartas não vendidas e não travadas. Retorna o custo pago, ou -1 sem tinta.
func reroll(gold: int, stats: RunStats, unlocked: Array[StringName], rng: RandomNumberGenerator) -> int:
	var cost: int = reroll_cost()
	if gold < cost:
		return -1
	for i: int in cards.size():
		if _sold[i] == 0 and i != _locked_slot:
			cards[i] = null
	_rerolls += 1
	_fill(stats, unlocked, rng)
	return cost


## Compra a carta `i`. Retorna o preço pago, ou -1 (vendida, vazia ou sem tinta).
func buy(i: int, gold: int) -> int:
	if i < 0 or i >= cards.size() or cards[i] == null or _sold[i] == 1 or gold < prices[i]:
		return -1
	_sold[i] = 1
	if i == _locked_slot:
		_clear_lock()
	return prices[i]


## Depois de uma compra ou venda: o que o jogador tem (o reroll não oferece o que ele já tem e
## volta a oferecer o que vendeu).
func set_owned(ids: Array[StringName]) -> void:
	_owned = ids


## Trava/destrava a carta `i` (só 1 travada). Retorna true se ficou travada.
func toggle_lock(i: int) -> bool:
	if i < 0 or i >= cards.size() or cards[i] == null or _sold[i] == 1:
		return false
	if i == _locked_slot:
		_clear_lock()
		return false
	_locked_slot = i
	_locked_item = cards[i]
	_locked_price = prices[i]
	return true


func locked_slot() -> int:
	return _locked_slot


func is_sold(i: int) -> bool:
	return _sold[i] == 1


func _clear_lock() -> void:
	_locked_slot = -1
	_locked_item = null
	_locked_price = 0


## Preenche as vagas vazias sem repetir carta na oferta.
func _fill(stats: RunStats, unlocked: Array[StringName], rng: RandomNumberGenerator) -> void:
	var used: Array[StringName] = []
	for c: ShopItemData in cards:
		if c != null:
			used.append(c.id)
	var apo_pool: Array[ShopItemData] = []
	var item_pool: Array[ShopItemData] = []
	var weapon_pool: Array[ShopItemData] = []
	for c: ShopItemData in deck:
		if used.has(c.id):
			continue
		if c.kind == &"apocrypha":
			if c.word != null and not unlocked.has(c.word.id):
				apo_pool.append(c)
		elif c.kind == &"weapon":
			if c.weapon != null and not _owned.has(c.weapon.id):
				item_pool.append(c)
				weapon_pool.append(c)
		elif c.kind == &"relic":
			if c.relic != null and not _owned.has(c.relic.id):
				item_pool.append(c)
		elif stats.can_offer(c):
			item_pool.append(c)
	for i: int in cards.size():
		if cards[i] != null:
			continue
		var is_apo_slot: bool = tuning.apocrypha_slot and i == cards.size() - 1
		var pool: Array[ShopItemData] = apo_pool if (is_apo_slot and not apo_pool.is_empty()) else item_pool
		if not is_apo_slot and (_weapons_first or (_guarantee_weapon and i == 0)) and not weapon_pool.is_empty():
			pool = weapon_pool
		if pool.is_empty():
			continue
		var pick: ShopItemData = pool[rng.randi_range(0, pool.size() - 1)]
		pool.erase(pick)
		item_pool.erase(pick)
		weapon_pool.erase(pick)
		cards[i] = pick
		prices[i] = price_of(pick, wave)
