extends Node
## Configurações do jogador (007 FR-707, FR-708; D-066, D-067). Autoload "Settings".
## Salvas em `user://settings.cfg` (no web, IndexedDB) e aplicadas ao abrir o jogo: volumes no
## AudioServer (via AudioManager), shake e mira no GameState, idioma no TranslationServer e as
## teclas no InputMap. Trocar uma tecla já usada troca as duas ações de lugar (sem conflito).

const PATH := "user://settings.cfg"
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]
const LANGUAGES: PackedStringArray = ["pt_BR", "en"]
## Ações que o jogador pode remapear (teclado).
const REBINDABLE: Array[StringName] = [
	&"move_up", &"move_down", &"move_left", &"move_right", &"cast", &"purge", &"word_list",
	&"pause", &"restart", &"shop_lock", &"shop_reroll", &"shop_next",
]

## Rodando a suíte GUT, as telas não gravam no arquivo real do jogador.
var persist: bool = not " ".join(OS.get_cmdline_args()).contains("gut_cmdln")
var shake_enabled: bool = true
var aim_with_mouse: bool = true
var high_contrast: bool = false
var language: String = "pt_BR"

var _volumes: Dictionary[StringName, float] = {}
var _bindings: Dictionary[StringName, int] = {}
## Teclas extras de fábrica (setas, Enter do teclado numérico): continuam valendo junto da principal.
var _extra_defaults: Dictionary[StringName, Array] = {}


func _ready() -> void:
	reset_defaults()
	load_from(PATH)
	apply()


## Volta aos valores de fábrica (a primeira tecla de cada ação no project.godot é a principal).
func reset_defaults() -> void:
	shake_enabled = true
	aim_with_mouse = true
	high_contrast = false
	language = "pt_BR"
	for bus: StringName in BUSES:
		_volumes[bus] = 1.0
	_bindings.clear()
	_extra_defaults.clear()
	for action: StringName in REBINDABLE:
		var keys: Array = _project_keys(action)
		_bindings[action] = keys[0] if not keys.is_empty() else KEY_NONE
		_extra_defaults[action] = keys.slice(1)


func volume(bus: StringName) -> float:
	return _volumes.get(bus, 1.0)


func set_volume(bus: StringName, linear: float) -> void:
	_volumes[bus] = clampf(linear, 0.0, 1.0)


func binding(action: StringName) -> int:
	return _bindings.get(action, KEY_NONE)


## Troca a tecla principal de `action`; se outra ação usava essa tecla, ela recebe a antiga.
func set_binding(action: StringName, keycode: int) -> void:
	var old: int = binding(action)
	for other: StringName in _bindings:
		if other != action and _bindings[other] == keycode:
			_bindings[other] = old
	_bindings[action] = keycode


## Nome curto da tecla principal de `action` para mostrar na tela (traduzido quando há chave).
func key_label(action: StringName) -> String:
	var name: String = OS.get_keycode_string(binding(action) as Key).to_upper()
	var key: String = "KEY_" + name
	var t: String = tr(key)
	return t if t != key else name


func apply() -> void:
	GameState.shake_enabled = shake_enabled
	GameState.aim_with_mouse = aim_with_mouse
	GameState.high_contrast = high_contrast
	TranslationServer.set_locale(language)
	for bus: StringName in BUSES:
		AudioManager.set_bus_volume(bus, volume(bus))
	for action: StringName in _bindings:
		if not InputMap.has_action(action):
			continue
		for ev: InputEvent in InputMap.action_get_events(action):
			if ev is InputEventKey:
				InputMap.action_erase_event(action, ev)
		_add_key(action, _bindings[action])
		for extra: int in _extra_defaults.get(action, []):
			if extra != _bindings[action] and not _bindings.values().has(extra):
				_add_key(action, extra)
	EventBus.settings_applied.emit()


## Aplica e guarda (o que as telas chamam a cada mudança).
func commit() -> void:
	apply()
	if persist:
		save_to(PATH)


func save_to(path: String = PATH) -> int:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "shake", shake_enabled)
	cfg.set_value("game", "aim_with_mouse", aim_with_mouse)
	cfg.set_value("game", "high_contrast", high_contrast)
	cfg.set_value("game", "language", language)
	for bus: StringName in BUSES:
		cfg.set_value("audio", String(bus), volume(bus))
	for action: StringName in _bindings:
		cfg.set_value("keys", String(action), _bindings[action])
	return cfg.save(path)


func load_from(path: String = PATH) -> int:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(path)
	if err != OK:
		return err
	shake_enabled = cfg.get_value("game", "shake", shake_enabled)
	aim_with_mouse = cfg.get_value("game", "aim_with_mouse", aim_with_mouse)
	high_contrast = cfg.get_value("game", "high_contrast", high_contrast)
	var lang: String = cfg.get_value("game", "language", language)
	language = lang if LANGUAGES.has(lang) else language
	for bus: StringName in BUSES:
		set_volume(bus, cfg.get_value("audio", String(bus), volume(bus)))
	for action: StringName in REBINDABLE:
		_bindings[action] = int(cfg.get_value("keys", String(action), binding(action)))
	return OK


func _add_key(action: StringName, keycode: int) -> void:
	if keycode == KEY_NONE:
		return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode as Key
	InputMap.action_add_event(action, ev)


## Teclas do project.godot para a ação (a ordem de lá: a primeira é a principal).
func _project_keys(action: StringName) -> Array:
	var out: Array = []
	var setting: Variant = ProjectSettings.get_setting("input/%s" % action)
	if setting is Dictionary:
		for ev: InputEvent in (setting as Dictionary).get("events", []):
			if ev is InputEventKey:
				out.append(int((ev as InputEventKey).physical_keycode))
	return out
