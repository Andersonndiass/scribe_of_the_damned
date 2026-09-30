class_name HudWordList
extends Node2D
## Segurar Tab mostra as palavras conhecidas (T074, FR-024). Latim sem tradução (Princípio VIII).
## As que cabem no atril atual em INK; as que não cabem em INK_SOFT. Coluna esquerda, fora da
## área central.

const PANEL := Rect2(8, 64, 140, 232)
const PAD := 6


func hud_rect() -> Rect2:
	return PANEL


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	var held: bool = Input.is_action_pressed(&"word_list")
	if held != visible:
		visible = held
		queue_redraw()


func _draw() -> void:
	UiStyle.draw_plate(self, PANEL)
	PixelFont.draw(self, tr(&"HUD_WORDS"), PANEL.position + Vector2(PAD, PAD), Palette.INK_SOFT)
	var field := get_tree().get_first_node_in_group(&"letter_field") as LetterField
	if field == null:
		return
	var y: float = PANEL.position.y + PAD + PixelFont.LINE_HEIGHT * 2
	for w: WordData in field.lexicon.words_with_prefix("", Atril.MAX_CAPACITY, 64):
		var fits: bool = w.latin.length() <= GameState.atril_capacity
		var at := Vector2(PANEL.position.x + PAD, y)
		PixelFont.draw(self, w.latin, at, Palette.INK if fits else Palette.INK_SOFT)
		if not fits:
			# Não cabe no atril: tom apagado + traço (não xadrez).
			draw_rect(Rect2(at.x, at.y + 3, PixelFont.width(w.latin), 1), Palette.INK_SOFT)
		y += PixelFont.LINE_HEIGHT + 2
