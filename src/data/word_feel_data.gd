class_name WordFeelData
extends Resource
## Peso da palavra como "ultimate" (017 T1740; animation-agent T1700 §4): hit-stop e tremor por
## tipo. Ataque = palavra com zona letal; tela = os golpes de tela e combos grandes; ferramenta =
## o resto (escudo, cura, buff), como antes.

@export var attack_hitstop_ms: int = 100
@export var attack_shake_px: float = 2.0
@export var attack_shake_time: float = 0.4
@export var screen_hitstop_ms: int = 100
@export var screen_shake_px: float = 3.0
@export var screen_shake_time: float = 0.4
@export var screen_words: Array[StringName] = [&"martyrium", &"purgo", &"requiem", &"miserere"]
@export var tool_hitstop_ms: int = 60


## {"hitstop_ms", "shake_px", "shake_time"} para a palavra ou combo.
func for_word(w: WordData) -> Dictionary:
	if w != null and screen_words.has(w.id):
		return {"hitstop_ms": screen_hitstop_ms, "shake_px": screen_shake_px, "shake_time": screen_shake_time}
	if w != null and w.kill_zone:
		return {"hitstop_ms": attack_hitstop_ms, "shake_px": attack_shake_px, "shake_time": attack_shake_time}
	return {"hitstop_ms": tool_hitstop_ms, "shake_px": 0.0, "shake_time": 0.0}
