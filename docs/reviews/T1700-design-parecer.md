# T1700 — Parecer do design-agent: visual da 017 "Arsenal sagrado"

> 2026-09-30 · **APROVADO com ressalvas.**
> - **Regra das armas:** no mundo, toda arma é miolo CHALK com contorno INK; nenhuma usa GOLD (o dourado é das palavras) nem BLOOD (é dos inimigos e das telegrafias).
> - **Mapas de pixels:** `T1700-design-maps.json` (`icons` = 7 ícones + `blessing_scapular`; `world` = sprites do mundo).
> - **Maquetes:** `img/t1700_mock_final_2x.png`, `img/t1700_mock_attacks_2x.png`, `img/t1700_icons_sheet.png`, `img/t1700_mock_inventory_crop4x.png`, `img/t1700_mock_menu_veil0_crop4x.png`.

## Ícones 24×24 (ITM_)
- **Armas:** `weapon_copyist_quill`, `weapon_bible` (livro aberto com o raio subindo), `weapon_crucifix`, `weapon_rosary` (anel de contas com a cruz), `weapon_censer` (argola e correntes), `weapon_aspergillum`.
  - Mesmo molde dos outros ícones: moldura INK_SOFT, contorno INK, material P/O/C. O destaque, que nos outros é GOLD, aqui é CHALK.
- **`reverse_magnet`:** pedra com 4 setas para fora.
- **`blessing_scapular`:** a bênção antiga "Rosário" vira Escapulário; mantém 1 destaque GOLD porque é bênção, não arma.

## Ataques no mundo (só K, k e C)
| Arma | Asset | Detalhes |
|---|---|---|
| Pena | `PRJ_INK_DROP` 4×4 | Como hoje; a v2 de 5×5 fica para a arte final |
| Bíblia | `PRJ_BIBLE_BOOK` 10×7 | Livro 10 px à frente, na direção da mira |
| | `VFX_BIBLE_BEAM` | Raio de 5 px (miolo CHALK de 3, borda INK de 1) desenhado com **pincel de pixel inteiro por Bresenham**, nunca `draw_line` com largura |
| | `VFX_BIBLE_TIP` 7×7 | Ponta do raio, 2 quadros |
| Crucifixo | `PRJ_CRUCIFIX` 8×10 | Sempre de pé, nunca invertido; rastro de 1 silhueta INK_SOFT |
| Rosário | `PRJ_ROSARY_BEAD` 6×6 + `PRJ_ROSARY_CROSS` 7×7 | A cruz é a 1ª conta |
| Turíbulo | `PRJ_CENSER` 8×7 + elos 2×2 a cada 3 px | Corrente da mão até o turíbulo |
| | `VFX_INCENSE_L/M/S` | Fumaça **abaixo dos inimigos** |
| Aspersório | `PRJ_HOLY_DROP` 4×4 + `VFX_ASPERGE_MOUTH` 9×5 | Gotas em leque |
| Ímã reverso | `VFX_REPEL_WAVE` | Anel INK_SOFT de 3 px (+1 px INK quando o nível dá dano), 4 raios e o quadro final em 8 arcos; abaixo dos inimigos |

## HUD do inventário (canto de baixo à esquerda)
- **Painel:** `draw_panel(Rect2(8,308,68,46))`; na 018, com as poções, `Rect2(8,308,148,46)`. `hud_rect` = `Rect2(7,307,70,49)` (`Rect2(7,307,150,49)` na 018).
- **Espaço s:** `Rect2(12+32·s, 312, 28, 28)`.
  - Ativo: sobe 2 px, borda INK de 2 px, miolo PARCHMENT.
  - Inativo: PARCHMENT_OLD com o ícone recolorido.
  - Sem GOLD.
- **Tecla:** etiqueta 8×9 no canto de cima à esquerda do espaço, com `key_label(weapon_N)`.
- **Nível:** 5 contas 4×4 em (x+2+5i, 344).
- **Poções (018):** 4 espaços 17×17 em (80+19i, 314), teclas "3" a "6".

## Menu de escolha da letra (acima do escriba, seguindo-o)
- **Posição:**
  - `Mx = clamp(px−50, 4, 536)`, `My = clamp(py−67, 42, 252)`;
  - com pouco espaço em cima, vai para baixo do escriba: `My = py+14`.
- **Painel:** `draw_panel(Rect2(Mx,My,100,46))`.
- **Carta i:** `Rect2(Mx+4+32i, My+4, 28, 28)`, com o losango da letra (`ltr_atlas`) ampliado 2× (a rara usa a linha GOLD do atlas).
- **Marca de letra útil:** anel GOLD/GOLD_LIGHT de 2 px pulsando a 700 ms em **toda letra que continua alguma palavra** (`next_letters`), não só na garantida.
- **Clique:** `Rect2(Mx+2+32i, My+2, 32, 32)`.
- **Foco:** a carta sobe 2 px com borda INK de 2 px; a pena-cursor fica em cima da carta; o foco começa na carta do meio.
- **Barra do tempo:** `Rect2(Mx+4, My+37, 92, 5)`, miolo INK_SOFT que esvazia pela direita; vira INK nos últimos 0,5 s. Sem BLOOD.
- **Fila:** etiqueta "+k" em INK com texto CHALK.
- **Câmera lenta:** sem véu (o xadrez esconde o escriba); **moldura INK de 2 px na borda da tela**.

## Fora do padrão
- **Ícone `rosary` (bênção):** vira `blessing_scapular`.
- **`lodestone`:** sai; entra `reverse_magnet`.
- **`bark_director` `HUD_RECTS`:** acrescentar `Rect2(7,305,150,51)`; calar os balões com o menu aberto.
- **Selo de nível de arma:** a conta "esta escolha" usa miolo CHALK, não GOLD.
- **Art bible:**
  - §4 (anel do ímã), §6.2 e §9 (letras no chão) ficam obsoletos;
  - §2 e §10 ganham a regra "armas sem GOLD".
- **Aspersório e Turíbulo:** são os ícones mais fracos da família; revisar na arte final.
