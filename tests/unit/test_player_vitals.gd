extends GutTest
## T023 Velas, i-frames e recuperação parado (FR-003, FR-004, D-010, D-011, D-012).

var _data: PlayerData
var _v: PlayerVitals


func before_each() -> void:
	_data = PlayerData.new()
	_data.start_candles = 3
	_data.max_candles = 8
	_data.iframes = 1.0
	_data.idle_regen_delay = 5.0
	_data.idle_regen_interval = 3.0
	_v = PlayerVitals.new()
	_v.setup(_data)


## Avança em passos de 0.25s (exatos em ponto flutuante). Retorna o total curado.
func _advance(seconds: float, idle: bool) -> int:
	var healed: int = 0
	for i: int in roundi(seconds / 0.25):
		healed += _v.tick(0.25, idle)
	return healed


func test_starts_with_three_candles_and_max_three() -> void:
	assert_eq(_v.candles, 3)
	assert_eq(_v.max_candles, 3)
	assert_eq(_v.cap, 8)


func test_weak_hit_removes_one_and_grants_iframes() -> void:
	assert_eq(_v.damage(1), 1)
	assert_eq(_v.candles, 2)
	assert_true(_v.is_invulnerable())
	assert_eq(_v.damage(1), 0, "durante os i-frames não leva dano")


func test_iframes_last_one_second() -> void:
	_v.damage(1)
	_advance(0.75, false)
	assert_true(_v.is_invulnerable())
	_advance(0.25, false)
	assert_false(_v.is_invulnerable())
	assert_eq(_v.damage(1), 1)


func test_strong_hit_removes_two() -> void:
	assert_eq(_v.damage(2), 2)
	assert_eq(_v.candles, 1)


func test_damage_never_goes_below_zero_and_kills() -> void:
	_v.damage(2)
	_advance(1.0, false)
	assert_eq(_v.damage(2), 1, "só tinha 1 vela")
	assert_false(_v.is_alive())


func test_idle_regen_first_candle_at_delay_plus_interval() -> void:
	_v.damage(1)
	assert_eq(_advance(7.75, true), 0, "antes de 5s + 3s não recupera")
	assert_eq(_advance(0.25, true), 1, "aos 8s recupera 1 vela")
	assert_eq(_v.candles, 3)


func test_idle_regen_continues_every_interval_until_max() -> void:
	_v.raise_max(2)
	_v.damage(1)
	assert_eq(_v.candles, 2)
	assert_eq(_v.max_candles, 5)
	assert_eq(_advance(8.0, true), 1)
	assert_eq(_advance(3.0, true), 1)
	assert_eq(_advance(3.0, true), 1)
	assert_eq(_v.candles, 5)
	assert_eq(_advance(30.0, true), 0, "não passa do máximo atual")


func test_moving_resets_idle_counter() -> void:
	_v.damage(1)
	_advance(6.0, true)
	_advance(0.25, false)
	assert_eq(_advance(7.75, true), 0, "a contagem recomeçou do zero")


func test_cast_resets_idle_counter() -> void:
	_v.damage(1)
	_advance(7.0, true)
	_v.notify_action()
	assert_eq(_advance(7.75, true), 0)


func test_taking_damage_resets_idle_counter() -> void:
	_v.damage(1)
	_advance(7.0, true)
	_v.damage(1)
	assert_eq(_advance(7.75, true), 0)


func test_dead_player_does_not_heal() -> void:
	_v.damage(2)
	_advance(1.0, false)
	_v.damage(2)
	assert_eq(_v.heal(1), 0)
	assert_eq(_advance(20.0, true), 0)


func test_raise_max_respects_cap() -> void:
	assert_eq(_v.raise_max(10), 8)
