extends GutTest
## Closes em camadas (feedback do autor: sprites separados, juntados na cena): cada rosto é uma pilha
## de camadas; trocar a expressão troca só as camadas de expressão; o CloseView monta a pilha na cena.

func test_face_is_a_stack_of_layers() -> void:
	var tex: Array[Texture2D] = CutsceneCloses.layers("anselmo", "scared")
	assert_eq(tex.size(), CutsceneCloses.BASE_LAYERS.size() + CutsceneCloses.EXPRESSION_LAYERS.size())
	for t: Texture2D in tex:
		if t != null:
			assert_eq(t.get_width(), CutsceneCloses.SIZE)


func test_expression_swaps_only_expression_layers() -> void:
	var a: Array[Texture2D] = CutsceneCloses.layers("anselmo", "scared")
	var b: Array[Texture2D] = CutsceneCloses.layers("anselmo", "determined")
	var base_n: int = CutsceneCloses.BASE_LAYERS.size()
	for i: int in base_n:
		assert_same(a[i], b[i], "camada de base %s é a mesma" % CutsceneCloses.BASE_LAYERS[i])
	assert_ne(a[base_n], b[base_n], "os olhos mudam")


func test_close_view_stacks_the_layers_in_the_scene() -> void:
	var view := CloseView.new()
	add_child_autofree(view)
	view.show_close("abbot_ghost", "smiling")
	assert_true(view.visible)
	assert_gt(view.layer_count(), 5, "fundo, roupa, rosto, barba, contorno e expressão")
	view.show_close("", "")
	assert_false(view.visible)
