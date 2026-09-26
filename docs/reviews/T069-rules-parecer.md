# T069 — Parecer do rules-agent: 7 palavras, heresia, purge e drop

> 2026-09-24 · Formato do `.claude/agents/rules-agent.md` · Escopo: `data/words/*.tres`, `data/tuning/drop_tuning.tres`, `data/enemies/imp.tres`, FR-013/FR-017..FR-022.

**PARECER: VÁLIDO COM RESSALVAS**

## 1. Números das 7 palavras

| Palavra | Letras | power_budget | Parâmetros | Leitura |
|---|---|---|---|---|
| LUX | 3 | 1.0 | dano 8 · largura 10 · alcance 320 | Mata qualquer Diabrete na linha (HP 2). Forte para 3 letras, mas é direcional: exige mirar andando. ✅ |
| PAX | 3 | 1.0 | raio 72 · empurrão 80 · stun 1.5s | Palavra de fuga, sem dano. ✅ |
| CRUX | 4 | 1.6 | 3 × 0.25s por 4s · braço 48 | Até ~48 de dano por inimigo parado no braço; na prática, 1–3 ticks. Bloqueio de projéteis testado. ✅ |
| VITA | 4 | 1.6 | +1 vela | Não escala com power (vela é inteira). Com a regeneração parado (D-011), VITA é o jeito ativo de curar. ✅ |
| AQUA | 4 | 1.6 | raio 56 · lentidão 50% · 4s | Controle de área. ✅ |
| IGNIS | 5 | 2.4 | 2 × 0.25s por 3s · raio 48 | Até 24 de dano em área. ✅ |
| MORTIS | 6 | 3.5 | mata HP ≤ 5 · 20 nos outros | Limpa a tela. Exige atril 6 (upgrade da 003). ✅ |

## 2. Checagens

- [x] Latim real, 3 a 8 letras — as 7 passam no Lexicon (teste `test_real_base_lexicon_loads`).
- [x] Poder monotônico com o tamanho — `test_word_power` (1.0 < 1.6 < 2.4 < 3.5).
- [x] Só letras do alfabeto ativo; B trancado até VERBUM — `test_gated_b_*`.
- [x] Todo número mora em `.tres` — nenhum número de gameplay nos scripts dos milagres.
- [x] Coerente com a game bible — efeitos da D-013; heresia da D-014; purge da D-009.
- [x] Regras cruzadas verificadas: combos (não implementados na 001; nenhum efeito bloqueia a 002) · VITA × velas máx (não passa do máximo) · MORTIS × capacidade 5 (recusado, `test_mortis_needs_atril_6`).

## 3. Mudanças feitas nesta fase (precisam do seu ok)

| ID | Antes | Depois | Justificativa |
|---|---|---|---|
| D-030 | Diabrete HP 3 | **HP 2** | Recomendação da C-004 aplicada por falta de resposta (regra combinada). A sonda com HP 2 matou ~2× mais. |
| D-030b | "Espaço fora de VALID = heresia" | Atril **vazio** + Espaço = nada | Apertar Espaço sem nenhuma letra não é "falar sem sentido"; puniria toque acidental. |
| D-031 | Letras do purge a 20px, puxadas pelo ímã (40px) depois de 0.3s | Letras do purge ficam **soltas**: o ímã as ignora; o jogador as recolhe andando por cima | Sem isso, o purge devolvia as mesmas letras na mesma ordem ruim em 0.3s — o FR-020 ("tentar de novo em outra ordem") não funcionava. |
| D-032 | Poça de aggro atrai todos | Atrai os inimigos a até `heresy_pool_radius` (64px) | Texto literal do FR-019. |

## 4. Ressalva principal: economia de letras (C-004 continua aberta)

A sonda automática mostrou o mecanismo funcionando (CRUX, AQUA, PAX conjuradas no jogo real), mas **o bot não é uma boa medida do ritmo de palavras**: o ímã puxa letras inúteis enquanto ele foge, e ele entra em laços de purge. Os números que ele produziu (0–2 palavras por onda) são um **piso**, não a experiência real.

**Recomendação:** playtest humano de 3 ondas no build web (`build/web`) antes de mexer em mais números. Alavancas prontas, todas em `.tres`, sem código:

| Alavanca | Arquivo | Efeito esperado |
|---|---|---|
| `letter_drop_chance` 0.6 → 0.8 | `data/enemies/imp.tres` | +33% letras |
| `target_bonus` 10 → 15 | `data/tuning/drop_tuning.tres` | mais letras úteis |
| `selective_magnet` false → true | `data/tuning/drop_tuning.tres` | o ímã só puxa letras que continuam a palavra (experimento) |
| `magnet_radius` 40 → 30 | `data/player/anselmo.tres` | menos letras inúteis puxadas sem querer |
| `letter_lifetime` 8 → 10 | `data/tuning/drop_tuning.tres` | mais tempo para escolher a ordem |

O rules-agent **não** aplica nenhuma dessas sem o parecer do playtest.
