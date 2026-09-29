class_name DamageSource
extends RefCounted
## Quem está ferindo agora (006, mechanics-agent): o milagre marca antes de cada golpe
## (Miracle.begin_hit), o projétil do ataque automático marca `&"auto"` e limpa depois. O chefe lê
## a marca ao receber dano, para o DamageFilter (teto por conjuração, regras por palavra).

static var tag: StringName = &""
static var cast_id: int = 0


static func mark(p_tag: StringName, p_cast_id: int) -> void:
	tag = p_tag
	cast_id = p_cast_id


static func clear() -> void:
	tag = &""
	cast_id = 0
