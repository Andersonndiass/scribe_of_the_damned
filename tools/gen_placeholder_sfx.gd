extends SceneTree
## Sons provisórios por síntese (009 T910, FR-912): um som curto por evento de prioridade ≥ 1,
## salvo em assets/audio/placeholders/ e ligado no `stream` do SoundData. Não toca em SoundData
## cujo stream NÃO seja provisório (o arquivo do autor tem prioridade). O audio_report continua
## listando os provisórios como "falta gravar".
## Uso: godot --headless --path . -s tools/gen_placeholder_sfx.gd

const OUT := "res://assets/audio/placeholders/"
const SFX_DIR := "res://data/audio/sfx/"
const RATE := 22050

## Receita: wave (sine|square|triangle|noise), freqs (Hz; várias = acorde), dur (s), attack (s),
## slide (razão freq final/inicial), lp (filtro passa-baixa 0–1; 1 = sem filtro), vol (0–1),
## layers (opcional: receitas somadas, cada uma com `delay` em s).
## Tempos e volumes revisados pelo animation-agent (2026-09-29, D-061).
const RECIPES: Dictionary = {
	# Ondas e capítulo: sinos.
	"wave_started": {"wave": "bell", "freqs": [660.0], "dur": 0.7, "attack": 0.005, "vol": 0.5},
	"wave_ended": {"wave": "bell", "freqs": [392.0, 523.0], "dur": 0.9, "attack": 0.005, "vol": 0.45},
	"chapter_completed": {"wave": "triangle", "freqs": [196.0, 247.0, 294.0, 392.0], "dur": 1.5, "attack": 0.08, "vol": 0.45},
	# Inimigos: estalos de tinta curtos, um timbre por tipo.
	"enemy_killed": {"wave": "noise", "freqs": [0.0], "dur": 0.12, "attack": 0.002, "lp": 0.35, "vol": 0.35},
	"enemy_killed_imp": {"wave": "square", "freqs": [880.0], "dur": 0.1, "attack": 0.002, "slide": 0.4, "lp": 0.5, "vol": 0.22},
	"enemy_killed_moth": {"wave": "noise", "freqs": [0.0], "dur": 0.14, "attack": 0.002, "lp": 0.8, "vol": 0.25},
	"enemy_killed_gargoyle": {"wave": "noise", "freqs": [0.0], "dur": 0.2, "attack": 0.002, "lp": 0.12, "vol": 0.35},
	"enemy_killed_hollow_monk": {"wave": "sine", "freqs": [196.0], "dur": 0.2, "attack": 0.02, "slide": 0.6, "vol": 0.35},
	"enemy_killed_ink_blot": {"wave": "noise", "freqs": [0.0], "dur": 0.16, "attack": 0.002, "lp": 0.2, "vol": 0.3},
	"champion_killed": {"wave": "bell", "freqs": [220.0, 233.0], "dur": 0.8, "attack": 0.002, "vol": 0.5,
		"layers": [{"wave": "noise", "freqs": [0.0], "dur": 0.15, "attack": 0.001, "lp": 0.25, "vol": 0.5, "delay": 0.0}]},
	# Escriba.
	"player_damaged": {"wave": "noise", "freqs": [0.0], "dur": 0.25, "attack": 0.005, "lp": 0.15, "vol": 0.5},
	"player_healed": {"wave": "sine", "freqs": [523.0, 659.0], "dur": 0.35, "attack": 0.01, "slide": 1.5, "vol": 0.35},
	"player_died": {"wave": "triangle", "freqs": [220.0, 262.0, 311.0], "dur": 1.2, "attack": 0.01, "slide": 0.5, "vol": 0.5},
	# Letras e tinta.
	"letter_dropped_rare": {"wave": "sine", "freqs": [1568.0], "dur": 0.12, "attack": 0.002, "vol": 0.18},
	"letter_collected": {"wave": "noise", "freqs": [0.0], "dur": 0.04, "attack": 0.001, "lp": 0.6, "vol": 0.12},
	"letter_collected_rare": {"wave": "noise", "freqs": [0.0], "dur": 0.04, "attack": 0.001, "lp": 0.6, "vol": 0.12,
		"layers": [{"wave": "sine", "freqs": [2093.0], "dur": 0.12, "attack": 0.002, "vol": 0.15, "delay": 0.02}]},
	"letter_rejected": {"wave": "square", "freqs": [110.0], "dur": 0.08, "attack": 0.002, "lp": 0.2, "vol": 0.3},
	"gold_ink_collected": {"wave": "sine", "freqs": [1318.0], "dur": 0.06, "attack": 0.002, "vol": 0.2,
		"layers": [{"wave": "sine", "freqs": [1760.0], "dur": 0.08, "attack": 0.002, "vol": 0.2, "delay": 0.05}]},
	# Conjuração: acordes de órgão breves, um timbre por palavra.
	"atril_valid": {"wave": "triangle", "freqs": [523.0, 784.0], "dur": 0.3, "attack": 0.03, "vol": 0.2},
	"word_cast": {"wave": "triangle", "freqs": [262.0, 330.0, 392.0], "dur": 0.4, "attack": 0.01, "vol": 0.4},
	"word_cast_lux": {"wave": "sine", "freqs": [1047.0, 1319.0, 1568.0], "dur": 0.35, "attack": 0.005, "vol": 0.35},
	"word_cast_pax": {"wave": "triangle", "freqs": [196.0, 294.0], "dur": 0.45, "attack": 0.02, "slide": 0.8, "vol": 0.45},
	"word_cast_crux": {"wave": "noise", "freqs": [0.0], "dur": 0.12, "attack": 0.001, "lp": 0.15, "vol": 0.5,
		"layers": [{"wave": "triangle", "freqs": [330.0, 440.0], "dur": 0.3, "attack": 0.01, "vol": 0.3, "delay": 0.03}]},
	"word_cast_vita": {"wave": "sine", "freqs": [523.0, 659.0, 784.0], "dur": 0.45, "attack": 0.02, "slide": 1.2, "vol": 0.35},
	"word_cast_aqua": {"wave": "sine", "freqs": [440.0, 554.0], "dur": 0.45, "attack": 0.02, "slide": 0.7, "vol": 0.35},
	"word_cast_ignis": {"wave": "noise", "freqs": [0.0], "dur": 0.4, "attack": 0.02, "lp": 0.3, "vol": 0.4,
		"layers": [{"wave": "square", "freqs": [220.0], "dur": 0.25, "attack": 0.005, "lp": 0.3, "vol": 0.2, "delay": 0.0}]},
	"word_cast_mortis": {"wave": "triangle", "freqs": [98.0, 147.0, 196.0], "dur": 0.6, "attack": 0.02, "slide": 0.9, "vol": 0.5},
	"combo_cast": {"wave": "triangle", "freqs": [262.0, 330.0, 392.0, 523.0], "dur": 0.55, "attack": 0.01, "vol": 0.5},
	"combo_cast_vapor": {"wave": "noise", "freqs": [0.0], "dur": 0.55, "attack": 0.01, "lp": 0.6, "vol": 0.35,
		"layers": [{"wave": "triangle", "freqs": [294.0, 440.0], "dur": 0.5, "attack": 0.02, "vol": 0.3, "delay": 0.0}]},
	"combo_cast_flamma": {"wave": "sine", "freqs": [1047.0, 1319.0], "dur": 0.3, "attack": 0.005, "vol": 0.3,
		"layers": [{"wave": "noise", "freqs": [0.0], "dur": 0.5, "attack": 0.02, "lp": 0.3, "vol": 0.4, "delay": 0.05}]},
	"combo_cast_caecitas": {"wave": "sine", "freqs": [1760.0, 2217.0], "dur": 0.5, "attack": 0.002, "vol": 0.3},
	"combo_cast_martyrium": {"wave": "triangle", "freqs": [330.0, 415.0, 494.0, 659.0], "dur": 0.6, "attack": 0.01, "vol": 0.45},
	"combo_cast_requiem": {"wave": "bell", "freqs": [147.0, 220.0], "dur": 0.9, "attack": 0.005, "vol": 0.5},
	# Heresia e purge.
	"heresy_committed": {"wave": "square", "freqs": [233.0, 247.0, 349.0], "dur": 0.4, "attack": 0.005, "lp": 0.35, "vol": 0.35,
		"layers": [{"wave": "noise", "freqs": [0.0], "dur": 0.2, "attack": 0.002, "lp": 0.4, "vol": 0.3, "delay": 0.0}]},
	"atril_purged": {"wave": "noise", "freqs": [0.0], "dur": 0.22, "attack": 0.03, "lp": 0.6, "vol": 0.3},
	"combo_window_opened": {"wave": "sine", "freqs": [880.0], "dur": 0.05, "attack": 0.002, "vol": 0.18,
		"layers": [{"wave": "sine", "freqs": [660.0], "dur": 0.05, "attack": 0.002, "vol": 0.18, "delay": 0.1}]},
}

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 1348
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var linked: int = 0
	for id: String in RECIPES:
		var sfx_path: String = SFX_DIR + id + ".tres"
		if not ResourceLoader.exists(sfx_path):
			push_error("gen_placeholder_sfx: SoundData %s não existe" % sfx_path)
			continue
		var sound: Resource = load(sfx_path)
		var current: Resource = sound.get("stream")
		if current != null and not current.resource_path.begins_with(OUT):
			continue  # arquivo do autor: não mexe
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = RATE
		wav.stereo = false
		wav.data = _render(RECIPES[id])
		var out_path: String = OUT + "sfx_%s.tres" % id
		ResourceSaver.save(wav, out_path)
		sound.set("stream", load(out_path))
		ResourceSaver.save(sound, sfx_path)
		linked += 1
	print("gen_placeholder_sfx: %d sons provisórios gerados e ligados" % linked)
	quit(0)


func _render(r: Dictionary) -> PackedByteArray:
	var total: float = float(r["dur"])
	for layer: Dictionary in r.get("layers", []):
		total = maxf(total, float(layer["delay"]) + float(layer["dur"]))
	var n: int = int(total * RATE)
	var mix := PackedFloat32Array()
	mix.resize(n)
	_add(mix, r, 0.0)
	for layer: Dictionary in r.get("layers", []):
		_add(mix, layer, float(layer["delay"]))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i: int in n:
		bytes.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32000.0))
	return bytes


func _add(mix: PackedFloat32Array, r: Dictionary, delay: float) -> void:
	var dur: float = float(r["dur"])
	var attack: float = maxf(float(r.get("attack", 0.005)), 0.0005)
	var slide: float = float(r.get("slide", 1.0))
	var lp: float = float(r.get("lp", 1.0))
	var vol: float = float(r.get("vol", 0.3))
	var freqs: Array = r["freqs"]
	var wave: String = r["wave"]
	var start: int = int(delay * RATE)
	var n: int = int(dur * RATE)
	var phases := PackedFloat32Array()
	phases.resize(freqs.size())
	var filtered: float = 0.0
	for i: int in n:
		var t: float = float(i) / RATE
		var env: float = minf(1.0, t / attack) * pow(1.0 - t / dur, 2.0)
		var s: float = 0.0
		for k: int in freqs.size():
			var f: float = float(freqs[k]) * lerpf(1.0, slide, t / dur)
			phases[k] = fmod(phases[k] + f / RATE, 1.0)
			s += _osc(wave, phases[k], t)
		s /= maxf(1.0, float(freqs.size()))
		filtered += lp * (s - filtered)
		var idx: int = start + i
		if idx < mix.size():
			mix[idx] += filtered * env * vol


func _osc(wave: String, ph: float, t: float) -> float:
	match wave:
		"sine":
			return sin(TAU * ph)
		"square":
			return 1.0 if ph < 0.5 else -1.0
		"triangle":
			return 4.0 * absf(ph - 0.5) - 1.0
		"noise":
			return _rng.randf_range(-1.0, 1.0)
		"bell":
			# Parciais inarmônicos de sino com decaimento mais rápido nos agudos.
			return sin(TAU * ph) + 0.5 * sin(TAU * ph * 2.76) * exp(-t * 6.0) + 0.25 * sin(TAU * ph * 5.4) * exp(-t * 12.0)
	return 0.0
