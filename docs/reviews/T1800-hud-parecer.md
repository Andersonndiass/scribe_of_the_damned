# T1800 — Parecer do design-agent: sistema de HUD

> 2026-09-30 · **HUD atual: REPROVADO. Proposta: APROVADA para implementar.** Nenhum número de gameplay muda.
> Pedido do autor: "melhore este HUD, pesquise como construir um HUD da melhor forma, pegue referências, veja como fazer uma pixel art de HUD adequada — e aplique".
> Maquetes: `img/t1800_hud_017(_2x).png`, `img/t1800_hud_018(_2x).png`, `img/t1800_hud_boss(_2x).png`, recortes 4× `img/t1800_hud_{topleft,inventory,atril}_crop4x.png`.

## Pesquisa (base)
- HUD nos cantos e bordas, centro livre; agrupar por função; 3 níveis de prioridade (sempre visível / contextual / menu).
- Leitura periférica: vida e recarga lidas sem olhar; nunca só cor (forma + posição + ícone).
- Barras em pixel art: moldura escura, trilho e preenchimento com contraste forte de valor, segmentos para contar; 9-slice para painéis; uma paleta só; espaçamento consistente.
- Margem segura e oclusão ≤ 10%.
- Referências: Vampire Survivors (armas em fileira de ícones pequenos), Brotato (vida/xp/material empilhados no canto), Hades (vida embaixo à esquerda, habilidades à direita).
- Fontes: [Rocketbrush — practical and pretty HUD](https://rocketbrush.com/blog/designing-practical-and-pretty-hud-in-video-games) · [Wayline — Bars, meters and panels](https://www.wayline.io/learn/game-ui-art/3) · [Game UI & HUD Design Patterns](https://cdn.jsdelivr.net/npm/@hegemonart/get-design-done@1.60.4/reference/domains/gaming-patterns.md) · [GameMaker — 9-slice](https://gamemaker.io/en/blog/slick-interfaces-with-9-slice).

## 1. Diagnóstico
- **(a) Quadro "I"**: não é HUD — capitular da camada de ornamentos (`tools/gen_arena_placeholders.gd:149-154`, (3,38) 18×18). Parece botão e está na coluna do HUD.
- **(b) Barrinha escura**: não é HUD — obstáculo `bench` (`data/arena/chapter_1.tres` o6, (104,328) 32×8). Colado ao inventário; com as poções da 018 ficaria sob o painel.

| Peça | Arquivo | Falha |
|---|---|---|
| Velas | `candles.gd` (8,8) | Soltas, sem painel |
| Graça | `grace_bar.gd` | GOLD sobre PARCHMENT_OLD 1,38:1; etiqueta "1" parece botão; sem segmentos |
| Tempo/onda | `wave_timer.gd` | Texto solto |
| Tinta | `ink_counter.gd` | Solta; margem 8 ≠ 6 do tempo |
| Atril + dicas | `atril_view.gd` | Espaços 1,54:1; sem recipiente; dicas flutuando |
| Combo | `combo_window.gd` | Barra solta |
| Inventário | `weapon_bar.gd` | Único painel; alto demais (contas 10 px); **sem recarga**; colado ao banco |
| Chefe | `boss_bar.gd` Y35–60 | Invade a faixa do menu da letra (My ≥ 42) |

## 2. Sistema
- **Grade:** margem da tela 6 px até a borda externa; módulo 4; 4 px entre painéis; respiro 3 (12 nas laterais do atril). Oclusão 5,0% (017) a 7,7% (018).
- **Painel padrão `UiStyle.draw_plate(ci, r)`** (9-slice desenhado): borda INK 1 px com canto recortado (2 no alto contraste), miolo PARCHMENT, **luz CHALK 1 px** em cima e à direita por dentro, assento INK_SOFT 1 px embaixo. Sem sombra difusa, alpha nem xadrez. `r` = miolo; ocupa `Rect2(r.x-1, r.y-1, r.w+2, r.h+3)`.
- **Barra padrão:** moldura INK 1 px; trilho e preenchimento de valores opostos (≥ 3:1).

| Barra | Trilho | Preenchimento | Detalhe | Contraste |
|---|---|---|---|---|
| Graça | INK_SOFT | GOLD | linha de cima GOLD_LIGHT; 10 segmentos | 3,4:1 |
| Chefe | PARCHMENT_OLD | INK | rastro CHALK | 8,6:1 |
| Recarga | PARCHMENT_OLD | INK | contínua | 8,6:1 |
| Combo | INK_SOFT | GOLD | contínua | como hoje |

- **Ícone + número:** tecla em cima à esquerda (8×9, fundo INK, texto CHALK); nível/quantidade embaixo à direita (8×9, borda INK, miolo PARCHMENT, número INK). Inativo: mesmas formas em INK_SOFT/PARCHMENT_OLD, ícone recolorido. A ativa sobe 2 px e tem borda de 2 px.
- **Cor:** GOLD/GOLD_LIGHT só na Graça, palavras, selo do perdão e gota de tinta; armas e poções só tinta; BLOOD só em tempo ≤ 10 s, última vela, heresia. Texto nunca em GOLD (destaque = INK sobre GOLD_LIGHT).

## 3. Layout (640×360)

| Peça | Desenho | hud_rect |
|---|---|---|
| A. Vida + Graça (Candles) | `draw_plate(Rect2(7,7,84,32))` | `Rect2(6,6,86,35)` |
| Velas | `ORIGIN (11,10)`, `SPACING 9` | dentro de A |
| Graça: nível | `Rect2(10,29,15,9)` fundo INK, miolo GOLD_LIGHT grow(-1), número INK em y31 | `Rect2(10,29,78,9)` |
| Graça: barra | borda `Rect2(27,30,61,7)` INK; trilho `Rect2(28,31,59,5)` INK_SOFT; GOLD `floor(59·f)`; y31 GOLD_LIGHT; separadores INK em x=33+6k (k 0..8), y31–35 | dentro de A |
| B. Tempo/onda | `draw_plate(Rect2(292,7,56,25))`; "ONDA N" INK_SOFT y10; tempo 2× y18 (BLOOD ≤ 10 s); com etiqueta, alarga até texto+8 | `Rect2(260,6,120,28)` |
| C. Tinta | `draw_plate(Rect2(595,7,38,12))`; gota (598,9); número INK à direita até x631, y10 | `Rect2(594,6,40,15)` |
| D. Atril | espaços como hoje (TOP 314, 12×14, gap 2); `draw_plate(Rect2(slots.x-12, 308, slots.w+24, 32))`; HÆRESIS! em y298 | `Rect2(slots.x-13,307,slots.w+26,35)` |
| Dicas | `HINTS_GAP 22`; `draw_plate(Rect2(hx-4,314,texto+8,14))`, texto y318 | |
| Combo | `BAR = Rect2(296,335,48,3)` dentro de D | `Rect2(295,334,50,5)` |
| E. Inventário 017 | `draw_plate(Rect2(7,311,66,40))` | `Rect2(6,310,68,43)` |
| E. Inventário 018 | `draw_plate(Rect2(7,311,160,40))` | `Rect2(6,310,162,43)` |
| Espaço de arma s | `Rect2(10+32s,314,28,28)`; ativo em y312 com assento `Rect2(sx-1,342,30,1)` | |
| Poção i (018) | `Rect2(78+22i,314,20,20)`, divisória `Rect2(74,314,1,35)` | |
| Chefe | `NAME_Y 8`, `BAR Rect2(120,18,400,10)`, `MARK_TOP 16`, `MARK_H 14` (o tempo some) | `Rect2(119,6,402,30)` |
| Lista (Tab) | `Rect2(8,64,140,232)` com `draw_plate` | como hoje |

- Capitular "I": sai dos ornamentos. Banco: proposta (184,328) — **depende do game-design-agent** e da sonda ARENA/STUCK.
- Menu da letra (Fase 3): limite de cima `My ≥ 44` (era 42).
- `BarkDirector.HUD_RECTS` e `arena_ambience.hud_avoid`: `Rect2(6,6,86,35), Rect2(260,6,120,28), Rect2(119,6,402,30), Rect2(594,6,40,15), Rect2(150,306,374,37), Rect2(6,310,163,44)` (+ `Rect2(8,64,140,232)` no hud_avoid).

## 4. Recarga (pixel exato)
- Barra sob cada espaço: `Rect2(sx,344,28,5)`, sx = 10+32s (não sobe com o ativo). Moldura INK (ativa) / INK_SOFT (inativa); trilho `Rect2(sx+1,345,26,3)` PARCHMENT_OLD; preenchimento `floor(26·c)` INK / INK_SOFT; pronta (ativa, c = 1): linha y345 CHALK. Contínua, sem pisca. Espaço vazio: sem barra.
- `WeaponSlot.charge` (só em execução): rajada `clamp(timer/interval)`; raio 1; antecipação 1; saque `min(c, 1 - draw_left/swap_draw_time)`. O `WeaponBar` redesenha só quando `floor(26·c)` muda.
- Nível: as contas saem; etiqueta `Rect2(sx+20, sy+19, 8, 9)`.

## 5. Ordem
1. `ui_style.gd`: `HUD_MARGIN 6`, `HUD_GAP 4`, `HUD_PAD 3`, `draw_plate`, `draw_bar`.
2. `candles.gd` → 3. `grace_bar.gd` → 4. `wave_timer.gd`, `ink_counter.gd` → 5. `boss_bar.gd` → 6. `atril_view.gd`, `combo_window.gd` → 7. `weapon_slot.gd` + `arsenal.gd` (charge) + `weapon_bar.gd` → 8. `bark_director.gd`, `arena_ambience` → 9. `word_list.gd` → 10. arena (após ok) → 11. GUT + teste de margens/sobreposição + export + captura.

## 6. Regras ("HUD em pixel art neste jogo")
1. HUD nos cantos e bordas; X160–480 × Y60–300 sempre livre; oclusão ≤ 10%.
2. Margem 6 px, módulo 4, 4 px entre painéis, 3 px de respiro.
3. Um painel só (`draw_plate`).
4. Agrupar por função: vida + Graça em cima à esquerda, tempo no centro de cima, tinta em cima à direita, atril no centro de baixo, armas e poções embaixo à esquerda.
5. Barras: trilho e preenchimento opostos (≥ 3:1), moldura INK; recurso segmentado, tempo contínuo.
6. Nada só por cor: forma + posição + ícone.
7. Todo espaço: ícone + tecla (sup. esq.) + número (inf. dir.), etiquetas 8×9.
8. GOLD das palavras e da Graça; armas/poções só tinta; BLOOD só no crítico.
9. Texto nunca em GOLD; destaque INK sobre GOLD_LIGHT.
10. Três níveis: sempre visível / contextual / menu.
11. Nada de cenário na faixa do HUD que pareça botão; o HUD não esconde obstáculo.
12. Toda peça nova de HUD entra nos `HUD_RECTS` e no `hud_avoid`.

## Pendências
- Arena (capitular, banco): ok do game-design-agent + sonda.
- DECISIONS: `My ≥ 44`; nível da arma em etiqueta (muda T1700); barra do chefe em Y18 (a 006 dizia Y44).
- Ícones das poções (018) 16×16 a desenhar.
