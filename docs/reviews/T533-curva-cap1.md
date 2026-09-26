# T533 — Parecer do rules-agent: curva das 9 ondas do Capítulo 1

> 2026-09-25 · Dados: sonda automática, 2 execuções por onda (`tools/balance_probe.gd -- cast wave=N`).

**PARECER: VÁLIDO COM RESSALVAS. Nenhum número muda agora.**

> ⚠️ **Errata (2026-09-26):** a sonda usada aqui apertava "conjurar" em todo frame, o que desde a Fase 5 da 001 gera heresia constante. A coluna "Palavras" da §2 está **contaminada** (subestima as palavras). Os dados de §1 (curva de carga) continuam válidos. Dados corretos na §6.

## 1. A curva é monotônica
- **Duração:** 60 → 90 s. **Diabrete:** 0.5 → 1.8 por s no início da onda.
- **Carga média (HP/s):** 2.5 · 3.0 · 3.45 · 4.05 · 5.0 · 5.4 · 6.45 · 7.5 · 8.35. Nenhum salto passa de 25%; o maior é o da 4 para a 5 (+23%, entrada da Gárgula).
- **Um inimigo novo por onda:** Traça (2), 1º campeão (3), Borrão (4), Gárgula (5), Monge (6). Da 7 à 9, só intensidade.

## 2. O que o bot permite concluir

| Onda | Morreu aos (s) | Palavras |
|---|---|---|
| 1 | 43–54 | 0 |
| 2 | 33 | 0 |
| 3 | 17–28 | 0 |
| 4 | 16–41 | 0 |
| 5 | 23–29 | 0 |
| 6 | 20–23 | 0 |
| 7 | 16–22 | 0 |
| 8 | 14–29 | 0 |
| 9 | 23–29 | 0 |

- **Dá para concluir:** sem palavras, o ataque básico (~1.25 HP/s) não segura nem a onda 1 (2.5 HP/s de carga). Isso é esperado: a palavra é o núcleo do jogo. Nenhum teto de `max_alive` travou o spawn (pico de 77 contra o teto de 110).
- **Não dá para concluir:** ritmo de palavras, dificuldade relativa entre as ondas, se alguma onda é vencível.
- **Alerta de "regressão", investigado pelo Claude:** não é regressão do jogo. As coletas mostram laços ("CCCC", "CCI"): o bot entra em beco sem saída, faz purge, as letras ficam **soltas** ao redor (D-031) e ele esbarra nelas de novo. A medição da C-004 foi feita **antes** da D-031, quando o bot esvaziava o atril. Os testes de integração do ciclo (coletar → LUX → conjurar → purge) continuam passando.

## 3. Mudar agora ou depois do playtest
- **Agora:** nada.
- **Depois do playtest humano:** ritmos do Diabrete nas ondas 1–3 · dano do dash da Gárgula (2 → 1, ou `windup` 0.6 → 0.8, se o jogador morrer quando ela entra) · `fire_interval` do Monge · `trail_interval` do Borrão · `hp_mul` do campeão.

## 4. O que fica provisório até a loja (003)
- **Provisório:** ritmos e durações das ondas 4–9, `hp_mul` do campeão e o teto de 3 velas. A onda 9 (~3,3× a carga da onda 1) foi pensada para quem já tem upgrades; testá-la "do zero" sempre vai dar derrota, e isso não é defeito.
- **Firme:** a onda 1 como linha de base, a ordem de introdução, a hierarquia de HP (Traça 1 < Diabrete 2 < Borrão 3 < Monge 4 < Gárgula 5), as chances de drop e os parâmetros de comportamento.
- **Como medir:** as ondas 4–9 só com o perfil de upgrades de uma run, que ainda está [A DEFINIR] pela 003.

## 5. Sugestão de ferramenta (não é número)
Um modo **invencível** da sonda que registre letras úteis por minuto e palavras possíveis, para medir o fluxo de letras sem depender de o bot sobreviver.

## 6. Fluxo de letras com a sonda corrigida (2026-09-26, D-047 2B)

Sonda invencível (`-- cast god wave=N`): o bot só conjura quando o atril está VÁLIDO e usa purge. 2 execuções por onda. "Alvo" = letras que servem para alguma palavra conhecida no momento.

| Onda | Letras caídas/min | Alvo/min | Coletadas/min | Comidas (Traça) | Palavras/min | Heresias |
|---|---|---|---|---|---|---|
| 1 | 21–32 | 8–9 | 10–19 | 0 | 0–1,0 | 0 |
| 2 | 35–89 | 9–28 | 18–55 | 7–8 | 0–1,9 | 0 |
| 3 | 15–54 | 6–24 | 8–32 | 6–8 | 0,9–2,6 | 0 |
| 4 | 30–31 | 6–7 | 15–16 | 7–10 | 0–0,8 | 0 |
| 5 | 14–38 | 2–15 | 7–26 | 7–10 | 0–3,0 | 0 |
| 6 | 24–25 | 6 | 12–14 | 10–11 | 0 | 0 |
| 7 | 17–22 | 4 | 8–10 | 9–13 | 0,7 | 0 |
| 8 | 20–27 | 5–6 | 11–12 | 8–15 | 0–0,7 | 0 |
| 9 | 19–32 | 8 | 10–16 | 10–12 | 0–1,3 | 0 |

**Leitura:** letras não faltam (~25/min), mas só ~6/min servem e a ordem certa raramente se completa: **mediana ~0,7 palavra/min** (0–4 por onda). A partir da onda 4 as Traças comem 7–15 letras por onda. O bot é pior que um humano (não planeja a palavra), então isto é um piso. Confirma a C-004; a decisão continua esperando o playtest do autor.
