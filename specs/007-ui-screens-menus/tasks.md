# 007 — Tarefas

## Fase 1 — Base (lógica, testes primeiro)
- **T700** [TEST-FIRST] `test_settings.gd` → `Settings` (autoload): volumes, shake, idioma, alto contraste e teclas; salva/carrega `user://settings.cfg`; aplica no AudioServer, no GameState, no TranslationServer e no InputMap (SC-702).
- **T701** Tradução: `i18n/ui.csv` (chave, pt_BR, en) importado como Translation; `tr()` em todo texto de interface; passar HUD, loja, cartas (display_name/short_desc viram chaves), overlays; teste `test_no_ui_literals.gd` (SC-704) e `test_translations.gd` (toda chave tem pt_BR e en).
- **T702** [TEST-FIRST] `test_codex.gd` → `Codex` (autoload): descobre palavra/combo ao conjurar, inimigo ao ver, chefe ao enfrentar; salva `user://codex.save`; sem bônus mecânico (SC-703).
- **T703** `ScreenRouter` + cena raiz `app.tscn` (nova main scene): troca de telas, pausa, volta ao menu; o jogo (`main.tscn`) vira uma tela. Os debug (`?stress`, `?boss`, `?shop`…) continuam indo direto.

**Checkpoint 007-A:** configurações, tradução e Grimório funcionam por teste; o jogo abre pelo roteador.

## Fase 2 — Telas
- **T710** Visual e tempos: parecer do design-agent (fichas 27, 29, 30; alto contraste) e do animation-agent; placeholders por script (sino, livro, medalhões, cadeado, selo, pena-cursor).
- **T711** Splash, Menu, Personagem (Anselmo; demais com cadeado), Capítulo (Cap. 1; demais acorrentados).
- **T712** Pausa (Continuar · Grimório · Opções · Abandonar), Game Over (estatísticas, 3,5 s até os botões) e Vitória (estatísticas, entradas novas do Grimório, Cap. 2 selado). Substituem os overlays mínimos.
- **T713** Créditos (página de texto rolando).

**Checkpoint 007-B:** do splash à vitória só com teclado.

## Fase 3 — Opções e Grimório
- **T720** Opções: sliders de volume, shake, idioma (troca na hora, SC-705), alto contraste, remap (esperar tecla, conflito = troca).
- **T721** Grimório: 4 abas (Palavras, Combos, Inimigos, Chefes), verbetes da narrativa §11 em PT-BR e EN, virada de página; entrada não descoberta = "?????".
- **T722** Integração `test_screens_flow.gd` (SC-701, SC-705).

## Fase 4 — Fechamento
- **T730** GUT, export web, SC-001 (SC-706), `FEATURES.md`, `CLAUDE.md`, `docs/DECISIONS.md`, push.
