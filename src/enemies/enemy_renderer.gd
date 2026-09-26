class_name EnemyRenderer
extends Node2D
## Desenha os inimigos do EnemyManager com Sprite2D pré-criados, um por slot (T032).
## Os sprites são criados no _ready, antes de qualquer onda (FR-027).
## Só escreve numa propriedade do Sprite2D quando o valor muda: no web cada escrita custa
## (D-043). A posição muda todo frame; textura, material, escala e espelho, raramente.

const ANIM := &"move"
enum Look { NORMAL, FLASH, CHAMPION }

@export var manager: EnemyManager

var _sprites: Array[Sprite2D] = []
var _flash_material: ShaderMaterial
var _outline_material: ShaderMaterial
var _time: float = 0.0
var _last_count: int = 0
var _telegraphs: Node2D
# Último estado escrito em cada sprite.
var _frame_key := PackedInt64Array()
var _look := PackedByteArray()
var _flip := PackedByteArray()


func _ready() -> void:
	y_sort_enabled = true
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = preload("res://assets/shaders/hit_flash.gdshader")
	_flash_material.set_shader_parameter(&"flash_color", Palette.CHALK)
	_flash_material.set_shader_parameter(&"flash_amount", 1.0)
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = preload("res://assets/shaders/outline.gdshader")
	_outline_material.set_shader_parameter(&"outline_color", Palette.BLOOD)
	_telegraphs = Node2D.new()
	_telegraphs.z_index = 1
	_telegraphs.draw.connect(func() -> void: manager.draw_telegraphs(_telegraphs, _time))
	add_child(_telegraphs)
	_frame_key.resize(EnemyManager.CAPACITY)
	_frame_key.fill(-1)
	_look.resize(EnemyManager.CAPACITY)
	_flip.resize(EnemyManager.CAPACITY)
	for i: int in EnemyManager.CAPACITY:
		var s := Sprite2D.new()
		s.centered = false
		s.visible = false
		add_child(s)
		_sprites.append(s)


func _process(delta: float) -> void:
	_time += delta
	var t0: int = Prof.start()
	var n: int = manager.count
	var champ_scale: float = manager.champion_tuning.radius_mul if manager.champion_tuning != null else 1.0
	for i: int in n:
		var d: EnemyData = manager.data_of[i]
		var s: Sprite2D = _sprites[i]
		var frames: SpriteFrames = d.sprite_frames
		var f: int = int((_time + manager.anim_phase[i]) * frames.get_animation_speed(ANIM)) % frames.get_frame_count(ANIM)
		# Chave = (tipo, quadro): o slot pode trocar de tipo no swap-remove.
		var key: int = (d.get_instance_id() << 8) | f
		if _frame_key[i] != key:
			_frame_key[i] = key
			s.texture = frames.get_frame_texture(ANIM, f)
			s.offset = -d.sprite_pivot
		s.position = manager.render_position(i).round()
		var vx: float = manager.velocities[i].x
		if absf(vx) > 1.0:
			var flip: int = 1 if vx < 0.0 else 0
			if _flip[i] != flip:
				_flip[i] = flip
				s.flip_h = flip == 1
		var champ: bool = manager.champion[i] == 1
		var look: int = Look.FLASH if manager.flash_left[i] > 0.0 else (Look.CHAMPION if champ else Look.NORMAL)
		if _look[i] != look or not s.visible:
			_look[i] = look
			s.material = _flash_material if look == Look.FLASH else (_outline_material if champ else null)
			# Placeholder: campeão = 1.5× (a ficha pede redesenho; vem com a arte gerada, D-024).
			s.scale = Vector2.ONE * (champ_scale if champ else 1.0)
			s.visible = true
	for i: int in range(n, _last_count):
		_sprites[i].visible = false
	_last_count = n
	_telegraphs.queue_redraw()
	Prof.stop(&"inimigos_desenho", t0)
