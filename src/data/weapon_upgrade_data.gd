class_name WeaponUpgradeData
extends Resource
## Um atributo que os selos sobem (D-098; rules-agent T1830 §2; mechanics-agent): cada posto troca
## os campos de `effects` pelo valor daquele posto (tabela explícita, sem somar: nada de erro de
## float acumulado). O teto é o tamanho das listas.

@export var id: StringName = &""
## Chave de tradução do rótulo (ex.: UPG_RATE → CADÊNCIA).
@export var label: String = ""
@export var icon: Texture2D
## Campo de WeaponLevelData → valor de cada posto (índice 0 = posto 1). Todas do mesmo tamanho.
@export var effects: Dictionary[StringName, PackedFloat64Array] = {}
## Campo mostrado no selo ("VALOR > PRÓXIMO") e a unidade: &"s", &"px", &"" ou &"slow" (o %).
@export var display_field: StringName = &""
@export var display_unit: StringName = &""


func max_rank() -> int:
	for f: StringName in effects:
		return effects[f].size()
	return 0


## O texto do selo: o valor de agora e o do próximo posto.
func describe(now: Resource, next: Resource) -> String:
	return "%s > %s" % [format_value(now.get(display_field)), format_value(next.get(display_field))]


func format_value(v: Variant) -> String:
	match display_unit:
		&"slow":
			return "%d%%" % roundi((1.0 - float(v)) * 100.0)
		&"s":
			return ("%.2f" % float(v)).replace(".", ",") + "S"
		&"px":
			return "%d" % roundi(float(v))
	return str(roundi(float(v))) if float(v) == roundf(float(v)) else ("%.2f" % float(v)).replace(".", ",")


## "" se válido; senão, o motivo (os campos existem em `probe` — por padrão os de arma — e as
## listas têm o mesmo tamanho ≥ 1).
func validate(probe: Resource = null) -> String:
	if id == &"" or effects.is_empty():
		return "atributo sem id ou sem efeito"
	var n: int = max_rank()
	if probe == null:
		probe = WeaponLevelData.new()
	for f: StringName in effects:
		if not f in probe:
			return "%s: campo %s não existe" % [id, f]
		if effects[f].size() != n or n < 1:
			return "%s: listas de tamanhos diferentes" % id
	if display_field != &"" and not effects.has(display_field):
		return "%s: display_field fora de effects" % id
	return ""


## `base` com os postos `ranks` de `ups` (valor do posto, não soma; int arredonda). Aloca.
static func compose_into(base: Resource, ups: Array[WeaponUpgradeData], ranks: Dictionary) -> Resource:
	var out: Resource = base.duplicate()
	for u: WeaponUpgradeData in ups:
		var r: int = int(ranks.get(u.id, 0))
		if r <= 0:
			continue
		for f: StringName in u.effects:
			var v: float = u.effects[f][mini(r, u.max_rank()) - 1]
			out.set(f, roundi(v) if typeof(out.get(f)) == TYPE_INT else v)
	return out
