class_name Palette
extends RefCounted
## GERADO por tools/gen_palette.gd a partir de design-tokens.json. NÃO EDITAR À MÃO.
## Princípio VII: nenhuma cor fora desta lista.

const BLOOD := Color(0.4941, 0.0863, 0.1529, 1.0)  # #7E1627
const BLOOD_DARK := Color(0.3059, 0.0510, 0.0941, 1.0)  # #4E0D18
const CHALK := Color(0.9608, 0.9529, 0.9255, 1.0)  # #F5F3EC
const GOLD := Color(0.7216, 0.5804, 0.2118, 1.0)  # #B89436
const GOLD_LIGHT := Color(0.8627, 0.7529, 0.4157, 1.0)  # #DCC06A
const INK := Color(0.0824, 0.0902, 0.1098, 1.0)  # #15171C
const INK_SOFT := Color(0.2431, 0.2667, 0.3137, 1.0)  # #3E4450
const PARCHMENT := Color(0.8941, 0.8667, 0.7961, 1.0)  # #E4DDCB
const PARCHMENT_OLD := Color(0.7412, 0.7020, 0.6039, 1.0)  # #BDB39A

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
