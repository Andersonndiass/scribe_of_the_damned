# 007 — Telas e menus

> Status: Complete (D-070)
> Parecer (2026-09-29): game-design-agent **AJUSTAR** (três cortes de escopo, aplicados como proposta **[P]**).
> Depende de: 001–006 (Complete). Game bible §6 (telas; PT-BR e EN; 100% teclado). Fichas 27 (Splash, Menu, Personagem, Capítulo), 29 (Pausa, Game Over, Vitória, Codex Completus), 30 (Opções, Grimório, Créditos, Loading). Narrativa §11 (verbetes do Grimório). D-047 (6B: opção de desligar o shake).
> **[P?]** = decisão do autor.

## Objetivo

Dar ao jogo **começo, meio e fim**: abrir num menu, escolher personagem e capítulo, pausar, perder e vencer com telas próprias, ajustar opções e consultar o **Grimório** — tudo em 640×360, só com teclado, com o visual das fichas (nenhum botão retangular genérico: fita, selo ou pergaminho; foco com a pena-cursor).

## Fora do escopo

| Item | Feature |
|---|---|
| Personagens além do Anselmo (Hildegarda etc.), passivas e desbloqueios | 010 (aqui só o seletor com os bloqueados) |
| Capítulos 2–5 | 012–015 (aqui só o seletor com os bloqueados) |
| Codex Completus (fim do Cap. 5) | 015 |
| Cutscenes (C1-01…C1-04) | 008 |
| Publicação no itch | 011 |
| **Loading HTML** (vela 0–100%, casca do export web) **[P]** | 011 |

## Histórias de usuário

- **US-1 (P1):** como jogador, abro o jogo, vejo o splash e o menu, e começo uma partida só com o teclado.
- **US-2 (P1):** como jogador, pauso a qualquer momento (Esc) e posso continuar, abrir o Grimório, as Opções ou abandonar.
- **US-3 (P1):** como jogador, quando morro vejo "A página ardeu" com as estatísticas da partida; quando venço o capítulo, a tela de vitória.
- **US-4 (P1):** como jogador, ajusto volumes (Geral, Música, Efeitos), desligo o shake e troco o idioma, e isso fica salvo.
- **US-5 (P2):** como jogador, consulto no Grimório as palavras, os combos, os inimigos e os chefes que já descobri, com a tradução e o verbete (o latim nunca é traduzido durante o jogo).
- **US-6 (P2):** como jogador, vejo os créditos (uma página de texto rolando; o itch pede atribuição).

## Requisitos funcionais

### Fluxo
- **FR-701** `Splash → Menu → Personagem → Capítulo → Jogo`, rápido (pilar "curto e intenso"). Um clique/tecla no splash libera o áudio (D-053 FR-910).
- **FR-702** **Menu**: Jogar · Grimório · Opções · Créditos (no web não há "Sair"). Livro abrindo, chama, pena-cursor (ficha 27).
- **FR-703** **Personagem**: medalhões; só o **Anselmo** disponível; os demais com cadeado (010). **Capítulo**: páginas; só o **Cap. 1**; os demais acorrentados.
- **FR-704** **Pausa** (Esc): fita desenrolando; Continuar · Grimório · Opções · Abandonar (volta ao Menu). O jogo para (árvore pausada), a loja continua sem Esc (D-059).
- **FR-705** **Game Over** ("A página ardeu", 3,5 s até os botões): estatísticas (onda, tempo, palavras conjuradas, inimigos, tinta) e Tentar de novo · Menu. Substitui o overlay mínimo da 001.
- **FR-706** **Vitória** (depois do chefe) **[P]**: "Página purificada", as estatísticas do Game Over + o tempo do chefe, as **entradas novas do Grimório** e o **Cap. 2 selado e acorrentado** ("em breve"). Um botão: Continuar → Menu. A cutscene C1-04 entra antes, na 008.

### Opções
- **FR-707** Volumes Geral/Música/Efeitos (sliders, API da 009), Shake (selo de cera liga/desliga, D-047), **Idioma (PT-BR ⇄ EN)**, **Mirar com o mouse** (sim/não, D-067), **Alto contraste** (variação legível dentro da paleta travada, pelo design-agent) e **Remapear teclas** (movimento, conjurar, purgar, lista de palavras, pausa, reiniciar; conflito = aviso e troca) **[D-066]**. As letras são coletadas andando, não digitadas: o remap não conflita com elas.
- **FR-708** As opções ficam salvas em `user://settings.cfg` (no web, IndexedDB) e valem ao abrir o jogo.

### Grimório
- **FR-709** 4 abas: **Palavras, Combos, Inimigos, Chefes**. Entrada descoberta = nome, tradução e verbete (narrativa §11); não descoberta = silhueta/"?????". Virada de página em 8 quadros.
- **FR-710** Descobrir = conjurar a palavra/combo pela primeira vez, ver o inimigo, **enfrentar** o chefe (não precisa vencer). O progresso fica salvo em `user://codex.save` entre partidas. **Nenhuma entrada dá bônus mecânico** (D-018: conhecimento, não poder) **[P]**.

### Idioma
- **FR-711** Todo texto de interface em arquivos de tradução — **nunca** no código (SC-704): telas, HUD, loja, cartas, Grimório (verbetes) — **PT-BR e EN completos nesta feature** **[D-066]**; troca nas Opções, na hora (SC-705). O latim das palavras e combos nunca é traduzido fora do Grimório (game bible §4).

### Técnica
- **FR-712** Telas como cenas próprias (`src/ui/screens/`), trocadas por um `ScreenRouter`; tudo desenhado em código no estilo das fichas (placeholders por script onde houver sprite: sino, livro, medalhões, cadeado, vela).
- **FR-713** Foco sempre visível (pena-cursor ou borda GOLD); ←/→/↑/↓ navegam, Espaço/Enter confirma, Esc volta.

## Critérios de sucesso

- **SC-701** Do splash à primeira onda e do Game Over de volta ao Menu, só com teclado (teste de input).
- **SC-702** Opções salvas sobrevivem a reiniciar o jogo (teste com `user://`).
- **SC-703** Entrada do Grimório só aparece depois de descoberta; o progresso sobrevive a reiniciar (teste).
- **SC-704** Nenhum texto de interface no código (teste varre `src/ui` por literais fora das chaves de tradução, exceto latim e números).
- **SC-705** Troca de idioma muda todas as telas na hora.
- **SC-706** O SC-001 se mantém (as telas não rodam durante a onda).
