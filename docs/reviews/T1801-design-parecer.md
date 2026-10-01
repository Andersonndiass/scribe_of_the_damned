# T1801 — Parecer do design-agent: arte das poções (018)

> 2026-10-01 · **APROVADO.** Mapas: `T1801-design-maps.json` (8 ícones + 10 peças de mundo; só `. K k P O C`, zero GOLD). Maquetes: `img/t1801_icons_sheet_4x.png`, `img/t1801_hud_potions_crop4x.png`, `img/t1801_world_holy_water_fervor_3x.png`, `img/t1801_vfx_crop4x.png`, `img/t1801_shop_shelf*.png`.
> **Escolha do Claude (pedido do autor: "novos designs com a skill de pixel art"):** os ícones 16×16 do HUD são os da skill `pixel-art-gen` (`T1801-potion-icons.json`); os ITM 24×24 da loja usam esses ícones no molde ITM (anel INK_SOFT, ≥1 px de folga). Os efeitos de mundo, estados do HUD e a prateleira seguem este parecer.

## Ícones
- HUD 16×16 em (x+2, 316) dentro do espaço 20×20; silhuetas distintas em INK sólido; contorno INK, luz de cima à direita, blocos.
- Estado apagado: mapa próprio `DIM_POTION = {ink→ink_soft, chalk→parchment}` (o das armas some com o vidro).

## HUD (poção i em x = 78+22i)
- Espaço `Rect2(x,314,20,20)`; **etiquetas embaixo do espaço** (desvio da regra 7 do T1800, para não cobrir o ícone): tecla `Rect2(x,335,8,9)`, cargas `Rect2(x+12,335,8,9)`; barra `Rect2(x,345,20,4)`. Cabe no `hud_rect` atual.

| Estado | Espaço | Tecla | Barra |
|---|---|---|---|
| Pronta | borda INK 1, miolo PARCHMENT | INK, texto CHALK | cheia INK + linha CHALK |
| Em efeito | sobe 2 px, borda INK 2, assento INK_SOFT | igual | duração restante em INK |
| Em intervalo | borda INK_SOFT, miolo PARCHMENT_OLD, ícone apagado | INK_SOFT | enchendo em INK_SOFT |
| Sem carga | borda INK_SOFT, ícone em silhueta INK_SOFT, "0" | apagada | traço INK_SOFT |
| Bloqueada | apagada | cadeado 5×6 no lugar da tecla | congelada |

## Mundo
- **Água Benta:** anel de 4 px (INK por fora, CHALK 2 px, INK_SOFT 1 px), sem preenchimento, **abaixo dos inimigos**; 4 marcadores 7×7 (N/L/S/O) **acima dos inimigos**. Não se confunde com o pulso do ímã reverso.
- **Vinho:** cálice 7×8 a 3 px acima da cabeça enquanto dura.
- **Óleo:** gota 4×5 caindo na vela do HUD + clarões 9×9 e 7×7 na vela e no escriba.
- **Iluminura:** cantoneiras INK 5×5 nas **três** cartas do menu (não marca a útil, D-087).

## Prateleira da loja
- Painel `Rect2(298,221,138,46)` entre o Rerolar e a fita; 4 células 32×42 em x = 300+34i, y = 223: ITM 24 em (+4,+2), cargas em quadradinhos 4×4 (passo 5) em +28, preço (gota + número; BLOOD sem tinta) em +33, nível em etiqueta a partir do nv 2; selecionada sobe 2 px com borda INK 2; cheia = "MAX" em INK_SOFT.
- Nome e efeito numa plaqueta `Rect2(298,280,138,16)` (sem `draw_tag`). Navegação ↑/↓ entre cartas e prateleira + mouse.
