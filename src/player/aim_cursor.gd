extends Node2D
## Mira do mouse (D-067; design-agent: UI_CURSOR_QUILL). Troca o cursor do sistema por uma pena de
## tinta 11×11 com o ponto quente na ponta (canto de baixo à esquerda), contorno CHALK para ler
## sobre inimigos. Atualiza `GameState.aim_point` (o Caster mira nele). Sem mouse na sessão, não
## aparece e a mira é a direção do escriba. Visível enquanto a mira pelo mouse vale (divergência
## da ficha: some só sem mouse, para não mirar num ponto invisível).

## Pixels da pena a partir da ponta (0,0): bico e haste em INK; barbas INK_SOFT em xadrez.
const NIB: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, -1), Vector2i(2, -2)]
const SHAFT_FROM := 3
const SHAFT_TO := 10

var _hidden_os: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 50
	visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		GameState.aim_point = get_global_mouse_position()


func _process(_delta: float) -> void:
	var active: bool = GameState.aim_with_mouse and GameState.aim_point != Vector2.INF and not get_tree().paused
	if active:
		GameState.aim_point = get_global_mouse_position()
		global_position = GameState.aim_point.round()
	visible = active
	var want_hidden: bool = active
	if want_hidden != _hidden_os:
		_hidden_os = want_hidden
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if want_hidden else Input.MOUSE_MODE_VISIBLE
	queue_redraw()


func _exit_tree() -> void:
	if _hidden_os:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _draw() -> void:
	var pts: Array[Vector2i] = []
	pts.append_array(NIB)
	for i: int in range(SHAFT_FROM, SHAFT_TO + 1):
		pts.append(Vector2i(i, -i))
	var barbs: Array[Vector2i] = []
	for i: int in range(SHAFT_FROM, SHAFT_TO - 1):
		for w: int in [1, 2]:
			barbs.append(Vector2i(i, -i - w - 1))
	# Contorno CHALK nos 8 vizinhos.
	var filled := {}
	for p: Vector2i in pts + barbs:
		filled[p] = true
	for p: Vector2i in filled:
		for dy: int in [-1, 0, 1]:
			for dx: int in [-1, 0, 1]:
				var q := Vector2i(p.x + dx, p.y + dy)
				if not filled.has(q):
					draw_rect(Rect2(q, Vector2.ONE), Palette.CHALK)
	for p: Vector2i in barbs:
		draw_rect(Rect2(p, Vector2.ONE), Palette.INK_SOFT if (p.x + p.y) % 2 == 0 else Palette.PARCHMENT_OLD)
	for p: Vector2i in pts:
		draw_rect(Rect2(p, Vector2.ONE), Palette.INK)
