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
## Tabela explícita, um item por nível.
@export var levels: Array[WeaponLevelData] = []


func max_level() -> int:
	return levels.size()


func stats(level: int) -> WeaponLevelData:
	return levels[clampi(level, 1, levels.size()) - 1]


## "" se a arma é válida; senão, o motivo.
func validate() -> String:
	if id == &"" or levels.is_empty():
		return "arma sem id ou sem níveis"
	if not [&"auto", &"aimed"].has(mode):
		return "%s: modo inválido" % id
	if not [&"burst", &"beam", &"orbit", &"swing_trail", &"fan"].has(pattern):
		return "%s: padrão inválido" % id
	for l: WeaponLevelData in levels:
		if l == null or l.damage < 1 or l.interval <= 0.0 or l.range <= 0.0 or l.count < 1:
			return "%s: nível com número inválido" % id
	return ""
