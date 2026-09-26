class_name PlayerState
extends State
## Base dos estados do jogador: dá acesso tipado ao Player.

var player: Player:
	get:
		return owner_node as Player
