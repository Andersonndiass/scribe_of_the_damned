extends Node
## Áudio do jogo (009 FR-901..FR-910). Autoload "AudioManager".
## Escuta o EventBus e toca o SoundData do evento (variante → base, AudioEventMap). Pool fixo de
## vozes criado no _ready (nada é criado durante a onda); o VoiceAllocator decide a voz.
## SFX pausa com a árvore; UI e música, não. Não obedece ao time_scale (hit-stop não distorce).
## No web, nada toca antes do primeiro input (política dos navegadores).

## Um som ocupou uma voz (métricas e testes).
signal sound_played(id: StringName)

const VOICES_SFX := 24
const VOICES_UI := 4
## Vozes de efeito que tocam com a árvore parada (cutscenes com o jogo pausado atrás, 008 FR-806b).
const VOICES_ALWAYS := 4
## Falas dubladas (008 FR-814, FR-816): `<pasta>/<idioma>/<id>.mp3` e `<pasta>/latin/<palavra>.mp3`.
const VOICE_DIR := "res://assets/audio/voice"
const VOICE_EXTS: PackedStringArray = ["mp3", "ogg", "wav"]
const HERESY_VOICE := &"haeresis"
const EVENT_MAP_PATH := "res://data/audio/event_map.tres"
const CHAPTER_MUSIC_PATH := "res://data/audio/music/chapter_1.tres"

var event_map: AudioEventMap
var music: MusicDirector
## Músicas por capítulo (a seleção de capítulo, 007, troca esta referência).
var chapter_music: MusicData
## Total de sons que passaram pelo allocator (métricas e testes).
var plays_total: int = 0
var last_played: StringName = &""

var _unlocked: bool = true
var _sfx: VoiceAllocator
var _ui: VoiceAllocator
var _always: VoiceAllocator
var _sfx_players: Array[AudioStreamPlayer] = []
var _ui_players: Array[AudioStreamPlayer] = []
var _always_players: Array[AudioStreamPlayer] = []
var _always_silent_end := PackedFloat64Array()
## Fala dublada (cutscene ou balão) e latim conjurado: um player cada, tocam com o jogo parado.
var _line_player: AudioStreamPlayer
var _latin_player: AudioStreamPlayer
## Último arquivo de voz tocado (testes e métricas); vazio = nenhum.
var last_voice: String = ""
## Fim da voz silenciosa (s); -1 = voz com stream (libera quando o player para).
var _sfx_silent_end := PackedFloat64Array()
var _ui_silent_end := PackedFloat64Array()
var _rng := RandomNumberGenerator.new()
var _atril_valid: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_unlocked = not OS.has_feature("web")
	if ResourceLoader.exists(EVENT_MAP_PATH):
		event_map = load(EVENT_MAP_PATH)
		event_map.build()
	if ResourceLoader.exists(CHAPTER_MUSIC_PATH):
		chapter_music = load(CHAPTER_MUSIC_PATH)
	_sfx = VoiceAllocator.new(VOICES_SFX)
	_ui = VoiceAllocator.new(VOICES_UI)
	_sfx_players = _make_players(VOICES_SFX, &"SFX", Node.PROCESS_MODE_PAUSABLE)
	_ui_players = _make_players(VOICES_UI, &"UI", Node.PROCESS_MODE_ALWAYS)
	_always = VoiceAllocator.new(VOICES_ALWAYS)
	_always_players = _make_players(VOICES_ALWAYS, &"SFX", Node.PROCESS_MODE_ALWAYS)
	_line_player = _make_players(1, &"SFX", Node.PROCESS_MODE_ALWAYS)[0]
	_latin_player = _make_players(1, &"SFX", Node.PROCESS_MODE_ALWAYS)[0]
	_sfx_silent_end.resize(VOICES_SFX)
	_ui_silent_end.resize(VOICES_UI)
	_always_silent_end.resize(VOICES_ALWAYS)
	music = MusicDirector.new()
	music.name = "Music"
	add_child(music)
	_connect_events()


func _make_players(n: int, bus: StringName, mode: Node.ProcessMode) -> Array[AudioStreamPlayer]:
	var out: Array[AudioStreamPlayer] = []
	for i: int in n:
		var p := AudioStreamPlayer.new()
		p.bus = bus
		p.process_mode = mode
		add_child(p)
		out.append(p)
	return out


# --- API --------------------------------------------------------------------------------------

## Toca o som de id `id` (cutscenes e animações, FR-907). Retorna true se ocupou uma voz.
## `always`: toca mesmo com a árvore parada (cutscenes por cima do jogo pausado).
func play(id: StringName, always: bool = false) -> bool:
	if event_map == null:
		return false
	var s: SoundData = event_map.by_id(id)
	return play_sound(s, always) if s != null else false


## Caminho da voz de uma fala no idioma atual (ou "" se não existir o arquivo).
static func voice_path(key: String, folder: String) -> String:
	for ext: String in VOICE_EXTS:
		var path: String = "%s/%s/%s.%s" % [VOICE_DIR, folder, key.to_lower(), ext]
		if ResourceLoader.exists(path):
			return path
	return ""


## Fala dublada (008 FR-814): a voz de `key` no idioma atual, se o arquivo existir.
func play_line_voice(key: String) -> bool:
	return _play_file(_line_player, voice_path(key, TranslationServer.get_locale()))


func stop_line_voice() -> void:
	_line_player.stop()


## Latim pronunciado (008 FR-816): o mesmo áudio nos dois idiomas.
func play_latin(word_id: StringName) -> bool:
	return _play_file(_latin_player, voice_path(String(word_id), "latin"))


func _play_file(p: AudioStreamPlayer, path: String) -> bool:
	if path == "" or not _unlocked:
		return false
	p.stop()
	p.stream = load(path)
	p.play()
	last_voice = path
	return true


## Toca o som do evento `key` (com variante opcional).
func play_event(key: StringName, variant: StringName = &"") -> bool:
	if event_map == null:
		return false
	var s: SoundData = event_map.resolve(key, variant)
	return play_sound(s) if s != null else false


func play_sound(s: SoundData, always: bool = false) -> bool:
	if not _unlocked:
		return false
	var ui: bool = s.bus == &"UI"
	var alloc: VoiceAllocator = _ui if ui else (_always if always else _sfx)
	var now: float = Time.get_ticks_msec() / 1000.0
	var v: int = alloc.request(s.id, s.max_voices, s.cooldown_ms, s.priority, now)
	if v < 0:
		return false
	var p: AudioStreamPlayer = (_ui_players if ui else (_always_players if always else _sfx_players))[v]
	var silent_end: PackedFloat64Array = _ui_silent_end if ui else (_always_silent_end if always else _sfx_silent_end)
	p.stop()
	if s.stream != null:
		p.stream = s.stream
		p.volume_db = s.volume_db
		p.pitch_scale = 1.0 + _rng.randf_range(-s.pitch_jitter, s.pitch_jitter)
		p.play()
		silent_end[v] = -1.0
	else:
		silent_end[v] = now + s.silent_length
	plays_total += 1
	last_played = s.id
	sound_played.emit(s.id)
	return true


## Volume linear (0–1) do barramento (FR-901; a tela de Opções usa).
func set_bus_volume(bus: StringName, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)))


func get_bus_volume(bus: StringName) -> float:
	var idx: int = AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx)) if idx >= 0 else 0.0


func is_unlocked() -> bool:
	return _unlocked


func sfx_busy_count() -> int:
	return _sfx.busy_count()


func sfx_active_count(id: StringName) -> int:
	return _sfx.active_count(id)


# --- internos ---------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _unlocked:
		return
	if (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) \
			and event.is_pressed():
		_unlocked = true


func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	_release_finished(_sfx, _sfx_players, _sfx_silent_end, now)
	_release_finished(_ui, _ui_players, _ui_silent_end, now)
	_release_finished(_always, _always_players, _always_silent_end, now)


func _release_finished(alloc: VoiceAllocator, players: Array[AudioStreamPlayer],
		silent_end: PackedFloat64Array, now: float) -> void:
	for v: int in alloc.size:
		if not alloc.is_busy(v):
			continue
		if silent_end[v] >= 0.0:
			if now >= silent_end[v]:
				alloc.release(v)
		elif not players[v].playing and not players[v].stream_paused:
			alloc.release(v)


func _connect_events() -> void:
	EventBus.wave_started.connect(func(index: int, _d: float) -> void:
		if index == 1 and chapter_music != null:
			music.start(chapter_music)
		music.on_wave_started(index)
		play_event(&"wave_started"))
	EventBus.wave_ended.connect(func(_i: int) -> void: play_event(&"wave_ended"))
	EventBus.chapter_completed.connect(func(_c: int) -> void: play_event(&"chapter_completed"))
	EventBus.enemy_killed.connect(func(_s: int, d: EnemyData, _p: Vector2) -> void:
		play_event(&"enemy_killed", d.id))
	EventBus.champion_killed.connect(func(_d: EnemyData, _p: Vector2) -> void: play_event(&"champion_killed"))
	EventBus.player_damaged.connect(func(_a: int, _c: int) -> void: play_event(&"player_damaged"))
	EventBus.player_healed.connect(func(_a: int, _c: int) -> void: play_event(&"player_healed"))
	EventBus.player_died.connect(func() -> void:
		music.on_player_died()
		play_event(&"player_died"))
	EventBus.letter_dropped.connect(func(_l: String, rare: bool, _t: bool, _p: Vector2) -> void:
		play_event(&"letter_dropped", &"rare" if rare else &""))
	EventBus.letter_collected.connect(func(_l: String, rare: bool) -> void:
		play_event(&"letter_collected", &"rare" if rare else &""))
	EventBus.letter_rejected.connect(func(_l: String) -> void: play_event(&"letter_rejected"))
	EventBus.letter_eaten.connect(func(_l: String, _p: Vector2) -> void: play_event(&"letter_eaten"))
	EventBus.gold_ink_collected.connect(func(_a: int, _t: int) -> void: play_event(&"gold_ink_collected"))
	EventBus.atril_changed.connect(func(_l: PackedStringArray, state: int, _h: PackedStringArray, _m: int) -> void:
		var valid: bool = state == Atril.Status.VALID
		if valid and not _atril_valid:
			play_event(&"atril_valid")
		_atril_valid = valid)
	EventBus.word_cast.connect(func(w: WordData, _pw: float, _o: Vector2, _dir: Vector2) -> void:
		play_event(&"word_cast", w.id)
		play_latin(w.id))
	EventBus.combo_cast.connect(func(c: ComboData, _pw: float) -> void:
		play_event(&"combo_cast", c.id)
		play_latin(c.id))
	EventBus.heresy_committed.connect(func(_p: Vector2) -> void:
		play_event(&"heresy_committed")
		play_latin(HERESY_VOICE))
	EventBus.atril_purged.connect(func(_l: PackedStringArray, _p: Vector2) -> void: play_event(&"atril_purged"))
	EventBus.combo_window_opened.connect(func(_w: WordData, _d: float, _pa: PackedStringArray) -> void:
		play_event(&"combo_window_opened"))
