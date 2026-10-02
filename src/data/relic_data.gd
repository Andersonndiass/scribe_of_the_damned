class_name RelicData
extends Resource
## Uma relíquia (D-103; mechanics-agent 019): passivo comprado na loja que dispara sozinho. Base +
## atributos que os selos sobem (como as armas, D-099). Nível = 1 + compras.

const PAIRS: Dictionary = {&"pulse": [&"repulse", &"stun"], &"aura": [&"slow"], &"on_hit": [&"burst"], &"shield": [&"absorb"]}

@export var id: StringName = &""
@export var display_name: String = ""
## Nome curto do subtítulo do selo (≤ 14 caracteres; D-103 resposta 4a).
@export var short_name: String = ""
@export var short_desc: String = ""
## Ícone do HUD (célula 20×20) e da loja/selo.
@export var icon: Texture2D
@export var shop_icon: Texture2D
## &"pulse" | &"aura" | &"on_hit" | &"shield".
@export var trigger: StringName = &"pulse"
## &"repulse" | &"stun" | &"slow" | &"burst" | &"absorb".
@export var effect: StringName = &"repulse"
## Pulso sem ninguém no raio: espera pronto.
@export var hold_when_empty: bool = true
## Campeão leva esta fração do controle (empurrão, atordoamento). O chefe é imune ao controle.
@export var champion_mul: float = 0.5
@export var base: RelicLevelData
@export var upgrades: Array[WeaponUpgradeData] = []
@export var max_upgrades: int = 4


func max_level() -> int:
	return 1 + max_upgrades


func upgrade(uid: StringName) -> WeaponUpgradeData:
	for u: WeaponUpgradeData in upgrades:
		if u.id == uid:
			return u
	return null


func compose(ranks: Dictionary) -> RelicLevelData:
	return WeaponUpgradeData.compose_into(base, upgrades, ranks)


## "" se válida; senão, o motivo. Com `limits`, confere o pior caso (tudo no teto).
func validate(limits: RelicTuning = null) -> String:
	if id == &"" or base == null:
		return "relíquia sem id ou sem base"
	if not PAIRS.has(trigger) or not (PAIRS[trigger] as Array).has(effect):
		return "%s: gatilho/efeito inválido" % id
	var seen := {}
	var total: int = 0
	var ranks := {}
	for u: WeaponUpgradeData in upgrades:
		var why: String = u.validate(RelicLevelData.new())
		if why != "":
			return "%s: %s" % [id, why]
		for f: StringName in u.effects:
			if seen.has(f):
				return "%s: o campo %s está em 2 atributos" % [id, f]
			seen[f] = true
		total += u.max_rank()
		ranks[u.id] = u.max_rank()
	if not upgrades.is_empty() and (max_upgrades < 1 or max_upgrades > total):
		return "%s: max_upgrades fora de 1..%d" % [id, total]
	if base.interval <= 0.0:
		return "%s: intervalo inválido" % id
	if effect == &"slow" and base.slow_time <= base.interval:
		return "%s: a lentidão da aura piscaria (slow_time ≤ interval)" % id
	if limits != null:
		var top: RelicLevelData = compose(ranks)
		if effect == &"slow" and top.slow_factor < limits.min_slow_factor - 0.0001:
			return "%s: lentidão abaixo do piso" % id
		if effect == &"absorb" and top.charges > limits.max_charges:
			return "%s: cargas acima do teto" % id
		if effect == &"stun" and top.interval < top.stun * limits.min_stun_ratio - 0.0001:
			return "%s: recarga curta demais para o atordoamento (stun-lock)" % id
	return ""
