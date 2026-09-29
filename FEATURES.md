# Roadmap de Features

> ⚠️ **Status real (2026-09-28):** `000` aprovada; **`001`, `005`, `002` e `003` Complete**; `009` com a Fase 1 pronta (áudio em silêncio). As demais features **não têm arquivos no repo**, apesar do "Tasked" abaixo; serão escritas just-in-time. Ver `docs/PLANO-ETAPAS.md`.

| # | Feature | Depende de | Status |
|---|---|---|---|
| 000 | game-bible (+ art-bible, design-tokens) | — | Specified ✅ |
| 00A | agents-setup (AGENTS.md + rules-agent + design-agent) | 000 | Coberto por T000–T002 da 001 ✅ |
| 001 | core-loop | 000 | **Complete ✅** (2026-09-25 · Firefox a medir pelo autor) |
| 002 | vocabulary-combos | 001 | **Complete** ✅ (2026-09-28) |
| 003 | shop-scriptorium | 001 | **Complete** ✅ (2026-09-28) |
| 004 | arena-degradation | 001 | Tasked ✅ |
| 005 | enemies-roster (+ ondas Cap. 1) | 001 | **Complete ✅** (2026-09-25 · shake da morte do campeão pendente) |
| 006 | boss-asmodeus (Cap. 1) | 002, 005 | Tasked ✅ |
| 007 | ui-screens-menus | 001 | Tasked ✅ |
| 008 | cutscenes-cap1 (**in-engine**, AnimationPlayer + roteiros) | 007 | Tasked ✅ (v2) |
| 009 | audio | 001 | Tasked ✅ |
| 010 | characters-unlocks | 003 | Tasked ✅ |
| 011 | web-export-itch (demo) | 001–010 | Tasked ✅ |
| 012 | boss-mae-das-tracas (Cap. 2) | 006 | Tasked ✅ |
| 013 | boss-abade-caido (Cap. 3) | 012 | Tasked ✅ |
| 014 | boss-padre-malaquias (Cap. 4) | 013 | Tasked ✅ |
| 015 | boss-semihaza (Cap. 5, final) | 014 | Tasked ✅ |

**Ordem de execução sugerida:** 001 → (002, 003, 004, 005 em paralelo) → 006 → 007 → 008, 009, 010 → 011 (demo publicada) → 012 → 013 → 014 → 015.

**Como começar:** `BOOTSTRAP.md` (prompt inicial) → `PLANO-DE-EXECUCAO.md` (plano em 7 etapas) → `PROMPTS.md` (prompts por fase).

**Plano completo:** 17/17 features com spec + plan + tasks. Próxima etapa: produção de arte no Claude Design (`design-prompts/`) e depois `/speckit.implement` a partir da 001.
