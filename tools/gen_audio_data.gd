extends SceneTree
## Gera os SoundData silenciosos de cada evento (009 T904), o AudioEventMap e a música do
## Capítulo 1. Não sobrescreve um SoundData que já tenha stream (o autor já pôs o arquivo).
## Uso: godot --headless --path . -s tools/gen_audio_data.gd

const SFX_DIR := "res://data/audio/sfx/"
const MUSIC_DIR := "res://data/audio/music/"
const MAP_PATH := "res://data/audio/event_map.tres"

## [evento, prioridade, max_voices, cooldown_ms, barramento, o que gravar]
const EVENTS: Array = [
	["wave_started", 2, 1, 0, "UI", "Sino curto de mosteiro: a página vira e a onda começa."],
	["wave_ended", 2, 1, 0, "UI", "Acorde grave que se resolve: a página respira."],
	["chapter_completed", 3, 1, 0, "UI", "Coro breve e grave: o capítulo foi reescrito."],
	["enemy_killed", 1, 3, 50, "SFX", "Morte genérica: tinta que se desfaz, curta (< 0,25 s)."],
	["enemy_killed:imp", 1, 3, 50, "SFX", "Diabrete: guincho agudo que vira borrão de tinta."],
	["enemy_killed:moth", 1, 3, 50, "SFX", "Traça: papel seco se esfarelando."],
	["enemy_killed:gargoyle", 1, 2, 60, "SFX", "Gárgula: pedra rachando."],
	["enemy_killed:hollow_monk", 1, 2, 60, "SFX", "Monge Oco: suspiro grave que some."],
	["enemy_killed:ink_blot", 1, 3, 50, "SFX", "Borrão: gota grossa espirrando."],
	["champion_killed", 3, 2, 0, "SFX", "Campeão: estalo forte + eco de sino rachado."],
	["player_damaged", 2, 1, 80, "SFX", "Vela apagando: sopro seco e chiado de pavio."],
	["player_healed", 2, 1, 0, "SFX", "Vela acendendo: fósforo e chama."],
	["player_died", 3, 1, 0, "SFX", "Morte do escriba: todas as velas se apagam, silêncio pesado."],
	["letter_dropped", 0, 2, 50, "SFX", "Letra caindo: pingo de tinta leve."],
	["letter_dropped:rare", 1, 2, 50, "SFX", "Vogal rara caindo: pingo com brilho metálico (ouro)."],
	["letter_collected", 1, 3, 30, "SFX", "Coleta: pena riscando o pergaminho, bem curta."],
	["letter_collected:rare", 1, 2, 30, "SFX", "Coleta rara: risco de pena + tilintar de ouro."],
	["letter_rejected", 1, 1, 100, "SFX", "Recusa (atril cheio): batida seca de madeira."],
	["letter_eaten", 0, 2, 80, "SFX", "Traça comendo a letra: mastigar de papel."],
	["gold_ink_collected", 1, 2, 30, "SFX", "Tinta dourada: moedas pequenas."],
	["atril_valid", 2, 1, 0, "UI", "Palavra pronta no atril: nota sustentada de órgão, suave."],
	["word_cast", 2, 1, 0, "SFX", "Conjuração genérica: palavra latina sussurrada em coro."],
	["word_cast:lux", 2, 1, 0, "SFX", "LUX: raio de luz, zunido cristalino."],
	["word_cast:pax", 2, 1, 0, "SFX", "PAX: onda grave que empurra, sopro."],
	["word_cast:crux", 2, 1, 0, "SFX", "CRUX: madeira cravada no chão."],
	["word_cast:vita", 2, 1, 0, "SFX", "VITA: respiração que volta, sino claro."],
	["word_cast:aqua", 2, 1, 0, "SFX", "AQUA: água se espalhando."],
	["word_cast:ignis", 2, 1, 0, "SFX", "IGNIS: fogo pegando no pergaminho."],
	["word_cast:mortis", 2, 1, 0, "SFX", "MORTIS: coro grave em onda, sino fúnebre."],
	["combo_cast", 3, 1, 0, "SFX", "Combo genérico: coro em uníssono + impacto."],
	["combo_cast:vapor", 3, 1, 0, "SFX", "VAPOR: chiado de água no fogo, névoa."],
	["combo_cast:flamma", 3, 1, 0, "SFX", "FLAMMA: raio + fogo rugindo ao longo da linha."],
	["combo_cast:caecitas", 3, 1, 0, "SFX", "CAECITAS: clarão agudo que ofusca, zumbido."],
	["combo_cast:martyrium", 3, 1, 0, "SFX", "MARTYRIUM: laser dourado girando, coro alto."],
	["combo_cast:requiem", 3, 1, 0, "SFX", "REQUIEM: coro de réquiem em onda, muitos sinos."],
	["heresy_committed", 2, 1, 0, "SFX", "Heresia: coro desafinado + estalo sujo de tinta."],
	["atril_purged", 1, 1, 0, "SFX", "Purge: letras sacudidas de volta ao chão, papel farfalhando."],
	["combo_window_opened", 1, 1, 0, "UI", "Janela de combo aberta: tique de relógio de areia."],
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SFX_DIR)
	DirAccess.make_dir_recursive_absolute(MUSIC_DIR)
	var map := AudioEventMap.new()
	var written: int = 0
	for e: Array in EVENTS:
		var event: String = e[0]
		var id: String = event.replace(":", "_")
		var path: String = SFX_DIR + id + ".tres"
		var s: SoundData = load(path) if ResourceLoader.exists(path) else SoundData.new()
		if s.stream == null:
			s.id = StringName(id)
			s.event = StringName(event)
			s.priority = e[1]
			s.max_voices = e[2]
			s.cooldown_ms = e[3]
			s.bus = StringName(e[4])
			s.note = e[5]
			ResourceSaver.save(s, path)
			s = load(path)
			written += 1
		map.sounds.append(s)
	ResourceSaver.save(map, MAP_PATH)
	var music_path: String = MUSIC_DIR + "chapter_1.tres"
	if not ResourceLoader.exists(music_path):
		var m := MusicData.new()
		m.id = &"chapter_1"
		m.note = "Capítulo 1 (Mosteiro de São Wendelino, 1348): 3 camadas no mesmo BPM. " \
			+ "Base: órgão e drone grave. Camada 2: canto gregoriano masculino. Camada 3: percussão e cordas tensas."
		ResourceSaver.save(m, music_path)
	print("gen_audio_data: %d sons gravados, %d no mapa" % [written, map.sounds.size()])
	quit(0)
