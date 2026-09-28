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
@export_multiline var note: String = ""


## Quantas camadas tocam na fração `f` do capítulo (pelo menos a base).
func layers_for_fraction(f: float) -> int:
	var n: int = 0
	for t: float in intensity_thresholds:
		if f >= t - 0.0001:
			n += 1
	return maxi(1, n)


## Fração do capítulo na onda `index` (1-based).
func fraction_for_wave(index: int) -> float:
	return clampf(float(index - 1) / float(maxi(1, waves - 1)), 0.0, 1.0)
