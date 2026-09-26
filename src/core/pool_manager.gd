extends Node
## Pools de nós reutilizáveis (plan §4.5, Princípio V). Autoload "PoolManager".
## Nós liberados ficam na árvore, invisíveis e sem processamento; nunca são removidos.
## Métodos opcionais nos nós pooled: _on_acquire() e _on_release().

## Total de instantiate() feitos pelo PoolManager. Durante uma onda não pode mudar (SC-002).
var instantiate_count: int = 0

var _scenes: Dictionary[StringName, PackedScene] = {}
var _parents: Dictionary[StringName, Node] = {}
var _free: Dictionary[StringName, Array] = {}
var _key_of: Dictionary[int, StringName] = {}


## Registra um pool e cria `prewarm` nós de antemão sob `parent`.
func register(key: StringName, scene: PackedScene, prewarm: int, parent: Node) -> void:
	_scenes[key] = scene
	_parents[key] = parent
	if not _free.has(key):
		_free[key] = []
	for i: int in prewarm:
		var node: Node = _create(key)
		_deactivate(node)
		(_free[key] as Array).append(node)


func is_registered(key: StringName) -> bool:
	return _scenes.has(key)


## Pega um nó livre do pool (cria um novo só se o pool esgotar, e isso conta no instantiate_count).
func acquire(key: StringName) -> Node:
	assert(_scenes.has(key), "PoolManager: pool não registrado '%s'" % key)
	var free_list: Array = _free[key]
	var node: Node
	if free_list.is_empty():
		push_warning("PoolManager: pool '%s' esgotou; instanciando fora do prewarm" % key)
		node = _create(key)
	else:
		node = free_list.pop_back()
	_activate(node)
	if node.has_method(&"_on_acquire"):
		node.call(&"_on_acquire")
	return node


## Como acquire, mas NUNCA cria: devolve null se o pool esgotou. Para o que é dispensável
## sob carga extrema (efeitos visuais, letras excedentes), preservando o SC-002.
func try_acquire(key: StringName) -> Node:
	assert(_scenes.has(key), "PoolManager: pool não registrado '%s'" % key)
	var free_list: Array = _free[key]
	if free_list.is_empty():
		return null
	var node: Node = free_list.pop_back()
	_activate(node)
	if node.has_method(&"_on_acquire"):
		node.call(&"_on_acquire")
	return node


## Devolve o nó ao pool.
func release(node: Node) -> void:
	var id: int = node.get_instance_id()
	if not _key_of.has(id):
		push_error("PoolManager: nó não pertence a nenhum pool: %s" % node)
		return
	if node.has_method(&"_on_release"):
		node.call(&"_on_release")
	_deactivate(node)
	(_free[_key_of[id]] as Array).append(node)


func free_count(key: StringName) -> int:
	return (_free.get(key, []) as Array).size()


## Esvazia todos os registros (usado entre testes e ao reiniciar a partida).
func clear_all() -> void:
	for key: StringName in _free.keys():
		for node: Node in (_free[key] as Array):
			if is_instance_valid(node):
				node.queue_free()
	_scenes.clear()
	_parents.clear()
	_free.clear()
	_key_of.clear()
	instantiate_count = 0


func _create(key: StringName) -> Node:
	var node: Node = _scenes[key].instantiate()
	instantiate_count += 1
	_key_of[node.get_instance_id()] = key
	_parents[key].add_child(node)
	return node


func _activate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is CanvasItem:
		(node as CanvasItem).visible = true


func _deactivate(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		(node as CanvasItem).visible = false
