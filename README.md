# Scribe of the Damned

Roguelite 2D de ação em pixel art, feito em **Godot 4.7.2**. Ano de 1348, o ano da peste: o Irmão Anselmo, copista do Mosteiro de São Wendelino, abre o códice proibido e fica preso dentro dele. Para sair, luta com **armas sagradas** e escreve **palavras em latim** que viram milagres.

> Autor: **Francisco**. Status: em desenvolvimento (Etapa 3). Última atualização deste README: 2026-10-01.

## Como se joga
- **Armas sagradas** atacam o tempo todo. Você leva **2** e troca entre elas no meio da onda: Pena do Copista, Bíblia (raio que você mira), Crucifixo, Rosário, Turíbulo e Aspersório. Elas sobem de nível nos selos e as novas se compram na loja.
- **Letras:** quando um inimigo solta uma letra, o jogo entra em **câmera lenta** e abre um **menu com 3 letras**. Uma delas continua a palavra que está no atril. Você tem 2,5 s para escolher.
- **Palavras (o "ultimate"):** com a palavra completa no atril, conjure. LUX, IGNIS, CRUX, SANCTUS… limpam a tela. Combos, apócrifos e orações são palavras raras e fortes. Errar a palavra é **heresia**: o escriba fica atordoado, aparece uma poça de aggro e o atril se perde.
- **Graça (XP):** vem das mortes e das palavras. A cada nível um **feixe de luz dourado** desce sobre o escriba e o jogo fica **2,5 s em câmera lenta** (uma barra mostra quanto falta); depois o jogo pausa e você escolhe **1 de 3 selos**: nível de arma, status (vela, velocidade, estante, tinteiro…), ímã reverso ou poção.
- **Loja (Scriptorium)** entre as ondas: armas, ímã reverso, apócrifos e, em breve, poções.
- **Capítulo 1:** 9 ondas e o chefe **Asmodeus, o Rasurador**. A página do livro se degrada a cada onda.

### Controles (teclado e mouse; trocáveis em Opções)
| Tecla | Ação |
|---|---|
| WASD / setas | Andar |
| Espaço | Conjurar a palavra do atril |
| Shift | Esvaziar o atril (sem heresia) |
| 1 · 2 | Trocar de arma |
| ← → (ou A/D) + Espaço, ou clique | Escolher a letra no menu |
| 1 · 2 · 3, ou clique | Escolher o selo ao subir de nível |
| Tab (segurar) | Ver as palavras conhecidas |
| Mouse | Mira da Bíblia, do Aspersório e das palavras direcionais |
| Esc | Pausa |
| 3 · 4 · 5 · 6 | Poções: Óleo da Unção (vela), Água Benta, Vinho do Fervor, Tinta Iluminada (018, em andamento: o Óleo já funciona) |

## Estado das features
| # | Feature | Status |
|---|---|---|
| 001–008 | Núcleo, vocabulário e combos, loja, arena que se degrada, inimigos, chefe Asmodeus, telas e menus, cutscenes do Cap. 1 | ✅ |
| 016 | Graça e subir de nível (3 selos, pingo de cera) | ✅ |
| 017 | Arsenal sagrado (6 armas, inventário de 2, menu da letra, ímã reverso, palavras como ultimate) | ✅ |
| T1800 | HUD novo (painéis em pixel art, recarga das armas) | ✅ |
| 018 | Poções (Óleo da Unção, Água Benta, Vinho do Fervor, Tinta Iluminada), subir de nível com feixe de luz e câmera lenta, passada de ritmo | 🔨 Fases 1–2 ✅ (feixe + câmera lenta, 1º nível mais rápido; poções no HUD, Óleo) · Fase 3 em seguida |
| 009 | Áudio (efeitos e falas via ElevenLabs; música do autor) | sons provisórios |
| 010–015 | Personagens, export para itch.io, capítulos 2–5 | planejado |

Detalhes em [`FEATURES.md`](FEATURES.md) e nas decisões em [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Rodar, testar e exportar
Godot 4.7.2 (não mono), renderer Compatibility.

```bash
# Jogar
godot --path .

# Testes (GUT 9.7.1)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit

# Export web
mkdir -p build/web && godot --headless --path . --export-release "Web" build/web/index.html
cd build/web && python -m http.server 8765 --bind 127.0.0.1
```

Atalhos de teste na URL do build web (ou depois de `--` na linha de comando):
`?weapons=bible,censer&wlevel=3` (armas e nível) · `?boss&unlock=all&atril=8` (luta direto) · `?shop` (loja) · `?stress`, `?stress=bible`, `?stress=arsenal` (medir FPS) · `?roster` (os inimigos) · `?cutscene=c1_01`.

Sonda de balanceamento: `godot --headless --path . -s tools/balance_probe.gd -- cast god wave=1 weapons=pen` (linhas PROBE, WEAPONS, LETTERS, FLOW, ARENA).

## Organização
| Pasta | O quê |
|---|---|
| `src/` | Código (GDScript tipado; componentes, máquinas de estado, EventBus) |
| `data/` | Todo o conteúdo em `.tres`/`.json`: palavras, inimigos, ondas, armas, bênçãos, loja, cutscenes, áudio |
| `assets/` | Arte (placeholders gerados por script até a arte final) |
| `specs/` | Game bible, art bible e uma spec por feature (com `tasks.md`) |
| `docs/` | Decisões, pareceres dos agentes (`docs/reviews/`), áudio, vozes |
| `tests/` | Testes GUT (unit e integração) |
| `tools/` | Scripts: sonda de balanceamento, geradores de arte, paleta e áudio |
| `.claude/agents/` | Agentes do projeto (game-design, rules, mechanics, design, animation, code, intel, audio, story) |

## Regras do projeto
A constituição está em `.specify/memory/constitution.md` e o guia de trabalho em [`CLAUDE.md`](CLAUDE.md). Em resumo:
- conteúdo em dados, nunca no código;
- pools em vez de `instantiate()` durante a onda;
- paleta travada de 9 cores, com o dourado só para palavras e Graça;
- pixel art sem ruído;
- GUT e export web ao fim de cada fase.
