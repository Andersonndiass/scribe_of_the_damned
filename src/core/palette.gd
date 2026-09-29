class_name Palette
extends RefCounted
## GERADO por tools/gen_palette.gd a partir de design-tokens.json. NÃO EDITAR À MÃO.
## Princípio VII: nenhuma cor fora desta lista.

const BLOOD := Color(126 / 255.0, 22 / 255.0, 39 / 255.0, 1.0)  # #7E1627
const BLOOD_DARK := Color(78 / 255.0, 13 / 255.0, 24 / 255.0, 1.0)  # #4E0D18
const CHALK := Color(245 / 255.0, 243 / 255.0, 236 / 255.0, 1.0)  # #F5F3EC
const GOLD := Color(184 / 255.0, 148 / 255.0, 54 / 255.0, 1.0)  # #B89436
const GOLD_LIGHT := Color(220 / 255.0, 192 / 255.0, 106 / 255.0, 1.0)  # #DCC06A
const INK := Color(21 / 255.0, 23 / 255.0, 28 / 255.0, 1.0)  # #15171C
const INK_SOFT := Color(62 / 255.0, 68 / 255.0, 80 / 255.0, 1.0)  # #3E4450
const PARCHMENT := Color(228 / 255.0, 221 / 255.0, 203 / 255.0, 1.0)  # #E4DDCB
const PARCHMENT_OLD := Color(189 / 255.0, 179 / 255.0, 154 / 255.0, 1.0)  # #BDB39A

const ALL: Dictionary[StringName, Color] = {
	&"blood": BLOOD,
	&"blood_dark": BLOOD_DARK,
	&"chalk": CHALK,
	&"gold": GOLD,
	&"gold_light": GOLD_LIGHT,
	&"ink": INK,
	&"ink_soft": INK_SOFT,
	&"parchment": PARCHMENT,
	&"parchment_old": PARCHMENT_OLD,
}


## Retorna true se a cor (ignorando alpha) pertence à paleta travada.
static func is_locked_color(color: Color) -> bool:
	for locked: Color in ALL.values():
		if locked.is_equal_approx(Color(color.r, color.g, color.b, 1.0)):
			return true
	return false
