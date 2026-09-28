class_name AudioEventMap
extends Resource
## Liga eventos do EventBus a sons (009 FR-905). Cada SoundData diz a própria chave (`event`);
## a variante ("word_cast:lux") vale antes da base ("word_cast").

@export var sounds: Array[SoundData] = []

var _by_event: Dictionary[StringName, SoundData] = {}
var _by_id: Dictionary[StringName, SoundData] = {}


func build() -> void:
	_by_event.clear()
	_by_id.clear()
	for s: SoundData in sounds:
		if s == null:
			continue
		_by_event[s.event] = s
		_by_id[s.id] = s


## O som do evento `key` com a variante `variant` (ou o da base), ou null.
func resolve(key: StringName, variant: StringName = &"") -> SoundData:
	if _by_event.is_empty() and not sounds.is_empty():
		build()
	if variant != &"":
		var v: SoundData = _by_event.get(StringName("%s:%s" % [key, variant]), null)
		if v != null:
			return v
	return _by_event.get(key, null)


func by_id(id: StringName) -> SoundData:
	if _by_id.is_empty() and not sounds.is_empty():
		build()
	return _by_id.get(id, null)
