# 017 — Arsenal sagrado: tarefas

> Ordem do mechanics-agent (T1700). Números: `docs/reviews/T1700-rules-parecer.md`; arte: `T1700-design-parecer.md`; tempo: `T1700-animation-parecer.md`. Cada fase termina com GUT + export web + commit. Agentes: tarefas simples com Sonnet, difíceis com Opus.

## Fase 1 — Inventário e Pena (sem mudar o que se sente)
- ✅ **T1701** Autoload `TimeScale` (base × fatores por dono; só ele escreve `Engine.time_scale`); `Hitstop` migrado; `reset()` nas Overlays, no ScreenRouter, na sonda e nos testes.
- ✅ **T1702** Contextos de tecla no `Settings` (`play`, `seals`, `letter_menu`, `shop`); ações `weapon_1`, `weapon_2`.
- ✅ **T1703** `WeaponData` / `WeaponLevelData` / `ArsenalTuning` + validação.
- ✅ **T1704** `Loadout` / `WeaponSlot` em `GameState` (zera no `start_run`).
- ✅ **T1705** `Arsenal` + `BurstWeapon` substituem o AutoAttack; `pen.tres` (nível 1 = ataque de hoje); `PlayerData.start_weapon`.
- ✅ **T1706** `weapon_interval_mul` (Pena de Ganso em todas as armas).
- ✅ **T1707** `WeaponBar` no HUD (canto de baixo à esquerda).
- ✅ **T1708** Troca mecânica nos testes (`auto_attack` → `arsenal`) + debug `?weapons=`.
- ✅ **T1709** Sonda: paridade da Pena com a mesma seed.

**Checkpoint 017-A:** o jogo se sente igual, agora com o inventário. ✅ (2026-09-30; GUT 486/486; T1709: paridade da Pena provada em `test_burst_weapon` — mesma cadência, alvo e dano do AutoAttack; a sonda não tem seed, então a paridade dela é informal)

## Fase 2 — Bíblia e Crucifixo
- ✅ **T1710** `ZoneShape` extraída de `KillZone`.
- ✅ **T1711** `WeaponZones` (não letal) + canal `weapon_touch_ready` no passe das zonas.
- ✅ **T1712** `SpatialHash.query_segment`.
- ✅ **T1713** `Aim.direction` comum (Caster, Bíblia, Aspersório).
- ✅ **T1714** `BeamWeapon` + `bible.tres` + raio por Bresenham.
- ✅ **T1715** Pierce/kind no PlayerProjectileManager + `crucifix.tres` (projétil que atravessa até 8, 360 px/s, congela 50 ms; D-088).
- ✅ **T1716** `?stress=bible` (SC-1703) + sonda `weapons`/`swap`.
- **T1717** **Playtest do autor** (SC-1705).

**Checkpoint 017-B:** Bíblia e Crucifixo jogáveis; o autor testa. (2026-09-30: jogáveis, GUT 500/500; stress desktop com a Bíblia 60 FPS, p95 56,7; SC-1703 no Chrome **não medido** — o Chrome do Claude não alcançou o servidor local; sonda onda 1 god: Pena 52, Bíblia 66, Crucifixo 66, as duas com troca 67 mortes/min. Falta o playtest do autor.)

## Fase 3 — Menu de escolha da letra
- ✅ **T1718** `LetterOfferRoll` (1 garantida + 2 sorteadas, distintas).
- ✅ **T1719** `LetterMenu` (FSM, fila, relógio real, câmera lenta) + `LetterMenuTuning`.
- ✅ **T1720** `LetterMenuView` (acima do escriba; setas, Espaço, clique; barra; **sem anel nas letras úteis — D-087 item 4**).
- ✅ **T1721** Guardas: GraceFlow, Main (loja), Caster, movimento.
- ✅ **T1722** Sai o chão: pool Letter, ímã de letras, marcação por clique, campos do DropTuning, sinais.
- ✅ **T1723** Traça nova.
- ✅ **T1724** Purge novo.
- ✅ **T1725** LetterSafety por oferta.
- ✅ **T1726** Áudio (mapa de sinais).
- ✅ **T1727** Testes da Fase 3.
- ✅ **T1728** Sonda `letters`/`react` + linha LETTERS.

**Checkpoint 017-C:** ✅ 2026-09-30 — menu da letra no lugar das letras do chão (D-090); GUT 504/504. Sonda onda 1: o menu abre e a sonda conjura; ~2 menus/min com a chance normal (alvo 5–6,5) → passada de ritmo. Ficou simples: o voo da letra até o atril.

## Fase 4 — Selos, loja e ímã reverso
- **T1729** `SealOption` / `SealPool` + pesos.
- **T1730** `GraceSeals` por tipo (nível de arma sem GOLD).
- **T1731** `RunUpgrade.apply_option`.
- **T1732** Estante Nova e Tinteiro Duplo viram bênção; sai a Pedra-Ímã; Escapulário.
- **T1733** Loja: tipos weapon/passive, exclui o que já tem, vaga de arma garantida, confirmação de troca.
- **T1734** `RepulseData` + `RepulseAura` + `repulse_pulsed`.
- **T1735** Testes da Fase 4.

## Fase 5 — Rosário, Turíbulo, Aspersório
- **T1736** `OrbitWeapon` + Rosário.
- **T1737** `SwingTrailWeapon` + Turíbulo.
- **T1738** `FanWeapon` + Aspersório.
- **T1739** `?stress=arsenal`.

## Fase 6 — Palavras ultimate, ritmo e fechamento
- **T1740** Palavras ×1,5 área / ×2,5 dano; `word_feel` (hit-stop 100 ms, shake, flash); filtro do chefe 250/500; `champion_strike_frac` 0,5; letras por onda; Graça nova.
- **T1741** SC-001/1703 (Chrome alternado).
- **T1742** Sonda por arma e por onda (SC-1704) + parecer do rules-agent.
- **T1743** Docs: art bible, FEATURES, CLAUDE.md, DECISIONS.
