class_name MusicData
extends Resource
## Música em camadas (009 FR-908, FR-909, data-model §3). Todas as camadas tocam juntas e só
## mudam de volume. Sem streams = silêncio sem erro.

@export var id: StringName = &""
## Mesma duração e BPM. A camada 0 é a base.
@export var layers: Array[AudioStream] = []
@export var bpm: float = 90.0
## Fração do capítulo (0–1) em que cada camada entra; o índice é o da camada.
@export var intensity_thresholds: PackedFloat32Array = PackedFloat32Array([0.0, 0.34, 0.67])
## Ondas do capítulo (para a fração da onda atual).
@export var waves: int = 9
## Rampa ao ligar/desligar uma camada.
@export var fade_ms: int = 700
## Rampa mais curta quando o escriba morre (acompanha o silêncio do player_died; animation-agent).
@export var death_fade_ms: int = 400
## "layers": camadas juntas pela fração do capítulo (009). "sections" (feedback do autor
## 2026-10-01): uma faixa por vez — calma, crescendo, clímax — pelo progresso dentro da onda,
## com cruzamento de `fade_ms`; todas tocam juntas desde o começo (só o volume muda).
@export var mode: StringName = &"layers"
## Modo sections: fração da onda (0–1) em que cada faixa assume; o índice é o da faixa.
@export var section_thresholds: PackedFloat32Array = PackedFloat32Array([0.0, 0.4, 0.75])
## Volume da música inteira (dB), para casar com a mixagem dos efeitos (data/audio/mix_targets.json).
@export var volume_db: float = 0.0
@export_multiline var note: String = ""


## Quantas camadas tocam na fração `f` do capítulo (pelo menos a base).
func layers_for_fraction(f: float) -> int:
	var n: int = 0
	for t: float in intensity_thresholds:
		if f >= t - 0.0001:
			n += 1
	return maxi(1, n)


## Modo sections: a faixa que toca na fração `f` da onda.
func section_for_fraction(f: float) -> int:
	var n: int = 0
	for i: int in section_thresholds.size():
		if f >= section_thresholds[i] - 0.0001:
			n = i
	return mini(n, maxi(0, layers.size() - 1))


## Fração do capítulo na onda `index` (1-based).
func fraction_for_wave(index: int) -> float:
	return clampf(float(index - 1) / float(maxi(1, waves - 1)), 0.0, 1.0)
