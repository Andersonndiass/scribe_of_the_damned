class_name WeaponData
extends Resource
## Uma arma sagrada (017 FR-1703; mechanics-agent e rules-agent T1700): como ataca e a tabela de
## números por nível (1..5). Arte só em tinta (INK/INK_SOFT/CHALK): o dourado é das palavras.

@export var id: StringName = &""
## Chaves de `tr()`.
@export var display_name: String = ""
@export var short_desc: String = ""
## ITM_ 24×24.
@export var icon: Texture2D
## &"auto" (mira sozinha) ou &"aimed" (mouse ou direção do movimento).
@export var mode: StringName = &"auto"
## &"burst" (rajada), &"beam" (raio contínuo), &"orbit", &"swing_trail", &"fan".
@export var pattern: StringName = &"burst"
## Índice do visual do projétil (0 = gota de tinta).
@export var projectile_kind: int = 0
## Saída relativa ao escriba (altura da pena).
@export var muzzle: Vector2 = Vector2(0, -8)
## O projétil vive até alcance × isto.
@export var travel_mul: float = 1.25
## Marca do dano no chefe: "auto" = sem teto por conjuração, não conta como palavra.
@export var boss_tag: StringName = &"auto"
## Dano × isto contra campeão e chefe (Bíblia 1,5; D-087). A fração fica guardada por alvo.
@export var precision_mul: float = 1.0
## Antecipação antes do disparo (Crucifixo 0,2 s; animation-agent). Trocar de arma no meio cancela
## sem gastar a recarga.
@export var windup: float = 0.0
## Congela por isto quem o projétil acerta (Crucifixo 50 ms; animation-agent).
@export var hit_freeze: float = 0.0
## Tremor da tela a cada disparo (px, s); 0 = nenhum.
@export var fire_shake_px: float = 0.0
@export var fire_shake_time: float = 0.0
## Direções possíveis da mira (Bíblia 32: o raio em pixel inteiro não treme); 0 = livre.
@export var aim_steps: int = 0
## Raio (Bíblia; D-098): com o mouse, o raio vai até o cursor, entre `beam_min_length` e o
## alcance do nível; sem mouse, usa o alcance inteiro. 0 = sempre o alcance.
@export var beam_min_length: float = 0.0
@export_group("Turíbulo (swing_trail)")
## Arco do balanço (°), alternando os lados (rules-agent T1700).
@export var swing_arc_deg: float = 150.0
## Duração de um balanço (animation-agent: 8 quadros de 50 ms).
@export var swing_time: float = 0.4
## Raio de acerto da cabeça do turíbulo (px).
@export var head_radius: float = 6.0
## Rastro de incenso: dano a cada `trail_tick` s; nuvem nova a cada `trail_every` s; teto de nuvens.
@export var trail_tick: float = 0.5
@export var trail_every: float = 0.1
@export var trail_cap: int = 25
@export_group("")
## D-098 (T1830): a arma tem uma base (o antigo nível 1) e atributos que os selos sobem, um
## posto por selo. Nível = 1 + compras, no máximo 1 + `max_upgrades`.
@export var base: WeaponLevelData
## Na ordem de prioridade da escolha automática (sonda, stress, `?wlevel`).
@export var upgrades: Array[WeaponUpgradeData] = []
@export var max_upgrades: int = 6


func max_level() -> int:
	return 1 + max_upgrades


func upgrade(uid: StringName) -> WeaponUpgradeData:
	for u: WeaponUpgradeData in upgrades:
		if u.id == uid:
			return u
	return null


## Os números com os postos `ranks` (id do atributo → posto). Aloca: só na troca de posto.
func compose(ranks: Dictionary) -> WeaponLevelData:
	var out: WeaponLevelData = base.duplicate()
	for u: WeaponUpgradeData in upgrades:
		var r: int = int(ranks.get(u.id, 0))
		if r <= 0:
			continue
		for f: StringName in u.effects:
			var v: float = u.effects[f][mini(r, u.max_rank()) - 1]
			out.set(f, roundi(v) if typeof(out.get(f)) == TYPE_INT else v)
	return out


## "" se a arma é válida; senão, o motivo. Com `limits`, confere também o pior caso (tudo no teto).
func validate(limits: ArsenalTuning = null) -> String:
	if id == &"" or base == null:
		return "arma sem id ou sem base"
	if not [&"auto", &"aimed"].has(mode):
		return "%s: modo inválido" % id
	if not [&"burst", &"beam", &"orbit", &"swing_trail", &"fan"].has(pattern):
		return "%s: padrão inválido" % id
	if base.damage < 1 or base.interval <= 0.0 or base.range <= 0.0 or base.count < 1:
		return "%s: base com número inválido" % id
	var seen := {}
	var total: int = 0
	var ranks := {}
	for u: WeaponUpgradeData in upgrades:
		var why: String = u.validate()
		if why != "":
			return "%s: %s" % [id, why]
		for f: StringName in u.effects:
			if seen.has(f):
				return "%s: o campo %s está em 2 atributos" % [id, f]
			seen[f] = true
		total += u.max_rank()
		ranks[u.id] = u.max_rank()
	if not upgrades.is_empty() and (max_upgrades < 1 or max_upgrades >= total):
		return "%s: max_upgrades fora de 1..%d" % [id, total - 1]
	if limits != null:
		var top: WeaponLevelData = compose(ranks)
		var min_iv: float = limits.min_beam_interval if pattern == &"beam" else limits.min_interval
		if top.count > limits.max_count or top.interval < min_iv - 0.0001 				or top.slow_factor < limits.min_slow_factor - 0.0001:
			return "%s: no teto passa dos limites (count/interval/slow)" % id
		if pattern == &"swing_trail" and top.trail_life / trail_every > float(trail_cap) + 0.0001:
			return "%s: rastro passa do teto de nuvens" % id
	return ""
