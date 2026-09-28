class_name SoundData
extends Resource
## Um som do jogo (009 FR-902, data-model §1). Sem `stream` = placeholder silencioso: passa por
## todo o caminho (voz, anti-spam), só não emite nada. Trocar o silêncio = pôr o arquivo aqui.

@export var id: StringName = &""
## Chave no AudioEventMap: evento do EventBus, com variante opcional ("word_cast:lux").
@export var event: StringName = &""
@export var stream: AudioStream
## &"SFX" ou &"UI".
@export var bus: StringName = &"SFX"
@export var volume_db: float = 0.0
## Pitch sorteado em 1 ± pitch_jitter.
@export var pitch_jitter: float = 0.05
## Vozes simultâneas deste som.
@export var max_voices: int = 4
## Intervalo mínimo entre dois disparos deste som.
@export var cooldown_ms: int = 30
## 0 baixa … 3 alta: no pool cheio, só rouba voz de prioridade menor ou igual.
@export var priority: int = 1
## Quanto a voz fica ocupada quando não há stream.
@export var silent_length: float = 0.2
## O que gravar (vai para docs/AUDIO-LIST.md).
@export_multiline var note: String = ""
