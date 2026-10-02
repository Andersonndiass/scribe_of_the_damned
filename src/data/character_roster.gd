class_name CharacterRoster
extends Resource
## Os escribas jogáveis (010; mechanics-agent), na ordem dos medalhões. O 1º é livre (Anselmo).

@export var characters: Array[PlayerData] = []


func by_id(cid: StringName) -> PlayerData:
	for c: PlayerData in characters:
		if c.id == cid:
			return c
	return null


func default() -> PlayerData:
	return characters[0] if not characters.is_empty() else null


func validate() -> String:
	var seen := {}
	for i: int in characters.size():
		var c: PlayerData = characters[i]
		if c == null or c.id == &"" or seen.has(c.id):
			return "roster: escriba sem id ou repetido"
		seen[c.id] = true
		if i == 0 and c.unlock != null:
			return "roster: o 1º precisa ser livre"
		if c.unlock != null and c.unlock.validate() != "":
			return "%s: %s" % [c.id, c.unlock.validate()]
		if c.start_weapon == null:
			return "%s: sem arma inicial" % c.id
	return ""
