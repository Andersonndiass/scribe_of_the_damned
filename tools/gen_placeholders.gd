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
const FONT_CHARS := "ABCDEFGHIJKLMNOPQRSTUVWXYZÆ0123456789:!?-./, "
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
