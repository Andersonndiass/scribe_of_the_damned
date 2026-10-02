extends GutTest
## 010 (D-101; T1000): desbloqueio por capítulo, heresias sobrevividas e Grimório; latch; anúncio.

func before_each() -> void:
	Progress.reset()


func after_each() -> void:
	Progress.reset()
	GameState.run_counts = false


func test_anselmo_is_free_and_others_locked() -> void:
	assert_true(Progress.is_unlocked(&"anselmo"))
	assert_false(Progress.is_unlocked(&"hildegarda"))


func test_chapter_win_unlocks_hildegarda_once() -> void:
	Progress.chapters_won.append(1)
	Progress.evaluate(true)
	assert_true(Progress.is_unlocked(&"hildegarda"))
	assert_has(Progress.new_this_run(), "hildegarda")
	assert_has(Progress.pending_announcements(), "hildegarda")
	Progress.mark_announced(&"hildegarda")
	assert_does_not_have(Progress.pending_announcements(), "hildegarda")


func test_heresies_progress_and_unlock() -> void:
	var tome: PlayerData = Progress.ROSTER.by_id(&"tome")
	Progress.heresies_survived = 4
	assert_eq(Progress.progress_of(tome), Vector2i(4, 10))
	Progress.heresies_survived = 10
	Progress.evaluate(true)
	assert_true(Progress.is_unlocked(&"tome"))


func test_heresy_survived_needs_the_window_without_losing_a_candle() -> void:
	GameState.run_counts = true
	EventBus.heresy_committed.emit(Vector2.ZERO)
	EventBus.player_damaged.emit(1, 2)
	await wait_seconds(3.2)
	assert_eq(Progress.heresies_survived, 0, "perdeu vela na janela: não conta")
	EventBus.heresy_committed.emit(Vector2.ZERO)
	await wait_seconds(3.2)
	assert_eq(Progress.heresies_survived, 1)


func test_debug_unlock_all_is_memory_only() -> void:
	Progress.debug_all = true
	assert_true(Progress.is_unlocked(&"beda"))
	assert_true(Progress.unlocked.is_empty(), "não grava")
