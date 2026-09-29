# 006 — Chefe: Asmodeus, o Rasurador (Cap. 1) + framework de chefes

> Status: **Aprovada** (2026-09-29, "1a2a3a4a"; D-062). Fase 1 ✅ (Checkpoint 006-A).
> Pareceres (2026-09-29): game-design-agent **AJUSTAR** e rules-agent **VÁLIDO COM RESSALVAS**. Ajustes aplicados (marcados **[P]**).
> Depende de: 002, 003, 005 (Complete). Game bible §3.12. Asset catalog §5 (fases). Ficha 16 (Asmodeus). Narrativa §5.3, §12 (C1-03). Ressalvas da D-057 e D-056. D-047 (6B: screen shake nesta feature, com opção de desligar).
> Legenda: **[INICIAL]** = número proposto, a validar pelo rules-agent; tudo fica nos `.tres`. **[P?]** = decisão do autor.

## Objetivo

Fechar o Capítulo 1: depois da loja da onda 9, **Asmodeus** entra na página. Ele é uma **rasura viva** (ficha 16) que tenta apagar o texto — inclusive as letras do atril. Três fases, ataques telegrafados, e a vitória conclui o capítulo. Junto vem o **framework comum de chefes** que os capítulos 2–5 (012–015) reusam.

## Fora do escopo

| Item | Feature |
|---|---|
| Cutscenes C1-03 (revelação) e C1-04 (vitória) | 008 |
| Música do chefe (a arquitetura da 009 já recebe) | 009 Fase 3 |
| Tela de vitória / Codex Completus / próximo capítulo | 007 |
| Opção de desligar o shake **na tela de Opções** | 007 (aqui só o ajuste e a API) |
| Arte final (60 quadros da ficha 16); aqui placeholder por script | arte |

## Histórias de usuário

- **US-1 (P1):** como jogador, depois da última loja enfrento Asmodeus, vejo a barra de vida dele e as três fases mudando o que ele faz.
- **US-2 (P1):** como jogador, leio cada ataque antes dele chegar (telegrafia) e consigo desviar se prestar atenção.
- **US-3 (P1):** como jogador, as minhas palavras ferem o chefe e as grandes palavras são o jeito de vencer, mas não o derrubam num golpe só.
- **US-4 (P1):** como jogador, não fico sem letras durante a luta: sempre há como montar palavras.
- **US-5 (P2):** como jogador, sinto o peso do chefe (shake, hit-stop) e posso desligar o shake.
- **US-6 (P1):** como jogador, ao vencer, o capítulo termina.

## Requisitos funcionais

### Framework (reusado nos caps. 2–5)
- **FR-601** `BossData` (id, nome, HP, fases, tamanho, arte), `PhaseData` (limiar de HP, ataques com peso, multiplicadores de velocidade/cadência) e `AttackData` (telegrafia, duração, dano **fraco (1) ou forte (2)**, `source_tag`, parâmetros) em `.tres`.
- **FR-602** FSM do chefe: `Enter → Idle → Telegraph → Attack → Recover → Idle`, `PhaseShift` ao cruzar o limiar (invulnerável por um instante, com aviso), `Stunned`, `Dead`.
- **FR-603** Escolha do próximo ataque ponderada pelo peso da fase, **sem repetir o mesmo ataque mais de 2 vezes seguidas**. Ataques com condição (Swipe só com o escriba a ≤ 64 px) saem do sorteio quando a condição falha.
- **FR-604** **DamageFilter**: todo dano que chega ao chefe passa por um filtro por `source_tag` (ataque automático, cada palavra, combo). Serve para (a) regras de chefe (Mãe das Traças: só palavras ferem; Semíhaza F3: só LUX) e (b) tetos **[P]**:
  - **por conjuração:** a soma de todos os ticks de um mesmo cast até **120** entra inteira; de 120 a **240** entra pela metade; acima de 240 nada. Efetivos: MORTIS 70, DOMINUS 100, MISERERE 200, MISERERE×GLORIA 240, SANCTUS 240, SPIRITUS 240 (o topo empata; a ordem pelo tamanho não inverte).
  - **por fase:** o dano para no limiar; o sobrante se perde e o chefe fica **1,5 s invulnerável** no PhaseShift.
  - Ataque automático e PURGO sem teto (o automático sozinho levaria ~20 min: palavras são o caminho).
- **FR-605** **LetterSafety [P]**: durante a luta, se houver menos de **3** letras úteis no chão por **4 s**, cai uma letra pelo drop ponderado (FR-013) a 48–80 px do escriba (cooldown 4 s). "Letra útil" = está em alguma palavra conhecida. Essencial na F1 (sem Summon); nas F2–F3 é rede, a fonte principal são os Diabretes do Summon.
- **FR-606** O chefe é **um só corpo grande** fora do EnemyManager (não é inimigo comum): tem hurtbox própria, recebe dano de `EnemyQuery` (as palavras e o ataque automático o acertam como a um inimigo) e fere por contato (forte).

### Asmodeus
- **FR-607** Entrada: depois da loja da onda 9, a página escurece, os inimigos restantes se dissolvem e Asmodeus sobe do centro-topo (animação de entrada). A cutscene C1-03 entra aqui na 008.
- **FR-608** **HP 1500**; fases em 66% e 33% (asset catalog §5) **[P]**. Contato fere forte (2). Telegrafia mínima de qualquer ataque: **600 ms**.

  | Ataque | Telegrafia | Forma | Dano |
  |---|---|---|---|
  | Raio | 900 ms | linha de 12 px, tela inteira, mira travada, ativo 200 ms | 2 |
  | Swipe | 600 ms | arco de 120°, 48 px; só com o escriba a ≤ 64 px | 1 |
  | Summon | 800 ms | 4 Diabretes em anel de 40 px; cooldown 10 s; máx. 8 vivos | — |
  | Raio duplo | 1000 ms | 2 linhas a ±20°, 12 px | 2 |
  | Cruz giratória | 1200 ms | 4 braços de 180 × 10 px, 36°/s, 5 s | 2 |
  | Rasura | 1000 ms | círculo de 24 px travado no escriba; apaga 1 letra do atril | — |

  | Fase | Pesos | Intervalo entre ataques |
  |---|---|---|
  | **F1 (100–66%)** | Raio 60 · Swipe 40 | 1,6 s |
  | **F2 (66–33%)** | Raio 30 · Swipe 20 · Duplo 25 · Summon 15 · Rasura 10 | 1,4 s |
  | **F3 (<33%)** | Cruz 25 · Duplo 25 · Raio 15 · Swipe 15 · Summon 10 · Rasura 10 | 1,08 s (×1,3) |
- **FR-609** **Rasura [D-062]** (narrativa C1-03: "ele apaga, inclusive as letras do atril"): ataque telegrafado (F2 e F3, cooldown 12 s / 9 s) que, se acertar, **apaga a última letra do atril**, sem dano de vela e sem contar como heresia. Proteções **[P]**: nunca apaga com o atril VALID (palavra pronta), nem a letra pega há menos de 0,5 s; atril vazio = nada. Contra-jogo: esquivar, ou soltar as letras com Shift antes (elas voltam ao chão).
- **FR-609b** **Janela de exposição [D-062]** (game-design): depois de um Raio ou Swipe que **errou**, o chefe fica **exposto por 1 s** e as palavras causam +25%. Premia quem lê o ataque sem tirar das palavras o papel de vencer.
- **FR-609c** **DOMINUS no chefe [D-062]**: stun de 1 s (em vez de 3 s nos inimigos) para não travar a luta.
- **FR-610** Asmodeus se move devagar pela metade de cima da página; nunca sai da área jogável.
- **FR-611** Morte: animação de dissolução (14 quadros), **explosão de letras douradas**, `boss_defeated` → `chapter_completed`.
- **FR-611b** Derrota no chefe = o Game Over normal (sem checkpoint; roguelite curto). Velas, atril, buffs e itens entram na luta como saíram da loja **[P]**.

### Sensação
- **FR-612** **Screen shake** (D-047 6B): câmera com shake em golpe forte do chefe, na troca de fase e na morte; e na morte de campeão (pendência da 005). Ajuste `shake_enabled` (padrão ligado) em `GameState`/configuração; a tela de Opções (007) liga e desliga.
- **FR-613** HUD: barra de vida do chefe no topo (fora da área central), com o nome e marcas nas fases.

### Técnica
- **FR-614** Ataques como cenas/Resources pooled; nenhum `instantiate()` durante a luta. Telegrafias com a mesma linguagem da 005 (BLOOD tracejado).
- **FR-615** Debug `?boss` abre direto na luta (com `?unlock=all&atril=8` combinável).

## Critérios de sucesso

- **SC-601** As três fases trocam nos limiares certos e só usam os ataques da fase (teste).
- **SC-602** Nenhum ataque repete mais de 2 vezes seguidas (teste com seed).
- **SC-603** O DamageFilter corta o golpe acima do teto e nenhuma palavra (nem MISERERE × GLORIA) tira mais que uma fase de uma vez (teste).
- **SC-604** Com LetterSafety, o chão nunca fica sem letra útil por mais de T s (teste).
- **SC-605** Todo ataque tem telegrafia de pelo menos **600 ms** antes do dano (teste).
- **SC-606** Matar Asmodeus emite `chapter_completed` (teste de integração).
- **SC-607** A luta roda a 60 FPS no Chrome (média ≥ 60 / p95 ≥ 55) com Summon + projéteis (stress `?stress=boss`).
- **SC-608** Um bot (sonda) com o vocabulário do Cap. 1 e ~6 compras vence Asmodeus em **3–4 min** **[D-062]**. O HP 1500 é estimativa: calibrar com a sonda.
- **SC-609** Morrer no chefe leva ao Game Over existente (teste).
