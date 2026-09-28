class_name PlayerBuffs
extends RefCounted
## Buffs do escriba (002 plan: PlayerBuffs no Player). Lógica pura com timers; quem aplica é o
## milagre, quem consulta é o sistema afetado (Player, LetterField, Caster).
##   FIDES: escudo com cargas até ser consumido ou o fim da onda (FR-206).
##   LUMEN: ímã e bônus da letra-alvo multiplicados por um tempo (FR-207).
##   GLORIA: dano e cura dos milagres multiplicados por um tempo (FR-209).
##   SPIRITUS / MISERERE: estado pronto para a Fase 4 (D-046).
## Reconjurar renova o tempo e não acumula.

var shield_charges: int = 0
var lumen_left: float = 0.0
var gloria_left: float = 0.0
var spiritus_left: float = 0.0
var forgive_heresy: bool = false

var _magnet_mul: float = 1.0
var _target_mul: float = 1.0
var _gloria_mul: float = 1.0
var _spiritus_speed: float = 1.0


func apply_fides(charges: int) -> void:
	shield_charges = maxi(shield_charges, charges)


func has_shield() -> bool:
	return shield_charges > 0


## Um golpe chegou: o escudo o absorve inteiro? (consome 1 carga)
func absorb_hit() -> bool:
	if shield_charges <= 0:
		return false
	shield_charges -= 1
	return true


func apply_lumen(duration: float, magnet: float, target: float) -> void:
	lumen_left = duration
	_magnet_mul = magnet
	_target_mul = target


func apply_gloria(duration: float, mul: float) -> void:
	gloria_left = duration
	_gloria_mul = mul


func apply_spiritus(duration: float, speed: float) -> void:
	spiritus_left = duration
	_spiritus_speed = speed


func grant_forgiveness() -> void:
	forgive_heresy = true


## MISERERE: a próxima heresia é perdoada (uma vez).
func consume_forgiveness() -> bool:
	if not forgive_heresy:
		return false
	forgive_heresy = false
	return true


func magnet_mul() -> float:
	return _magnet_mul if lumen_left > 0.0 else 1.0


func target_weight_mul() -> float:
	return _target_mul if lumen_left > 0.0 else 1.0


func damage_mul() -> float:
	return _gloria_mul if gloria_left > 0.0 else 1.0


func speed_mul() -> float:
	return _spiritus_speed if spiritus_left > 0.0 else 1.0


## SPIRITUS: atravessa corpos (contato não fere); projéteis e heresia ainda doem (D-046).
func is_intangible() -> bool:
	return spiritus_left > 0.0


func tick(delta: float) -> void:
	lumen_left = maxf(0.0, lumen_left - delta)
	gloria_left = maxf(0.0, gloria_left - delta)
	spiritus_left = maxf(0.0, spiritus_left - delta)


## Fim de onda: o escudo da FIDES acaba (FR-206).
func on_wave_ended() -> void:
	shield_charges = 0
