extends CutsceneFx
## C1-04 — O canto de cima à direita da página se levanta (a origem do nó é o canto da tela, 640,0):
## o triângulo descoberto mostra o verso escuro; a aba dobrada é PARCHMENT_OLD com contorno INK e a
## sombra em bloco na dobra. `progress` = perna do triângulo até 56 px.

const LEG := 56.0


func _draw() -> void:
	var s: int = roundi(progress * LEG)
	if s <= 0:
		return
	# Verso descoberto (triângulo no canto).
	for y: int in s:
		rect(-(s - y), y, s - y, 1, Palette.INK)
	# Aba dobrada (o triângulo espelhado na diagonal).
	for y: int in s:
		var w: int = s - y
		rect(-s, y, w, 1, Palette.PARCHMENT_OLD)
		rect(-s + w - 1, y, 1, 1, Palette.INK)
	rect(-s, 0, 1, s, Palette.INK)
	rect(-s, 0, s, 1, Palette.INK)
	# Sombra da dobra.
	for y: int in s:
		rect(-(s - y) + 1, y, 2, 1, Palette.INK_SOFT)
