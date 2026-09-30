# T1600 — Parecer do design-agent: selos, barra, ícones e pingo da 016

> 2026-09-30 · **APROVADO** com 2 ressalvas, que já estão resolvidas abaixo. Maquete: `img/t1600_seals_mock.png`. Mapas de pixels: `T1600-design-maps.json`.

## Ressalvas
- **C1 — xadrez 50%:**
  - A animação proposta tinha xadrez 50% na entrada e na saída dos selos e na coleta do pingo. Isso vai contra a D-076 e o art bible §3.
  - Resolução: segue a regra de pixel art, que é diretriz permanente do autor, e usa quadros lisos.
    - Entrada no degrau y−8: só a silhueta do selo em INK_SOFT.
    - Saída: carta lisa PARCHMENT_OLD com borda INK_SOFT, depois corte seco.
    - Coleta do pingo: silhueta lisa em CHALK.
  - Os tempos do animation-agent continuam os mesmos.
- **C2 — balão sobre a barra:** no `bark_director.gd`, `HUD_RECTS` passa de `Rect2(8,6,150,28)` para `Rect2(8,6,150,32)`.

## Selos (CanvasLayer acima do HUD, fora da câmera)
**Fundo e título**
- **Escurecimento:** `dim_screen` 25% e depois 50%; 75% no alto contraste. O HUD também escurece.
- **Título:**
  - placa INK de `Rect2(320−(w+16)/2, 44, w+16, 18)`;
  - texto CHALK em escala 2, y 47;
  - chave `GRACE_LEVELUP_TITLE` "GRAÇA - NÍVEL {n}";
  - com fila, `draw_tag("+k")` à direita.

**Posição das cartas**
- Carta de 128×132, com passo de 152.
  - 3 cartas: x 104, 256, 408.
  - 2 cartas: x 180, 332.
  - 1 carta: x 256.
  - y 96 em todos os casos.
- Área de clique: `Rect2(x, 90, 128, 160)`.

**Camadas de cada selo**
| Camada | O que é | Detalhes |
|---|---|---|
| L0 | Sombra | INK_SOFT em (2,2); no foco, (3,6). |
| L1 | Pergaminho | Borda INK de 1 px (2 no alto contraste), miolo PARCHMENT e `frame` PARCHMENT_OLD recuado 2 px. |
| L2 | Lacre | Duas fitas 3×12 PARCHMENT_OLD com contorno INK, em x+57 e x+68, y+140..152. Anel INK r10 e disco BLOOD_DARK r9 em (x+64, y+138). Cruz CHALK 2×6 + 6×2. Brilho GOLD_LIGHT em (x+68, y+132). |
| L3 | Ícone | 24×24 ampliado 2×, em (x+40, y+10). |
| L4 | Texto | Nome INK a 1×, até 20 caracteres por linha, em y+64 (e y+72). Divisor PARCHMENT_OLD 104×1 em (x+12, y+82). Frase INK_SOFT em y+88, 96 e 104, até 3 linhas. |
| L4b | Contas do teto | Uma conta 7×7 por escolha possível, passo 10, centradas em y+116. Já escolhida: INK. Esta escolha: borda INK, miolo GOLD e canto GOLD_LIGHT. Falta: borda INK_SOFT e miolo PARCHMENT_OLD. |
| L5 | Tecla | `draw_tag(key_label(grace_pick_N), x+64, y−2)`. Travada: PARCHMENT_OLD e INK_SOFT. Liberada: GOLD_LIGHT e INK. |
| L6 | Foco | Sobe 4 px e a borda vira GOLD de 2 px (mais CHALK no alto contraste). Pena-cursor em (x−6, y+66+bob), só depois da trava. Foco inicial no selo 1. |

**Rodapé e carimbo**
- **Rodapé:**
  - placa INK em y 321..333;
  - texto `text_on_dark(true)` em y 324;
  - chave `GRACE_HINT`.
- **Carimbo:** flash CHALK no corpo da carta; o lacre não muda.

## Barra de Graça (HUD)
- **Área:** `hud_rect` = `Rect2(8, 28, 108, 10)`, logo abaixo das velas e fora da área central.
- **Número do nível:**
  - etiqueta INK de `Rect2(8,28,max(17,w+6),10)`, com miolo GOLD_LIGHT;
  - número INK em y 30.
- **Barra:**
  - borda INK em `Rect2(27,30,88,6)`;
  - miolo em `Rect2(28,31,86,4)`: vazio PARCHMENT_OLD, cheio GOLD, com a linha de cima GOLD_LIGHT;
  - assento INK_SOFT 86×1 em (28,36);
  - largura do cheio = `floori(86·fração)`.

## Ícones 24×24 e pingo de cera
- **Ícones novos:** `itm_consecrated_ink` (gota com auréola) e `itm_grace_full` (ostensório). Mapas no JSON.
- **Ícones atuais:** os 7 servem como estão.
- **Pingo de cera:** `ITM_WAX_DROP` 8×13, pivot (4,12). É um toco de vela apagada com fumaça INK_SOFT, sem GOLD nem BLOOD.
  - Base: `itm_wax_drop_base`.
  - Fumaça: `itm_wax_drop_smoke`, 2 quadros em ping-pong de 700 ms.

## Tela de Opções
A subpágina **Remapear teclas** passa de 12 para 15 linhas.
- **Linhas:**
  - `KEY_Y0` 58, `KEY_STEP` 14, `KEY_ROW_H` 12;
  - `KEY_SUBTITLE_Y` 48;
  - faixa de foco `grow(1)`; no alto contraste, `grow(2)` INK mais `grow(1)` GOLD.
- **Aviso e Voltar:**
  - `NOTICE` em `Rect2(124,272,392,12)`;
  - `KEY_BACK` em (320,294).
- **Rótulos:** `ACTION_GRACE_PICK_1..3` = "GRAÇA: SELO N".
