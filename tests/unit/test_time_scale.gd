extends GutTest
## T1701 TimeScale (017): dono único do Engine.time_scale — base × fatores; o hit-stop volta para a
## câmera lenta (não para ×1); reset mantém a base.


func after_each() -> void:
	TimeScale.set_base(1.0)
	TimeScale.reset()


func test_factors_multiply_and_clear_independently() -> void:
	TimeScale.set_factor(&"letter_menu", 0.2)
	assert_almost_eq(Engine.time_scale, 0.2, 0.0001)
	TimeScale.set_factor(&"hitstop", 0.0)
	assert_eq(Engine.time_scale, 0.0, "hit-stop congela")
	TimeScale.clear(&"hitstop")
	assert_almost_eq(Engine.time_scale, 0.2, 0.0001, "volta para a câmera lenta, não para 1")
	TimeScale.clear(&"letter_menu")
	assert_eq(Engine.time_scale, 1.0)


func test_base_survives_reset() -> void:
	TimeScale.set_base(4.0)
	TimeScale.set_factor(&"hitstop", 0.0)
	TimeScale.reset()
	assert_eq(Engine.time_scale, 4.0, "a sonda continua a 4×")


func test_hitstop_uses_the_owner() -> void:
	TimeScale.set_factor(&"letter_menu", 0.2)
	Hitstop.request(30)
	assert_eq(Engine.time_scale, 0.0)
	# Espera pelo relógio real (o 1º quadro pode vir com um delta grande acumulado).
	var until: int = Time.get_ticks_msec() + 100
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
	await get_tree().process_frame
	assert_almost_eq(Engine.time_scale, 0.2, 0.0001, "o hit-stop acabou e a câmera lenta ficou")
