class_name BarkDirector
extends CanvasLayer
## Frases curtas na partida (008 FR-815, D-072; ficha T810 do design-agent, tempos do animation-agent):
## escuta os gatilhos de `data/barks/barks.json`, mostra um balão de fala ao lado de quem fala (voz se
## o arquivo existir) e respeita os intervalos (4 s entre frases, 20 s para repetir; as do Asmodeus
## têm prioridade e cortam o balão atual). Um balão por vez; fora do hit-stop e do shake (UI).
## Posição: acima, abaixo, à direita ou à esquerda do falante — descarta o que cobre o HUD ou sai da
## tela e, entre os que sobram, fica o que menos invade a área central.

const DATA_PATH := "res://data/barks/barks.json"
const BODY := Vector2(160, 22)
const TAIL := 6
const CHARS := 25
const LINE_Y: Array[int] = [4, 11]
const SINGLE_Y := 8
const IN_TIME := 0.1
const RISE := 2.0
const CENTRAL := Rect2(160, 60, 320, 240)
## Áreas do HUD que o balão nunca cobre (velas, cronômetro, barra do chefe, tinta, atril e dicas).
const HUD_RECTS: Array[Rect2] = [
	Rect2(8, 6, 150, 32), Rect2(275, 6, 90, 26), Rect2(120, 35, 400, 26),
	Rect2(520, 6, 112, 24), Rect2(150, 300, 340, 40),
]
## Tamanho de cada falante na tela (o balão fica fora dele).
const SPEAKER_SIZE: Dictionary = {"anselmo": Vector2(16, 16), "asmodeus": Vector2(64, 64)}

var player: Node2D
var boss: Node2D
var data: Dictionary = {}
## Balão atual: {"bark", "text_lines", "left", "total", "age"}; vazio = nenhum.
var current: Dictionary = {}

var _since_any: float = INF
var _last_by_id: Dictionary = {}
var _canvas: Node2D
var _side: StringName = &"above"


func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	data = parsed if parsed is Dictionary else {}
	_canvas = Node2D.new()
	_canvas.draw.connect(_draw_balloon)
	add_child(_canvas)
	EventBus.boss_phase_changed.connect(func(i: int) -> void: _trigger("boss_phase_changed", {"phase": i}))
	EventBus.letter_erased.connect(func(_l: String, _p: Vector2) -> void: _trigger("letter_erased", {}))
	EventBus.boss_defeated.connect(func(_b: BossData) -> void: _trigger("boss_defeated", {}))
	EventBus.heresy_committed.connect(func(_p: Vector2) -> void: _trigger("heresy_committed", {}))
	EventBus.player_damaged.connect(func(_a: int, candles: int) -> void: _trigger("player_damaged", {"candles": candles}))
	EventBus.wave_ended.connect(func(_i: int) -> void: _trigger("wave_ended", {}))


func _process(delta: float) -> void:
	var real: float = delta / maxf(Engine.time_scale, 0.001)
	_since_any += real
	for id: String in _last_by_id.keys():
		_last_by_id[id] += real
	if current.is_empty():
		return
	current["age"] += real
	if current["age"] >= current["total"]:
		current = {}
	_canvas.queue_redraw()


## Um gatilho aconteceu: acha a frase que casa com o filtro e tenta mostrar.
func _trigger(trigger: String, info: Dictionary) -> void:
	for bark: Dictionary in data.get("barks", []):
		if bark["trigger"] != trigger:
			continue
		if bark.has("phase") and int(bark["phase"]) != int(info.get("phase", -1)):
			continue
		if bark.has("candles") and int(bark["candles"]) != int(info.get("candles", -1)):
			continue
		say(bark)
		return


## Mostra a frase se os intervalos deixarem (a de prioridade ignora o intervalo global e corta a atual).
func say(bark: Dictionary) -> bool:
	var id: String = bark["id"]
	var priority: bool = bark.get("priority", false)
	var repeat_gap: float = float(bark.get("repeat_gap", data.get("repeat_gap", 20.0)))
	if _last_by_id.has(id) and _last_by_id[id] < repeat_gap:
		return false
	if not priority and (_since_any < float(data.get("global_gap", 4.0)) or not current.is_empty()):
		return false
	var text: String = PixelFont.normalize(tr(str(bark["key"])))
	var lines: PackedStringArray = UiStyle.wrap_words(text, CHARS)
	var total: float = clampf(text.length() / float(data.get("chars_per_second", 15.0)),
		float(data.get("min_time", 1.5)), float(data.get("max_time", 2.5)))
	if AudioManager.play_line_voice(str(bark["key"])):
		total = clampf(total + float(data.get("voice_extra", 0.3)), total, float(data.get("voice_max", 3.0)))
	current = {"bark": bark, "lines": lines, "total": total, "age": 0.0}
	_since_any = 0.0
	_last_by_id[id] = 0.0
	_canvas.queue_redraw()
	return true


## Retângulo do falante na tela (centro na posição do nó).
func _bounds(speaker: String) -> Rect2:
	var node: Node2D = player if speaker == "anselmo" else boss
	var at: Vector2 = node.global_position if node != null else Vector2(320, 180)
	var size: Vector2 = SPEAKER_SIZE.get(speaker, Vector2(16, 16))
	return Rect2(at - size / 2.0, size)


## Escolhe o lado do balão: descarta os que cobrem o HUD ou saem da tela; fica o que menos invade o
## centro; o lado atual é mantido enquanto for válido (histerese).
func place(who: Rect2) -> Dictionary:
	var c: Vector2 = who.get_center()
	var candidates: Dictionary = {
		&"above": Rect2(c.x - BODY.x / 2.0, who.position.y - BODY.y - TAIL - 2, BODY.x, BODY.y),
		&"below": Rect2(c.x - BODY.x / 2.0, who.end.y + TAIL + 2, BODY.x, BODY.y),
		&"right": Rect2(who.end.x + TAIL + 2, c.y - BODY.y / 2.0, BODY.x, BODY.y),
		&"left": Rect2(who.position.x - TAIL - 2 - BODY.x, c.y - BODY.y / 2.0, BODY.x, BODY.y),
	}
	var valid: Dictionary = {}
	for side: StringName in candidates:
		var r: Rect2 = candidates[side]
		r.position.x = clampf(r.position.x, 8.0, 472.0)
		if r.position.y < 4.0 or r.end.y > 298.0 or r.intersects(who):
			continue
		var hits_hud: bool = false
		for h: Rect2 in HUD_RECTS:
			if h.intersects(r):
				hits_hud = true
				break
		if not hits_hud:
			valid[side] = r
	if valid.has(_side):
		return {"side": _side, "rect": valid[_side]}
	var best: StringName = &""
	var best_area: float = INF
	for side: StringName in [&"above", &"below", &"right", &"left"]:
		if valid.has(side):
			var area: float = (valid[side] as Rect2).intersection(CENTRAL).get_area()
			if area < best_area:
				best_area = area
				best = side
	if best == &"":
		var r: Rect2 = candidates[&"above"]
		r.position.x = clampf(r.position.x, 8.0, 472.0)
		r.position.y = maxf(r.position.y, 64.0)
		return {"side": &"above", "rect": r}
	_side = best
	return {"side": best, "rect": valid[best]}


func _draw_balloon() -> void:
	if current.is_empty():
		return
	var bark: Dictionary = current["bark"]
	var speaker: String = bark["speaker"]
	var who: Rect2 = _bounds(speaker)
	var anchor: Vector2 = who.get_center()
	var placed: Dictionary = place(who)
	var body: Rect2 = placed["rect"]
	var k: float = clampf(current["age"] / IN_TIME, 0.0, 1.0)
	body.position.y += roundf(RISE * (1.0 - k))
	body.position = body.position.round()
	var dark: bool = speaker == "asmodeus"
	var fill: Color = Palette.INK if dark else Palette.PARCHMENT
	var edge: Color = Palette.CHALK if dark else Palette.INK
	var text_c: Color = Palette.CHALK if dark else Palette.INK
	_canvas.draw_rect(body.grow(1), edge)
	_canvas.draw_rect(body, fill)
	if dark:
		for c: Vector2 in [body.position, Vector2(body.end.x - 2, body.position.y), Vector2(body.position.x, body.end.y - 2), body.end - Vector2(2, 2)]:
			_canvas.draw_rect(Rect2(c, Vector2(2, 2)), Palette.INK_SOFT)
	else:
		_canvas.draw_rect(Rect2(body.position.x + 1, body.end.y + 1, body.size.x, 1), Palette.INK_SOFT)
		_canvas.draw_rect(Rect2(body.end.x + 1, body.position.y + 1, 1, body.size.y), Palette.INK_SOFT)
	_draw_tail(body, anchor, placed["side"], fill, edge)
	var lines: PackedStringArray = current["lines"]
	for i: int in mini(lines.size(), 2):
		var y: float = body.position.y + (SINGLE_Y if lines.size() == 1 else LINE_Y[i])
		PixelFont.draw_centered(_canvas, lines[i], body.get_center().x, y, text_c)


## Rabicho de 6 px apontando para o falante (base 7 px afinando até 1 px, sem borda na junção).
func _draw_tail(body: Rect2, anchor: Vector2, side: StringName, fill: Color, edge: Color) -> void:
	for i: int in TAIL:
		var w: int = maxi(1, 7 - i * 2 + (1 if i == 0 else 0))
		match side:
			&"above":
				var x: float = clampf(anchor.x, body.position.x + 6, body.end.x - 6)
				_canvas.draw_rect(Rect2(x - w / 2.0 - 1, body.end.y + i, w + 2, 1), edge)
				_canvas.draw_rect(Rect2(x - w / 2.0, body.end.y + i, w, 1), fill)
			&"below":
				var xb: float = clampf(anchor.x, body.position.x + 6, body.end.x - 6)
				_canvas.draw_rect(Rect2(xb - w / 2.0 - 1, body.position.y - 1 - i, w + 2, 1), edge)
				_canvas.draw_rect(Rect2(xb - w / 2.0, body.position.y - 1 - i, w, 1), fill)
			&"right":
				var y: float = clampf(anchor.y, body.position.y + 4, body.end.y - 4)
				_canvas.draw_rect(Rect2(body.position.x - 1 - i, y - w / 2.0 - 1, 1, w + 2), edge)
				_canvas.draw_rect(Rect2(body.position.x - 1 - i, y - w / 2.0, 1, w), fill)
			_:
				var yl: float = clampf(anchor.y, body.position.y + 4, body.end.y - 4)
				_canvas.draw_rect(Rect2(body.end.x + i, yl - w / 2.0 - 1, 1, w + 2), edge)
				_canvas.draw_rect(Rect2(body.end.x + i, yl - w / 2.0, 1, w), fill)
