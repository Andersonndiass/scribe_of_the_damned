extends SceneTree
## Lista o que falta gravar (009 FR-911): todo SoundData e MusicData sem stream vai para
## docs/AUDIO-LIST.md, com o evento que o usa e a nota do que gravar.
## Uso: godot --headless --path . -s tools/audio_report.gd

const MAP_PATH := "res://data/audio/event_map.tres"
const MUSIC_DIR := "res://data/audio/music/"
const OUT_PATH := "res://docs/AUDIO-LIST.md"


func _init() -> void:
	var map: AudioEventMap = load(MAP_PATH)
	var lines: PackedStringArray = [
		"# Lista de áudio — o que falta gravar",
		"",
		"> Gerado por `tools/audio_report.gd` a partir de `data/audio/` (009 FR-911). Não editar à mão.",
		"> Para ligar um som: abra o `.tres` indicado e ponha o arquivo em `stream`. Formatos: `.ogg` (música) e `.wav` (efeitos).",
		"",
		"## Efeitos",
		"",
		"| Arquivo | Evento | Canal | O que gravar |",
		"|---|---|---|---|",
	]
	var missing: int = 0
	for s: SoundData in map.sounds:
		if s.stream != null:
			continue
		missing += 1
		lines.append("| `data/audio/sfx/%s.tres` | `%s` | %s | %s |" % [s.id, s.event, s.bus, s.note])
	lines.append_array(["", "## Música", "", "| Arquivo | Camadas | O que gravar |", "|---|---|---|"])
	var dir := DirAccess.open(MUSIC_DIR)
	if dir != null:
		for f: String in dir.get_files():
			if not f.ends_with(".tres"):
				continue
			var m: MusicData = load(MUSIC_DIR + f)
			if m.layers.is_empty():
				missing += 1
				lines.append("| `data/audio/music/%s` | %d | %s |" % [f, m.intensity_thresholds.size(), m.note])
	lines.append_array(["", "**Faltam %d arquivos.**" % missing, ""])
	var out := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	out.store_string("\n".join(lines))
	print("audio_report: %d faltando → %s" % [missing, OUT_PATH])
	quit(0)
