# 006 — Tarefas

## Fase 1 — Framework (lógica)
- ✅ **T600** Resources: `BossData`, `PhaseData`, `AttackData`, `BossDamageFilterData`, `LetterSafetyTuning` + os `.tres` do Asmodeus (números da D-062).
- ✅ **T601** [TEST-FIRST] `test_attack_picker.gd` → `AttackPicker` (pesos, sem 3 iguais, cooldown, distância; SC-602).
- ✅ **T602** [TEST-FIRST] `test_boss_damage_filter.gd` → `BossDamageFilter` (teto por conjuração, limiar da fase + invulnerável, exposição +25%, automático sem teto; SC-603).
- ✅ **T603** [TEST-FIRST] `test_letter_safety.gd` → `LetterSafety` (N letras / T s, cooldown; SC-604).
- ✅ **T604** `DamageSource` + alvo extra no `EnemyManager`: todas as palavras, combos e o automático ferem o chefe; varreduras 1× por conjuração; stun só do DOMINUS (1 s).

**Checkpoint 006-A:** ✅ o framework decide e filtra por teste, sem chefe na tela (2026-09-29; `test_boss_targeting` com chefe falso).

## Fase 2 — Asmodeus
- ✅ **T610** `Boss` + FSM (Enter, Idle, Telegraph, Attack, Recover, Exposed, PhaseShift, Stunned, Dead).
- ✅ **T611** Os 6 ataques (Raio, Swipe, Summon, Raio duplo, Cruz giratória, Rasura) com telegrafia ≥ 600 ms (SC-605). Visual pelo design-agent, tempos pelo animation-agent.
- ✅ **T612** Placeholder BSS_ASMODEUS 64×64 por script (ficha 16).
- ✅ **T613** Fluxo: loja da onda 9 → luta → `chapter_completed`; derrota → Game Over (SC-606, SC-609). HUD da barra de vida. Debug `?boss`.
- ✅ **T614** Integração `test_boss_fight.gd` (fases, ataques por fase, palavras ferem, vitória, derrota).

**Checkpoint 006-B:** ✅ Asmodeus jogável do começo ao fim (2026-09-29; `?boss`; conferido no Chrome).

## Fase 3 — Sensação e fechamento
- **T620** Câmera + `ScreenShake` (golpe forte do chefe, troca de fase, morte do chefe e do campeão); `GameState.shake_enabled`.
- **T621** Sonda: o bot enfrenta o chefe (SC-608, 3–4 min); calibrar o HP com o rules-agent.
- **T622** Stress `?stress=boss` no Chrome (SC-607); GUT, export, `FEATURES.md`, `CLAUDE.md`, `docs/DECISIONS.md`.
