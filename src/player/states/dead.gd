extends PlayerState
## Sem velas (FR-005): para tudo e avisa o jogo.


func enter(_msg: Dictionary = {}) -> void:
	player.velocity = Vector2.ZERO
	player.arsenal.enabled = false
	player.sprite.stop()
	EventBus.player_died.emit()


func physics_update(_delta: float) -> void:
	pass
