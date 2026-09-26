# 005 — Inimigos e ondas do Capítulo 1

> Status: **Aprovada** (2026-09-25). **Complete** (2026-09-25). Pendente fora do escopo de código: screen shake da morte do campeão (sem câmera com shake ainda).
> Depende de: 001 (Complete). Game bible §3.8. Fichas 07–15. Narrativa §5, §11.
> Legenda de números: **[INICIAL]** = proposta validada pelo rules-agent; ajustável só nos `.tres`.
> Pareceres (2026-09-25): game-design-agent **AJUSTAR** e rules-agent **VÁLIDO COM RESSALVAS**. Os ajustes já estão aplicados abaixo (marcados **[P]**).

## Objetivo

O Capítulo 1 jogável da onda 1 à 9: os 5 inimigos do capítulo com comportamentos distintos, campeões a partir da onda 3, a tinta dourada caindo dos campeões e as 9 ondas com curva de dificuldade. A performance da 001 precisa ser mantida.

## Fora do escopo

| Item | Feature |
|---|---|
| Loja, gastar tinta dourada | 003 |
| Asmodeus (depois da onda 9) | 006 |
| Inimigos dos capítulos 2–5 | 012–015 |
| Arte final dos inimigos (os sprites continuam placeholders no tamanho do catálogo) | D-024 |
| Áudio | 009 |

## Histórias de usuário

- **US-1 (P1):** como jogador, reconheço cada inimigo pela silhueta e pelo jeito de se mover, e sei o que cada um vai fazer antes que ele faça (telegrafia).
- **US-2 (P1):** como jogador, as traças me obrigam a recolher as letras rápido, porque elas comem as letras do chão.
- **US-3 (P1):** como jogador, a Gárgula me ensina a ler a linha tracejada e sair do caminho.
- **US-4 (P1):** como jogador, o Monge Oco me obriga a me aproximar ou a usar CRUX contra os tiros.
- **US-5 (P2):** como jogador, o Borrão deixa poças que me deixam lento, e isso muda o meu caminho.
- **US-6 (P1):** como jogador, um campeão é um evento: mais forte e marcado em vermelho, e matá-lo rende tinta dourada e uma vela.
- **US-7 (P1):** como jogador, as 9 ondas ficam mais difíceis de forma perceptível, mas justa.

## Requisitos funcionais

### Comportamentos (arquitetura)
- **FR-501** Comportamentos são **Resources stateless** (`EnemyBehavior` e subclasses). O estado de cada inimigo (fase, timer, mira) mora nos arrays do EnemyManager, nunca no Resource. Um `.tres` de comportamento pode ser compartilhado por muitos inimigos.
- **FR-502** O EnemyManager continua com um único laço e o steering escalonado (D-039). O comportamento só decide a **velocidade desejada** e dispara ações (tiro, dash, poça). A separação e a integração continuam no manager.

### Os 5 inimigos do Capítulo 1
- **FR-503 Diabrete** (existente): persegue; contato fraco.
- **FR-504 Traça Gigante:** voa sem colidir com obstáculos. Mira a **letra no chão mais próxima** num raio `seek_radius`, **exceto** letras já puxadas pelo ímã **[P]**, e **marca a letra-alvo** com um sinal visual **[P]**. Ao alcançá-la, leva `eat_time` s para comer (a letra some, com a animação EATEN, e `letter_eaten` é emitido). Come no máximo `max_eaten` letras e depois foge do jogador **[P]**. **Ao morrer, devolve as letras que comeu** ao chão **[P]**: vira um cofre, não um ralo. Sem letras por perto, se aproxima do jogador devagar. HP baixo.
- **FR-505 Gárgula-Marginália:** anda até a distância `trigger_range` do jogador, para, **telegrafa** por `windup` s com uma linha tracejada BLOOD na direção do jogador, e dá um **dash** reto a `dash_speed` por `dash_time` s. **A direção é travada no início do windup** **[P]**: é isso que torna o dash esquivável (rules-agent: 0.6 s + 0.41 s de trajeto). Depois espera `cooldown` s. Contato **forte** (2 velas) durante o dash e fraco fora dele.
- **FR-506 Monge Oco:** mantém a distância entre `keep_min` e `keep_max` do jogador. A cada `fire_interval` s telegrafa por `windup` s (páginas BLOOD) e dispara **1 projétil** BLOOD em linha reta. Projétil: fraco, bloqueado pela CRUX (`ProjectileBlockers`). **[P]** A CRUX passa a ler `arm_width` e um novo `block_radius` (16 px ao redor do centro) de `crux.tres`. Hoje a largura do braço é uma constante no código (viola o Princípio IV) e não protege de forma confiável contra tiros em diagonal.
- **FR-507 Borrão de Tinta:** persegue devagar. A cada `trail_interval` s deixa uma **poça de lentidão** de 24×10 que dura 3 s. O total de poças tem teto (pool com `try_acquire`) **[P]**. A poça de lentidão é **visualmente distinta** da poça de heresia: INK_SOFT molhado com brilho CHALK, contra o tracejado BLOOD da heresia (design-agent) **[P]**. Ao morrer, deixa uma poça. O jogador dentro de uma poça anda a `player_slow_factor` da velocidade.

### Projéteis inimigos
- **FR-508** Os projéteis inimigos vivem num **gerenciador de laço único** (arrays + um único desenho), sem nó por projétil. Máximo de 10×10 px, sempre com BLOOD (art bible §2.2). Somem ao acertar o jogador, ao sair da página, ao expirar ou ao tocar um bloqueador.

### Campeões
- **FR-509** A partir da onda 3, **1 campeão por onda** (D-019), sorteado do `champion_pool` da onda e surgido num `champion_times` fixo. A **Traça não entra** no pool de campeões **[P]**: com HP 4 ela seria barata demais para um evento.
- **FR-510** Campeão = mesmo tipo com os multiplicadores de `ChampionTuning` (HP, velocidade, raio), **contorno BLOOD de 1px** (shader), aura de 4 partículas BLOOD e telegrafia de spawn de **0.8 s** com anel maior (ficha 15).
- **FR-511** Morte de campeão: hit-stop de **40 ms**, shake médio, **+1 vela** (D-011) e **3–5 gotas de tinta dourada** que o ímã puxa.

### Tinta dourada
- **FR-512** Gota de tinta dourada (6×8, 4 frames) pooled, puxada pelo ímã como as letras e somada a `GameState.gold_ink`. O HUD mostra o total no canto superior direito, fora da área central. Na 005 não há onde gastar (a loja é a 003).

### Ondas do Capítulo 1
- **FR-513** 9 `WaveData` em `data/waves/chapter_1/wave_01..09.tres`. A duração cresce de 60 a 90 s. A composição introduz um inimigo por vez (tabela no data-model §6). O loop do protótipo (D-035) passa a seguir wave_01 → … → wave_09. Depois da 9, o protótipo mostra "CAPÍTULO COMPLETO" e para (o chefe entra na 006).
- **FR-514** O `LetterEater` e o drop de letras continuam respeitando os tetos dos pools (`try_acquire`, D-037).

### Técnica
- **FR-515** Nenhum `instantiate()` durante a onda. Pools novos (projéteis inimigos, poças, gotas de tinta, campeões) são pré-aquecidos.
- **FR-516** Todo número nos `.tres`; toda cor da paleta.

## Critérios de sucesso

- **SC-501** As ondas 1–9 do Cap. 1 rodam do começo ao fim sem erro (teste de integração com o tempo acelerado).
- **SC-502** Cada comportamento tem teste unitário próprio (Traça come letra; Gárgula telegrafa e faz o dash; Monge mantém distância e atira; Borrão deixa poça; campeão dropa tinta e dá vela).
- **SC-503** Cena de stress com a composição da onda 9 (300 inimigos misturados + 60 projéteis inimigos + 20 poças): **média ≥ 60 e p95 ≥ 55 no Chrome** (mesmo critério do SC-001).
- **SC-504** Zero `instantiate` durante as ondas (estende o `test_zero_instantiate`).
- **SC-506** O rules-agent mede **palavras por onda** em cada uma das 9 ondas, não só a sobrevivência. Se o número cair da onda 4 em diante, a curva está errada **[P]**.
- **SC-505** Playtest do autor: cada inimigo é reconhecível em 1× e o telegrafado dá tempo de reagir (verificação manual).
