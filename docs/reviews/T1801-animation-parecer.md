# T1801 — Parecer do animation-agent: 018 Poções

> 2026-10-01 · Degraus de 50/100 ms, px inteiros, sem easing. UI usa relógio real; efeitos da simulação usam o delta do jogo. **Nenhuma poção tem hit-stop nem shake** (pilar 1: o impacto é das palavras). Cores INK/INK_SOFT/CHALK, sem GOLD.
> Nota do Claude: onde o parecer pede "0,3 ↔ 1" (alpha), aplicar como alternância INK ↔ INK_SOFT (regra do HUD T1800: sem alpha desenhado), como na barra do menu da letra.

## 1. Beber (teclas 3–6) — o escriba não para
| Poção | Frames × 50 ms | Evento |
|---|---|---|
| Óleo da Unção | 3 | f1 `potion_used` (a vela acende junto) |
| Água Benta | 4 | f1 `potion_used`, f2 círculo abre |
| Vinho do Fervor | 3 | f1 `potion_used` |
| Iluminura | 4 | f4 pede o menu da letra |

Frasco sobe 2 px até a mão (f1–f2) e volta (f3); sprite sobreposto.

## 2. Efeitos
- **Óleo:** vela acende em 2 degraus de 100 ms; a vela nova pisca 2× no HUD. Velas cheias = bloqueada (não gasta).
- **Água Benta:** abre em 4×50 ms (25/50/75/100% do raio); anel INK_SOFT 1 px com pulso de 700 ms (1↔2 px, degraus de 350 ms); aviso nos últimos 1000 ms (pisca a 100 ms; a 50 ms nos últimos 300 ms); fecha em 4×50 ms. Heresia dentro: mesmo fechamento + flash CHALK de 50 ms.
- **Vinho:** 1 px CHALK no contorno da arma ativa no HUD + barra de duração no ícone; aviso nos últimos 1000 ms; some em 1 degrau.
- **Iluminura:** a pena sobe 2 px e brilha CHALK 4×50 ms; no f4 abre o menu (câmera lenta e trava de 100 ms de sempre; os 2,5 s contam do menu). Pausa congela o rito; menu ou selo antes do f4 cancela sem gastar.
- Renovar a mesma poção: barra e pulso recomeçam + flash CHALK de 50 ms no ícone.

## 3. Tecla
| Caso | Resposta |
|---|---|
| Sem carga | ícone treme 1 px (2×50 ms) e o "0" pisca 2× (2×100 ms); som seco |
| Bloqueada | ícone apagado enquanto durar; ao apertar, X CHALK de 1 px por 100 ms (sem tremor) |
| Em intervalo | a barra do ícone mostra o intervalo (degraus de 100 ms); ao apertar, flash de 50 ms |
Som no máximo 1 a cada 100 ms.

## 4. Campos para os .tres
Global: `drink_frame_ms` 50; frames 3/4/3/4; `warn_ms` 1000, `warn_blink_ms` 100, `warn_blink_fast_ms` 50, `warn_fast_last_ms` 300; `deny_shake_ms` 100 (1 px); `deny_blink_ms` 200; `blocked_x_ms` 100; `use_flash_ms` 50; `refresh_flash_ms` 50; `sfx_min_gap_ms` 100; `hitstop_ms` 0; `shake_px` 0.
Óleo `light_ms` 200; Água Benta `open_ms` 200, `close_ms` 200, `pulse_ms` 700, `heresy_flash_ms` 50; Vinho `mark_ms` 100; Iluminura `rite_ms` 200, `request_frame` 4. Durações, intervalo e cargas: rules-agent (e se contam em tempo real ou de jogo).
