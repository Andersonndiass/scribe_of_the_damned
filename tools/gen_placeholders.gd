extends SceneTree
## Gera sprites de placeholder nos tamanhos do ASSET-CATALOG, só com cores da paleta (T020).
## Saída: PNG (para o design-agent conferir) + .tres com ImageTexture embutida (carrega sem import).
## Uso: godot --headless --path . -s tools/gen_placeholders.gd
## Serão substituídos pelos sprites gerados a partir das fichas (D-024).

const OUT := "res://assets/placeholders/"

## Mapa de caracteres -> cor da paleta. "." = transparente.
var COLORS: Dictionary[String, Color] = {
	"K": Palette.INK, "k": Palette.INK_SOFT, "P": Palette.PARCHMENT, "O": Palette.PARCHMENT_OLD,
	"C": Palette.CHALK, "G": Palette.GOLD, "L": Palette.GOLD_LIGHT, "B": Palette.BLOOD,
}

# --- Irmão Anselmo 16×16, pivot (8,15) ---
const ANSELMO_BASE: Array[String] = [
	"................",
	"......KKKK......",
	".....KCPPPK.....",
	"....KPPPPPPK....",
	"....KPKPPKPK....",
	"....KPPPPPPK....",
	".....KPPPPK.....",
	"....KkkKKkkK..C.",
	"...KkkkkkkkkKCK.",
	"...KkkkOkkkkK...",
	"...KkkkOkkkkK...",
	"...KkkkkkkkkK...",
	"...KkkkkkkkkK...",
	"....KkkkkkkK....",
	"....KKK..KKK....",
	"................",
]
const LEGS_A := "....KKK..KKK...."
const LEGS_B := "...KKK....KK...."
const LEGS_C := "....KK....KKK..."

# --- Diabrete 12×12, pivot (6,11) ---
const IMP_A: Array[String] = [
	"............",
	"..K......K..",
	"..KK....KK..",
	"...KKKKKK...",
	"..KKKKKKKK..",
	".KKCKKKKCKK.",
	".KKCCKKCCKK.",
	".KKKKKKKKKK.",
	".KKKCKCKKKK.",
	"..KKKKKKKK.K",
	"..Kk....kK..",
	"............",
]
const IMP_FEET_B := "...kK..Kk..."


# --- Letras 10×10, pivot (5,5), ficha 21: losango de cantos cortados + glifo 5×6 em X3–7, Y2–7 ---
const LETTER_ORDER := "ACDEFGILMNOPQRSTUVXB"
const DIAMOND: Array[String] = [
	"...KKKK...",
	"..KPPPPK..",
	".KPPPPPOK.",
	"KPPPPPPPPK",
	"KPPPPPPPPK",
	"KPPPPPPPPK",
	"KkPPPPPPPK",
	".KkPPPPPK.",
	"..KkPPPK..",
	"...KKKK...",
]
const GLYPHS: Dictionary[String, Array] = {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#"],
	"C": [".####", "#....", "#....", "#....", "#....", ".####"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "####.", "#....", "#....", "#...."],
	"G": [".####", "#....", "#....", "#..##", "#...#", ".####"],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "#####"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"X": ["#...#", ".#.#.", "..#..", "..#..", ".#.#.", "#...#"],
	"B": ["####.", "#...#", "####.", "#...#", "#...#", "####."],
}


# --- Fonte pixel 5×6 (ficha 26): as letras dos losangos + estes glifos extras ---
## Tem de ser igual a PixelFont.CHARS (test_pixel_font confere).
const FONT_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZÆ0123456789:!?-./, +%[];<>"
const FONT_EXTRA: Dictionary[String, Array] = {
	"H": ["#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"J": ["....#", "....#", "....#", "....#", "#...#", ".###."],
	"K": ["#...#", "#..#.", "###..", "#..#.", "#...#", "#...#"],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "##.##", "#...#"],
	"Y": ["#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "...#.", "..#..", ".#...", "#....", "#####"],
	"Æ": [".####", "#.#..", "####.", "#.#..", "#.#..", "#.###"],
	"0": [".###.", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "..##.", "....#", "....#", "####."],
	"4": ["#..#.", "#..#.", "#####", "...#.", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "####."],
	"6": [".###.", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", "..#..", "..#.."],
	"8": [".###.", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", ".###."],
	":": [".....", "..#..", ".....", ".....", "..#..", "....."],
	"!": ["..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
	"?": [".###.", "#...#", "...#.", "..#..", ".....", "..#.."],
	"-": [".....", ".....", ".###.", ".....", ".....", "....."],
	".": [".....", ".....", ".....", ".....", ".....", "..#.."],
	"/": ["....#", "...#.", "..#..", ".#...", "#....", "....."],
	",": [".....", ".....", ".....", ".....", "..#..", ".#..."],
	" ": [".....", ".....", ".....", ".....", ".....", "....."],
	# Loja (003, design-agent): preços, teclas e percentuais.
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#.."],
	"%": ["##..#", "##.#.", "..#..", ".#...", "#..##", "...##"],
	"[": [".###.", ".#...", ".#...", ".#...", ".#...", ".###."],
	"]": [".###.", "...#.", "...#.", "...#.", "...#.", ".###."],
	";": [".....", "..#..", ".....", ".....", "..#..", ".#..."],
	"<": ["...#.", "..##.", ".###.", "..##.", "...#.", "....."],
	">": [".#...", ".##..", ".###.", ".##..", ".#...", "....."],
}


# --- Inimigos do Cap. 1 (005 T517): tamanhos do ASSET-CATALOG §3 ---
const MOTH_A: Array[String] = [
	"..K..........K..",
	"...K........K...",
	"....K.KKKK.K....",
	".OOO.KkkkkK.OOO.",
	"OOOOOKkCkCKOOOOO",
	"OOOOOKkkkkKOOOOO",
	".kOOOKkkkkKOOOk.",
	"..kkkKkkkkKkkk..",
	"...kk.KkkK.kk...",
	"......KkkK......",
	".......KK.......",
	"................",
]
const MOTH_B_ROWS: Dictionary[int, String] = {3: "..OO.KkkkkK.OO..", 4: ".OOOOKkCkCKOOOO.", 5: ".OOOOKkkkkKOOOO.", 6: "..kOOKkkkkKOOk.."}
const GARGOYLE_A: Array[String] = [
	"................",
	"...K......K.....",
	"..KkK....KkK....",
	"..KkkKKKKkkK....",
	".KkkkkkkkkkkK...",
	".KkCkkkkkkkkkKK.",
	".KkkkkkkkkkkkkkK",
	".KkkkkkkkkkkkKK.",
	"..KkkKkkkkkK....",
	".KkkkKkkkkkkK...",
	".KkkkkKkkkkkK...",
	".KkKkkkkkkKkK...",
	"..KkkkkkkkkK....",
	"..KkK...KkK.....",
	"..KKK...KKK.....",
	"................",
]
const GARGOYLE_B_ROWS: Dictionary[int, String] = {13: "...KkK..KkK.....", 14: "...KKK..KKK....."}
const MONK_A: Array[String] = [
	".......K........",
	"......KkK.......",
	".....KkkkK......",
	"....KkkkkkK.....",
	"...KkKKKKkkK....",
	"...KkKBKBKkK....",
	"...KkKKKKKkK....",
	"..KkkkKKKkkkK...",
	"..KkkkkkkkkkK...",
	".KkkkkkkkkkkkK..",
	".KkkPPPPkkkkkK..",
	".KkkPKKPkkkkkK..",
	".KkkPPPPkkkkkK..",
	".KkkkkkkkkkkkK..",
	".KkkkkkkkkkkkK..",
	"KkkkkkkkkkkkkkK.",
	"KkkkkkkkkkkkkkK.",
	"KkkkkkkkkkkkkkK.",
	"KkkkkkkkkkkkkkK.",
	"KkkkkkkkkkkkkkK.",
	".KkkkkkkkkkkkK..",
	".KkKkkKkkKkkKK..",
	"..K.K..K..K.K...",
	"................",
]
const MONK_B_ROWS: Dictionary[int, String] = {21: ".KKkkKkkKkkKkK..", 22: ".K.K..K..K.K...."}
const BLOT_A: Array[String] = [
	"...K..........",
	"..KCK....K....",
	"...K....KCK...",
	"...K.....K....",
	"..KKKK...K....",
	".KKKKKKKKKK...",
	"KKCKKKKKKKKK..",
	"KKKKKKKKKKKKK.",
	".KKKKKKKKKKKKK",
	"..KK.KKKKK.K..",
]
const BLOT_B_ROWS: Dictionary[int, String] = {4: ".KKKKK..K.....", 9: ".KKK.KKKK.KK.."}
const GOLD_DROP: Array[String] = ["..G...", "..G...", ".GGG..", ".GLGG.", "GGLGGG", "GGGGGG", ".GGGG.", "..GG.."]

# --- Gota de tinta do jogador 4×4 (sem BLOOD: art bible §2.2) ---
const INK_DROP: Array[String] = [
	".KK.",
	"KkCK",
	"KkkK",
	".KK.",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var ok: bool = true
	ok = _anselmo() and ok
	ok = _imp() and ok
	ok = _ink_drop() and ok
	ok = _letters() and ok
	ok = _font() and ok
	ok = _enemies_ch1() and ok
	ok = _shop_icons() and ok
	quit(0 if ok else 1)


func _anselmo() -> bool:
	var idle0: Array[String] = ANSELMO_BASE.duplicate()
	var idle1: Array[String] = _bob(ANSELMO_BASE)
	var run: Array = []
	for legs: String in [LEGS_A, LEGS_B, LEGS_A, LEGS_C]:
		var f: Array[String] = ANSELMO_BASE.duplicate()
		f[14] = legs
		run.append(f)
	run[1] = _bob(run[1])
	run[3] = _bob(run[3])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	if not _add_anim(frames, &"idle", [idle0, idle1], 4.0, true, "chr_anselmo_idle"):
		return false
	if not _add_anim(frames, &"run", run, 12.0, true, "chr_anselmo_run"):
		return false
	return _save(frames, "chr_anselmo_frames.tres")


func _imp() -> bool:
	var b: Array[String] = IMP_A.duplicate()
	b[10] = IMP_FEET_B
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	if not _add_anim(frames, &"move", [IMP_A.duplicate(), b], 8.0, true, "enm_diabrete_move"):
		return false
	return _save(frames, "enm_diabrete_frames.tres")


func _ink_drop() -> bool:
	var img: Image = _image(INK_DROP)
	if img == null:
		return false
	img.save_png(OUT + "prj_ink_drop.png")
	return _save(ImageTexture.create_from_image(img), "prj_ink_drop.tres")


## Atlas das letras: linha 0 = comum (contorno INK), linha 1 = vogal rara (contorno GOLD).
func _letters() -> bool:
	var atlas := Image.create_empty(10 * LETTER_ORDER.length(), 20, false, Image.FORMAT_RGBA8)
	for i: int in LETTER_ORDER.length():
		for rare: int in 2:
			var rows: Array[String] = DIAMOND.duplicate()
			var glyph: Array = GLYPHS[LETTER_ORDER[i]]
			for gy: int in 6:
				var row: String = rows[2 + gy]
				for gx: int in 5:
					if (glyph[gy] as String)[gx] == "#":
						row = row.substr(0, 3 + gx) + "K" + row.substr(4 + gx)
				rows[2 + gy] = row
			if rare == 1:
				for y: int in rows.size():
					var r: String = rows[y]
					var first: int = r.find("K")
					var last: int = r.rfind("K")
					if y == 0 or y == rows.size() - 1:
						r = r.replace("K", "G")
					else:
						r = r.substr(0, first) + "G" + r.substr(first + 1, last - first - 1) + "G" + r.substr(last + 1)
					rows[y] = r
			var img: Image = _image(rows)
			if img == null:
				return false
			atlas.blit_rect(img, Rect2i(0, 0, 10, 10), Vector2i(i * 10, rare * 10))
	atlas.save_png(OUT + "ltr_atlas.png")
	return _save(ImageTexture.create_from_image(atlas), "ltr_atlas.tres")


## Atlas da fonte: glifos brancos (máscara) em células de 6px, na ordem de PixelFont.CHARS.
func _font() -> bool:
	var chars: String = FONT_CHARS
	var atlas := Image.create_empty(6 * chars.length(), 6, false, Image.FORMAT_RGBA8)
	for i: int in chars.length():
		var ch: String = chars[i]
		var glyph: Array = GLYPHS[ch] if GLYPHS.has(ch) else FONT_EXTRA.get(ch, [])
		if glyph.is_empty():
			push_error("gen_placeholders: sem glifo para '%s'" % ch)
			return false
		for y: int in 6:
			for x: int in 5:
				if (glyph[y] as String)[x] == "#":
					atlas.set_pixel(i * 6 + x, y, Color.WHITE)
	atlas.save_png(OUT + "ui_font_atlas.png")
	return _save(ImageTexture.create_from_image(atlas), "ui_font_atlas.tres")


## Os 4 inimigos novos do Cap. 1 (2 quadros de "move") e a gota de tinta dourada.
func _enemies_ch1() -> bool:
	var specs: Array = [
		["enm_traca", MOTH_A, MOTH_B_ROWS, 10.0],
		["enm_gargula", GARGOYLE_A, GARGOYLE_B_ROWS, 6.0],
		["enm_monge_oco", MONK_A, MONK_B_ROWS, 5.0],
		["enm_borrao", BLOT_A, BLOT_B_ROWS, 6.0],
	]
	for s: Array in specs:
		var a: Array[String] = (s[1] as Array[String]).duplicate()
		var b: Array[String] = a.duplicate()
		var alt: Dictionary = s[2]
		for k: int in alt:
			b[k] = alt[k]
		var frames := SpriteFrames.new()
		frames.remove_animation(&"default")
		if not _add_anim(frames, &"move", [a, b], s[3], true, "%s_move" % s[0]):
			return false
		if not _save(frames, "%s_frames.tres" % s[0]):
			return false
	var img: Image = _image(GOLD_DROP)
	if img == null:
		return false
	img.save_png(OUT + "itm_gota_dourada.png")
	return _save(ImageTexture.create_from_image(img), "itm_gota_dourada.tres")


# --- Loja (003 T310): ícones ITM_ 24×24 (ficha 31; formas e destaques do design-agent) ---
## Moldura circular INK_SOFT r=11, área útil 20×20, sem fundo sólido, 1 cor de destaque.
func _shop_icons() -> bool:
	var ok: bool = true
	var icons: Dictionary[String, Callable] = {
		"lodestone": _ico_lodestone, "rosary": _ico_rosary, "sandals": _ico_sandals,
		"alms_purse": _ico_purse, "copyist_lenses": _ico_lenses, "double_inkwell": _ico_inkwell,
		"fine_quill": _ico_quill, "blessed_candle": _ico_candle, "new_shelf": _ico_shelf,
		"apocrypha_fides": _ico_scroll.bind("F", &"shield"), "apocrypha_lumen": _ico_scroll.bind("L", &"eye"),
		"apocrypha_purgo": _ico_scroll.bind("P", &"flame"), "apocrypha_gloria": _ico_scroll.bind("G", &"halo"),
		"apocrypha_verbum": _ico_scroll.bind("V", &"echo"),
	}
	for id: String in icons:
		var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
		_ring(img, Vector2i(12, 12), 11, COLORS["k"])
		icons[id].call(img)
		img.save_png(OUT + "itm_%s.png" % id)
		ok = _save(ImageTexture.create_from_image(img), "itm_%s.tres" % id) and ok
	return ok


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


func _box(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy: int in h:
		for xx: int in w:
			_px(img, x + xx, y + yy, c)


func _line(img: Image, a: Vector2i, b: Vector2i, c: Color) -> void:
	var n: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i: int in n + 1:
		var t: float = float(i) / maxf(1.0, float(n))
		_px(img, roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)), c)


func _ring(img: Image, c: Vector2i, r: int, col: Color) -> void:
	for a: int in 96:
		var ang: float = TAU * a / 96.0
		_px(img, roundi(c.x + cos(ang) * r), roundi(c.y + sin(ang) * r), col)


func _disc(img: Image, c: Vector2i, r: int, col: Color) -> void:
	for y: int in range(-r, r + 1):
		for x: int in range(-r, r + 1):
			if x * x + y * y <= r * r:
				_px(img, c.x + x, c.y + y, col)


func _ico_lodestone(img: Image) -> void:
	_disc(img, Vector2i(10, 13), 5, COLORS["K"])
	_line(img, Vector2i(7, 11), Vector2i(12, 16), COLORS["k"])
	_line(img, Vector2i(10, 9), Vector2i(13, 12), COLORS["k"])
	for p: Vector2i in [Vector2i(17, 7), Vector2i(18, 10), Vector2i(16, 5)]:
		_px(img, p.x, p.y, COLORS["C"])


func _ico_rosary(img: Image) -> void:
	for a: int in 10:
		var ang: float = TAU * a / 10.0
		_px(img, roundi(12 + cos(ang) * 5), roundi(9 + sin(ang) * 4), COLORS["k"])
	_box(img, 12, 13, 1, 7, COLORS["G"])
	_box(img, 10, 15, 5, 1, COLORS["G"])


func _ico_sandals(img: Image) -> void:
	_box(img, 9, 5, 7, 14, COLORS["O"])
	_box(img, 10, 4, 5, 1, COLORS["O"])
	_box(img, 9, 9, 7, 1, COLORS["K"])
	_box(img, 9, 14, 7, 1, COLORS["K"])
	for p: Vector2i in [Vector2i(5, 17), Vector2i(4, 19), Vector2i(6, 20)]:
		_px(img, p.x, p.y, COLORS["C"])


func _ico_purse(img: Image) -> void:
	_disc(img, Vector2i(11, 14), 5, COLORS["O"])
	_box(img, 9, 6, 5, 3, COLORS["O"])
	_box(img, 8, 9, 7, 1, COLORS["K"])
	_box(img, 17, 16, 2, 3, COLORS["G"])
	_px(img, 17, 15, COLORS["G"])


func _ico_lenses(img: Image) -> void:
	for c: Vector2i in [Vector2i(8, 12), Vector2i(16, 12)]:
		_disc(img, c, 3, COLORS["k"])
		_ring(img, c, 4, COLORS["K"])
	_box(img, 12, 11, 1, 1, COLORS["K"])
	_px(img, 7, 11, COLORS["C"])
	_px(img, 15, 11, COLORS["C"])


func _ico_inkwell(img: Image) -> void:
	_box(img, 5, 13, 6, 6, COLORS["K"])
	_box(img, 7, 11, 2, 2, COLORS["K"])
	_box(img, 13, 13, 6, 6, COLORS["K"])
	_box(img, 15, 11, 2, 2, COLORS["K"])
	for p: Vector2i in [Vector2i(11, 4), Vector2i(10, 5), Vector2i(12, 5), Vector2i(10, 6), Vector2i(11, 6), Vector2i(12, 6), Vector2i(10, 7), Vector2i(12, 7)]:
		_px(img, p.x, p.y, COLORS["C"])


func _ico_quill(img: Image) -> void:
	_line(img, Vector2i(7, 18), Vector2i(18, 5), COLORS["C"])
	_line(img, Vector2i(9, 18), Vector2i(18, 7), COLORS["C"])
	_line(img, Vector2i(11, 12), Vector2i(17, 5), COLORS["C"])
	_px(img, 6, 19, COLORS["G"])
	_px(img, 5, 20, COLORS["G"])


func _ico_candle(img: Image) -> void:
	_box(img, 10, 9, 4, 11, COLORS["O"])
	_box(img, 11, 12, 2, 5, COLORS["K"])
	_box(img, 10, 13, 4, 1, COLORS["K"])
	_box(img, 11, 5, 2, 3, COLORS["L"])
	_px(img, 11, 4, COLORS["L"])


func _ico_shelf(img: Image) -> void:
	_box(img, 5, 11, 14, 1, COLORS["k"])
	_box(img, 5, 19, 14, 1, COLORS["k"])
	_box(img, 7, 5, 2, 6, COLORS["K"])
	_box(img, 10, 6, 2, 5, COLORS["K"])
	_box(img, 7, 13, 2, 6, COLORS["K"])
	_box(img, 15, 13, 2, 6, COLORS["G"])


## Carta de apócrifo: rolo de pergaminho 16×20 com a inicial e um símbolo (design-agent).
func _ico_scroll(img: Image, initial: String, symbol: StringName) -> void:
	_box(img, 4, 3, 16, 18, COLORS["P"])
	_box(img, 4, 2, 16, 1, COLORS["K"])
	_box(img, 4, 21, 16, 1, COLORS["K"])
	var glyph: Array = GLYPHS[initial] if GLYPHS.has(initial) else FONT_EXTRA.get(initial, [])
	for y: int in 6:
		for x: int in 5:
			if (glyph[y] as String)[x] == "#":
				_px(img, 6 + x, 5 + y, COLORS["K"])
	match symbol:
		&"shield":
			_box(img, 13, 12, 5, 5, COLORS["G"])
			_box(img, 14, 17, 3, 1, COLORS["G"])
			_px(img, 15, 18, COLORS["G"])
		&"eye":
			_box(img, 12, 14, 7, 3, COLORS["k"])
			_box(img, 15, 14, 1, 3, COLORS["C"])
		&"flame":
			_box(img, 14, 14, 3, 4, COLORS["k"])
			_box(img, 15, 12, 1, 3, COLORS["C"])
		&"halo":
			_ring(img, Vector2i(15, 15), 3, COLORS["L"])
		&"echo":
			# "V" repetido em xadrez INK_SOFT, deslocado: o eco do VERBUM.
			var v: Array = GLYPHS["V"]
			for y: int in 6:
				for x: int in 5:
					if (v[y] as String)[x] == "#" and (x + y) % 2 == 0:
						_px(img, 12 + x, 12 + y, COLORS["k"])


## Desce tudo 1px (respiro / passo), mantendo a linha dos pés.
func _bob(rows: Array[String]) -> Array[String]:
	var w: int = rows[0].length()
	var out: Array[String] = [".".repeat(w)]
	for i: int in range(0, rows.size() - 3):
		out.append(rows[i])
	out.append(rows[rows.size() - 2])
	out.append(rows[rows.size() - 1])
	return out


func _add_anim(frames: SpriteFrames, anim: StringName, list: Array, fps: float, loop: bool, png_base: String) -> bool:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	var strip: Image
	for i: int in list.size():
		var img: Image = _image(list[i])
		if img == null:
			push_error("gen_placeholders: frame inválido em %s[%d]" % [anim, i])
			return false
		frames.add_frame(anim, ImageTexture.create_from_image(img))
		if strip == null:
			strip = Image.create_empty(img.get_width() * list.size(), img.get_height(), false, Image.FORMAT_RGBA8)
		strip.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(i * img.get_width(), 0))
	strip.save_png(OUT + png_base + ".png")
	return true


func _image(rows: Array) -> Image:
	var h: int = rows.size()
	var w: int = (rows[0] as String).length()
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y: int in h:
		var row: String = rows[y]
		if row.length() != w:
			push_error("gen_placeholders: linha %d tem %d colunas, esperado %d: '%s'" % [y, row.length(), w, row])
			return null
		for x: int in w:
			var ch: String = row[x]
			if ch == ".":
				continue
			if not COLORS.has(ch):
				push_error("gen_placeholders: caractere desconhecido '%s'" % ch)
				return null
			img.set_pixel(x, y, COLORS[ch])
	return img


func _save(res: Resource, file: String) -> bool:
	var err: int = ResourceSaver.save(res, OUT + file)
	if err != OK:
		push_error("gen_placeholders: falha ao salvar %s (%d)" % [file, err])
		return false
	print("gen_placeholders: %s" % file)
	return true
