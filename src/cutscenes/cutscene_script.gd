class_name CutsceneScript
extends RefCounted
## Roteiro de uma cutscene (008 FR-801): lê e valida `data/cutscenes/<id>.json`. Erros vão para
## `errors` (o player não trava: fail-open, FR-806). O vocabulário (camadas, propriedades, easings,
## marcas) é do sistema; o conteúdo (atores, tempos, falas) é do JSON.

const DIR := "res://data/cutscenes/"
const SPEAKERS_PATH := "res://data/cutscenes/speakers.json"
const VERSION := 1
const FPS := 60.0
const LAYERS: PackedStringArray = ["bg", "actors", "fx"]
const KINDS: PackedStringArray = ["sprite", "frames", "fx"]
const PLAY_MODES: PackedStringArray = ["once", "always"]
const EVENT_TYPES: PackedStringArray = ["key", "line", "caption", "sound", "mark"]
## Propriedades animáveis e o tipo do valor no JSON.
const PROPS: Dictionary = {
	"position": TYPE_VECTOR2, "scale": TYPE_VECTOR2, "modulate:a": TYPE_FLOAT, "visible": TYPE_BOOL,
	"frame": TYPE_INT, "progress": TYPE_FLOAT, "reveal": TYPE_FLOAT,
}
const EASES: PackedStringArray = ["linear", "in", "out", "in_out", "step"]
## Marcas que o jogo entende (lista fechada).
const MARKS: PackedStringArray = ["boss_bar_shown", "music_cue", "flash"]
const LOCALES: PackedStringArray = ["pt_BR", "en"]

var id: StringName = &""
var duration: float = 0.0
var play_mode: StringName = &"always"
var actors: Dictionary = {}
var events: Array[Dictionary] = []
var speakers: Dictionary = {}
var errors := PackedStringArray()


static func load_file(path: String) -> CutsceneScript:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		var bad := CutsceneScript.new()
		bad.errors.append("%s: JSON inválido" % path)
		return bad
	return parse(parsed)


static func parse(data: Dictionary) -> CutsceneScript:
	var s := CutsceneScript.new()
	s.speakers = load_speakers()
	s._read(data)
	return s


static func load_speakers() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEAKERS_PATH))
	return (parsed as Dictionary).get("speakers", {}) if parsed is Dictionary else {}


## Quadro (a 60 FPS) de um tempo em segundos.
static func frame_of(t: float) -> int:
	return roundi(t * FPS)


## A chave existe e tem texto nos dois idiomas.
static func key_exists(key: String) -> bool:
	if key == "":
		return false
	for loc: String in LOCALES:
		var tr_obj: Translation = TranslationServer.get_translation_object(loc)
		if tr_obj == null or String(tr_obj.get_message(key)) == "":
			return false
	return true


## Converte o valor do JSON para o tipo da propriedade (Vector2 a partir de [x, y]).
static func convert_value(prop: String, v: Variant) -> Variant:
	match PROPS.get(prop, TYPE_NIL):
		TYPE_VECTOR2:
			return Vector2(v[0], v[1]) if v is Array and (v as Array).size() == 2 else null
		TYPE_FLOAT:
			return float(v) if v is float or v is int else null
		TYPE_INT:
			return int(v) if v is float or v is int else null
		TYPE_BOOL:
			return v if v is bool else null
	return null


func _err(msg: String) -> void:
	errors.append("%s: %s" % [id, msg])


func _read(d: Dictionary) -> void:
	id = StringName(str(d.get("id", "")))
	if id == &"":
		_err("sem id")
	if int(d.get("version", 0)) != VERSION:
		_err("versão diferente de %d" % VERSION)
	duration = float(d.get("duration", 0.0))
	if duration <= 0.0:
		_err("duração precisa ser maior que 0")
	play_mode = StringName(str(d.get("play", "always")))
	if not PLAY_MODES.has(String(play_mode)):
		_err("play precisa ser once ou always")
	_read_actors(d.get("actors", {}))
	for raw: Variant in d.get("events", []):
		if raw is Dictionary:
			events.append(raw)
		else:
			_err("evento que não é objeto")
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("t", 0.0)) < float(b.get("t", 0.0)))
	_check_events()


func _read_actors(raw: Dictionary) -> void:
	for name: String in raw:
		var a: Dictionary = raw[name]
		actors[name] = a
		if not LAYERS.has(str(a.get("layer", ""))):
			_err("ator %s: camada inválida" % name)
		if not KINDS.has(str(a.get("kind", ""))):
			_err("ator %s: tipo inválido" % name)
		var src: String = str(a.get("src", ""))
		if src == "" or not ResourceLoader.exists(src):
			_err("ator %s: recurso %s não existe" % [name, src])
		var init: Dictionary = a.get("init", {})
		for prop: String in init:
			if not PROPS.has(prop) or convert_value(prop, init[prop]) == null:
				_err("ator %s: valor inicial de %s inválido" % [name, prop])


func _check_events() -> void:
	var key_frames: Dictionary = {}  # "alvo:prop" -> {quadro: true}
	var track_eases: Dictionary = {}  # "alvo:prop" -> [usa step, usa outro]
	var line_spans: Array = []
	for e: Dictionary in events:
		var type: String = str(e.get("type", ""))
		var t: float = float(e.get("t", -1.0))
		if not EVENT_TYPES.has(type):
			_err("tipo de evento %s desconhecido" % type)
			continue
		if t < 0.0 or t > duration:
			_err("%s em t=%s fora da duração" % [type, t])
		match type:
			"key":
				_check_key(e, key_frames, track_eases)
			"line", "caption":
				var end: float = float(e.get("end", -1.0))
				if end <= t or end > duration:
					_err("%s em t=%s: end inválido" % [type, t])
				if not key_exists(str(e.get("key", ""))):
					_err("%s em t=%s: chave %s sem PT-BR e EN" % [type, t, e.get("key", "")])
				else:
					_check_fits(e, type)
				if type == "line":
					_check_speaker(e)
					for span: Array in line_spans:
						if t < span[1] and end > span[0]:
							_err("falas sobrepostas em t=%s" % t)
					line_spans.append([t, end])
			"sound":
				if str(e.get("id", "")) == "":
					_err("som sem id em t=%s" % t)
			"mark":
				if not MARKS.has(str(e.get("id", ""))):
					_err("marca %s fora da lista" % e.get("id", ""))


func _check_key(e: Dictionary, key_frames: Dictionary, track_eases: Dictionary) -> void:
	var target: String = str(e.get("target", ""))
	var prop: String = str(e.get("prop", ""))
	if not actors.has(target):
		_err("chave para ator inexistente %s" % target)
		return
	if not PROPS.has(prop):
		_err("propriedade %s fora da lista" % prop)
		return
	if convert_value(prop, e.get("value")) == null:
		_err("valor de %s:%s inválido" % [target, prop])
	var ease: String = str(e.get("ease", "linear"))
	if not EASES.has(ease):
		_err("easing %s desconhecido" % ease)
	var track: String = target + ":" + prop
	var frames: Dictionary = key_frames.get_or_add(track, {})
	var f: int = frame_of(float(e.get("t", 0.0)))
	if frames.has(f):
		_err("duas chaves de %s no quadro %d" % [track, f])
	frames[f] = true
	var used: Array = track_eases.get_or_add(track, [false, false])
	used[0 if ease == "step" else 1] = true
	if used[0] and used[1]:
		_err("%s mistura step com outros easings" % track)
	# O valor antes da primeira chave vem do init (senão a trilha assume a primeira chave).
	if not (actors[target].get("init", {}) as Dictionary).has(prop) and f > 0 and frames.size() == 1:
		_err("%s precisa de valor inicial (init) ou de uma chave em t=0" % track)


## Fala e legenda cabem em 2 linhas nos dois idiomas (ficha T810: 39 por linha na faixa, 48 do
## narrador, 32 na legenda).
func _check_fits(e: Dictionary, type: String) -> void:
	for loc: String in LOCALES:
		var text: String = PixelFont.normalize(String(TranslationServer.get_translation_object(loc).get_message(str(e["key"]))))
		var lines: int
		if type == "caption":
			lines = CutsceneBand.caption_lines(text).size()
		else:
			lines = UiStyle.wrap_words(text, CutsceneBand.chars_for(str(e.get("speaker", "")))).size()
		if lines > 2:
			_err("%s %s em %s passa de 2 linhas" % [type, e["key"], loc])


func _check_speaker(e: Dictionary) -> void:
	var who: String = str(e.get("speaker", ""))
	if not speakers.has(who):
		_err("falante %s não existe" % who)
		return
	var closes: Dictionary = speakers[who].get("closes", {})
	if not closes.has(str(e.get("expr", ""))):
		_err("falante %s sem a expressão %s" % [who, e.get("expr", "")])
