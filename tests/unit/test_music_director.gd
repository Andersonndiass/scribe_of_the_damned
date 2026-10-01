extends GutTest
## T905 MusicDirector (009 FR-908, FR-909): camadas pela intensidade da onda, rampa de volume,
## base na morte do escriba; silêncio sem erro quando não há streams.

var _m: MusicDirector
var _data: MusicData


func before_each() -> void:
	_data = MusicData.new()
	_data.waves = 9
	_data.intensity_thresholds = PackedFloat32Array([0.0, 0.34, 0.67])
	_data.fade_ms = 800
	_m = MusicDirector.new()
	add_child_autofree(_m)
	_m.start(_data)


func test_layers_follow_the_wave_fraction() -> void:
	assert_eq(_data.layers_for_fraction(_data.fraction_for_wave(1)), 1, "onda 1: só a base")
	assert_eq(_data.layers_for_fraction(_data.fraction_for_wave(4)), 2)
	assert_eq(_data.layers_for_fraction(_data.fraction_for_wave(7)), 3)
	assert_eq(_data.layers_for_fraction(_data.fraction_for_wave(9)), 3)


func test_wave_sets_active_layers_and_gains_ramp() -> void:
	_m.on_wave_started(7)
	assert_eq(_m.active_layers, 3)
	_m.step(0.4)
	assert_almost_eq(_m.gain_of(2), 0.5, 0.01, "metade da rampa de 800 ms")
	_m.step(0.5)
	assert_eq(_m.gain_of(2), 1.0)
	assert_eq(_m.gain_of(0), 1.0, "a base sempre toca")


func test_death_returns_to_base_with_shorter_fade() -> void:
	_data.death_fade_ms = 400
	_m.on_wave_started(9)
	_m.step(1.0)
	_m.on_player_died()
	assert_eq(_m.active_layers, 1)
	_m.step(0.2)
	assert_almost_eq(_m.gain_of(2), 0.5, 0.01, "metade da rampa de 400 ms")
	_m.step(0.2)
	assert_eq(_m.gain_of(1), 0.0)
	assert_eq(_m.gain_of(2), 0.0)


func test_silent_music_has_no_players_playing() -> void:
	_m.on_wave_started(5)
	_m.step(0.1)
	for p: AudioStreamPlayer in _m.players:
		assert_false(p.playing, "sem stream não toca")


## Feedback do autor (2026-10-01): batalha em faixas — calma, crescendo, clímax pelo progresso da onda.
func test_sections_follow_the_wave_progress_and_reset_at_the_end() -> void:
	var d := MusicData.new()
	d.mode = &"sections"
	d.layers = [AudioStreamWAV.new(), AudioStreamWAV.new(), AudioStreamWAV.new()]
	d.section_thresholds = PackedFloat32Array([0.0, 0.4, 0.75])
	d.fade_ms = 1000
	_m.start(d)
	_m.on_wave_started(1, 60.0)
	assert_eq(_m.section, 0, "começo: calma")
	_m.advance_wave(30.0)
	assert_eq(_m.section, 1, "50%: crescendo")
	_m.advance_wave(20.0)
	assert_eq(_m.section, 2, "83%: clímax")
	_m.step(1.0)
	assert_almost_eq(_m.gain_of(2), 1.0, 0.01)
	assert_almost_eq(_m.gain_of(0), 0.0, 0.01, "só uma faixa audível")
	_m.on_wave_ended()
	assert_eq(_m.section, 0, "fim da onda: volta à calma")

