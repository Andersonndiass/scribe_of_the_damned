extends SceneTree
## Gera sprites de placeholder nos tamanhos do ASSET-CATALOG, só com cores da paleta (T020).
## Saída: PNG (para o design-agent conferir) + .tres com ImageTexture embutida (carrega sem import).
## Uso: godot --headless --path . -s tools/gen_placeholders.gd
## Serão substituídos pelos sprites gerados a partir das fichas (D-024).

const OUT := "res://assets/placeholders/"

## Mapa de caracteres -> cor da paleta. "." = transparente.
var COLORS: Dictionary[String, Color] = {
	"K": Palette.INK, "k": Palette.INK_SOFT, "P": Palette.PARCHMENT, "O": Palette.PARCHMENT_OLD,
	"C": Palette.CHALK, "G": Palette.GOLD, "L": Palette.GOLD_LIGHT, "g": Palette.GOLD_LIGHT, "B": Palette.BLOOD,
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
## Gota dourada 6×8 (D-076): contorno INK, ouro em 2 tons, luz de cima à direita.
const GOLD_DROP: Array[String] = ["..K...", "..KK..", ".KGgK.", "KGGGgK", "KGGGgK", "KGGGGK", ".KGGK.", "..KK.."]

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
	ok = _world_sprites() and ok
	ok = _asmodeus() and ok
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


# --- Asmodeus, o Rasurador (006 T612): 64×64, pivot (32,32); ficha 16 + design-agent ---
## Quadros mínimos até o PNG real (D-063): idle 3, telegraph 1, hit 1, invuln 2, death 4, e os
## overlays crack (F2) e flame 2 (F3).
func _asmodeus() -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var anims: Dictionary = {
		&"idle": [_asm_body(0, false), _asm_body(1, false), _asm_body(2, false)],
		&"telegraph": [_asm_body(0, true)],
		&"hit": [_asm_recolor(_asm_body(0, false), COLORS["C"])],
		&"invuln": [_asm_dither(_asm_body(0, false), 0), _asm_dither(_asm_body(0, false), 1)],
		&"death": [_asm_bayer(_asm_body(0, false), 1), _asm_bayer(_asm_body(0, false), 2), _asm_bayer(_asm_body(0, false), 3), _asm_bayer(_asm_body(0, false), 4)],
		&"crack": [_asm_crack()],
		&"flame": [_asm_flame(0), _asm_flame(1)],
	}
	for anim: StringName in anims:
		frames.add_animation(anim)
		frames.set_animation_loop(anim, anim != &"death")
		for img: Image in anims[anim]:
			frames.add_frame(anim, ImageTexture.create_from_image(img))
	(anims[&"idle"][0] as Image).save_png(OUT + "bss_asmodeus_idle.png")
	return _save(frames, "bss_asmodeus_frames.tres")


func _asm_body(phase: int, raised: bool) -> Image:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var K: Color = COLORS["K"]
	var k: Color = COLORS["k"]
	var arm_top: int = 17 if raised else 20
	# Sombra 32×4 em dither.
	for y: int in range(58, 62):
		for x: int in range(16, 48):
			if (x + y) % 2 == 0:
				_px(img, x, y, k)
	# Redemoinho: base que afina até (32,58).
	for y: int in range(44, 59):
		var half: int = maxi(1, int((58 - y) * 0.7))
		_box(img, 32 - half, y, half * 2, 1, k)
		_px(img, 32 - half - 1, y, K)
		_px(img, 32 + half, y, K)
		if (y + phase) % 3 == 0:
			_px(img, 32 - half / 2, y, K)
	# Braços 4 px até Y50 com raspador 8×5 (PARCHMENT_OLD, fio CHALK).
	for side: int in [-1, 1]:
		var ax: int = 18 if side < 0 else 42
		_box(img, ax, arm_top, 4, 50 - arm_top, k)
		_box(img, ax - 1, arm_top, 1, 50 - arm_top, K)
		_box(img, ax + 4, arm_top, 1, 50 - arm_top, K)
		var sx: int = ax - 2 if side < 0 else ax - 2
		_box(img, sx, 50, 8, 5, COLORS["O"])
		_box(img, sx, 54, 8, 1, COLORS["C"])
	# Tronco X22–41 Y16–44 com rabiscos em 3 camadas.
	_box(img, 22, 16, 20, 29, k)
	for y: int in range(16, 45):
		for x: int in range(22, 42):
			if (x + y + phase) % 3 == 0 or (x - y + phase) % 5 == 0 or (y + phase) % 4 == 0 and x % 2 == 0:
				_px(img, x, y, K)
	_box(img, 21, 16, 1, 29, K)
	_box(img, 42, 16, 1, 29, K)
	_box(img, 21, 15, 22, 1, K)
	# Cabeça 10×10 sem rosto.
	_box(img, 27, 6, 10, 10, k)
	_box(img, 26, 6, 1, 10, K)
	_box(img, 37, 6, 1, 10, K)
	_box(img, 26, 5, 12, 1, K)
	# Coroa de 5 penas CHALK; a 2ª e a 4ª partidas.
	for f: int in 5:
		var fx: int = 27 + f * 2
		var top: int = 0 if f % 2 == 0 else 2
		_box(img, fx, top, 1, 5 - top, COLORS["C"])
	# Olho 12×10: esclera CHALK, íris BLOOD 6×6 (8×8 na telegrafia), pupila INK 2×4.
	for y: int in range(24, 34):
		for x: int in range(26, 38):
			var dx: float = (x - 31.5) / 6.0
			var dy: float = (y - 28.5) / 5.0
			if dx * dx + dy * dy <= 1.0:
				_px(img, x, y, COLORS["C"])
	var iris: int = 8 if raised else 6
	_box(img, 32 - iris / 2, 29 - iris / 2, iris, iris, COLORS["B"])
	_box(img, 31, 27, 2, 4, K)
	return img


func _asm_recolor(src: Image, c: Color) -> Image:
	var img: Image = src.duplicate()
	for y: int in 64:
		for x: int in 64:
			var p: Color = img.get_pixel(x, y)
			if p.a > 0.5 and (p.is_equal_approx(COLORS["k"])):
				img.set_pixel(x, y, c)
	return img


func _asm_dither(src: Image, parity: int) -> Image:
	var img: Image = src.duplicate()
	for y: int in 64:
		for x: int in 64:
			if img.get_pixel(x, y).a > 0.5 and (x + y + parity) % 2 == 0:
				img.set_pixel(x, y, COLORS["P"])
	return img


## Morte: Bayer 4×4 apagando `level` quartos do corpo (1..4).
func _asm_bayer(src: Image, level: int) -> Image:
	var bayer: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var img: Image = src.duplicate()
	for y: int in 64:
		for x: int in 64:
			if bayer[(y % 4) * 4 + (x % 4)] < level * 4:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return img


func _asm_crack() -> Image:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	_line(img, Vector2i(27, 24), Vector2i(30, 28), COLORS["K"])
	_line(img, Vector2i(36, 33), Vector2i(33, 29), COLORS["K"])
	return img


func _asm_flame(parity: int) -> Image:
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for f: int in 5:
		var fx: int = 27 + f * 2
		var top: int = 0 if f % 2 == 0 else 2
		var h: int = 2 + ((f + parity) % 3)
		_box(img, fx, maxi(0, top - h), 1, h, COLORS["B"])
	return img


# --- Loja (003 T310; D-076): ícones ITM_ 24×24 a partir dos mapas do design-agent ---
const ICON_MAPS := "res://tools/item_icon_maps.json"


func _shop_icons() -> bool:
	var ok: bool = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ICON_MAPS))
	if not parsed is Dictionary:
		push_error("gen_placeholders: não li %s" % ICON_MAPS)
		return false
	var icons: Dictionary = (parsed as Dictionary)["icons"]
	for id: String in icons:
		var img: Image = _image(icons[id])
		if img == null:
			return false
		img.save_png(OUT + "itm_%s.png" % id)
		ok = _save(ImageTexture.create_from_image(img), "itm_%s.tres" % id) and ok
	return ok


## Sprites do mundo das armas (017; mapas do design-agent em T1700-design-maps.json): só PNG,
## importado pelo Godot (sem textura embutida no .tres: pck menor).
func _world_sprites() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ICON_MAPS))
	if not parsed is Dictionary or not (parsed as Dictionary).has("world"):
		push_error("gen_placeholders: sem a seção world em %s" % ICON_MAPS)
		return false
	var world: Dictionary = (parsed as Dictionary)["world"]
	for id: String in world:
		var img: Image = _image(world[id])
		if img == null:
			return false
		img.save_png(OUT + "%s.png" % id)
		print("gen_placeholders: %s.png" % id)
	return true


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
