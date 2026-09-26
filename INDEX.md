# Scribe of the Damned — índice

**Primeiro arquivo que qualquer agente ou pessoa lê.** Depois dele, leia `CLAUDE.md` e a constituição.

## O jogo

Roguelite survivors-like em arena fechada. Um monge copista, preso num códice amaldiçoado, mata demônios, arranca letras deles e conjura **palavras em latim** (LUX, PAX, CRUX…) que viram milagres. São 5 capítulos, cada um uma página do códice com seu chefe: Asmodeus → Mãe das Traças → Abade Caído → Padre Malaquias → Semíhaza.
Godot **4.7.2**, GDScript tipado, alvo principal **Web (itch.io)**.

## Estado atual (2026-09-24)

**Features 001 (core loop) e 005 (inimigos + 9 ondas do Cap. 1) Complete** (2026-09-25). Próximo: spec 002. Ver `CLAUDE.md` → Estado atual.

| Insumo | Situação |
|---|---|
| Constituição v1.1, game bible v1.0, art bible, design tokens | ✅ Aprovados (hex da paleta provisórios) |
| Spec 001 | ✅ Escrita (`specs/001-core-loop/`) |
| Specs 002–015 | ⏳ Serão escritas just-in-time |
| Narrativa | ✅ `specs/000-game-bible/narrative.md` |
| Áudio | ⏳ O autor vai mandar |
| Fichas de arte (32) | ✅ `design/claude-design/`, só o layout |
| Sprites | ⏳ Gerados por script a partir das fichas (D-024); placeholders até lá |

## Mapa de pastas

| Caminho | Conteúdo |
|---|---|
| `INDEX.md` | Este arquivo |
| `CLAUDE.md` | Regras permanentes de trabalho, comandos e estado atual |
| `AGENTS.md` | Catálogo dos 6 agentes e ordem de acionamento |
| `.claude/agents/` | Definições dos agentes |
| `.specify/memory/constitution.md` | **Regras não negociáveis.** Prevalece sobre tudo |
| `specs/000-game-bible/` | `spec.md` (design), `art-bible.md` (arte), `design-tokens.json` (paleta e tempos) |
| `specs/<NNN>-<feature>/` | spec, plan, data-model e tasks de cada feature (a criar) |
| `FEATURES.md` | Roadmap e dependências |
| `BOOTSTRAP.md`, `PLANO-DE-EXECUCAO.md`, `PROMPTS.md` | Documentos originais do autor |
| `docs/PLANO-ETAPAS.md` | Plano de execução revisado, com divergências |
| `docs/DECISIONS.md` | Log de decisões |
| `docs/GLOSSARIO.md` | Termos do jogo (PT e latim) |
| `docs/ASSET-CATALOG.md` | Tamanho, pivot e frames de todos os assets |
| `design/claude-design/` | Fichas de arte do Claude Design (`.dc.html`) |
| `data/` | Conteúdo em `.tres` e `.json` (a criar) |
| `src/` | Código GDScript (a criar) |
| `assets/` | Sprites, áudio e fontes (a criar) |
| `tests/` | Testes GUT (a criar) |

## Glossário curto

- **Atril:** a estante onde as letras coletadas se enfileiram; é onde a palavra é montada.
- **Heresia:** punição por conjurar errado: stun de 0.5s, poça de aggro e atril limpo.
- **Milagre:** o efeito de uma palavra conjurada.
- **Códice:** o livro amaldiçoado; cada capítulo é uma página.
- **Campeão:** versão 1.5× de um inimigo, com contorno BLOOD; solta tinta dourada.
- **Tinta dourada:** a moeda da loja.
- **Apócrifos:** as 5 palavras além das 7 de base (FIDES, LUMEN, PURGO, GLORIA, VERBUM).

Glossário completo: `docs/GLOSSARIO.md`.
