class_name CloseView
extends Node2D
## Monta um close na cena a partir das camadas (feedback do autor: sprites separados, juntados na
## cena): um Sprite2D por camada, empilhados na ordem de CutsceneCloses.layers(). Trocar a expressão
## troca só as texturas; a pilha de nós fica a mesma (nada é criado durante a cena).

const MAX_LAYERS := 9

var speaker: String = ""
var expr: String = ""
var _sprites: Array[Sprite2D] = []


func _init() -> void:
	for i: int in MAX_LAYERS:
		var s := Sprite2D.new()
		s.centered = false
		s.name = "Layer%d" % i
		add_child(s)
		_sprites.append(s)


## Mostra `who` com a expressão `e` (vazio esconde).
func show_close(who: String, e: String) -> void:
	visible = who != ""
	if who == speaker and e == expr:
		return
	speaker = who
	expr = e
	var textures: Array[Texture2D] = []
	if who != "":
		textures = CutsceneCloses.layers(who, e)
	for i: int in _sprites.size():
		var tex: Texture2D = textures[i] if i < textures.size() else null
		_sprites[i].texture = tex
		_sprites[i].visible = tex != null
		if tex != null and tex.get_width() != CutsceneCloses.SIZE:
			_sprites[i].scale = Vector2.ONE * float(CutsceneCloses.SIZE) / tex.get_width()
		else:
			_sprites[i].scale = Vector2.ONE


## Mostra uma pilha qualquer de camadas (bustos da seleção de personagem, por exemplo).
func show_layers(textures: Array[Texture2D]) -> void:
	speaker = ""
	expr = ""
	visible = not textures.is_empty()
	for i: int in _sprites.size():
		var tex: Texture2D = textures[i] if i < textures.size() else null
		_sprites[i].texture = tex
		_sprites[i].visible = tex != null
		_sprites[i].scale = Vector2.ONE


## Nomes das camadas visíveis, de baixo para cima (testes).
func layer_count() -> int:
	var n: int = 0
	for s: Sprite2D in _sprites:
		if s.visible:
			n += 1
	return n
