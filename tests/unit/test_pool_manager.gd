extends GutTest
## T012 PoolManager: depois do prewarm, acquire/release não instanciam (base do SC-002).

const KEY := &"test_pooled"

var _parent: Node2D
var _scene: PackedScene


func before_each() -> void:
	PoolManager.clear_all()
	_parent = Node2D.new()
	add_child_autofree(_parent)
	var proto := Node2D.new()
	_scene = PackedScene.new()
	_scene.pack(proto)
	proto.free()


func after_each() -> void:
	PoolManager.clear_all()


func test_prewarm_creates_nodes_once() -> void:
	PoolManager.register(KEY, _scene, 10, _parent)
	assert_eq(PoolManager.instantiate_count, 10)
	assert_eq(PoolManager.free_count(KEY), 10)
	assert_eq(_parent.get_child_count(), 10)


func test_acquire_release_does_not_instantiate() -> void:
	PoolManager.register(KEY, _scene, 5, _parent)
	var before: int = PoolManager.instantiate_count
	for round_i: int in 20:
		var taken: Array[Node] = []
		for i: int in 5:
			taken.append(PoolManager.acquire(KEY))
		for n: Node in taken:
			PoolManager.release(n)
	assert_eq(PoolManager.instantiate_count, before)
	assert_eq(PoolManager.free_count(KEY), 5)


func test_acquired_node_is_active_and_released_is_disabled() -> void:
	PoolManager.register(KEY, _scene, 1, _parent)
	var n := PoolManager.acquire(KEY) as Node2D
	assert_true(n.visible)
	assert_eq(n.process_mode, Node.PROCESS_MODE_INHERIT)
	PoolManager.release(n)
	assert_false(n.visible)
	assert_eq(n.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_true(is_instance_valid(n), "nó liberado continua vivo na árvore")


func test_try_acquire_never_instantiates() -> void:
	PoolManager.register(KEY, _scene, 1, _parent)
	assert_not_null(PoolManager.try_acquire(KEY))
	assert_null(PoolManager.try_acquire(KEY), "esgotado: null em vez de criar")
	assert_eq(PoolManager.instantiate_count, 1)


func test_exhausted_pool_grows_and_counts() -> void:
	PoolManager.register(KEY, _scene, 1, _parent)
	PoolManager.acquire(KEY)
	PoolManager.acquire(KEY)
	assert_eq(PoolManager.instantiate_count, 2, "crescimento fora do prewarm é contado")
