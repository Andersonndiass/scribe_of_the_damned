extends Node
## Progresso entre partidas (010; D-101 6b; rules-agent T1000; mechanics-agent). Autoload "Progress".
## Guarda os contadores que o Grimório não tem (capítulos vencidos, heresias sobrevividas), o
## desbloqueio dos escribas (latch: uma vez livre, fica livre) e o que ainda falta anunciar.
## Combos e palavras vêm do Codex (é o "misto com o Grimório"). Só conta no jogo de verdade
## (`GameState.run_counts`); sonda, GUT e debug não gravam.
## Heresia sobrevivida (T1000): a heresia conta se, nos `window` s seguintes, o escriba não perde
## vela nem morre (FIDES/Selo de Cera absorvendo contam; a perdoada pela MISERERE não é heresia).

const ROSTER := preload("res://data/player/roster.tres")
const LEXICON := preload("res://data/lexicon/base.tres")

var save_path: String = "user://progress.save"
var persist: bool = not (OS.get_cmdline_args().has("-s") or OS.get_cmdline_args().has("--script") or " ".join(OS.get_cmdline_args()).contains("gut_cmdln"))

var heresies_survived: int = 0
var chapters_won := PackedInt32Array()
var unlocked := PackedStringArray()
var announced := PackedStringArray()
## `?unlock=all`: todos livres só em memória.
var debug_all: bool = false
var _new_this_run := PackedStringArray()
## Cada vela perdida invalida as janelas abertas (contador de geração).
var _hurt_gen: int = 0


func _ready() -> void:
	load_saved()
	EventBus.heresy_committed.connect(_on_heresy)
	EventBus.player_damaged.connect(func(_a: int, _c: int) -> void: _hurt_gen += 1)
	EventBus.player_died.connect(func() -> void: _hurt_gen += 1)
	EventBus.chapter_completed.connect(_on_chapter_completed)
	EventBus.codex_discovered.connect(func(_c: StringName, _i: StringName) -> void: evaluate())
	evaluate()


func begin_run() -> void:
	_new_this_run = PackedStringArray()
	_hurt_gen += 1


func new_this_run() -> PackedStringArray:
	return _new_this_run.duplicate()


func is_unlocked(cid: StringName) -> bool:
	var c: PlayerData = ROSTER.by_id(cid)
	return c != null and (c.unlock == null or debug_all or unlocked.has(String(cid)))


## (atual, alvo) da condição de `c`; o atual trava no alvo.
func progress_of(c: PlayerData) -> Vector2i:
	if c.unlock == null:
		return Vector2i(1, 1)
	var u: UnlockData = c.unlock
	var now: int = 0
	match u.kind:
		&"chapter_won":
			now = 1 if chapters_won.has(u.chapter) else 0
		&"heresies_survived":
			now = heresies_survived
		&"combos_discovered":
			now = Codex.discovered(&"combos").size()
		&"words_discovered":
			var found: Array = Codex.discovered(&"words")
			for w: WordData in LEXICON.words:
				if w.group == u.word_group and found.has(w.id):
					now += 1
	return Vector2i(mini(now, u.target), u.target)


## Libera quem cumpriu (latch) e grava. Fora do jogo de verdade (GUT, sonda) só com `force`: o
## Grimório em memória dos testes não pode liberar ninguém.
func evaluate(force: bool = false) -> void:
	if not persist and not force:
		return
	var changed: bool = false
	for c: PlayerData in ROSTER.characters:
		if c.unlock == null or unlocked.has(String(c.id)):
			continue
		var p: Vector2i = progress_of(c)
		if p.x >= p.y:
			unlocked.append(String(c.id))
			_new_this_run.append(String(c.id))
			changed = true
			EventBus.character_unlocked.emit(c.id)
	if changed:
		_save()


## Escribas livres que a tela de Personagem ainda não anunciou ("nome reescrito no registro").
func pending_announcements() -> PackedStringArray:
	var out := PackedStringArray()
	for cid: String in unlocked:
		if not announced.has(cid):
			out.append(cid)
	return out


func mark_announced(cid: StringName) -> void:
	if not announced.has(String(cid)):
		announced.append(String(cid))
		_save()


func _on_heresy(_pos: Vector2) -> void:
	if not GameState.run_counts:
		return
	var tome: PlayerData = ROSTER.by_id(&"tome")
	var window: float = tome.unlock.window if tome != null and tome.unlock != null else 3.0
	var gen: int = _hurt_gen
	get_tree().create_timer(window, false).timeout.connect(func() -> void:
		if gen == _hurt_gen and GameState.run_counts:
			heresies_survived += 1
			_save()
			evaluate())


func _on_chapter_completed(chapter: int) -> void:
	if not GameState.run_counts or chapters_won.has(chapter):
		return
	chapters_won.append(chapter)
	_save()
	evaluate()


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "version", 1)
	cfg.set_value("progress", "heresies_survived", heresies_survived)
	cfg.set_value("progress", "chapters_won", chapters_won)
	cfg.set_value("characters", "unlocked", unlocked)
	cfg.set_value("characters", "announced", announced)
	cfg.save(save_path)


func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	heresies_survived = cfg.get_value("progress", "heresies_survived", 0)
	chapters_won = cfg.get_value("progress", "chapters_won", PackedInt32Array())
	unlocked = cfg.get_value("characters", "unlocked", PackedStringArray())
	announced = cfg.get_value("characters", "announced", PackedStringArray())


## Testes: zera tudo em memória.
func reset() -> void:
	heresies_survived = 0
	chapters_won = PackedInt32Array()
	unlocked = PackedStringArray()
	announced = PackedStringArray()
	_new_this_run = PackedStringArray()
	debug_all = false
