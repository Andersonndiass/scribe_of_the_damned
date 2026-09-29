# 001 — Core Loop

> Status: **Specified** (2026-09-24), aguardando o Checkpoint 0.5.
> Depende de: 000 (game bible v1.0). Decisões: `docs/DECISIONS.md` D-006 a D-022.

## Objetivo

Uma onda completa jogável no navegador: o Irmão Anselmo anda pela página, o ataque automático mata Diabretes, as letras caem, o jogador monta palavras no atril e conjura as 7 palavras base, com heresia, purge, HUD, degradação da página e 60 FPS com carga máxima.

## Fora do escopo (vai para outras features)

| Item | Feature |
|---|---|
| Combos, apócrifos, Grandes Orações, letra B | 002 |
| Loja, RunStats, itens, upgrades de atril e velas | 003 |
| Arenas dos 5 capítulos, obstáculos, degradação completa | 004 |
| Outros 7 inimigos, campeões (e a vela por matar campeão), ondas 2–9 | 005 |
| Chefes | 006 |
| Menus, telas completas, localização, opções | 007 |
| Cutscenes, tutorial com o Abade | 008 |
| Áudio | 009 |
| Outros personagens e passivas | 010 |

## Histórias de usuário

- **US-1 (P1):** como jogador, ando pela página e vejo meu ataque automático matar os Diabretes que vêm até mim.
- **US-2 (P1):** como jogador, coleto as letras que os Diabretes soltam e vejo elas entrando no atril, na ordem.
- **US-3 (P1):** como jogador, quando o atril forma LUX, aperto Espaço e um raio de luz mata os inimigos em linha.
- **US-4 (P1):** como jogador, se aperto Espaço com uma palavra inválida, sofro heresia; se só quero recomeçar, aperto Shift e as letras caem no chão.
- **US-5 (P2):** como jogador, vejo no HUD as velas, o atril com seu estado, as palavras ainda possíveis, o tempo e o número da onda.
- **US-6 (P2):** como jogador, se fico parado por 5s sem conjurar e sem levar dano, recupero velas.
- **US-7 (P2):** como jogador, vejo a página se degradar ao fim da onda.
- **US-8 (P1, técnica):** o jogo roda a 60 FPS no navegador com 300 inimigos, 150 letras e 200 projéteis.

## Requisitos funcionais

### Jogador
- **FR-001** Movimento em 8 direções (WASD) a `PlayerData.move_speed` (90 px/s), normalizado na diagonal, sem sair da área jogável (X24–615, Y24–335).
- **FR-002** Ataque automático a cada `PlayerData.attack_interval` (0.8s): um `PRJ_INK_DROP` pooled vai até o inimigo mais próximo dentro de `attack_range`. Sem alvo, não dispara.
- **FR-003** Velas: começa com `PlayerData.start_candles` (3), limite `max_candles` (8). Um golpe tira o `contact_damage` do inimigo (1 = fraco, 2 = forte). Depois do dano: invulnerável por `iframes` (1.0s), com pisca-pisca.
- **FR-004** Recuperação parado: sem se mover, sem conjurar e sem levar dano por `idle_regen_delay` (5s), ganha +1 vela a cada `idle_regen_interval` (3s), até o limite. Qualquer movimento, conjuração ou dano zera o contador.
- **FR-005** Com 0 velas: estado morto → tela mínima de Game Over com "tentar de novo" (a tela completa é da 007).

### Arena
- **FR-006** Página de 640×360 com parede de colisão na margem de 24px. Câmera fixa.

### Inimigos e ondas
- **FR-007** Inimigos comuns **não são nós de física**. O EnemyManager guarda o estado em arrays e move todos num único `_physics_process`. A separação entre eles usa o SpatialHash.
- **FR-008** O Diabrete (`data/enemies/imp.tres`) persegue o jogador e causa dano de contato fraco.
- **FR-009** O spawn tem telegrafia: um marcador BLOOD aparece no ponto por `EnemyData.telegraph_time` antes do inimigo. O ponto fica a pelo menos `WaveData.min_spawn_distance` do jogador.
- **FR-010** O WaveDirector lê o `WaveData` (`data/waves/chapter_1/wave_01.tres`): duração de 60s e grupos de spawn com ritmo crescente. Ao fim da onda, os inimigos restantes se dissolvem e `wave_ended` é emitido.
- **FR-011** Ao morrer, o inimigo toca a dissolução (art bible §6.1), deixa um decal e tem `EnemyData.letter_drop_chance` de soltar uma letra.

### Letras
- **FR-012** Letras são pooled. Vida de `DropTuning.letter_lifetime` (8s), piscando nos últimos `blink_time` (2s). Dentro de `PlayerData.magnet_radius` (40px), são puxadas com tween QUAD_IN e coletadas ao tocar.
- **FR-013** **Drop ponderado.** A letra sorteada usa `peso_base[letra]` + `target_bonus` se ela continua algum prefixo de palavra conhecida que **caiba na capacidade atual do atril**. Com o atril vazio, o bônus vai para as primeiras letras das palavras que cabem. O B tem peso 0 enquanto VERBUM não estiver desbloqueado. Vogais têm `rare_chance` de sair raras. A letra que ganhou o bônus é marcada como **letra-alvo** (indicador visual).
- **FR-014** O Lexicon carrega o `LexiconData` e valida no load: cada palavra tem 3 a 8 letras, só letras do alfabeto, sem duplicatas. Qualquer violação faz o load falhar com erro claro.

### Atril
- **FR-015** Fila ordenada com capacidade `PlayerData.atril_capacity` (5). Letras entram na ordem da coleta; não há reordenação. Com o atril cheio e sem palavra válida, a letra é **recusada** e fica no chão (`letter_rejected`).
- **FR-016** Estados: `EMPTY`, `FILL` (tem letras, nenhum prefixo válido), `PARTIAL` (é prefixo de uma palavra que cabe), `VALID` (é palavra completa), `FULL_REJECT`. Transições visuais: `CAST`, `PURGE`, `HERESY`.
- **FR-017** Espaço com o atril em `VALID`: consome as letras, emite `word_cast` e dispara o milagre da palavra, com hit-stop de 60ms e flash de 8×8 na pena.
- **FR-018** O poder do milagre cresce com o tamanho da palavra: `WordData.power_budget` é estritamente maior para palavras mais longas. Cada vogal rara na palavra multiplica o poder por `DropTuning.rare_power_bonus` (1.5).
- **FR-019** **Heresia:** Espaço com letras no atril fora de `VALID` (atril vazio não faz nada, D-030b) → stun de `heresy_stun` (0.5s), poça de aggro no ponto do erro por `heresy_pool_time` (2s), que atrai os inimigos dentro de `heresy_pool_radius`, e atril limpo (letras perdidas). A poça atrai os inimigos a até `heresy_pool_radius` dela (D-032).
- **FR-020** **Purge:** Shift com o atril não vazio → as letras voltam para o chão num anel de `purge_scatter_radius` ao redor do jogador, com vida útil renovada. Sem custo nem recarga. As letras ficam intocáveis por 0.3s e **soltas**: o ímã as ignora e o jogador as recolhe andando por cima, na ordem que escolher (D-031).

### Palavras (as 7 base)
- **FR-021** Cada palavra é um `WordData` (`data/words/<id>.tres`) com uma cena de milagre pooled:
  - **LUX:** raio reto na última direção do movimento, dano em tudo na linha.
  - **PAX:** onda circular que empurra e atordoa.
  - **CRUX:** cruz fixa com dano periódico em + e bloqueio de projéteis inimigos.
  - **VITA:** +1 vela.
  - **AQUA:** poça de lentidão.
  - **IGNIS:** área de fogo com dano contínuo, que deixa decal queimado.
  - **MORTIS:** onda na tela toda que mata inimigos com HP ≤ limiar e causa dano nos outros.
- **FR-022** Palavras maiores que a capacidade atual do atril simplesmente não podem ser montadas (MORTIS exige atril 6, que chega na 003). Os testes cobrem MORTIS com capacidade 6.

### HUD e interface mínima
- **FR-023** O HUD nunca cobre a área X160–480, Y60–300. Mostra: velas (acesas e apagadas, até 8), atril (com os espaços da capacidade atual e os estados do FR-016), **dicas** (até 3 palavras possíveis para o prefixo atual), timer, "Onda N".
- **FR-024** Segurar Tab mostra a lista das palavras conhecidas (latim, sem tradução), com as que cabem no atril destacadas.
- **FR-025** Esc pausa o jogo (overlay mínimo com "continuar" e "reiniciar"; a tela completa é da 007).

### Página
- **FR-026** A degradação da página avança 1 estágio por onda (4 estágios, em loop no protótipo). Os decals (manchas, queimaduras) vão para um SubViewport acumulativo, com custo fixo por frame.

### Técnica
- **FR-027** Nenhum `instantiate()` e nenhum `queue_free()` de entidade durante uma onda. Todos os pools são pré-aquecidos antes da onda 1.
- **FR-028** Todo número de gameplay vem dos `.tres` do data-model. Toda cor vem de `palette.gd`.

## Critérios de sucesso

- **SC-001** Cena de stress com 300 inimigos, 150 letras e 200 projéteis: **média ≥ 60 FPS e p95 ≥ 55 FPS** no build web, no Chrome e no Firefox, numa máquina de referência [a registrar no relatório].
- **SC-002** Durante a onda, o contador de `instantiate` do PoolManager fica em **zero**, verificado por teste de integração.
- **SC-003** Um jogador novo conjura LUX na onda 1 usando só as dicas do HUD (verificação manual no M2).
- **SC-004** Os testes GUT de Lexicon, Atril e LetterDropper passam e foram escritos antes da implementação.
- **SC-005** Teste estatístico do drop (seed fixa, 10 mil sorteios): letras-alvo ≥ 40% dos drops quando existe prefixo parcial [valor inicial, rules-agent].

## Premissas
- Personagem único: Irmão Anselmo, com os números de `data/player/anselmo.tres`.
- Sprites são placeholders no tamanho exato do `ASSET-CATALOG.md` enquanto os `scribe-*.js` não chegam (D-022).
- "Sem atacar" no FR-004 = sem conjurar e sem levar dano. O ataque automático não conta (D-011, a confirmar).

## Emenda 2026-09-29 — controles com mouse (D-067, playtest)

- **FR-028** **Marcar letra:** clicar numa letra do chão a marca (a mais próxima do clique, até 10 px); clicar de novo nela ou no chão vazio desmarca; só uma marca por vez. Com marca, o ímã (mesmo raio) puxa **só** a letra marcada; as outras que estavam perto ficam de lado até saírem do raio. A marca some quando a letra sai do chão (coletada, expirada, comida). Letras pisadas continuam sendo coletadas. Sem clique, nada muda.
