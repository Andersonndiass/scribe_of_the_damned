class_name CutsceneBuilder
extends RefCounted
## Builder JSON → Animation (008 FR-802; constituição IX; R-04). Uma trilha de valor por
## ator+propriedade (caminho `Stage/<camada>/<ator>:<prop>`, relativo ao CutscenePlayer) e uma
## trilha de método com os cues (falas, legendas, sons, marcas): uma chave por quadro chamando
## `_cue(i)`, com `i` = o último cue daquele quadro (o player dispara todos os pendentes até `i`).
## Todo tempo cai no quadro de 60 FPS mais próximo.

## Curva do `ease()` do Godot por easing do roteiro (1 = linear; >1 entra devagar; <1 sai devagar;
## negativo = entra e sai).
const TRANSITIONS: Dictionary = {"linear": 1.0, "in": 2.0, "out": 0.5, "in_out": -2.0, "step": 1.0}
const CUE_METHOD := &"_cue"


class Result:
	var source: CutsceneScript
	var animation: Animation
	## Cues em ordem: {"t", "frame", "kind", "payload"}.
	var cues: Array[Dictionary] = []


static func track_path(s: CutsceneScript, target: String, prop: String) -> NodePath:
	var layer: String = str((s.actors.get(target, {}) as Dictionary).get("layer", "actors"))
	return NodePath("Stage/%s/%s:%s" % [layer, target, prop])


static func snap(t: float) -> float:
	return CutsceneScript.frame_of(t) / CutsceneScript.FPS


static func build(s: CutsceneScript) -> Result:
	var r := Result.new()
	r.source = s
	var anim := Animation.new()
	anim.length = s.duration
	anim.step = 1.0 / CutsceneScript.FPS
	r.animation = anim
	_build_value_tracks(s, anim)
	r.cues = _collect_cues(s)
	_build_cue_track(r.cues, anim)
	return r


static func _build_value_tracks(s: CutsceneScript, anim: Animation) -> void:
	var tracks: Dictionary = {}  # "alvo:prop" -> índice
	for e: Dictionary in s.events:
		if e.get("type") != "key":
			continue
		var target: String = e["target"]
		var prop: String = e["prop"]
		var name: String = target + ":" + prop
		if not tracks.has(name):
			var tr_idx: int = anim.add_track(Animation.TYPE_VALUE)
			anim.track_set_path(tr_idx, track_path(s, target, prop))
			anim.value_track_set_update_mode(tr_idx, Animation.UPDATE_CONTINUOUS)
			var init: Dictionary = (s.actors[target] as Dictionary).get("init", {})
			if init.has(prop) and CutsceneScript.frame_of(float(e["t"])) > 0:
				anim.track_insert_key(tr_idx, 0.0, CutsceneScript.convert_value(prop, init[prop]))
			tracks[name] = tr_idx
		var idx: int = tracks[name]
		var ease: String = str(e.get("ease", "linear"))
		if ease == "step":
			anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_NEAREST)
		# A curva de uma chave vale do valor dela até a próxima: o easing do roteiro descreve como se
		# CHEGA na chave, então vai na chave anterior.
		var value: Variant = CutsceneScript.convert_value(prop, e["value"])
		var k: int = anim.track_insert_key(idx, snap(float(e["t"])), value)
		if k > 0:
			anim.track_set_key_transition(idx, k - 1, TRANSITIONS.get(ease, 1.0))


static func _collect_cues(s: CutsceneScript) -> Array[Dictionary]:
	var cues: Array[Dictionary] = []
	for e: Dictionary in s.events:
		var t: float = float(e.get("t", 0.0))
		match str(e.get("type")):
			"line":
				cues.append(_cue(t, &"line_start", e))
				cues.append(_cue(float(e["end"]), &"line_end", e))
			"caption":
				cues.append(_cue(t, &"caption_on", e))
				cues.append(_cue(float(e["end"]), &"caption_off", e))
			"sound":
				cues.append(_cue(t, &"sound", e))
			"mark":
				cues.append(_cue(t, &"mark", e))
	cues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["frame"] < b["frame"])
	return cues


static func _cue(t: float, kind: StringName, payload: Dictionary) -> Dictionary:
	return {"t": t, "frame": CutsceneScript.frame_of(t), "kind": kind, "payload": payload}


static func _build_cue_track(cues: Array[Dictionary], anim: Animation) -> void:
	if cues.is_empty():
		return
	var idx: int = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(idx, NodePath("."))
	var last_by_frame: Dictionary = {}
	for i: int in cues.size():
		last_by_frame[cues[i]["frame"]] = i
	for frame: int in last_by_frame:
		anim.track_insert_key(idx, frame / CutsceneScript.FPS, {"method": CUE_METHOD, "args": [last_by_frame[frame]]})
