extends BossAttack
## Rasura (006 FR-609, F2–F3; D-062): círculo de `radius` px travado no escriba no começo da
## telegrafia; se ele ainda estiver dentro no golpe, o chefe pede para apagar a última letra do
## atril (o LetterField aplica as proteções). Não fere vela.
## Visual (design-agent): círculo BLOOD tracejado que cresce em px inteiros nos 2/3 e pisca no
## terço final; no atril, a última letra ganha um traço BLOOD na diagonal (HudAtril).

var _center: Vector2


func _on_begin() -> void:
	_center = player_body()
	EventBus.erasure_warned.emit(true)


func _on_activate() -> void:
	EventBus.erasure_warned.emit(false)
	if player_body().distance_to(_center) <= attack.radius + boss.manager.player_hurt_radius:
		hit_player = true
		EventBus.atril_erase_requested.emit()


func cancel() -> void:
	EventBus.erasure_warned.emit(false)
	super.cancel()


func _draw() -> void:
	if not is_telegraphing():
		return
	var grow: float = clampf(_t / (attack.telegraph * 2.0 / 3.0), 0.25, 1.0)
	var r: float = roundf(attack.radius * grow)
	if _t < attack.telegraph * 2.0 / 3.0 or telegraph_on():
		var segs: int = 16
		for k: int in segs:
			if k % 2 == 0:
				draw_arc(_center, r, TAU * k / segs, TAU * (k + 1) / segs, 3, Palette.BLOOD, 1.0)
