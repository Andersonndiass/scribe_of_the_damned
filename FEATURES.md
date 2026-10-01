# Roadmap de Features

> ⚠️ **Status real (2026-10-01):** `000` aprovada; **`001`, `005`, `002`, `003`, `006`, `007`, `008`, `004`, `016`, `017` e `018` Complete** (HUD novo T1800); `009` com as Fases 1–2 prontas (sons provisórios). As demais features **não têm arquivos no repo**, apesar do "Tasked" abaixo; serão escritas just-in-time. Ver `docs/PLANO-ETAPAS.md`.

| # | Feature | Depende de | Status |
|---|---|---|---|
| 000 | game-bible (+ art-bible, design-tokens) | — | Specified ✅ |
| 00A | agents-setup (AGENTS.md + rules-agent + design-agent) | 000 | Coberto por T000–T002 da 001 ✅ |
| 001 | core-loop | 000 | **Complete ✅** (2026-09-25 · Firefox a medir pelo autor) |
| 002 | vocabulary-combos | 001 | **Complete** ✅ (2026-09-28) |
| 003 | shop-scriptorium | 001 | **Complete** ✅ (2026-09-28) |
| 004 | arena-degradation | 001 | **Complete** ✅ (2026-09-29, D-081 · arte por camada: autor, `assets/arena/chapter_1/`) |
| 005 | enemies-roster (+ ondas Cap. 1) | 001 | **Complete ✅** (2026-09-25 · shake da morte do campeão pendente) |
| 006 | boss-asmodeus (Cap. 1) | 002, 005 | **Complete** ✅ (2026-09-29 · vida do chefe a confirmar no playtest) |
| 007 | ui-screens-menus | 001 | **Complete** ✅ (2026-09-29 · verbetes que faltam: autor, D-069) |
| 008 | cutscenes-cap1 (**in-engine**, AnimationPlayer + roteiros) | 007 | **Complete** ✅ (2026-09-29 · vozes: autor, `docs/voice/`) |
| 009 | audio | 001 | Tasked ✅ |
| 010 | characters-unlocks | 003 | Tasked ✅ |
| 011 | web-export-itch (demo) | 001–010 | Tasked ✅ |
| 012 | boss-mae-das-tracas (Cap. 2) | 006 | Tasked ✅ |
| 013 | boss-abade-caido (Cap. 3) | 012 | Tasked ✅ |
| 014 | boss-padre-malaquias (Cap. 4) | 013 | Tasked ✅ |
| 015 | boss-semihaza (Cap. 5, final) | 014 | Tasked ✅ |
| 016 | grace-levelup (XP "Graça" + subir de nível com 3 selos; pingo de cera) | 003, D-082 | **Complete** ✅ (2026-09-30, D-086) |
| 017 | arsenal-sagrado (inventário de 2 armas trocáveis; Pena, Bíblia, Crucifixo, Rosário, Turíbulo, Aspersório; menu de escolha da letra; ímã reverso; selos melhoram armas/status) | 016, D-085 | **Complete** ✅ (2026-10-01, D-087…D-093 · playtest do autor e medição no Chrome pendentes) |
| 018 | pocoes (Óleo da Unção, Água Benta, Vinho do Fervor, Tinta Iluminada; teclas 3–6; feixe de luz no level-up; passada de ritmo) | 017 | **Complete** ✅ (2026-10-01, D-094…D-096 · playtest do autor pendente) |

**Ordem de execução sugerida:** 001 → (002, 003, 004, 005 em paralelo) → 006 → 007 → 008, 009, 010 → 011 (demo publicada) → 012 → 013 → 014 → 015.

**Como começar:** `BOOTSTRAP.md` (prompt inicial) → `PLANO-DE-EXECUCAO.md` (plano em 7 etapas) → `PROMPTS.md` (prompts por fase).

**Plano completo:** 17/17 features com spec + plan + tasks. Próxima etapa: produção de arte no Claude Design (`design-prompts/`) e depois `/speckit.implement` a partir da 001.
