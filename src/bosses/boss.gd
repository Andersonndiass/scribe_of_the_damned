class_name Boss
extends BossHurtbox
## Chefe na página (006 FR-601..FR-611). Um corpo grande fora do EnemyManager: registra-se como
## `boss_target` (as palavras e o ataque automático o ferem pelo DamageSource), fere por contato,
## anda devagar na metade de cima, escolhe ataques pelo AttackPicker e passa a vida pelo
## BossDamageFilter. A FSM ($StateMachine) cuida de Enter/Idle/Telegraph/Attack/Recover/Exposed/
## PhaseShift/Stunned/Dead. Os executores dos ataques são criados no _ready (nunca na luta).

const FLASH_TIME := 0.06
## Onde o chefe fica: faixa de cima da página (FR-610).
const HOME := Vector2(320, 110)
const MIN_Y := 70.0
const MAX_Y := 150.0
const SPRITE_HALF := Vector2(32, 32)
const SAFETY_CHECK := 0.25
const EXECUTORS: Dictionary = {
	&"beam": preload("res://src/bosses/attacks/beam_attack.gd"),
	&"double_beam": preload("res://src/bosses/attacks/beam_attack.gd"),
	&"swipe": preload("res://src/bosses/attacks/swipe_attack.gd"),
	&"rotating_cross": preload("res://src/bosses/attacks/cross_attack.gd"),
	&"summon": preload("res://src/bosses/attacks/summon_attack.gd"),
	&"erasure": preload("res://src/bosses/attacks/erasure_attack.gd"),
}

@export var data: BossData
@export var filter_data: BossDamageFilterData = preload("res://data/tuning/boss_damage_filter.tres")
@export var safety_tuning: LetterSafetyTuning = preload("res://data/tuning/letter_safety.tres")

var filter: BossDamageFilter
var picker: AttackPicker
var safety: LetterSafety
var player: Player
var manager: EnemyManager
var letter_field: LetterField
var fighting: bool = false
var targetable: bool = false
## Ataque em curso (escolhido no Idle) e o executor dele.
var current_attack: AttackData
var current_executor: BossAttack
## Entrada: fração do corpo já revelada (0..1).
var reveal: float = 1.0
var clock: float = 0.0

var _executors: Dictionary[StringName, BossAttack] = {}
var _flash_left: float = 0.0
var _phase_seen: int = 0
var _safety_timer: float = 0.0

@onready var machine: StateMachine = $StateMachine


func _ready() -> void:
	visible = false
	for kind: StringName in EXECUTORS:
		var ex: BossAttack = (EXECUTORS[kind] as GDScript).new()
		ex.name = "Attack_%s" % kind
		add_child(ex)
		_executors[kind] = ex


## Começa a luta (FR-607): o chefe entra no alto da página.
func start_fight() -> void:
	filter = BossDamageFilter.new(filter_data, data)
	picker = AttackPicker.new(GameState.rng)
	safety = LetterSafety.new(safety_tuning)
	_phase_seen = 0
	clock = 0.0
	if letter_field != null:
		letter_field.erase_grace = data.erasure_grace
	global_position = HOME
	manager.boss_target = self
	fighting = true
	visible = true
	EventBus.boss_spawned.emit(data)
	EventBus.boss_damaged.emit(filter.hp, data.max_hp)
	machine.transition_to(&"Enter")


func executor_for(attack: AttackData) -> BossAttack:
	return _executors.get(attack.kind, null)


func phase() -> PhaseData:
	return data.phases[filter.phase_index]


func distance_to_player() -> float:
	return manager.player_body().distance_to(global_position) if manager != null else INF


func cancel_attack() -> void:
	if current_executor != null:
		current_executor.cancel()
	current_executor = null
	current_attack = null


func state_name() -> StringName:
	return machine.current.name if machine != null and machine.current != null else &""


# --- BossHurtbox ------------------------------------------------------------------------------

func hurt_radius() -> float:
	return data.body_radius


func is_targetable() -> bool:
	return fighting and targetable


func take(amount: int, tag: StringName, cast_id: int) -> void:
	if tag == &"":
		push_warning("Boss: dano sem origem (DamageSource vazio)")
	var got: int = filter.apply(amount, tag, cast_id)
	if got <= 0:
		return
	_flash_left = FLASH_TIME
	EventBus.boss_damaged.emit(filter.hp, data.max_hp)
	if filter.is_dead():
		machine.transition_to(&"Dead")
	elif filter.phase_index != _phase_seen:
		_phase_seen = filter.phase_index
		machine.transition_to(&"PhaseShift")


func stun(seconds: float) -> void:
	if state_name() in [&"Dead", &"PhaseShift", &"Enter"]:
		return
	machine.transition_to(&"Stunned", {"time": seconds * data.stun_mul})


# --- laço -----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not fighting:
		return
	clock += delta
	filter.tick(delta)
	_flash_left = maxf(0.0, _flash_left - delta)
	if targetable and state_name() != &"Dead":
		_drift(delta)
		_contact()
		_letter_safety(delta)
	queue_redraw()


func _drift(delta: float) -> void:
	var target := Vector2(clampf(manager.player_body().x, Arena.PLAYABLE.position.x + 40.0, Arena.PLAYABLE.end.x - 40.0),
		clampf(global_position.y, MIN_Y, MAX_Y))
	global_position = global_position.move_toward(target, data.move_speed * delta)


func _contact() -> void:
	if player == null or not player.vitals.is_alive():
		return
	if manager.player_body().distance_to(global_position) <= data.body_radius + manager.player_hurt_radius:
		player.take_hit(data.contact_damage, &"contact")


func _letter_safety(delta: float) -> void:
	_safety_timer -= delta
	if _safety_timer > 0.0 or letter_field == null:
		return
	_safety_timer = SAFETY_CHECK
	if safety.tick(SAFETY_CHECK, letter_field.count_useful_on_ground()):
		letter_field.drop_safety_letter(safety.drop_position(manager.player_body(), GameState.rng, Arena.PLAYABLE))


## Desenho (design-agent): quadros gerados por script; overlays da F2 (rachaduras) e da F3 (fogo).
func _draw() -> void:
	if data == null or data.sprite_frames == null:
		return
	var frames: SpriteFrames = data.sprite_frames
	var st: StringName = state_name()
	var anim: StringName = &"idle"
	var frame: int = int(clock * 1000.0 / float(phase().idle_frame_ms if filter != null else 140)) % frames.get_frame_count(&"idle")
	if st == &"Dead":
		anim = &"death"
		frame = mini(frames.get_frame_count(&"death") - 1, int(machine.current.get(&"elapsed") / (data.death_time / 4.0)))
	elif filter != null and filter.is_invulnerable() and st == &"PhaseShift":
		anim = &"invuln"
		frame = int(clock / 0.08) % 2
	elif _flash_left > 0.0:
		anim = &"hit"
		frame = 0
	elif st == &"Telegraph":
		anim = &"telegraph"
		frame = 0
	elif st == &"Exposed":
		frame = 0
	var tex: Texture2D = frames.get_frame_texture(anim, frame)
	var top_left: Vector2 = -SPRITE_HALF
	if reveal < 1.0:
		var h: float = roundf(64.0 * reveal)
		draw_texture_rect_region(tex, Rect2(top_left + Vector2(0, 64.0 - h), Vector2(64, h)), Rect2(0, 64.0 - h, 64, h))
		return
	draw_texture(tex, top_left)
	if filter != null and filter.phase_index >= 1 and st != &"Dead":
		draw_texture(frames.get_frame_texture(&"crack", 0), top_left)
	if filter != null and filter.phase_index >= 2 and st != &"Dead":
		draw_texture(frames.get_frame_texture(&"flame", int(clock / 0.1) % 2), top_left)
	if st == &"Exposed" and int(clock / 0.1) % 2 == 0:
		draw_rect(Rect2(top_left + Vector2(20, 14), Vector2(24, 32)), Palette.CHALK, false, 1.0)
	if st == &"PhaseShift":
		for k: int in 16:
			if k % 2 == 0:
				draw_arc(Vector2.ZERO, 36.0, TAU * k / 16.0, TAU * (k + 1) / 16.0, 3, Palette.INK, 1.0)
