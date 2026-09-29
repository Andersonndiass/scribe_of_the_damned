extends Node2D
## Mira do mouse (D-067; design-agent: UI_CURSOR_QUILL). Troca o cursor do sistema por uma pena de
## tinta 11×11 com o ponto quente na ponta (canto de baixo à esquerda), contorno CHALK para ler
## sobre inimigos. Atualiza `GameState.aim_point` (o Caster mira nele). Sem mouse na sessão, não
## aparece e a mira é a direção do escriba. Visível enquanto a mira pelo mouse vale (divergência
## da ficha: some só sem mouse, para não mirar num ponto invisível).

## O desenho da pena é o mesmo da pena-cursor dos menus (UiStyle.draw_quill).

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
	UiStyle.draw_quill(self, Vector2.ZERO)
