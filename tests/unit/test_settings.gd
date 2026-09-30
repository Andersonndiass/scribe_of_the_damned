extends GutTest
## T700 Settings (007 FR-707, FR-708, SC-702; D-066/D-067): volumes, shake, idioma, alto contraste,
## mira com o mouse e teclas; salva e carrega; aplica nos sistemas; troca de tecla em conflito.

const PATH := "user://test_settings.cfg"

var _s: Node


func before_each() -> void:
	_s = (load("res://src/core/settings.gd") as GDScript).new()
	add_child_autofree(_s)
	_s.reset_defaults()


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Settings.apply()  # devolve o autoload ao estado dele


func test_defaults() -> void:
	assert_eq(_s.volume(&"Master"), 1.0)
	assert_true(_s.shake_enabled)
	assert_true(_s.aim_with_mouse, "mira com o mouse ligada por padrão (D-067)")
	assert_false(_s.high_contrast)
	assert_eq(_s.language, "pt_BR")


func test_save_and_load_roundtrip() -> void:
	_s.set_volume(&"Music", 0.25)
	_s.shake_enabled = false
	_s.language = "en"
	_s.high_contrast = true
	_s.aim_with_mouse = false
	_s.set_binding(&"cast", KEY_J)
	assert_eq(_s.save_to(PATH), OK)
	var other: Node = (load("res://src/core/settings.gd") as GDScript).new()
	add_child_autofree(other)
	other.reset_defaults()
	assert_eq(other.load_from(PATH), OK)
	assert_almost_eq(other.volume(&"Music"), 0.25, 0.001)
	assert_false(other.shake_enabled)
	assert_eq(other.language, "en")
	assert_true(other.high_contrast)
	assert_false(other.aim_with_mouse)
	assert_eq(other.binding(&"cast"), KEY_J, "SC-702")


func test_apply_reaches_the_systems() -> void:
	_s.shake_enabled = false
	_s.aim_with_mouse = false
	_s.language = "en"
	_s.set_volume(&"SFX", 0.5)
	_s.apply()
	assert_false(GameState.shake_enabled)
	assert_false(GameState.aim_with_mouse)
	assert_eq(TranslationServer.get_locale(), "en")
	assert_almost_eq(AudioManager.get_bus_volume(&"SFX"), 0.5, 0.01)


func test_rebinding_swaps_on_conflict() -> void:
	var cast_key: int = _s.binding(&"cast")
	var purge_key: int = _s.binding(&"purge")
	_s.set_binding(&"cast", purge_key)
	assert_eq(_s.binding(&"cast"), purge_key)
	assert_eq(_s.binding(&"purge"), cast_key, "a tecla antiga vai para quem perdeu a sua")


func test_binding_reaches_the_input_map() -> void:
	_s.set_binding(&"cast", KEY_J)
	_s.apply()
	var found: bool = false
	for ev: InputEvent in InputMap.action_get_events(&"cast"):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_J:
			found = true
	assert_true(found)


func test_missing_file_keeps_defaults() -> void:
	assert_ne(_s.load_from("user://does_not_exist.cfg"), OK)
	assert_true(_s.shake_enabled)


func test_contexts_let_1_and_2_serve_weapons_and_seals() -> void:
	# 017 T1702: armas (jogo) e selos (pausa) dividem as teclas 1/2 sem se empurrar.
	var s = _s
	assert_eq(s.binding(&"weapon_1"), s.binding(&"grace_pick_1"), "mesma tecla nos dois contextos")
	assert_eq(s.conflicts(&"weapon_1", s.binding(&"grace_pick_1")).size(), 0)
	var w: int = s.binding(&"move_up")
	s.set_binding(&"weapon_1", w)
	assert_eq(s.binding(&"move_up"), KEY_1, "no mesmo contexto a tecla antiga vai para a outra ação")
	assert_eq(s.binding(&"grace_pick_1"), KEY_1, "o selo não é afetado")
	assert_true(Settings.same_context(&"pause", &"grace_pick_1"), "a Pausa conflita com todos")
