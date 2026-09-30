extends GutTest
## T604 Palavras e ataque automático ferem o chefe (006 FR-604, FR-606; mechanics-agent):
## alvo extra no EnemyManager, origem pelo DamageSource, varreduras 1× por conjuração,
## stun só do DOMINUS, sem lentidão/cegueira/empurrão.

const MAIN_SCENE := preload("res://src/main/main.tscn")


class FakeBoss:
	extends BossHurtbox
	var hits: Array[Dictionary] = []
	var stuns: Array[float] = []
	var radius: float = 20.0

	func hurt_radius() -> float:
		return radius

	func is_targetable() -> bool:
		return true

	func take(amount: int, tag: StringName, cast_id: int) -> void:
		hits.append({"amount": amount, "tag": tag, "cast": cast_id})

	func stun(seconds: float) -> void:
		stuns.append(seconds)

	func tags() -> Array[StringName]:
		var out: Array[StringName] = []
		for h: Dictionary in hits:
			out.append(h["tag"])
		return out


var _main: Node2D
var _player: Player
var _field: LetterField
var _caster: Caster
var _manager: EnemyManager
var _boss: FakeBoss


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child_autofree(_main)
	_main.get_node("WaveDirector").stop()
	_player = _main.get_node("World/Player")
	_player.auto_attack.enabled = false
	_player.vitals.iframes_left = 1.0e6
	_player.facing = Vector2.RIGHT
	_field = _main.get_node("World/LetterField")
	_field.atril.set_capacity(8)
	_caster = _main.get_node("Caster")
	_manager = _main.get_node("World/EnemyManager")
	_manager.dissolve_all()
	_boss = FakeBoss.new()
	_main.add_child(_boss)
	_boss.global_position = _player.global_position + Caster.PEN_OFFSET + Vector2(80, 0)
	_manager.boss_target = _boss
	for word: WordData in _field.lexicon_data.words:
		if word.requires_unlock:
			GameState.unlock_word(word)


func after_each() -> void:
	GameState.unlocked_words.clear()
	TimeScale.reset()


func _cast(word: String) -> void:
	for ch: String in word:
		_field.collect(ch, false)
	assert_true(_caster.cast(), word)


func test_lux_hits_the_boss_with_its_tag_and_a_cast_id() -> void:
	_cast("LUX")
	assert_eq(_boss.tags(), [&"lux"] as Array[StringName])
	assert_gt(int(_boss.hits[0]["cast"]), 0, "cada conjuração tem um id")


func test_two_casts_have_different_ids() -> void:
	_cast("LUX")
	_cast("LUX")
	assert_ne(_boss.hits[0]["cast"], _boss.hits[1]["cast"])


func test_screen_sweeps_hit_once_even_without_enemies() -> void:
	_cast("MORTIS")
	await wait_physics_frames(40)
	assert_eq(_boss.tags().count(&"mortis"), 1, "1× por conjuração, mesmo sem inimigos (F1)")


func test_dominus_stuns_the_boss() -> void:
	_cast("DOMINUS")
	assert_eq(_boss.stuns.size(), 1)
	assert_has(_boss.tags(), &"dominus")


func test_purgo_hits_with_literal_elite_damage() -> void:
	_cast("PURGO")
	var purgo: WordData = null
	for w: WordData in _field.lexicon_data.words:
		if w.id == &"purgo":
			purgo = w
	assert_eq(int(_boss.hits[0]["amount"]), int(purgo.damage), "10 literais (D-055)")
	assert_eq(_boss.hits[0]["tag"], &"purgo")


func test_pax_does_not_stun_the_boss() -> void:
	_boss.global_position = _player.global_position + Caster.PEN_OFFSET + Vector2(30, 0)
	_cast("PAX")
	assert_eq(_boss.stuns.size(), 0, "só o DOMINUS atordoa o chefe")


func test_auto_attack_aims_and_hits_the_boss_alone() -> void:
	_player.auto_attack.enabled = true
	await wait_seconds(2.0)
	assert_has(_boss.tags(), &"auto", "o automático mira o chefe mesmo sem inimigos")


func test_ignis_ticks_share_one_cast_id() -> void:
	_boss.global_position = _player.global_position + Caster.PEN_OFFSET + Vector2(20, 0)
	_cast("IGNIS")
	await wait_seconds(1.0)
	var casts: Array = []
	for h: Dictionary in _boss.hits:
		if h["tag"] == &"ignis" and not casts.has(h["cast"]):
			casts.append(h["cast"])
	assert_eq(casts.size(), 1, "os ticks somam na mesma conjuração (teto)")
	assert_gt(_boss.tags().count(&"ignis"), 1)
