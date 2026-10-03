class_name EatPageAttack
extends BossAttack
## Eat_Page (012 FR-1212; T1200 §4; D-102): a Mãe morde uma borda da página. Telegrafia longa com a
## faixa marcada; uma palavra que acerta a Mãe nesse aviso (ou o atordoamento do DOMINUS) cancela
## a mordida. Sem cancelamento, a borda anda até o alvo durante o golpe e a área (PlayArea) fica
## menor de vez; a borda comida só empurra (sem dano). Cancelar no meio do golpe termina a mordida
## no alvo: a página nunca volta.
## Visual: faixa BLOOD tracejada piscando; no golpe, a faixa roída avança (EatenEdgeView desenha).

const BITE_SIDES_TIE := [&"left", &"right"]

var side: StringName = &""
var strip: Rect2
var target: Rect2
## Motivo do próximo `cancel()` (o Boss marca &"word"; o resto é &"stun").
var cancel_reason: StringName = &"stun"

var _from: Rect2
var _last_tie: int = 1


## Ainda há borda para comer?
func is_available_for(a: AttackData) -> bool:
	for s: StringName in a.bite_sides:
		if PlayArea.slack(s, a.bite_min_size) > 0.5:
			return true
	return false


func _depth(s: StringName) -> float:
	return attack.bite_depth_bottom if s == &"bottom" else attack.bite_depth_side


func _pick_side() -> StringName:
	var best: StringName = &""
	var best_slack: float = 0.5
	for s: StringName in attack.bite_sides:
		var sl: float = PlayArea.slack(s, attack.bite_min_size)
		if sl > best_slack + 0.01:
			best = s
			best_slack = sl
		elif absf(sl - best_slack) <= 0.01 and s in BITE_SIDES_TIE and best in BITE_SIDES_TIE:
			# Empate esquerda × direita: alterna.
			best = BITE_SIDES_TIE[1 - _last_tie]
	if best in BITE_SIDES_TIE:
		_last_tie = BITE_SIDES_TIE.find(best)
	return best


func _on_begin() -> void:
	cancel_reason = &"stun"
	side = _pick_side()
	if side == &"":
		return
	strip = PlayArea.strip(side, _depth(side), attack.bite_min_size)
	target = PlayArea.target(side, _depth(side), attack.bite_min_size)
	EventBus.page_bite_warned.emit(side, strip)


func _on_activate() -> void:
	if side == &"":
		return
	_from = PlayArea.rect
	EventBus.page_bite_started.emit(side, strip, target)


func _active_tick(_delta: float) -> void:
	if side == &"":
		return
	var t: float = clampf(_t / maxf(attack.active, 0.01), 0.0, 1.0)
	PlayArea.shrink_to(Rect2(_from.position.lerp(target.position, t), _from.size.lerp(target.size, t)))


func finish() -> void:
	if is_active() and side != &"":
		PlayArea.shrink_to(target)  # termina no alvo, mesmo cortado no meio
		EventBus.page_bite_finished.emit(PlayArea.rect)
	super()


func cancel() -> void:
	if is_telegraphing() and side != &"":
		EventBus.page_bite_cancelled.emit(side, cancel_reason)
		side = &""
	finish()


func _draw() -> void:
	if attack == null or side == &"" or not is_telegraphing() or not telegraph_on():
		return
	draw_rect(strip, Palette.BLOOD, false, 1.0)
	var step: float = 6.0
	var x: float = strip.position.x
	while x < strip.end.x:
		dashed_line(Vector2(x, strip.position.y), Vector2(x, strip.end.y), Palette.BLOOD)
		x += step * 2.0
