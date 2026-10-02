extends GutTest
## T800 Roteiro e builder das cutscenes (008 FR-801, FR-802, FR-802b, SC-801; R-04): o JSON vira uma
## `Animation` com cada `t` no quadro certo (±1 a 60 FPS), estático e avançando quadro a quadro; o
## load recusa roteiro inválido; `step` vira interpolação NEAREST.

const FPS := 60.0
const SPRITE := "res://assets/placeholders/chr_anselmo_idle.png"


## Roteiro mínimo válido; cada teste altera o que precisa.
func _script() -> Dictionary:
	return {
		"id": "test", "version": 1, "duration": 4.0, "play": "always",
		"actors": {
			"anselmo": {"layer": "actors", "kind": "sprite", "src": SPRITE, "init": {"position": [100, 200], "modulate:a": 0.0}},
		},
		"events": [
			{"t": 0.5, "type": "key", "target": "anselmo", "prop": "modulate:a", "value": 1.0, "ease": "out"},
			{"t": 1.017, "type": "key", "target": "anselmo", "prop": "position", "value": [140, 200], "ease": "in_out"},
			{"t": 1.0, "type": "line", "speaker": "anselmo", "expr": "scared", "key": "CS_C1_01_ANSELMO_1", "end": 2.5},
			{"t": 2.6, "type": "caption", "key": "CS_C1_01_CAPTION_1", "end": 3.5},
			{"t": 3.9, "type": "mark", "id": "boss_bar_shown"},
		],
	}


func _parse(d: Dictionary) -> CutsceneScript:
	return CutsceneScript.parse(d)


# --- validação --------------------------------------------------------------------------------

func test_valid_script_has_no_errors() -> void:
	var s: CutsceneScript = _parse(_script())
	assert_eq(s.errors, PackedStringArray(), "roteiro válido")
	assert_eq(s.id, &"test")
	assert_almost_eq(s.duration, 4.0, 0.0001)


func test_rejects_invalid_scripts() -> void:
	var cases: Dictionary = {
		"alvo inexistente": func(d: Dictionary) -> void: d["events"][0]["target"] = "ninguem",
		"propriedade fora da lista": func(d: Dictionary) -> void: d["events"][0]["prop"] = "rotation",
		"chave de tradução faltando": func(d: Dictionary) -> void: d["events"][2]["key"] = "CS_NAO_EXISTE",
		"t fora da duração": func(d: Dictionary) -> void: d["events"][4]["t"] = 9.0,
		"falante inexistente": func(d: Dictionary) -> void: d["events"][2]["speaker"] = "ninguem",
		"marca fora da lista": func(d: Dictionary) -> void: d["events"][4]["id"] = "qualquer",
		"falas sobrepostas": func(d: Dictionary) -> void:
			d["events"].append({"t": 2.0, "type": "line", "speaker": "abbot_ghost", "expr": "neutral", "key": "CS_C1_02_ABBOT_1", "end": 3.0}),
		"duas chaves no mesmo quadro": func(d: Dictionary) -> void:
			d["events"].append({"t": 0.505, "type": "key", "target": "anselmo", "prop": "modulate:a", "value": 0.5, "ease": "out"}),
		"step misturado": func(d: Dictionary) -> void:
			d["events"].append({"t": 2.0, "type": "key", "target": "anselmo", "prop": "modulate:a", "value": 0.2, "ease": "step"}),
		"recurso do ator inexistente": func(d: Dictionary) -> void: d["actors"]["anselmo"]["src"] = "res://nao/existe.png",
		"propriedade sem valor inicial": func(d: Dictionary) -> void: d["actors"]["anselmo"]["init"].erase("position"),
	}
	for name: String in cases:
		var d: Dictionary = _script().duplicate(true)
		(cases[name] as Callable).call(d)
		assert_gt(_parse(d).errors.size(), 0, "recusa: %s" % name)


# --- builder: estático ------------------------------------------------------------------------

func test_every_key_lands_on_its_frame() -> void:
	var s: CutsceneScript = _parse(_script())
	var build: CutsceneBuilder.Result = CutsceneBuilder.build(s)
	var anim: Animation = build.animation
	assert_almost_eq(anim.length, 4.0, 0.0001)
	assert_almost_eq(anim.step, 1.0 / FPS, 0.0001)
	for e: Dictionary in s.events:
		if e["type"] != "key":
			continue
		var track: int = anim.find_track(CutsceneBuilder.track_path(s, e["target"], e["prop"]), Animation.TYPE_VALUE)
		assert_ne(track, -1, "trilha de %s:%s" % [e["target"], e["prop"]])
		var key: int = anim.track_find_key(track, e["t"], Animation.FIND_MODE_APPROX)
		if key == -1:
			key = anim.track_find_key(track, e["t"], Animation.FIND_MODE_NEAREST)
		assert_lte(absf(anim.track_get_key_time(track, key) * FPS - e["t"] * FPS), 1.0, "t=%s no quadro certo" % e["t"])


func test_initial_value_is_keyed_at_zero() -> void:
	var build: CutsceneBuilder.Result = CutsceneBuilder.build(_parse(_script()))
	var s: CutsceneScript = build.source
	var track: int = build.animation.find_track(CutsceneBuilder.track_path(s, "anselmo", "modulate:a"), Animation.TYPE_VALUE)
	assert_eq(build.animation.track_get_key_count(track), 2, "valor inicial em t=0 + a chave do roteiro")
	assert_almost_eq(build.animation.track_get_key_time(track, 0), 0.0, 0.0001)
	assert_almost_eq(float(build.animation.track_get_key_value(track, 0)), 0.0, 0.0001)


func test_position_values_become_vectors() -> void:
	var build: CutsceneBuilder.Result = CutsceneBuilder.build(_parse(_script()))
	var track: int = build.animation.find_track(CutsceneBuilder.track_path(build.source, "anselmo", "position"), Animation.TYPE_VALUE)
	assert_eq(build.animation.track_get_key_value(track, 1), Vector2(140, 200))


func test_step_ease_uses_nearest() -> void:
	var d: Dictionary = _script()
	d["events"][0]["ease"] = "step"
	var build: CutsceneBuilder.Result = CutsceneBuilder.build(_parse(d))
	var track: int = build.animation.find_track(CutsceneBuilder.track_path(build.source, "anselmo", "modulate:a"), Animation.TYPE_VALUE)
	assert_eq(build.animation.track_get_interpolation_type(track), Animation.INTERPOLATION_NEAREST)


func test_cues_are_ordered_and_snapped() -> void:
	var build: CutsceneBuilder.Result = CutsceneBuilder.build(_parse(_script()))
	var kinds: Array = build.cues.map(func(c: Dictionary) -> StringName: return c["kind"])
	assert_eq(kinds, [&"line_start", &"line_end", &"caption_on", &"caption_off", &"mark"])
	var last: int = -1
	for c: Dictionary in build.cues:
		assert_gte(c["frame"], last, "em ordem")
		last = c["frame"]
		assert_eq(c["frame"], roundi(c["t"] * FPS))


# --- builder: execução quadro a quadro --------------------------------------------------------

class Recorder extends Node2D:
	var frame: int = 0
	var fired: Dictionary = {}
	func _cue(index: int) -> void:
		for i: int in range(fired.size(), index + 1):
			fired[i] = frame


func test_cues_fire_on_their_frame_when_played() -> void:
	var build: CutsceneBuilder.Result = CutsceneBuilder.build(_parse(_script()))
	var rec := Recorder.new()
	var stage := Node2D.new()
	stage.name = "Stage"
	rec.add_child(stage)
	for layer: String in CutsceneScript.LAYERS:
		var l := Node2D.new()
		l.name = layer
		stage.add_child(l)
	var actor := Sprite2D.new()
	actor.name = "anselmo"
	stage.get_node("actors").add_child(actor)
	var player := AnimationPlayer.new()
	rec.add_child(player)
	add_child_autofree(rec)
	var lib := AnimationLibrary.new()
	lib.add_animation(&"cutscene", build.animation)
	player.add_animation_library(&"", lib)
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	player.play(&"cutscene")
	player.advance(0.0)
	var frames: int = roundi(build.animation.length * FPS)
	for f: int in range(1, frames + 1):
		rec.frame = f
		player.advance(1.0 / FPS)
	for i: int in build.cues.size():
		assert_true(rec.fired.has(i), "cue %d disparou" % i)
		if rec.fired.has(i):
			assert_lte(absi(rec.fired[i] - build.cues[i]["frame"]), 1, "cue %d no quadro certo" % i)
	assert_almost_eq(actor.position.x, 140.0, 0.01, "valor final da trilha")


func test_long_line_is_rejected() -> void:
	var d: Dictionary = _script()
	d["events"][2]["key"] = "LORE_MORTIS"
	assert_gt(_parse(d).errors.size(), 0, "fala que passa de 2 linhas é recusada")


func test_every_chapter_1_line_fits_two_lines() -> void:
	var f := FileAccess.open("res://i18n/ui.csv", FileAccess.READ)
	f.get_csv_line()
	var n: int = 0
	while not f.eof_reached():
		var row: PackedStringArray = f.get_csv_line()
		if row.size() < 3 or not row[0].begins_with("CS_C1_"):
			continue
		n += 1
		for text: String in [row[1], row[2]]:
			var norm: String = PixelFont.normalize(text)
			var lines: int = CutsceneBand.caption_lines(norm).size() if row[0].contains("CAPTION") \
				else UiStyle.wrap_words(norm, CutsceneBand.chars_for("narrator" if row[0].contains("NARRATOR") else "anselmo")).size()
			assert_lte(lines, 2, "%s cabe em 2 linhas" % row[0])
	assert_eq(n, 20, "as 12 falas e legendas do Cap. 1 + 8 variantes por escriba (D-101 7a)")


# --- roteiros do projeto ----------------------------------------------------------------------

func test_every_project_script_is_valid() -> void:
	var dir: String = CutsceneScript.DIR
	var n: int = 0
	for f: String in DirAccess.get_files_at(dir):
		if not f.ends_with(".json") or f == "speakers.json":
			continue
		n += 1
		var s: CutsceneScript = CutsceneScript.load_file(dir + f)
		assert_eq(s.errors, PackedStringArray(), f)
		assert_eq(String(s.id), f.get_basename(), "id igual ao nome do arquivo")
	gut.p("%d roteiros no projeto" % n)
	pass_test("roteiros conferidos")
