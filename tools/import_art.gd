extends SceneTree
## Converte uma imagem para a arte do jogo (D-074): tamanho do asset + as 9 cores, com pontilhado.
## Uso:
##   godot --headless --path . -s tools/import_art.gd -- in=C:/caminho/rosto.png \
##       out=res://assets/cutscenes/closes/anselmo_scared.png size=192x192 fit=cover dither=fs bg=parchment_old
## Parâmetros: in (obrigatório), out (obrigatório), size=LxA (obrigatório), fit=cover|contain|stretch
## (padrão cover), dither=fs|bayer|none (padrão fs), bg=<token> (fundo opaco; sem bg = transparente),
## alpha=0.5 (corte de transparência). Depois rode o import do Godot para o jogo enxergar o arquivo.


func _initialize() -> void:
	var args: Dictionary = {}
	for a: String in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	for need: String in ["in", "out", "size"]:
		if not args.has(need):
			printerr("import_art: falta %s= (veja o topo do script)" % need)
			quit(1)
			return
	var src := Image.load_from_file(ProjectSettings.globalize_path(args["in"]))
	if src == null or src.is_empty():
		printerr("import_art: não abri %s" % args["in"])
		quit(1)
		return
	var dims: PackedStringArray = str(args["size"]).to_lower().split("x")
	var size := Vector2i(int(dims[0]), int(dims[1]))
	var out: Image = ArtQuantizer.to_game_art(src, size, args.get("fit", "cover"), args.get("dither", "fs"),
		args.get("bg", ""), float(args.get("alpha", "0.5")))
	var out_path: String = ProjectSettings.globalize_path(args["out"])
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var err: int = out.save_png(out_path)
	if err != OK:
		printerr("import_art: erro %d ao salvar %s" % [err, out_path])
		quit(1)
		return
	print("import_art: %s (%dx%d, %s, %s)" % [args["out"], size.x, size.y, args.get("fit", "cover"), args.get("dither", "fs")])
	quit(0)
