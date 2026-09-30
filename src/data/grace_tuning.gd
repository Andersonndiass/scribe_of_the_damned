class_name GraceTuning
extends Resource
## Números da Graça (016; rules-agent 2026-09-30, D-083). A Graça por inimigo mora em `EnemyData.grace`.

@export_group("Graça")
## Por letra da palavra digitada (LUX 18 … 8 letras 48).
@export var per_letter: float = 6.0
## A 2ª palavra do combo vale × (1 + isto).
@export var combo_bonus: float = 0.5
@export var champion_mul: float = 5.0
## Multiplica toda a Graça durante a luta com o chefe (alavanca se houver pausa demais).
@export var boss_grace_mul: float = 1.0
## O eco do VERBUM vale as letras desta palavra (as 6 de VERBUM), não as da palavra repetida.
@export var echo_word: WordData = preload("res://data/words/verbum.tres")

@export_group("Curva")
## Subir do nível n para o n+1 custa level_base + level_step × (n − 1).
@export var level_base: int = 30
@export var level_step: int = 6
## Se não vazia, substitui a fórmula: custo de cada nível a partir do 1→2 (depois do fim, a fórmula).
@export var level_costs: PackedInt32Array = PackedInt32Array()

@export_group("Selos")
@export var choices: int = 3
## A escolha só vale depois disto (s reais) e com tecla apertada depois que os selos abriram.
@export var pick_guard: float = 0.4
## Invulnerabilidade depois do último selo da fila.
@export var post_pick_iframes: float = 0.5
## Tempos do animation-agent (s reais; docs/reviews/T1600-animation-parecer.md).
@export var announce_time: float = 0.4
@export var stamp_time: float = 0.4
## Lista explícita (o build web não lista pastas).
@export var blessings: Array[BlessingData] = []
## Reserva quando todas as bênçãos estão no teto.
@export var fallback: BlessingData
## Tinta dada pela reserva quando as velas já estão cheias.
@export var fallback_ink: int = 3


## Custo para subir do nível `level` para o seguinte.
func cost(level: int) -> int:
	var i: int = level - 1
	if i >= 0 and i < level_costs.size():
		return level_costs[i]
	return level_base + level_step * maxi(0, level - 1)


## "" se os dados fazem sentido; senão, o motivo.
func validate() -> String:
	if per_letter <= 0.0 or champion_mul < 1.0 or level_base <= 0 or level_step < 0:
		return "números da Graça inválidos"
	if choices < 1 or choices > 3:
		return "choices fora de 1..3"
	if blessings.is_empty() or fallback == null:
		return "sem bênçãos ou sem reserva"
	var ids: Dictionary = {}
	for b: BlessingData in blessings:
		if b == null or b.id == &"" or ids.has(b.id):
			return "bênção vazia ou repetida"
		ids[b.id] = true
		if b.stat == &"" and b.heal_candles <= 0:
			return "bênção %s não faz nada" % b.id
	for i: int in range(1, level_costs.size()):
		if level_costs[i] <= 0:
			return "custo de nível inválido"
	return ""
