class_name WeaponZone
extends ZoneShape
## Zona de uma arma (017 T1711; mechanics-agent T1700): fere, mas nunca mata o comum na hora (isso
## é só das palavras, D-084). Cada inimigo tem o próprio relógio: leva `damage` no máximo a cada
## `interval` s (rules-agent: checado todo tick, então 0,33 s vale 0,33 s). `max_targets` > 0 fere só
## os N mais próximos da origem ao longo da forma (Bíblia: 2; o chefe ocupa uma vaga). Contra
## campeão e chefe o dano vale × `precision_mul`, com a fração guardada por alvo (1,5 → 1, 2, 1, 2…).
## O EnemyManager aplica no mesmo passe das zonas letais; o dono (a arma) move a forma a cada tick.

## Chave do chefe nos relógios (os inimigos usam o uid, sempre ≥ 1).
const BOSS_KEY := -1
## Acima disto, os relógios vencidos são podados (inimigos mortos não voltam).
const PRUNE_AT := 256

var live: bool = false
var damage: int = 1
var interval: float = 0.5
var max_targets: int = 0
var precision_mul: float = 1.0
## Marca do dano no chefe (DamageSource).
var tag: StringName = &"auto"
## uid → próximo instante (EnemyManager.clock) em que pode ferir de novo.
var _ready_at: Dictionary[int, float] = {}
## uid → fração de dano guardada (só campeão e chefe).
var _carry: Dictionary[int, float] = {}
## Quantos acertos esta zona já deu (testes, sonda).
var hits: int = 0
## Lentidão no acerto (D-098; 1 = nenhuma); o EnemyManager aplica em quem sobreviveu.
var slow_factor: float = 1.0
var slow_time: float = 0.0
## Arma dona (som do acerto, `EventBus.weapon_hit`); vazio = sem som.
var weapon_id: StringName = &""


func open(p_shape: Shape) -> void:
	shape = p_shape
	live = true
	_ready_at.clear()
	_carry.clear()


func close() -> void:
	live = false
	_ready_at.clear()
	_carry.clear()


## O alvo `key` pode levar dano agora?
func ready_for(key: int, clock: float) -> bool:
	return _ready_at.get(key, -INF) <= clock


## Marca o toque em `key` e devolve o dano (com a precisão, se `elite`).
func take_hit(key: int, clock: float, elite: bool) -> int:
	if _ready_at.size() > PRUNE_AT:
		_prune(clock)
	_ready_at[key] = clock + interval
	hits += 1
	if weapon_id != &"":
		EventBus.weapon_hit.emit(weapon_id)
	if not elite or is_equal_approx(precision_mul, 1.0):
		return damage
	var total: float = _carry.get(key, 0.0) + float(damage) * precision_mul
	var whole: int = floori(total)
	_carry[key] = total - float(whole)
	return whole


func _prune(clock: float) -> void:
	for key: int in _ready_at.keys():
		if _ready_at[key] < clock:
			_ready_at.erase(key)
			_carry.erase(key)
