class_name CutsceneScreen
extends UiScreen
## Rota "cutscene" do roteador (008 FR-807, T821): toca em sequência as cenas de
## `GameState.cutscene_queue` (corte seco entre elas: a virada de página da C1-01 já termina no
## pergaminho da C1-02) e, no fim, pede `GameState.after_cutscene`. Cada cena vista (ou pulada) fica
## gravada no Grimório (FR-810). A entrada é da cena (Espaço adianta, segurar Esc pula).

var player: CutscenePlayer
var played: Array[StringName] = []


## As cenas de abertura que ainda devem tocar ("once" já vistas saem). 010 (D-101 6a): o escriba
## com abertura própria a vê no lugar das do capítulo marcadas para outro escriba (`"for"`).
static func pending_intro(chapter: ChapterData, scribe: PlayerData = null) -> Array[StringName]:
	var out: Array[StringName] = []
	if chapter == null:
		return out
	var who: StringName = scribe.speaker_id if scribe != null and scribe.speaker_id != &"" else &"anselmo"
	if scribe != null and scribe.intro_cutscene != &"" and chapter.chapter == 1:  # 012: só abre o Cap. 1
		var own: CutsceneScript = CutsceneScript.load_file(CutsceneScript.DIR + String(scribe.intro_cutscene) + ".json")
		if not (own.play_mode == &"once" and Codex.cutscene_seen(scribe.intro_cutscene)):
			out.append(scribe.intro_cutscene)
	for id: StringName in chapter.intro_cutscenes:
		var s: CutsceneScript = CutsceneScript.load_file(CutsceneScript.DIR + String(id) + ".json")
		if s.play_mode == &"once" and Codex.cutscene_seen(id):
			continue
		if s.for_speaker != &"" and s.for_speaker != who:
			continue
		out.append(id)
	return out


func _ready() -> void:
	super()
	player = CutscenePlayer.new()
	add_child(player)
	EventBus.cutscene_finished.connect(_on_finished)
	_next.call_deferred()


func _exit_tree() -> void:
	if EventBus.cutscene_finished.is_connected(_on_finished):
		EventBus.cutscene_finished.disconnect(_on_finished)


func handle_input(_event: InputEvent) -> bool:
	return false


func _next() -> void:
	if GameState.cutscene_queue.is_empty():
		request(GameState.after_cutscene)
		return
	var id: StringName = GameState.cutscene_queue.pop_front()
	player.load_cutscene(id)
	player.play()


func _on_finished(id: StringName, _skipped: bool) -> void:
	Codex.mark_cutscene_seen(id)
	played.append(id)
	_next.call_deferred()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Palette.INK)
