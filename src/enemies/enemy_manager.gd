class_name EnemyManager
extends Node2D
## Todos os inimigos comuns (plan §4.8, FR-007). Estado em arrays densos (slots 0..count-1),
## um único _physics_process, separação e consultas via SpatialHash. Nenhum inimigo é nó de física.
## Remoção por swap-remove: o último slot ocupa o lugar do removido.
## É o provider do EnemyQuery (AutoAttack, projéteis, milagres).

const CAPACITY := 400
## Raio de separação = raio do inimigo × este fator.
const SEPARATION_RADIUS_MUL := 2.2
## Força máxima da separação, em múltiplos da velocidade do inimigo.
const SEPARATION_MAX := 1.5
## Dentro de raio × este fator do alvo, o inimigo desacelera (já está encostando).
const ARRIVE_RADIUS_MUL := 3.0
## Folga nas consultas: o hash é reconstruído no início do frame e os inimigos andam um pouco depois.
const QUERY_PAD := 8.0
## Maior raio de inimigo previsto (consultas de acerto somam isto ao raio pedido).
const MAX_ENEMY_RADIUS := 12.0
const HASH_CELL := 16.0
## Cada inimigo recalcula steering + separação a cada STEER_STRIDE ticks (1/STEER_STRIDE deles em cada tick, para
## não gerar picos) com o passo multiplicado; o EnemyRenderer interpola a posição (T085 §4, D-039).
const STEER_STRIDE := 3
const AURA_PARTICLES := 4
const FLASH_TIME := 0.06
## O jogador é mirado no meio do corpo, não nos pés.
const PLAYER_BODY_OFFSET := Vector2(0, -4)
## Inimigo que não vê o escriba (CAECITAS, VAPOR) vaga a esta fração da velocidade, girando devagar.
const WANDER_SPEED_MUL := 0.5
const WANDER_TURN_PER_TICK := 0.02
## Venda do cego (design-agent, 002): altura dos olhos em raios acima do pé.
const BLINDFOLD_Y_MUL := 1.5
## Coroa dos atordoados (DOMINUS, PAX; design-agent): 3 pontos GOLD girando acima da cabeça.
const CROWN_ABOVE := 12.0
const CROWN_RADIUS := 3.0
const CROWN_POINTS := 3

@export var player: Node2D
@export var player_hurt_radius: float = 5.0
@export var world_rect: Rect2 = Arena.PLAYABLE
@export var champion_tuning: ChampionTuning = preload("res://data/tuning/champion.tres")

var count: int = 0
var positions := PackedVector2Array()
## Posição antes do último passo de steering de cada inimigo (para a interpolação do desenho).
var prev_positions := PackedVector2Array()
## Tick de física mais recente processado (o renderer usa para saber a "idade" de cada passo).
var last_tick: int = 0
var velocities := PackedVector2Array()
var hp := PackedInt32Array()
var flash_left := PackedFloat32Array()
var stun_left := PackedFloat32Array()
var slow_factor := PackedFloat32Array()
var slow_left := PackedFloat32Array()
var anim_phase := PackedFloat32Array()
var data_of: Array[EnemyData] = []
## Estado por inimigo para os comportamentos stateless (005 data-model §7).
var state := PackedInt32Array()
var state_timer := PackedFloat32Array()
var aim := PackedVector2Array()
var champion := PackedByteArray()
var max_hp_of := PackedInt32Array()
## Multiplicador de velocidade próprio do inimigo (campeões: ChampionTuning.speed_mul).
var speed_mul := PackedFloat32Array()
## Letras que o inimigo carrega (Traça), devolvidas na morte.
var carried := PackedStringArray()
## Raio efetivo do slot (campeões: × ChampionTuning.radius_mul).
var radius_of := PackedFloat32Array()
## Caches por slot para o laço quente (evitam buscas de propriedade no web; D-043).
var behavior_of: Array[EnemyBehavior] = []
var _tick_flag := PackedByteArray()
var _chase_flag := PackedByteArray()
var _speed_of := PackedFloat32Array()
## CAECITAS (002 FR-203, D-046): cego vaga sem perseguir nem atacar, mas o contato ainda fere.
var blind_left := PackedFloat32Array()
## REQUIEM: a morte deste slot solta letra com certeza (LetterField consulta).
var guaranteed_drop := PackedByteArray()
## Toques com intervalo por inimigo (ANGELUS, SPIRITUS): instante (relógio da física) em que o
## slot pode ser tocado de novo.
var touch_ready := PackedFloat32Array()
## Relógio da física (s), para os intervalos por inimigo.
var clock: float = 0.0
## Chefe na página (006): testado em cada função de dano, com a origem do DamageSource.
var boss_target: BossHurtbox = null
## Toque com intervalo (ANGELUS, SPIRITUS) no chefe: instante em que pode ser tocado de novo.
var _boss_touch_ready: float = 0.0

var _letter_field: LetterField
var _projectiles: EnemyProjectileManager
var _hazards: HazardField

## Comportamento padrão para EnemyData sem behavior.
static var _default_behavior: EnemyBehavior = ChaseBehavior.new()

var _hash: SpatialHash
var _hash_dirty: bool = true
var _aggro_point: Vector2 = Vector2.INF
var _aggro_left: float = 0.0
var _aggro_radius: float = INF
## VAPOR: enquanto o escriba está na nuvem, quem está fora dela não o vê.
var _hide_center: Vector2 = Vector2.INF
var _hide_radius: float = 0.0
var _hide_left: float = 0.0


func _init() -> void:
	positions.resize(CAPACITY)
	prev_positions.resize(CAPACITY)
	velocities.resize(CAPACITY)
	hp.resize(CAPACITY)
	flash_left.resize(CAPACITY)
	stun_left.resize(CAPACITY)
	slow_factor.resize(CAPACITY)
	slow_left.resize(CAPACITY)
	anim_phase.resize(CAPACITY)
	data_of.resize(CAPACITY)
	state.resize(CAPACITY)
	state_timer.resize(CAPACITY)
	aim.resize(CAPACITY)
	champion.resize(CAPACITY)
	max_hp_of.resize(CAPACITY)
	speed_mul.resize(CAPACITY)
	carried.resize(CAPACITY)
	radius_of.resize(CAPACITY)
	behavior_of.resize(CAPACITY)
	_tick_flag.resize(CAPACITY)
	_chase_flag.resize(CAPACITY)
	_speed_of.resize(CAPACITY)
	blind_left.resize(CAPACITY)
	guaranteed_drop.resize(CAPACITY)
	touch_ready.resize(CAPACITY)
	## Célula ~ raio de separação: cada consulta toca poucas células com poucos inimigos.
	_hash = SpatialHash.new(Rect2(Vector2.ZERO, Arena.PAGE_SIZE), HASH_CELL)


func _enter_tree() -> void:
	EnemyQuery.provider = self


func _exit_tree() -> void:
	if EnemyQuery.provider == self:
		EnemyQuery.provider = null


## Cria um inimigo no slot livre. Retorna o slot, ou -1 se a capacidade acabou.
## is_champion: os multiplicadores do campeão entram no T521.
func spawn(data: EnemyData, pos: Vector2, is_champion: bool = false) -> int:
	if count >= CAPACITY:
		push_warning("EnemyManager: capacidade %d esgotada" % CAPACITY)
		return -1
	var i: int = count
	positions[i] = _clamp_to_world(pos)
	prev_positions[i] = positions[i]
	velocities[i] = Vector2.ZERO
	hp[i] = data.max_hp
	flash_left[i] = 0.0
	stun_left[i] = 0.0
	slow_factor[i] = 1.0
	slow_left[i] = 0.0
	anim_phase[i] = GameState.rng.randf()
	data_of[i] = data
	state[i] = EnemyBehavior.STATE_IDLE
	state_timer[i] = 0.0
	aim[i] = Vector2.ZERO
	champion[i] = 1 if is_champion else 0
	max_hp_of[i] = data.max_hp
	speed_mul[i] = 1.0
	radius_of[i] = data.radius
	var b: EnemyBehavior = data.behavior if data.behavior != null else _default_behavior
	behavior_of[i] = b
	_tick_flag[i] = 1 if b.needs_tick else 0
	# Perseguição pura (Diabrete) é calculada direto no laço, sem chamada de função.
	_chase_flag[i] = 1 if b.get_script() == ChaseBehavior else 0
	_speed_of[i] = data.move_speed
	if is_champion and champion_tuning != null:
		max_hp_of[i] = roundi(data.max_hp * champion_tuning.hp_mul)
		hp[i] = max_hp_of[i]
		speed_mul[i] = champion_tuning.speed_mul
		radius_of[i] = data.radius * champion_tuning.radius_mul
	carried[i] = ""
	blind_left[i] = 0.0
	guaranteed_drop[i] = 0
	touch_ready[i] = 0.0
	count += 1
	_hash_dirty = true
	EventBus.enemy_spawned.emit(i, data)
	return i


func count_of(data: EnemyData) -> int:
	var n: int = 0
	for i: int in count:
		if data_of[i] == data:
			n += 1
	return n


## Poça de aggro da heresia (FR-019): por `duration` s, inimigos a até `radius` de `point`
## vão para a poça em vez de perseguir o jogador (sem radius = todos).
func set_aggro(point: Vector2, duration: float, radius: float = INF) -> void:
	_aggro_point = point
	_aggro_left = duration
	_aggro_radius = radius


## MISERERE: a poça de heresia deixa de atrair.
func clear_aggro() -> void:
	_aggro_left = 0.0


func is_aggro_active() -> bool:
	return _aggro_left > 0.0


func _physics_process(delta: float) -> void:
	if _aggro_left > 0.0:
		_aggro_left -= delta
	if _hide_left > 0.0:
		_hide_left -= delta
	clock += delta
	last_tick += 1
	if count == 0:
		return
	var step_dt: float = delta * STEER_STRIDE
	var t_hash: int = Prof.start()
	_rebuild_hash()
	Prof.stop(&"inimigos_hash", t_hash)
	var t_move: int = Prof.start()
	var player_pos: Vector2 = Vector2.INF
	if player != null:
		player_pos = player.global_position + PLAYER_BODY_OFFSET
	var aggro: bool = _aggro_left > 0.0
	var aggro_r2: float = _aggro_radius * _aggro_radius
	var can_hit_player: bool = player != null and player.has_method(&"take_hit")
	var hidden: bool = _hide_left > 0.0
	var hide_r2: float = _hide_radius * _hide_radius
	# Laço quente: grade acessada direto, sem alocar (o hash guarda a foto do início do frame).
	var snap: PackedVector2Array = positions.duplicate()
	var cs: PackedInt32Array = _hash.cell_start()
	var sorted: PackedInt32Array = _hash.sorted_slots()
	var cols: int = _hash.cols()
	var rows: int = _hash.rows()
	var inv_cell: float = 1.0 / _hash.cell_size()
	var org: Vector2 = _hash.origin()

	for i: int in count:
		var d: EnemyData = data_of[i]
		flash_left[i] = maxf(0.0, flash_left[i] - delta)
		if slow_left[i] > 0.0:
			slow_left[i] -= delta
			if slow_left[i] <= 0.0:
				slow_factor[i] = 1.0
		if stun_left[i] > 0.0:
			stun_left[i] -= delta
			velocities[i] = Vector2.ZERO
			prev_positions[i] = positions[i]
			continue
		var p: Vector2 = positions[i]
		var sees: bool = true
		if blind_left[i] > 0.0:
			blind_left[i] -= delta
			sees = false
		elif hidden and p.distance_squared_to(_hide_center) > hide_r2:
			sees = false
		if sees and _tick_flag[i] == 1:
			behavior_of[i].tick(self, i, delta)
			if i >= count or data_of[i] != d:
				continue  # o tick removeu este inimigo (swap-remove): o slot já é outro
			p = positions[i]
		if (i + last_tick) % STEER_STRIDE != 0:
			# Não é a vez deste inimigo: só o contato com o jogador.
			if can_hit_player and _drawn_position(i).distance_to(player_pos) <= radius_of[i] + player_hurt_radius:
				player.call(&"take_hit", _contact_damage(i, d), &"contact")
			continue
		prev_positions[i] = p
		var target: Vector2 = player_pos
		if aggro and p.distance_squared_to(_aggro_point) <= aggro_r2:
			target = _aggro_point
		var desired := Vector2.ZERO
		if not sees:
			var heading: float = anim_phase[i] * TAU + float(last_tick) * WANDER_TURN_PER_TICK
			desired = Vector2.RIGHT.rotated(heading) * _speed_of[i] * slow_factor[i] * WANDER_SPEED_MUL
		elif _chase_flag[i] == 1:
			# = ChaseBehavior.seek, inline (mesma fórmula; test_behavior_contract cobre).
			if target != Vector2.INF:
				var to_t: Vector2 = target - p
				var dist_t: float = to_t.length()
				if dist_t > 1.0:
					var arrive: float = clampf(dist_t / (radius_of[i] * ARRIVE_RADIUS_MUL), 0.0, 1.0)
					desired = to_t / dist_t * _speed_of[i] * slow_factor[i] * speed_mul[i] * arrive
		else:
			desired = behavior_of[i].desired_velocity(self, i, target, step_dt)
		# Separação.
		var sep_r: float = radius_of[i] * SEPARATION_RADIUS_MUL
		var push := Vector2.ZERO
		# Só as células que o raio de separação toca (1–4 com células de 16px).
		var sx0: int = clampi(int((p.x - sep_r - org.x) * inv_cell), 0, cols - 1)
		var sx1: int = clampi(int((p.x + sep_r - org.x) * inv_cell), 0, cols - 1)
		var sy0: int = clampi(int((p.y - sep_r - org.y) * inv_cell), 0, rows - 1)
		var sy1: int = clampi(int((p.y + sep_r - org.y) * inv_cell), 0, rows - 1)
		for cy: int in range(sy0, sy1 + 1):
			for cx: int in range(sx0, sx1 + 1):
				var c: int = cy * cols + cx
				for k: int in range(cs[c], cs[c + 1]):
					var j: int = sorted[k]
					if j == i or j >= count:
						continue
					var away: Vector2 = p - snap[j]
					var dist2: float = away.length_squared()
					if dist2 >= sep_r * sep_r:
						continue
					if dist2 < 0.000001:
						push += Vector2.RIGHT.rotated(float(i) * 2.399)
					else:
						var dist: float = sqrt(dist2)
						push += (away / dist) * ((sep_r - dist) / sep_r)
		push = push.limit_length(SEPARATION_MAX)
		var v: Vector2 = desired + push * _speed_of[i] * d.separation_weight
		p = _clamp_to_world(p + v * step_dt)
		positions[i] = p
		velocities[i] = v
		if can_hit_player and _drawn_position(i).distance_to(player_pos) <= radius_of[i] + player_hurt_radius:
			player.call(&"take_hit", _contact_damage(i, d), &"contact")
	Prof.stop(&"inimigos_mover_separar", t_move)


## Dano de contato: forte durante o dash quando o tipo define dash_contact_damage (D-012).
func _contact_damage(i: int, d: EnemyData) -> int:
	if state[i] == EnemyBehavior.STATE_DASH and d.dash_contact_damage > 0:
		return d.dash_contact_damage
	return d.contact_damage


## Dano num slot. Retorna true se matou.
func damage_at(i: int, amount: int) -> bool:
	if i < 0 or i >= count:
		return false
	hp[i] -= amount
	flash_left[i] = FLASH_TIME
	if hp[i] <= 0:
		kill(i)
		return true
	return false


## Morte com recompensa (letra, dissolução): emite enemy_killed.
func kill(i: int) -> void:
	var d: EnemyData = data_of[i]
	var pos: Vector2 = positions[i]
	EventBus.enemy_killed.emit(i, d, pos)
	if champion[i] == 1:
		# Recompensas (vela, tinta) ficam no ChampionRewards; aqui só o evento e o hit-stop.
		EventBus.champion_killed.emit(d, pos)
		if champion_tuning != null:
			EventBus.hitstop_requested.emit(champion_tuning.death_hitstop_ms)
			EventBus.shake_requested.emit(champion_tuning.death_shake, champion_tuning.death_shake_time)
	var b: EnemyBehavior = d.behavior if d.behavior != null else _default_behavior
	b.on_death(self, i)
	_spawn_dissolve(d, pos)
	_remove(i)


## Fim de onda (FR-010): todos se dissolvem, sem recompensa.
func dissolve_all() -> void:
	while count > 0:
		var last: int = count - 1
		_spawn_dissolve(data_of[last], positions[last])
		_remove(last)


# --- EnemyQuery provider -------------------------------------------------------------------

func query_nearest(pos: Vector2, radius: float) -> Vector2:
	var boss_pos: Vector2 = Vector2.INF
	if _boss_live() and boss_target.hurt_center().distance_to(pos) <= radius + boss_target.hurt_radius():
		boss_pos = boss_target.hurt_center()
	if count == 0:
		return boss_pos
	_rebuild_hash_if_dirty()
	var best: int = -1
	var best_d: float = radius * radius
	for j: int in _hash.query_radius(pos, radius + QUERY_PAD):
		if j >= count:
			continue
		var d2: float = positions[j].distance_squared_to(pos)
		if d2 <= best_d:
			best_d = d2
			best = j
	if best >= 0 and (boss_pos == Vector2.INF or best_d <= boss_pos.distance_squared_to(pos)):
		return positions[best]
	return boss_pos


func query_hit(pos: Vector2, radius: float, damage: int) -> bool:
	if _boss_live() and _boss_in_circle(pos, radius):
		_hit_boss(damage)
		return true
	if count == 0:
		return false
	var t0: int = Prof.start()
	var hit: bool = _query_hit(pos, radius, damage)
	Prof.stop(&"projeteis_acerto", t0)
	return hit


func _query_hit(pos: Vector2, radius: float, damage: int) -> bool:
	_rebuild_hash_if_dirty()
	var reach: float = radius + MAX_ENEMY_RADIUS + QUERY_PAD
	var cs: PackedInt32Array = _hash.cell_start()
	var sorted: PackedInt32Array = _hash.sorted_slots()
	var cols: int = _hash.cols()
	var rows: int = _hash.rows()
	var inv_cell: float = 1.0 / _hash.cell_size()
	var org: Vector2 = _hash.origin()
	var x0: int = clampi(int((pos.x - reach - org.x) * inv_cell), 0, cols - 1)
	var x1: int = clampi(int((pos.x + reach - org.x) * inv_cell), 0, cols - 1)
	var y0: int = clampi(int((pos.y - reach - org.y) * inv_cell), 0, rows - 1)
	var y1: int = clampi(int((pos.y + reach - org.y) * inv_cell), 0, rows - 1)
	for cy: int in range(y0, y1 + 1):
		for cx: int in range(x0, x1 + 1):
			var c: int = cy * cols + cx
			for k: int in range(cs[c], cs[c + 1]):
				var j: int = sorted[k]
				if j >= count:
					continue
				var r: float = radius + radius_of[j]
				if positions[j].distance_squared_to(pos) <= r * r:
					damage_at(j, damage)
					return true
	return false


## Dano em todos os inimigos cujo círculo toca o segmento origin→origin+dir*length com largura
## `width`. Retorna quantos acertou. Aplica do maior slot para o menor (seguro com swap-remove).
func damage_line(origin: Vector2, dir: Vector2, length: float, width: float, damage: int) -> int:
	var d: Vector2 = dir.normalized()
	if _boss_live():
		var rel_b: Vector2 = boss_target.hurt_center() - origin
		var along_b: float = rel_b.dot(d)
		var rb: float = boss_target.hurt_radius()
		if along_b >= -rb and along_b <= length + rb and absf(rel_b.cross(d)) <= width / 2.0 + rb:
			_hit_boss(damage)
	var hits := PackedInt32Array()
	for i: int in count:
		var rel: Vector2 = positions[i] - origin
		var along: float = rel.dot(d)
		var r: float = radius_of[i]
		if along < -r or along > length + r:
			continue
		if absf(rel.cross(d)) <= width / 2.0 + r:
			hits.append(i)
	_damage_descending(hits, damage)
	return hits.size()


## Dano em todos os inimigos a até `radius` de `center`. Retorna quantos acertou.
func damage_in_radius(center: Vector2, radius: float, damage: int) -> int:
	if _boss_live() and _boss_in_circle(center, radius):
		_hit_boss(damage)
	var hits := _slots_in_radius(center, radius)
	_damage_descending(hits, damage)
	return hits.size()


## Dano nos inimigos que tocam a cruz (+) centrada em `center`, com braços de `arm` px.
func damage_cross(center: Vector2, arm: float, width: float, damage: int) -> int:
	if _boss_live() and _boss_on_cross(center, 0.0, arm, width):
		_hit_boss(damage)
	var hits := PackedInt32Array()
	for i: int in count:
		var rel: Vector2 = positions[i] - center
		var reach: float = width / 2.0 + radius_of[i]
		var on_h: bool = absf(rel.y) <= reach and absf(rel.x) <= arm + radius_of[i]
		var on_v: bool = absf(rel.x) <= reach and absf(rel.y) <= arm + radius_of[i]
		if on_h or on_v:
			hits.append(i)
	_damage_descending(hits, damage)
	return hits.size()


## Toque (ANGELUS, SPIRITUS): fere quem está no raio e ainda não foi tocado nos últimos
## `cooldown` s. Chamado todo tick: nada "pula" entre um toque e outro. Retorna quantos feriu.
func damage_touch(center: Vector2, radius: float, damage: int, cooldown: float) -> int:
	if _boss_live() and _boss_in_circle(center, radius) and _boss_touch_ready <= clock:
		_boss_touch_ready = clock + cooldown
		_hit_boss(damage)
	var hits := PackedInt32Array()
	for i: int in _slots_in_radius(center, radius):
		if touch_ready[i] <= clock:
			touch_ready[i] = clock + cooldown
			hits.append(i)
	_damage_descending(hits, damage)
	return hits.size()


## Cruz girada de `angle` rad em torno de `center` (MARTYRIUM). Retorna quantos acertou.
func damage_cross_rotated(center: Vector2, angle: float, arm: float, width: float, damage: int) -> int:
	if _boss_live() and _boss_on_cross(center, angle, arm, width):
		_hit_boss(damage)
	var hits := PackedInt32Array()
	for i: int in count:
		var rel: Vector2 = (positions[i] - center).rotated(-angle)
		var reach: float = width / 2.0 + radius_of[i]
		var on_h: bool = absf(rel.y) <= reach and absf(rel.x) <= arm + radius_of[i]
		var on_v: bool = absf(rel.x) <= reach and absf(rel.y) <= arm + radius_of[i]
		if on_h or on_v:
			hits.append(i)
	_damage_descending(hits, damage)
	return hits.size()


## Atordoa e empurra para longe de `center` os inimigos no raio (PAX). Retorna quantos.
func stun_in_radius(center: Vector2, radius: float, stun: float, knockback: float) -> int:
	var hits := _slots_in_radius(center, radius)
	for i: int in hits:
		stun_left[i] = maxf(stun_left[i], stun)
		var away: Vector2 = positions[i] - center
		if away.is_zero_approx():
			away = Vector2.RIGHT.rotated(float(i) * 2.399)
		positions[i] = _clamp_to_world(positions[i] + away.normalized() * knockback)
		prev_positions[i] = positions[i]
	_hash_dirty = true
	return hits.size()


## Deixa lentos os inimigos no raio por `duration` s (AQUA). factor = multiplicador de velocidade.
func slow_in_radius(center: Vector2, radius: float, factor: float, duration: float) -> int:
	var hits := _slots_in_radius(center, radius)
	for i: int in hits:
		slow_factor[i] = minf(slow_factor[i], factor)
		slow_left[i] = maxf(slow_left[i], duration)
	return hits.size()


## CAECITAS: cega os inimigos no raio por `duration` s (vagam; o contato continua). Retorna quantos.
func blind_in_radius(center: Vector2, radius: float, duration: float) -> int:
	var hits := _slots_in_radius(center, radius)
	for i: int in hits:
		blind_left[i] = maxf(blind_left[i], duration)
	return hits.size()


## VAPOR: chamado a cada tick enquanto o escriba está na nuvem; quem está fora dela o perde de
## vista pelos próximos `duration` s.
func hide_player(center: Vector2, radius: float, duration: float) -> void:
	_hide_center = center
	_hide_radius = radius
	_hide_left = duration


func is_player_hidden() -> bool:
	return _hide_left > 0.0


## REQUIEM em lotes: como mortis_step, mas quem morre aqui solta letra com certeza, até
## `drops_left`. Retorna Vector2i(próximo cursor, drops restantes).
func requiem_step(cursor: int, max_ops: int, kill_threshold: int, damage: int, drops_left: int) -> Vector2i:
	var i: int = mini(cursor, count - 1)
	var ops: int = 0
	while i >= 0 and ops < max_ops:
		var dmg: int = hp[i] if hp[i] <= kill_threshold else damage
		if hp[i] <= dmg and drops_left > 0:
			guaranteed_drop[i] = 1
			drops_left -= 1
		damage_at(i, dmg)
		i -= 1
		ops += 1
	return Vector2i(i, drops_left)


## PURGO em lotes (002 FR-208): mata os comuns seja qual for o HP e dá `elite_damage` nos
## campeões (forte contra a massa, fraco contra a elite). Retorna o próximo cursor (-1 = acabou).
func purgo_step(cursor: int, max_ops: int, elite_damage: int) -> int:
	var i: int = mini(cursor, count - 1)
	var ops: int = 0
	while i >= 0 and ops < max_ops:
		damage_at(i, elite_damage if champion[i] == 1 else hp[i])
		i -= 1
		ops += 1
	return i


## DOMINUS em lotes (002 FR-212): atordoa por `stun` s e dá `damage` em todos, do cursor para
## baixo. Retorna o próximo cursor (-1 = acabou).
func stun_damage_step(cursor: int, max_ops: int, stun: float, damage: int) -> int:
	var i: int = mini(cursor, count - 1)
	var ops: int = 0
	while i >= 0 and ops < max_ops:
		stun_left[i] = maxf(stun_left[i], stun)
		damage_at(i, damage)
		i -= 1
		ops += 1
	return i


## Varredura de tela no chefe (006): MORTIS, DOMINUS, MISERERE, PURGO e REQUIEM chamam 1× no
## começo. Só o dano: o chefe nunca morre "por limiar".
func hit_boss_sweep(amount: int) -> void:
	if _boss_live():
		_hit_boss(amount)


## DOMINUS no chefe (o chefe aplica o próprio multiplicador; D-062 3A).
func stun_boss(seconds: float) -> void:
	if _boss_live():
		boss_target.stun(seconds)


func _boss_live() -> bool:
	return boss_target != null and is_instance_valid(boss_target) and boss_target.is_targetable()


func _boss_in_circle(center: Vector2, radius: float) -> bool:
	var r: float = radius + boss_target.hurt_radius()
	return boss_target.hurt_center().distance_squared_to(center) <= r * r


func _boss_on_cross(center: Vector2, angle: float, arm: float, width: float) -> bool:
	var rel: Vector2 = (boss_target.hurt_center() - center).rotated(-angle)
	var rb: float = boss_target.hurt_radius()
	var reach: float = width / 2.0 + rb
	return (absf(rel.y) <= reach and absf(rel.x) <= arm + rb) or (absf(rel.x) <= reach and absf(rel.y) <= arm + rb)


func _hit_boss(amount: int) -> void:
	boss_target.take(amount, DamageSource.tag, DamageSource.cast_id)


## MORTIS em lotes (FR-021): processa até `max_ops` slots, do `cursor` para baixo. Inimigos com
## HP ≤ `kill_threshold` morrem; os outros levam `damage`. Retorna o próximo cursor (-1 = acabou).
## Descer os índices é seguro com o swap-remove.
func mortis_step(cursor: int, max_ops: int, kill_threshold: int, damage: int) -> int:
	var i: int = mini(cursor, count - 1)
	var ops: int = 0
	while i >= 0 and ops < max_ops:
		if hp[i] <= kill_threshold:
			damage_at(i, hp[i])
		else:
			damage_at(i, damage)
		i -= 1
		ops += 1
	return i


## Posição interpolada para desenho: o passo de steering vale STEER_STRIDE ticks e é espalhado
## entre eles (atraso de ~1 tick, sem serrilhado).
func render_position(i: int) -> Vector2:
	var age: int = (i + last_tick) % STEER_STRIDE
	var alpha: float = (float(age) + Engine.get_physics_interpolation_fraction()) / STEER_STRIDE
	return prev_positions[i].lerp(positions[i], clampf(alpha, 0.0, 1.0))


## Onde o sprite estará ao fim deste tick (render_position sem a fração do frame). O contato usa
## esta posição, não a lógica, que anda até um passo à frente: sem "golpe fantasma" na investida
## rápida (parecer do animation-agent sobre o STEER_STRIDE 3).
func _drawn_position(i: int) -> Vector2:
	var age: int = (i + last_tick) % STEER_STRIDE
	return prev_positions[i].lerp(positions[i], float(age + 1) / STEER_STRIDE)


## Centro do corpo do jogador (Vector2.INF sem jogador). Para comportamentos.
func player_body() -> Vector2:
	return player.global_position + PLAYER_BODY_OFFSET if player != null else Vector2.INF


## Sistemas vizinhos, procurados por grupo na 1ª vez (os testes podem atribuir direto).
func get_letter_field() -> LetterField:
	if _letter_field == null and is_inside_tree():
		_letter_field = get_tree().get_first_node_in_group(&"letter_field") as LetterField
	return _letter_field


func get_projectiles() -> EnemyProjectileManager:
	if _projectiles == null and is_inside_tree():
		_projectiles = get_tree().get_first_node_in_group(&"enemy_projectiles") as EnemyProjectileManager
	return _projectiles


func get_hazards() -> HazardField:
	if _hazards == null and is_inside_tree():
		_hazards = get_tree().get_first_node_in_group(&"hazards") as HazardField
	return _hazards


## Telegrafias de windup + aura dos campeões (usado pelo EnemyRenderer).
## Aura (ficha 15): 4 partículas BLOOD orbitando por fora do sprite, 1 volta/s.
func draw_telegraphs(canvas: CanvasItem, time: float = 0.0) -> void:
	for i: int in count:
		if champion[i] == 1:
			var r: float = radius_of[i] * 2.0 + 3.0
			var center: Vector2 = render_position(i) + Vector2(0, -radius_of[i])
			for k: int in AURA_PARTICLES:
				var a: float = TAU * (time + float(k) / AURA_PARTICLES)
				canvas.draw_rect(Rect2((center + Vector2.RIGHT.rotated(a) * r).round(), Vector2.ONE), Palette.BLOOD)
		if stun_left[i] > 0.0:
			var head: Vector2 = render_position(i) - Vector2(0, radius_of[i] * 2.0 + CROWN_ABOVE)
			for k: int in CROWN_POINTS:
				var a: float = TAU * (time + float(k) / CROWN_POINTS)
				canvas.draw_rect(Rect2((head + Vector2(cos(a) * CROWN_RADIUS, sin(a))).round(), Vector2.ONE), Palette.GOLD)
		if blind_left[i] > 0.0:
			# Venda CHALK 5×1 com contorno INK na linha dos olhos (CAECITAS).
			var eye: Vector2 = (render_position(i) - Vector2(0, radius_of[i] * BLINDFOLD_Y_MUL)).round()
			canvas.draw_rect(Rect2(eye - Vector2(3, 1), Vector2(7, 3)), Palette.INK)
			canvas.draw_rect(Rect2(eye - Vector2(2, 0), Vector2(5, 1)), Palette.CHALK)
		if state[i] == EnemyBehavior.STATE_WINDUP:
			var d: EnemyData = data_of[i]
			var b: EnemyBehavior = d.behavior if d.behavior != null else _default_behavior
			b.draw_telegraph(self, i, canvas)


# --- internos -------------------------------------------------------------------------------

func _slots_in_radius(center: Vector2, radius: float) -> PackedInt32Array:
	var hits := PackedInt32Array()
	for i: int in count:
		if positions[i].distance_to(center) <= radius + radius_of[i]:
			hits.append(i)
	return hits


func _damage_descending(slots: PackedInt32Array, damage: int) -> void:
	for k: int in range(slots.size() - 1, -1, -1):
		damage_at(slots[k], damage)

func _remove(i: int) -> void:
	var last: int = count - 1
	if i != last:
		positions[i] = positions[last]
		prev_positions[i] = prev_positions[last]
		velocities[i] = velocities[last]
		hp[i] = hp[last]
		flash_left[i] = flash_left[last]
		stun_left[i] = stun_left[last]
		slow_factor[i] = slow_factor[last]
		slow_left[i] = slow_left[last]
		anim_phase[i] = anim_phase[last]
		data_of[i] = data_of[last]
		state[i] = state[last]
		state_timer[i] = state_timer[last]
		aim[i] = aim[last]
		champion[i] = champion[last]
		max_hp_of[i] = max_hp_of[last]
		speed_mul[i] = speed_mul[last]
		carried[i] = carried[last]
		radius_of[i] = radius_of[last]
		behavior_of[i] = behavior_of[last]
		_tick_flag[i] = _tick_flag[last]
		_chase_flag[i] = _chase_flag[last]
		_speed_of[i] = _speed_of[last]
		blind_left[i] = blind_left[last]
		guaranteed_drop[i] = guaranteed_drop[last]
		touch_ready[i] = touch_ready[last]
	data_of[last] = null
	behavior_of[last] = null
	count -= 1
	_hash_dirty = true


func _spawn_dissolve(d: EnemyData, pos: Vector2) -> void:
	if not PoolManager.is_registered(DissolveFx.POOL_KEY):
		return
	# Visual dispensável: sob carga extrema (MORTIS em 300) pula em vez de instanciar.
	var fx := PoolManager.try_acquire(DissolveFx.POOL_KEY) as DissolveFx
	if fx != null:
		fx.start(pos, d.dissolve_size)


func _rebuild_hash() -> void:
	_hash.rebuild(positions, count)
	_hash_dirty = false


func _rebuild_hash_if_dirty() -> void:
	if _hash_dirty:
		_rebuild_hash()


func _clamp_to_world(p: Vector2) -> Vector2:
	return Vector2(
		clampf(p.x, world_rect.position.x, world_rect.end.x),
		clampf(p.y, world_rect.position.y, world_rect.end.y))
