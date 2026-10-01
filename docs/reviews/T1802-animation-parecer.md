# T1802 — Parecer do animation-agent: subir de nível com feixe e câmera lenta (D-095)

> 2026-10-01 · Skills: ui-ux-game (feedback instantâneo), game-development/game-art. Sem alpha, sem xadrez, px inteiros.

1. **Câmera lenta ×0,2** (a mesma do menu da letra), dono `levelup_slow` no `TimeScale`; entrada 0,5 por 50 ms → 0,2; **sem rampa de saída** (aos 2,5 s o jogo pausa para os selos; o GraceFlow limpa o fator ao anunciar).
2. **2,5 s em tempo real** contados por `delta / TimeScale.factor_product()` (hit-stop e Pausa não comem a barra); parar o contador com a árvore pausada.
3. **Feixe (50 quadros de 50 ms):** entrada 0–200 ms (desce 25/50/75/100% da altura até os pés; flash CHALK de 50 ms no Anselmo no q3; coro até 700 ms); pulso 200–2200 ms (16 px por 200 ms, 12 px por 200 ms, cortes secos); saída 2200–2500 ms (12, 8, 4 px por 100 ms). Cores: borda GOLD 2 px, miolo GOLD_LIGHT, filete CHALK 4 px (2 px no estreito). 4 motes CHALK 2×2 subindo 2 px a cada 100 ms (opcional). A página não escurece.
4. **Barra:** 6 px acima da cabeça, segue o escriba, 25×3 px com contorno INK; 25 degraus de 100 ms esvaziando da direita para a esquerda; GOLD; nos últimos 700 ms alterna GOLD/CHALK a 100 ms (a 50 ms nos últimos 200 ms).
5. **Casos:** menu da letra aberto ou no intervalo → o feixe espera; durante o feixe o menu não abre (fica na fila); hit-stop congela tudo e volta; morte limpa o fator e corta o feixe; vários níveis = 1 feixe só, os selos em fila como hoje; o jogador anda, ataca e conjura normalmente a ×0,2; Esc congela.
6. Sem hit-stop e sem shake.
7. **Campos em `grace.tres`:** `levelup_slow_time` 2.5, `levelup_slow_factor` 0.2, `levelup_slow_in_steps` [0.5, 0.2], `levelup_slow_in_step_time` 0.05, `beam_enter_steps` 4, `beam_enter_step` 0.05, `beam_pulse_step` 0.2, `beam_width` 16, `beam_width_narrow` 12, `beam_exit_widths` [12, 8, 4], `beam_exit_step` 0.1, `bar_width` 25, `bar_height` 3, `bar_offset_y` 6, `bar_step` 0.1, `bar_blink_time` 0.7, `bar_blink_step` 0.1, `bar_blink_fast_time` 0.2, `bar_blink_fast_step` 0.05, `beam_flash` 0.05, `mote_count` 4.
