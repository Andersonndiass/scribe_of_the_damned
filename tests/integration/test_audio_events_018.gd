extends GutTest
## 009/018: os 101 efeitos do manifesto ligados (DIRECAO-SONORA §4.2): todo efeito do manifesto
## tem SoundData com arquivo; loops ligam e desligam; arma sem som próprio fica muda; os sinais
## só de áudio tocam o som certo.

const MANIFEST := "res://docs/audio/sfx_manifest.json"


func after_each() -> void:
	AudioManager.stop_all_loops()


func test_every_manifest_sound_is_in_the_map_with_a_file() -> void:
	var items: Array = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for it: Dictionary in items:
		if not it.get("generated", true):
			continue  # ainda não gerado (tools/gen_missing_sfx.py)
		var s: SoundData = AudioManager.event_map.resolve(StringName(it["event"]))
		assert_not_null(s, "evento %s no mapa" % it["event"])
		if s != null:
			assert_not_null(s.stream, "%s tem arquivo" % it["event"])


func test_loop_starts_and_stops() -> void:
	assert_true(AudioManager.start_loop(&"letter_menu_countdown"))
	assert_true(AudioManager.is_looping(&"letter_menu_countdown"))
	assert_true(AudioManager.start_loop(&"letter_menu_countdown"), "de novo: continua o mesmo")
	AudioManager.stop_loop(&"letter_menu_countdown")
	assert_false(AudioManager.is_looping(&"letter_menu_countdown"))


func test_beam_toggles_the_bible_loop() -> void:
	EventBus.weapon_beam_toggled.emit(&"bible", true)
	assert_true(AudioManager.is_looping(&"weapon_loop", &"bible"))
	EventBus.weapon_beam_toggled.emit(&"bible", false)
	assert_false(AudioManager.is_looping(&"weapon_loop", &"bible"))


func test_weapon_without_its_own_sound_stays_silent() -> void:
	var before: int = AudioManager.plays_total
	EventBus.weapon_hit.emit(&"inexistente")
	assert_eq(AudioManager.plays_total, before, "arma sem som próprio: não cai no som base")
	EventBus.weapon_fired.emit(&"pen")
	assert_eq(AudioManager.last_played, &"weapon_pen_fire")


func test_audio_only_signals_play_their_sound() -> void:
	EventBus.letter_menu_cursor_moved.emit(1)
	assert_eq(AudioManager.last_played, &"letter_menu_move")
	EventBus.shop_purchase_denied.emit()
	assert_eq(AudioManager.last_played, &"shop_denied")
	EventBus.potion_drunk.emit(&"wine", 1, 0)
	assert_eq(AudioManager.last_played, &"potion_3_speed", "Vinho = velocidade")
	EventBus.boss_attack_started.emit(&"rotating_cross")
	assert_true(AudioManager.is_looping(&"boss_attack", &"rotating_cross"), "a cruz gira em loop")
	EventBus.boss_attack_finished.emit(&"rotating_cross")
	assert_false(AudioManager.is_looping(&"boss_attack", &"rotating_cross"))


func test_letter_menu_muffles_the_music_while_open() -> void:
	EventBus.letter_menu_opened.emit([])
	assert_true(AudioManager.is_music_muffled(), "passa-baixa ligado com o menu aberto")
	EventBus.letter_menu_closed.emit()
	assert_false(AudioManager.is_music_muffled())


func test_voice_bus_exists_and_has_a_volume_setting() -> void:
	assert_gt(AudioServer.get_bus_index(&"Voice"), 0)
	assert_true(Settings.BUSES.has(&"Voice"), "Falas nas Opções")
