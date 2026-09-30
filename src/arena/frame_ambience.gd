class_name FrameAmbience
extends Node2D
## Ambientes da moldura (004 FR-404; animation-agent T420): ameaça nos últimos segundos da onda,
## poeira no estágio ≥ 2 e brasas no 3. Um nó só, arrays de tamanho fixo criados no _ready,
## desenho por draw_rect/draw_texture_rect_region — nada é criado durante a onda. Só na moldura,
## fora do HUD. Pausa junto com a árvore (a loja congela o que estiver na tela).

enum Kind { SMOKE, THREAT_EMBER, DUST, EMBER }

const EMBER_FRAME := 4
## Quadros da tira da brasa: cheia, esfriando, fria, apagando.
const F_FULL := 0
const F_COOL := 1
const F_OUT := 3

@export var tuning: ArenaAmbienceTuning = preload("res://data/tuning/arena_ambience.tres")
@export var ember_texture: Texture2D = preload("res://assets/placeholders/vfx_ember.png")

## Estado da página (o Arena passa o seu).
var page: PageDegradation

var _pos := PackedVector2Array()
var _age := PackedFloat32Array()
var _kind := PackedInt32Array()
var _dir := PackedFloat32Array()
var _alive := PackedByteArray()
var _next_threat: float = 0.0
var _next_dust: float = 0.0
var _next_ember: float = 0.0
var _rng := RandomNumberGenerator.new()
var _signature: int = 0


func _ready() -> void:
	var n: int = tuning.threat_max + tuning.dust_max + tuning.ember_max
	_pos.resize(n)
	_age.resize(n)
	_kind.resize(n)
	_dir.resize(n)
	_alive.resize(n)
	_rng.seed = tuning.rng_seed


func count(kind: int = -1) -> int:
	var c: int = 0
	for i: int in _alive.size():
		if _alive[i] == 1 and (kind < 0 or _kind[i] == kind):
			c += 1
	return c


## Posições vivas (para testes).
func positions() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in _alive.size():
		if _alive[i] == 1:
			out.append(_pos[i])
	return out


func _process(delta: float) -> void:
	if page == null:
		return
	var threatened: bool = page.threatened()
	var shown: int = page.shown_stage
	for i: int in _alive.size():
		if _alive[i] == 0:
			continue
		# A ameaça acabou (a onda terminou): quem é da ameaça vai direto para a saída.
		if not threatened and (_kind[i] == Kind.SMOKE or _kind[i] == Kind.THREAT_EMBER):
			_age[i] = maxf(_age[i], tuning.life - tuning.fade_out)
		_age[i] += delta
		if _age[i] >= tuning.life:
			_alive[i] = 0
			continue
		_pos[i] += _velocity(i) * delta
	if threatened:
		_next_threat -= delta
		if _next_threat <= 0.0:
			_next_threat = _rng.randf_range(tuning.threat_interval_min, tuning.threat_interval_max)
			var kind: int = Kind.THREAT_EMBER if page.next_stage >= tuning.ember_stage else Kind.SMOKE
			_spawn(kind, tuning.threat_max, Vector2(0, -tuning.threat_rise))
	if shown >= tuning.dust_from_stage:
		_next_dust -= delta
		if _next_dust <= 0.0:
			_next_dust = _rng.randf_range(tuning.dust_interval_min, tuning.dust_interval_max)
			_spawn(Kind.DUST, tuning.dust_max, Vector2(tuning.dust_drift, tuning.dust_fall))
	if shown >= tuning.ember_stage:
		_next_ember -= delta
		if _next_ember <= 0.0:
			_next_ember = _rng.randf_range(tuning.ember_interval_min, tuning.ember_interval_max)
			_spawn(Kind.EMBER, tuning.ember_max, Vector2(0, -tuning.ember_rise))
	# Só redesenha quando algo muda no pixel ou de fase (animation-agent).
	var sig: int = 17
	for i: int in _alive.size():
		if _alive[i] == 1:
			var p: Vector2i = Vector2i(_draw_pos(i))
			sig = sig * 31 + p.x * 1009 + p.y * 7 + _phase(i)
	if sig != _signature:
		_signature = sig
		queue_redraw()


func _velocity(i: int) -> Vector2:
	match _kind[i]:
		Kind.DUST:
			return Vector2(tuning.dust_drift * _dir[i], tuning.dust_fall)
		Kind.EMBER:
			return Vector2(0, -tuning.ember_rise)
		_:
			return Vector2(0, -tuning.threat_rise)


func _spawn(kind: int, cap: int, velocity: Vector2) -> void:
	if count(kind) >= cap:
		return
	var slot: int = _alive.find(0)
	if slot < 0:
		return
	var dir: float = -1.0 if _rng.randf() < 0.5 else 1.0
	var travel: Vector2 = Vector2(velocity.x * dir, velocity.y) * tuning.life
	for t: int in tuning.spawn_tries:
		var p: Vector2 = _random_band_point()
		if not in_band(p) or not in_band(p + travel) or _under_hud(p) or _under_hud(p + travel):
			continue
		if _too_close(p):
			continue
		_pos[slot] = p
		_age[slot] = 0.0
		_kind[slot] = kind
		_dir[slot] = dir
		_alive[slot] = 1
		return


func _random_band_point() -> Vector2:
	var depth: float = _rng.randf_range(tuning.band_min, tuning.band_max)
	var size: Vector2 = Arena.PAGE_SIZE
	var along: float = _rng.randf() * (size.x * 2.0 + size.y * 2.0)
	if along < size.x:
		return Vector2(along, depth)
	along -= size.x
	if along < size.x:
		return Vector2(along, size.y - 1.0 - depth)
	along -= size.x
	if along < size.y:
		return Vector2(depth, along)
	return Vector2(size.x - 1.0 - depth, along - size.y)


## Dentro da faixa da moldura (entre band_min e band_max px da borda externa, em algum lado).
func in_band(p: Vector2) -> bool:
	var size: Vector2 = Arena.PAGE_SIZE
	if p.x < 0.0 or p.y < 0.0 or p.x > size.x - 1.0 or p.y > size.y - 1.0:
		return false
	var d: float = minf(minf(p.x, size.x - 1.0 - p.x), minf(p.y, size.y - 1.0 - p.y))
	return d >= tuning.band_min and d <= tuning.band_max


func _under_hud(p: Vector2) -> bool:
	for r: Rect2 in tuning.hud_avoid:
		if r.grow(EMBER_FRAME).has_point(p):
			return true
	return false


func _too_close(p: Vector2) -> bool:
	for i: int in _alive.size():
		if _alive[i] == 1 and _pos[i].distance_to(p) < tuning.min_spacing:
			return true
	return false


## 0 = entrando (1º degrau), 1 = entrando (2º), 2 = cheio, 3 = saindo (1º), 4 = saindo (2º).
func _phase(i: int) -> int:
	var a: float = _age[i]
	if a < tuning.fade_in:
		return 0 if a < tuning.fade_in * 0.5 else 1
	var left: float = tuning.life - a
	if left < tuning.fade_out:
		return 4 if left < tuning.fade_out * 0.5 else 3
	return 2


func _draw_pos(i: int) -> Vector2:
	var p: Vector2 = _pos[i].round()
	if _kind[i] == Kind.EMBER:
		p.x += [0, 1, 0, -1][int(_age[i] / tuning.ember_wobble_period) % 4]
	return p


func _draw() -> void:
	for i: int in _alive.size():
		if _alive[i] == 0:
			continue
		var p: Vector2 = _draw_pos(i)
		var phase: int = _phase(i)
		match _kind[i]:
			Kind.SMOKE:
				# Entra e sai em 2 degraus: meio (xadrez no nível do bloco) → inteiro.
				var half: bool = phase == 0 or phase == 4
				for x: int in 3:
					for y: int in 2:
						if not half or (x + y) % 2 == 0:
							draw_rect(Rect2(p + Vector2(x, y), Vector2.ONE), Palette.INK_SOFT)
			Kind.DUST:
				if phase != 0 and phase != 4:
					draw_rect(Rect2(p, Vector2.ONE), Palette.INK_SOFT)
			_:
				var frame: int = F_FULL
				if phase == 0 or phase == 4:
					frame = F_OUT
				elif phase == 1 or phase == 3:
					frame = F_COOL
				draw_texture_rect_region(ember_texture, Rect2(p - Vector2(2, 2), Vector2(EMBER_FRAME, EMBER_FRAME)),
					Rect2(frame * EMBER_FRAME, 0, EMBER_FRAME, EMBER_FRAME))
