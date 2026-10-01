class_name PotionData
extends Resource
## Uma poção (018 FR-1803; rules-agent, design-agent T1801). Cargas compradas na loja; o nível sobe
## pelos selos e vale para a partida toda. Arte só em tinta (sem GOLD).

@export var id: StringName = &""
## &"heal" (Óleo), &"refuge" (Água Benta), &"fervor" (Vinho), &"illumination" (Tinta Iluminada).
@export var effect: StringName = &"heal"
## Chaves de `tr()`.
@export var display_name: String = ""
@export var short_desc: String = ""
## UI_POTION 16×16 (HUD) e ITM 24×24 (loja).
@export var icon: Texture2D
@export var shop_icon: Texture2D
@export var levels: Array[PotionLevelData] = []
@export var max_charges: int = 2
@export var base_price: int = 4


func max_level() -> int:
	return levels.size()


func stats(level: int) -> PotionLevelData:
	return levels[clampi(level, 1, levels.size()) - 1]


## "" se a poção faz sentido; senão, o motivo.
func validate() -> String:
	if id == &"" or levels.is_empty() or max_charges < 1 or base_price < 1:
		return "poção sem id, níveis, cargas ou preço"
	if not [&"heal", &"refuge", &"fervor", &"illumination"].has(effect):
		return "%s: efeito inválido" % id
	for l: PotionLevelData in levels:
		if l == null:
			return "%s: nível vazio" % id
		match effect:
			&"heal":
				if l.heal < 1:
					return "%s: o Óleo precisa acender vela" % id
			&"refuge":
				if l.duration <= 0.0 or l.radius <= 0.0:
					return "%s: círculo sem raio ou duração" % id
			&"fervor":
				if l.duration <= 0.0 or l.interval_mul <= 0.0 or l.interval_mul >= 1.0:
					return "%s: Vinho sem duração ou sem acelerar" % id
			&"illumination":
				if l.useful_options < 1 or l.useful_options > 3:
					return "%s: úteis fora de 1..3" % id
	return ""
