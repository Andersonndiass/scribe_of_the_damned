class_name Player
extends CharacterBody2D
## Jogador (Irmão Anselmo na 001). Movimento em 8 direções, velas, i-frames, recuperação parado,
## squash & stretch e flash de acerto (FR-001..FR-005, T022–T025).

const SQUASH_RUN := Vector2(1.1, 0.9)
const SQUASH_HURT := Vector2(1.2, 0.8)
const SQUASH_RECOVER_TIME := 0.12
## Cadência do pisca-pisca dos i-frames (ficha 01: 80ms).
const IFRAME_BLINK_MS := 80
## Flash CHALK 8×8 na ponta da pena ao conjurar (art bible §6.2): 1 quadro.
const PEN_FLASH_SIZE := Vector2(8, 8)
const PEN_FLASH_POS := Vector2(2, -13)
const PEN_FLASH_TIME := 0.034

@export var data: PlayerData

var vitals := PlayerVitals.new()
## Apócrifos e orações (002): FIDES, LUMEN, GLORIA, SPIRITUS, MISERERE.
var buffs := PlayerBuffs.new()
var facing: Vector2 = Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var flash: Flash = $Sprite/Flash
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var arsenal: Arsenal = $Arsenal
var repulse_aura: RepulseAura
var potion_user: PotionUser
## Nome antigo (antes da 017) para o arsenal: `enabled`, `projectiles` e `fired` continuam.
var auto_attack: Arsenal:
	get:
		return arsenal
@onready var machine: StateMachine = $StateMachine

var _squash_tween: Tween
var _pen_flash: ColorRect
var _hazards: HazardField


func _ready() -> void:
	add_to_group(&"player")
	vitals.setup(data)
	arsenal.data = data
	# 017: ímã reverso (só age com o passivo comprado).
	repulse_aura = RepulseAura.new()
	repulse_aura.name = "RepulseAura"
	repulse_aura.player = self
	add_child(repulse_aura)
	# 018: poções nas teclas 3–6.
	potion_user = PotionUser.new()
	potion_user.name = "PotionUser"
	potion_user.player = self
	add_child(potion_user)
	_sync_state()
	hurtbox.hit.connect(take_hit)
	EventBus.wave_ended.connect(func(_i: int) -> void: buffs.on_wave_ended())
	sprite.frame_changed.connect(_on_frame_changed)
	_pen_flash = ColorRect.new()
	_pen_flash.size = PEN_FLASH_SIZE
	_pen_flash.position = PEN_FLASH_POS
	_pen_flash.color = Palette.CHALK
	_pen_flash.visible = false
	_pen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pen_flash)


func _physics_process(delta: float) -> void:
	var idle: bool = velocity.is_zero_approx() and machine.current != null \
		and machine.current.name == &"Idle"
	buffs.tick(delta)
	var healed: int = vitals.tick(delta, idle)
	if healed > 0:
		_sync_state()
		EventBus.player_healed.emit(healed, vitals.candles)
	hurtbox.invulnerable = vitals.is_invulnerable() or not vitals.is_alive()
	sprite.visible = not vitals.is_invulnerable() \
		or (int(vitals.iframes_left * 1000.0) / IFRAME_BLINK_MS) % 2 == 0


## Direção pedida pelo teclado, já normalizada (diagonal não é mais rápida).
func input_direction() -> Vector2:
	if GameState.letter_menu_open:
		return Vector2.ZERO  # 017 D-087: com o menu da letra aberto, o escriba fica parado
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func move(direction: Vector2) -> void:
	velocity = direction * RunStats.of(data).value(&"move_speed") * buffs.speed_mul() * _hazard_slow()
	if not direction.is_zero_approx():
		facing = direction.normalized()
		sprite.flip_h = facing.x < 0.0
	move_and_slide()


## Lentidão das poças do Borrão no ponto do jogador (005 FR-507). 1.0 = normal.
func _hazard_slow() -> float:
	if _hazards == null and is_inside_tree():
		_hazards = get_tree().get_first_node_in_group(&"hazards") as HazardField
	return _hazards.slow_at(global_position) if _hazards != null else 1.0


func play_anim(anim: StringName) -> void:
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
	if anim != &"run" and not _is_squashing():
		sprite.scale = Vector2.ONE


## Dano recebido (1 = fraco, 2 = forte). Chamado pela Hurtbox ou pelo EnemyManager.
func take_hit(amount: int, source_tag: StringName = &"") -> void:
	# SPIRITUS: intangível a corpos; projéteis ainda doem (D-046).
	if source_tag == &"contact" and buffs.is_intangible():
		return
	# FIDES: o escudo absorve o golpe inteiro (1 ou 2 velas) e dá os i-frames normais.
	if amount > 0 and vitals.is_alive() and not vitals.is_invulnerable() and buffs.absorb_hit():
		vitals.grant_iframes()
		EventBus.shield_broken.emit(global_position)
		return
	var applied: int = vitals.damage(amount)
	if applied == 0:
		return
	_sync_state()
	EventBus.player_damaged.emit(applied, vitals.candles)
	flash.play()
	squash(SQUASH_HURT)
	if not vitals.is_alive():
		machine.transition_to(&"Dead")
	else:
		machine.transition_to(&"Hurt")


func heal(amount: int) -> void:
	var applied: int = vitals.heal(amount)
	if applied > 0:
		_sync_state()
		EventBus.player_healed.emit(applied, vitals.candles)


## Flash de 1 quadro na pena (ignora o hit-stop, que congela o tempo do jogo).
## SPIRITUS: o escriba em xadrez CHALK enquanto está intangível.
func set_spirit_look(on: bool) -> void:
	flash.set_dither_tint(on)


## VAPOR: dentro da nuvem o escriba é desenhado em xadrez (oculto).
func set_hidden_look(on: bool) -> void:
	flash.set_dither_hidden(on)


func pen_flash() -> void:
	_pen_flash.visible = true
	await get_tree().create_timer(PEN_FLASH_TIME, true, false, true).timeout
	_pen_flash.visible = false


func stun(duration: float) -> void:
	if vitals.is_alive():
		machine.transition_to(&"Stunned", {"time": duration})


func squash(amount: Vector2) -> void:
	if _squash_tween != null:
		_squash_tween.kill()
	sprite.scale = amount
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, ^"scale", Vector2.ONE, SQUASH_RECOVER_TIME)


func _is_squashing() -> bool:
	return _squash_tween != null and _squash_tween.is_running()


func _on_frame_changed() -> void:
	if sprite.animation == &"run" and not _is_squashing():
		sprite.scale = SQUASH_RUN if sprite.frame % 2 == 0 else Vector2.ONE




func _sync_state() -> void:
	GameState.candles = vitals.candles
	GameState.max_candles = vitals.max_candles
