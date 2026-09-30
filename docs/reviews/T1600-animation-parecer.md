# T1600 — Parecer do animation-agent: tempos da 016 "Graça"

> 2026-09-30 · Base para as Fases 2, 4 e 5 da 016. Escala do projeto 50/100/200/400/700 ms. Sem easing: só degraus e cortes secos, posições em px inteiros.

## Avisos para o código
- **Relógio real:** GraceFlow, GraceSeals e o brilho da barra contam com `Time.get_ticks_msec()`, não somando `delta`, porque o hit-stop (`Engine.time_scale` 0) encolhe o `delta` até dos nós ALWAYS.
- **Tremor parado na pausa:** ao entrar em ANNOUNCING, zerar o offset da `ShakeCamera`. Os selos ficam num CanvasLayer que não segue a câmera.
- **Som na pausa:** o player de UI do `AudioManager` precisa estar em ALWAYS.

## 1. Anúncio (`announce_time` 400 ms)
- **Barra de Graça:** brilho de 4 degraus de 50 ms (CHALK e GOLD alternando). No q0 a barra salta a 100%; no q6 o número do nível sobe (e o texto sobe 1 px por 100 ms); no q12 a barra mostra a sobra.
- **Página escurecida** (`dim_screen`): 25% no q0, 50% no q6 (75% no modo alto contraste).
- **Cada selo cai de cima** em 4 degraus de 50 ms:
  - y−8 em xadrez 50%;
  - y−3 cheio;
  - y+1 com squash (+4 px de largura, −4 px de altura);
  - repouso.
- **Ordem de entrada:** selo 1 no q6, selo 2 no q9, selo 3 no q12. O selo 3 termina no q24, onde saem `seals_shown` e a trava começa.
- **Som:** um "toc" de pergaminho por selo.

## 2. Trava (400 ms, relógio real)
- **Durante a trava:** a etiqueta da tecla fica desabilitada (INK_SOFT sobre PARCHMENT_OLD) e nada pisca.
- **Ao liberar:** a etiqueta vira `draw_tag` GOLD_LIGHT e sobe 1 px por 100 ms, e a pena-cursor aparece. Uma tecla que já estava segurada continua desabilitada até ser solta.
- **Foco:** anda durante a trava; só confirmar e clique ficam bloqueados.
- **Pausa (Esc) por cima dos selos:** ao fechar, os selos continuam na tela e só a trava recomeça.

## 3. Foco
- **Troca de foco:** corte no mesmo quadro, com o som "mover" do menu.
- **Selo em foco:**
  - sobe 4 px (`HOVER_LIFT`);
  - a sombra vai de (2,2) para (3,6);
  - ganha contorno GOLD de 2 px;
  - a pena-cursor oscila a 400 ms.
- **Foco inicial:** selo 1.

## 4. Carimbo (`stamp_time` 400 ms)
| Quadros | O que acontece |
|---|---|
| q0–q2 | `blessing_chosen`; o selo escolhido sobe mais 2 px |
| q3–q5 | Impacto: afunda 1 px, squash +6/−4 px, flash CHALK de 50 ms, 4 respingos de 2×2 px na diagonal (4 e 8 px), som de carimbo em cera |
| q6–q11 | Assentado, continua 1 px afundado; o efeito aparece no HUD |
| q3–q9 | Os outros 2 selos ficam em xadrez 50% e somem no q9 |
| q12–q17 | Selo escolhido em xadrez; escurecimento 25% |
| q18–q23 | Selo escolhido some; escurecimento 0% |
| q24 | `seals_hidden`, a pausa acaba e começam 0,5 s de invulnerabilidade (usa o visual que já existe) |

## 5. Fila de níveis
- **Transição:** carimbo sem a saída do escurecimento (200 ms), saída do selo em xadrez (100 ms), novo anúncio sem os degraus de escurecimento (400 ms) e nova trava (400 ms).
- **Tempo total:** 1100 ms entre um carimbo e a próxima escolha liberada.

## 6. Barra de Graça
- **Morte:** a barra enche direto, sem pulso.
- **Palavra** (inclusive o eco do VERBUM):
  - o trecho ganho aparece em CHALK;
  - a barra sobe 1 px e fica com borda GOLD por 100 ms;
  - depois a cor cheia avança sobre o CHALK em 200 ms.
- **Enchimento:** pode usar o `delta` do jogo. Só o brilho usa o relógio real.

## 7. Pingo de cera
- **Nascimento:** 4 degraus de 50 ms (y−6, y−2, squash +2/−2 px, repouso) e som "plic". Só pode ser pego depois de 200 ms.
- **Parado:** 2 quadros de 700 ms em ping-pong, sem GOLD.
- **Piscar nos últimos 2 s:** igual à letra (alpha 1 e 0,3 a cada 100 ms; nos últimos 0,5 s, a cada 50 ms).
- **Velas cheias:** o pingo balança ±1 px (2 × 50 ms), uma vez por entrada, sem som.
- **Coleta:**
  - o pingo sobe 2 px e depois mais 4 px em xadrez, e some (100 ms);
  - sai `wax_drop_collected`;
  - a chama da vela no HUD fica CHALK por 100 ms e 1 px maior.

## 8. Hit-stop, tremor e som
- Nenhum hit-stop e nenhum tremor novos (UI não treme).
- **Sons:**
  - subir de nível: sino ou coro de até 700 ms;
  - selo pousando: "toc";
  - carimbo: carimbo em cera;
  - pingo: "plic" e vela acendendo.

## Números para os dados
- **`grace.tres`:**
  - `announce_time` 0.4
  - `bar_flash_time` 0.2
  - `bar_flash_step` 0.05
  - `dim_step` 0.1
  - `seal_enter_steps` 4
  - `seal_enter_step` 0.05
  - `seal_enter_start` 0.1
  - `seal_stagger` 0.05
  - `unlock_pop` 0.1
  - `stamp_time` 0.4
  - `stamp_lift` 0.05
  - `stamp_impact` 0.05
  - `stamp_hold` 0.1
  - `stamp_exit_step` 0.1
  - `queue_exit` 0.1
  - `bar_word_pulse` 0.1
  - `bar_fill_time` 0.2
- **`wax_drop.tres`:**
  - `lifetime` 12
  - `blink_time` 2
  - `blink_slow` 0.1
  - `blink_fast` 0.05
  - `blink_fast_window` 0.5
  - `blink_alpha` 0.3
  - `spawn_step` 0.05
  - `pickup_lock` 0.2
  - `idle_step` 0.7
  - `reject_shake` 0.1
  - `collect_time` 0.1

## Para o playtest
- A trava conta a partir do fim da entrada, então são 800 ms do anúncio até poder escolher.
- Se o autor achar lento, a alavanca é começar a trava no q0, o que dá 400 ms.
