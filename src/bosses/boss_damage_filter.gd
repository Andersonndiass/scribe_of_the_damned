class_name BossDamageFilter
extends RefCounted
## Vida e fases do chefe com os tetos de dano (006 FR-604, FR-609b; D-062). Lógica pura:
##   - por conjuração (`cast_id`): a soma entra inteira até `cast_soft_cap`, pela metade até
##     `cast_hard_cap`, e nada acima (o automático e o PURGO não têm esse teto);
##   - por fase: o dano para no limiar; o chefe fica invulnerável por `phase_shift_invulnerable`;
##   - exposição: por `exposed_time`, as palavras (não o automático) ferem +`exposed_word_bonus`.

var data: BossDamageFilterData
var boss: BossData
var hp: int = 0
var phase_index: int = 0

## Por que o último golpe não entrou: &"immune", &"invulnerable", &"cap" ou &"" (entrou).
var last_block: StringName = &""

var _invulnerable_left: float = 0.0
var _exposed_left: float = 0.0
var _cast_raw: Dictionary[int, float] = {}
var _cast_given: Dictionary[int, int] = {}


func _init(p_data: BossDamageFilterData, p_boss: BossData) -> void:
	data = p_data
	boss = p_boss
	hp = boss.max_hp


## Aplica `amount` de `tag`/`cast_id`. Retorna quanto a vida caiu de fato.
func apply(amount: int, tag: StringName, cast_id: int) -> int:
	last_block = &""
	if amount <= 0 or is_dead():
		return 0
	var is_word: bool = is_word_tag(tag)
	if boss.words_only and not is_word:
		last_block = &"immune"
		return 0
	if _invulnerable_left > 0.0:
		last_block = &"invulnerable"
		return 0
	var d: int = amount
	if is_word and _exposed_left > 0.0:
		d = roundi(d * (1.0 + boss.exposed_word_bonus))
	if not data.uncapped_tags.has(tag):
		var raw: float = _cast_raw.get(cast_id, 0.0) + d
		_cast_raw[cast_id] = raw
		var target: int = int(floor(_effective(raw) + 0.0001))
		d = target - _cast_given.get(cast_id, 0)
		_cast_given[cast_id] = target
	var floor_hp: int = _next_threshold_hp()
	d = mini(d, hp - floor_hp)
	if d <= 0:
		last_block = &"cap"
		return 0
	hp -= d
	if hp == floor_hp and phase_index < boss.phases.size() - 1:
		phase_index += 1
		_invulnerable_left = boss.phase_shift_invulnerable
	return d


## Palavra ou combo (inclui PURGO); vazio e as `non_word_tags` não são.
func is_word_tag(tag: StringName) -> bool:
	return tag != &"" and not data.non_word_tags.has(tag)


func expose() -> void:
	_exposed_left = boss.exposed_time


func is_exposed() -> bool:
	return _exposed_left > 0.0


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func is_dead() -> bool:
	return hp <= 0


func fraction() -> float:
	return float(hp) / float(boss.max_hp)


func tick(delta: float) -> void:
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)
	_exposed_left = maxf(0.0, _exposed_left - delta)


func _effective(raw: float) -> float:
	var soft: float = minf(raw, data.cast_soft_cap)
	var over: float = clampf(raw, data.cast_soft_cap, data.cast_hard_cap) - data.cast_soft_cap
	return soft + over * data.over_soft_mul


## A vida em que a fase atual acaba (0 na última).
func _next_threshold_hp() -> int:
	if phase_index + 1 >= boss.phases.size():
		return 0
	return ceili(boss.max_hp * boss.phases[phase_index + 1].threshold)
