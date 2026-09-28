class_name ComboData
extends WordData
## Um combo entre duas palavras base (002 FR-202, FR-203, data-model §3). Herda os parâmetros de
## milagre do WordData; é pooled com a chave = id. A ordem de word_a/word_b não importa.
## `power` multiplica SÓ o dano (e a cura); raio, comprimento, duração, stun e limiar são literais
## (parecer do rules-agent, D-051).

@export_group("Combo")
@export var word_a: WordData
@export var word_b: WordData
## Nome em latim na tela (D-045): VAPOR, FLAMMA, CAECITAS, MARTYRIUM, REQUIEM.
@export var display_name: String = ""
## Vapor: fora da nuvem, os inimigos perdem o escriba de vista (0 = não o veem).
@export var stealth_aggro_mul: float = 1.0
## Chama Radiante: dano do raio (o `damage` herdado é o do fogo).
@export var burst_damage: float = 0.0


## O combo herda as marcas das duas palavras (FR-202c): conta como `id` se uma delas for `id`.
func has_word_id(id_: StringName) -> bool:
	return (word_a != null and word_a.id == id_) or (word_b != null and word_b.id == id_)
