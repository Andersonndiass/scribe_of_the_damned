class_name CutsceneFx
extends Node2D
## Base dos elementos desenhados das cutscenes (008 T820; ficha T810): cada um é uma camada própria
## no palco, animada pelo roteiro através de `progress` (0 → 1). `t` corre em tempo real para os
## laços (fogo, chama, roer). Regras de pixel art (D-075/D-076): blocos lisos, luz da direita,
## contorno INK, sem pixel solto; xadrez só em transparência de fantasma e em área grande.

@export var progress: float = 0.0:
	set(v):
		progress = v
		queue_redraw()
## Semente dos limiares (hash fixo por célula; nunca randf no draw).
@export var seed_value: int = 7

var t: float = 0.0


func _process(delta: float) -> void:
	t += delta
	if animated():
		queue_redraw()


## Os que têm laço próprio (fogo, chama) redesenham todo quadro.
func animated() -> bool:
	return false


## Hash determinístico em [0, 1).
func hash01(i: int) -> float:
	var h: int = (i * 73856093) ^ (seed_value * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h) % 10000) / 10000.0


func rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), roundf(w), roundf(h)), c)


func disc(center: Vector2, r: int, c: Color) -> void:
	UiStyle.disc(self, center, r, c)
