class_name Palette
extends RefCounted
## GERADO por tools/gen_palette.gd a partir de design-tokens.json. NÃO EDITAR À MÃO.
## Princípio VII: nenhuma cor fora desta lista.

const BLOOD := Color(0.5569, 0.1098, 0.1098, 1.0)  # #8E1C1C
const BLOOD_DARK := Color(0.3569, 0.0627, 0.0706, 1.0)  # #5B1012
const CHALK := Color(0.9686, 0.9490, 0.9020, 1.0)  # #F7F2E6
const GOLD := Color(0.7882, 0.6039, 0.1804, 1.0)  # #C99A2E
const GOLD_LIGHT := Color(0.9137, 0.7843, 0.4000, 1.0)  # #E9C866
const INK := Color(0.1098, 0.0902, 0.0784, 1.0)  # #1C1714
const INK_SOFT := Color(0.2902, 0.2510, 0.2235, 1.0)  # #4A4039
const PARCHMENT := Color(0.9137, 0.8627, 0.7490, 1.0)  # #E9DCBF
const PARCHMENT_OLD := Color(0.7843, 0.6980, 0.5412, 1.0)  # #C8B28A

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
