extends SceneTree
func _init() -> void:
	var m := EnemyManager.new()
	var p := Node2D.new()
	root.add_child(p)
	p.position = Vector2(150, 180)
	m.player = p
	root.add_child(m)
	var imp: EnemyData = load("res://data/enemies/imp.tres")
	for i: int in 20:
		m.spawn(imp, Vector2(150, 180))
	for f: int in 3:
		m._physics_process(1.0 / 60.0)
		print(f, " ", m.positions.slice(0, 4))
	quit()
