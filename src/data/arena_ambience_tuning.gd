class_name ArenaAmbienceTuning
extends Resource
## Tempos e quantidades dos ambientes da moldura (004 FR-404; parecer do animation-agent T420)
## e retângulos do HUD que eles evitam (design-agent T420).

## Revelação do estágio novo: degraus do dissolve em blocos 2×2 (o tempo é o WaveTuning.reveal_time).
@export var reveal_steps: int = 4

@export_group("Vida de cada elemento")
@export var life: float = 2.5
@export var fade_in: float = 0.4
@export var fade_out: float = 0.4

@export_group("Ameaça (últimos segundos da onda)")
@export var threat_max: int = 6
## px/s para cima (fumaça de tinta e brasa sobem).
@export var threat_rise: float = 4.0
@export var threat_interval_min: float = 0.4
@export var threat_interval_max: float = 0.7

@export_group("Poeira (estágio ≥ 2)")
@export var dust_from_stage: int = 2
@export var dust_max: int = 6
@export var dust_drift: float = 3.0
@export var dust_fall: float = 1.0
@export var dust_interval_min: float = 0.5
@export var dust_interval_max: float = 0.9

@export_group("Brasas (estágio 3)")
@export var ember_stage: int = 3
@export var ember_max: int = 6
@export var ember_rise: float = 6.0
## Oscila ±1 px na horizontal, trocando a cada `ember_wobble_period` s.
@export var ember_wobble_period: float = 0.4
@export var ember_interval_min: float = 0.4
@export var ember_interval_max: float = 0.7

@export_group("Onde nascem")
## Faixa da moldura, em px a partir da borda externa (a faixa colada na área jogável fica livre).
@export var band_min: float = 2.0
@export var band_max: float = 19.0
@export var min_spacing: float = 48.0
@export var spawn_tries: int = 8
## HUD sobre a moldura: velas, cronômetro, tinta, lista de palavras, atril (design-agent).
@export var hud_avoid: Array[Rect2] = [
	Rect2(6, 6, 86, 35), Rect2(260, 6, 120, 28), Rect2(119, 6, 402, 30), Rect2(594, 6, 40, 15),
	Rect2(244, 306, 152, 37), Rect2(6, 310, 163, 44), Rect2(8, 64, 140, 232), Rect2(6, 45, 134, 138), Rect2(390, 305, 70, 40),
]
@export var rng_seed: int = 1348
