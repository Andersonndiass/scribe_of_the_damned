class_name HudWordGuard
extends Node2D
## A palavra guardada (D-099), à direita do atril, na mesma linha (y308–340). Provisório até a ficha
## UI_WORD_GUARD do design-agent: painel único (UiStyle.draw_plate), o latim em GOLD com contorno
## INK (é palavra); com a parceira de combo pronta no atril, 2ª moldura GOLD (como o COMBO_READY
## do atril). Vazia, só a placa com um traço INK_SOFT.

const PLATE := Rect2(404, 310, 60, 28)
const TEXT_Y := 321.0

var word: WordData = null
var combo_ready: bool = false


func _ready() -> void:
	EventBus.word_stored.connect(func(w: WordData, _r: int, _p: PackedStringArray) -> void:
		word = w
		queue_redraw())
	EventBus.stored_word_released.connect(func(_w: WordData, _c: StringName) -> void:
		word = null
		combo_ready = false
		queue_redraw())
	EventBus.player_died.connect(func() -> void:
		word = null
		queue_redraw())


func _process(_delta: float) -> void:
	var atril := get_parent().get_node_or_null(^"Atril") as HudAtril  # irmão no mesmo HUD
	var ready_now: bool = word != null and atril != null and atril.is_combo_ready()
	if ready_now != combo_ready:
		combo_ready = ready_now
		queue_redraw()


func hud_rect() -> Rect2:
	return UiStyle.plate_area(PLATE).grow(2.0)


func _draw() -> void:
	UiStyle.draw_plate(self, PLATE)
	if word == null:
		draw_rect(Rect2(PLATE.get_center().x - 8, TEXT_Y + 2, 16, 1), Palette.INK_SOFT)
		return
	if combo_ready:
		var r: Rect2 = PLATE.grow(2.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Palette.GOLD)
		draw_rect(Rect2(r.position.x, r.end.y - 1, r.size.x, 1), Palette.GOLD)
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), Palette.GOLD)
		draw_rect(Rect2(r.end.x - 1, r.position.y, 1, r.size.y), Palette.GOLD)
	var x: float = PLATE.get_center().x
	for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		PixelFont.draw_centered(self, word.latin, x + o.x, TEXT_Y - 3 + o.y, Palette.INK)
	PixelFont.draw_centered(self, word.latin, x, TEXT_Y - 3, Palette.GOLD)
