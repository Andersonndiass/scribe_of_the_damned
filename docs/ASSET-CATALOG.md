# Catálogo de assets — Scribe of the Damned

> **Rascunho extraído das fichas do Claude Design** (`design/claude-design/*.dc.html`, 2026-09-24).
> Só entra aqui o que está escrito nas fichas. Os pixels ainda não estão no repo: ficam nos módulos `scribe-*.js`, que não foram exportados.
> Quando `specs/000-game-bible/art-bible.md` chegar, ele passa a valer e este arquivo vira conferência cruzada.

Legenda: **F** = frames · **Pivot** em pixels (x,y), a partir do canto superior esquerdo · "—" = não consta na ficha.

## 1. Personagens jogáveis (rig compartilhado)

| # | Nome | ID arquivo | Tamanho | Pivot | Frames | Animações | Notas |
|---|---|---|---|---|---|---|---|
| 01 | Irmão Anselmo | `CHR_ANSELMO` | 16×16 | (8,15) base-centro | 41 | 9 | 12 FPS. Cabeça 8×7. GOLD só na ponta da pena (CAST F2, VICTORY F5) |
| 02 | Irmã Hildegarda | `CHR_HILDEGARDA` | 16×16 | (8,15) | 41 | 9 (rig do Anselmo) | Véu anima com 1F de atraso. Boca 1px BLOOD_DARK (única exceção). GOLD nas páginas (CAST F3, VICTORY F5) |
| 03 | Frei Tomé | `CHR_TOME` | 16×16 | (8,15) | 41 | 9 (rig do Anselmo) | Leitura: barba + braços cruzados. Remendo 2×2 PARCHMENT_OLD no hábito, pena CHALK na orelha direita. Idle F2/F3: dedo bate em (11,10)↔(11,11). Run descruza os braços. GOLD 1px na ponta (CAST F2, VICTORY F5). Stun sem gotas (passiva) |
| 04 | O Iluminador | `CHR_ILUMINADOR` | 16×16 | (8,15) | 41 | 9 | RUN a 110ms. Coleta: 2 faíscas 2F. Máx. 3px GOLD parado. HURT: lente esquerda desce 1px |
| 05 | Noviço Beda | `CHR_BEDA` | 14×14 | (7,13) | 43 | 9 | RUN 8F a 70ms. Idle saltita 1px em F2. Poeira `VFX_DUST_SMALL` nos contatos |

**Estados comuns (01–05):** i-frames 80ms · HP=1 pulsa a 100ms · ímã = anel pontilhado CHALK 1px girando 30°/s · atril válido = 1px GOLD sobe a cada 300ms · squash de corrida 1.1/0.9, de dano 1.2/0.8 · flash de acerto 60ms **por shader, não por frame**.

## 2. Retratos (06)

| Tipo | Tamanho | Contorno | Personagens |
|---|---|---|---|
| Busto | 48×48 | 1px INK | anselmo, hildegarda, tome, iluminador, beda, abade_fantasma, asmodeus, mae_tracas, abade_caido, malaquias, semihaza |
| Close (cutscene) | 128×128 | 2px INK | anselmo (assustado, aliviado, determinado), abade_vivo (neutro, sorrindo), abade_caido, malaquias (sorriso, olhos_abertos), semihaza (vendado, chorando) |

Expressões dos bustos: neutro · determinado · assustado (· aliviado). Blink: F1 meia pálpebra, F2 fechada, 100ms, a cada 3–5s. Respiro: sobe 1px, 1200ms ping-pong, só pixel inteiro.

## 3. Inimigos

| # | Nome | ID arquivo | Tamanho | Pivot | Sombra | Frames | Anims | Campeão (1.5×) | Particularidade |
|---|---|---|---|---|---|---|---|---|---|
| 07 | Diabrete | `ENM_DIABRETE` | 12×12 | (6,11) | 6×2 | 13 | 3 | 18×18 | Base achatada em Y10. Zero BLOOD no corpo |
| 08 | Traça Gigante | `ENM_TRACA` | 16×12 | (8,11) | 10×2, +2Y | 16 | 4 | 24×18 | Vista de cima. Antenas sempre visíveis |
| 09 | Gárgula-Marginália | `ENM_GARGULA` | 16×16 | (8,15) | 10×2 | 23 | 6 | 24×24 | Dash 18×10 extrapola o quadro para trás. Telegrafia com linha tracejada BLOOD obrigatória |
| 10 | Monge Oco | `ENM_MONGE_OCO` | 16×24 | (8,23) | 8×2 | 23 | 4 (6+6+4+7) | 24×36 | Atirador. Rosto = vazio INK + 2 pontos BLOOD |
| 11 | Borrão de Tinta | `ENM_BORRAO` | 14×10 | (7,9) | 12×1 | 13 | 3 | 21×15 | Poça de lentidão: decal 24×10, dura 3s. Olhos atrasam 1F |
| 12 | Traça-Mãe pequena | `ENM_TRACA_MAE` | 20×16 | (10,15) | 12×2, +3Y | 10 | 2 | 30×24 | Bolsa de ovos 6×8 é o ponto de leitura |
| 13 | Noviço Espectral | `ENM_NOVICO_ESPECTRAL` | 14×20 | (7,19) | 6×1 dither 25% | 19 | 4 (6+4+4+5) | 21×30 | Sem contorno INK: contorno CHALK e interior em dithering 50%. Olhos só 1F no float |
| 14 | Coroinha Possuído | `ENM_COROINHA` | 12×16 | (6,15) | 6×2 | 17 | 3 (6+6+5) | 18×24 | Anda em fila de 4, os 4 no mesmo frame. Vela com 1F de atraso |

**Campeão (comum a todos):** contorno 1px BLOOD nos 8 vizinhos (shader) · aura de 4 partículas BLOOD, 1 volta/s · spawn com telegrafia de 0.8s e anel maior · morte com hit-stop de 40ms, shake médio e 3–5 gotas GOLD magnetizadas.

## 4. VFX compartilhados de inimigos (15)

| Efeito | Tamanho | Frames | Tempo |
|---|---|---|---|
| Aura do campeão | 20×20 | 8 | 125ms |
| Spawn do campeão (runas) | 24×24 | 8 | 100ms |
| Explosão de Tinta Dourada | 24×24 | 6 | — |
| Gota de tinta (item) | 6×8 | 4 | — |
| Dissolução 12×12 / 16×16 / 16×24 | igual ao inimigo | 6 cada | 60ms |
| Decal de mancha | 8×4 | 4 passos | desbota em 2s |

Regras: a aura orbita com raio = metade da largura + 3px; a dissolução **sobe** e nenhum pixel cai.

## 5. Chefes

| # | Nome | ID | Tamanho | Pivot | Frames | Sombra | Props separados |
|---|---|---|---|---|---|---|---|
| 16 | Asmodeus, o Rasurador (Cap. 1) | `BSS_ASMODEUS` | 64×64 | (32,32) | 60 (12+6+4+3+6+5+2+8+14) | 32×4 fixa | — |
| 17 | A Mãe das Traças (Cap. 2) | `BSS_MAE_TRACAS` | 80×64 | (40,32) | 67 (10+6+3+5+6+4+3+8+2+8+12) | 48×6 | — |
| 18 | O Abade Caído (Cap. 3) | `BSS_ABADE_CAIDO` | 96×96 | (48,95) base-centro | 86 (14+8+6+3+6+5+4+6+6+2+10+16) | 40×6 fraca | Livro Negro 24×20, 20F (4+3+2+3+8) |
| 19 | Padre Malaquias (Cap. 4) | `BSS_MALAQUIAS` | 48×72 | (24,71) base-centro | 87 (12+6+6+4+5+6+3+8+6+5+2+10+14) | 20×3 | Turíbulo 10×12 (swing 6F @90 ping-pong + versão em chamas) · Confessionário 40×56 (balançar 4, abrir 3, fechar 3, desabar 6) |
| 20 | Semíhaza (Cap. 5, final) | `BSS_SEMIHAZA` | 128×112 | (64,56) centro, flutua 16px | 103 (16+8+6+3+4+4+6+8+2+10+12+6+18) | 60×6 dithering | Trombeta 20×10 (2+4) · Espada de Pena 12×40 (4) · Pena Negra 10×10 (5+6+2+4) |

### Fases (como estão nas fichas; os números precisam ser validados pelo rules-agent contra as specs)

**Asmodeus:** F1 100–66% Raio + Swipe · F2 66–33% + Summon, raio duplo, olho com 2 rachaduras · F3 <33% raio em cruz giratório, +30% de velocidade, idle a 110ms, coroa em chamas.

**Mãe das Traças:** F1 100–66% Wing_Gust + Swarm_Release · F2 66–33% + Dust_Cloud, idle a 70ms, swarm solta 12 · F3 <33% + Eat_Page a cada 15s (arena mínima 400×220), asas esqueléticas. Só palavras ferem o chefe; o ataque básico acerta as traças filhas.

**Abade Caído:** F1 100–75% Profane_Word (XUL) + Staff_Slam · F2 75–50% + SINGI; o livro orbita e dispara `PRJ_PROFANE_LETTER` a cada 1.5s · F3 50–25% + Mirror_Cast; XURC em cruz giratória · F4 <25% halo GOLD, ataques 30% mais rápidos, Kneel a cada 12s. XURC só é bloqueado por CRUX. Palavras copiadas ficam 4s bloqueadas no grimório.

**Padre Malaquias:** F1 100–66% Penance a cada 15s + Censer_Swing · F2 66–33% + Sermon e Confession; 2 confessionários (Retreat) · F3 <33% olhos abertos, Penance a cada 10s com 2 palavras, turíbulo em chamas deixando rastro. Só palavras causam dano; cada heresia o cura em 5%. Penance nunca escolhe palavra que o atril do personagem não monte.

**Semíhaza:** F1 100–60% Feather_Rain + Feather_Slash · F2 60–25% + Trumpet_Blast e Dive; Feather_Rain solta 20 penas · F3 <25% não ataca mais; só LUX causa dano; limite de 45s, depois volta à F2 com 30% de HP. Pena Negra no meio de uma palavra = heresia automática (limpar com Purge/Shift). Na F3 o drop ponderado mira sempre L, U e X.

## 6. Letras coletáveis (21)

- `LTR_<LETRA>` · 10×10 · pivot (5,5). Glifo 5×6 em X3–7, Y2–7. G, P e Q descem 1 linha.
- **Alfabeto:** A C D E F G I L M N O P Q R S T U V X (20 comuns, contando o B) + **B**, que só cai depois que VERBUM é desbloqueado (D-015).
- **Vogais raras:** A E I O U, com contorno do losango em GOLD.
- **Letra-alvo:** 12×12, anel GOLD extra por fora, pulsando a 700ms ping-pong. Pode ser ligado nas Opções e vem ligado por padrão no Cap. 1.
- Animações: DROP 4 · IDLE 6 (@120ms; F3 = perfil, F4 = verso INK_SOFT) · RARE_SHINE 4 · COLLECT 3 · EXPIRED 3 · EATEN 3.
- **Corrompida (Pena Negra, Cap. 5):** FALL 5 · IDLE 6 · IN_ATRIL 2 · PURGED 4. Glitch: 1 frame a cada 2s, glifo BLOOD por 60ms.
- Só código (sem frame): MAGNETIZED (tween QUAD_IN + 2 cópias em alpha 0.4/0.2) · EXPIRING (nos últimos 2s pisca alpha 1/0.3 a cada 100ms e acelera para 50ms no último 0.5s).

## 7. Projéteis (22)

- `PRJ_INK_DROP` é o **único** projétil do jogador: INK, INK_SOFT e CHALK, sem BLOOD.
- Todo projétil de inimigo leva BLOOD. GOLD só no laser de Martírio.
- Máximo 10×10, exceto raios e paredes: XUL 24×8 · SINGI 32×16 · XURC 16×24 · SERMÃO 64×6.
- 5 projéteis + impactos + 3 palavras profanas (XUL, SINGI, XURC) + Sermão. Pivot no centro.

## 8. VFX de milagres (23)

Arquivo: `VFX_<PALAVRA>_<ANIMACAO>.PNG` · 12 palavras, com start, loop e end separados.

| Palavra | Frames | Palavra | Frames |
|---|---|---|---|
| LUX | 3+4+3 | MORTIS | 8+3 |
| PAX | 6+3+3 | FIDES | 4+6+3+5 |
| CRUX | 6+4+2+5 | LUMEN | 4 |
| VITA | 7 | PURGO | 16 |
| AQUA | 4+4+3+3 | GLORIA | 5+4 |
| IGNIS | 5+6+4 | VERBUM | 6 |

+ overlay do nome (5F) + overlay de combo (4F). Toda conjuração: hit-stop de 60ms + flash CHALK 8×8 na ponta da pena (1F). Nome em blackletter GOLD de 24px sobre o escriba.

## 9. Combos, heresia e ambientais (24)

- **Combos:** Radiant 10 · Cegueira 4 · Martírio 4 + Cruz 4 · Vapor 8 · Réquiem 12 · Janela de combo (`UI_COMBO_WINDOW`) 12.
- **Heresia:** 6F @60ms + texto "HÆRESIS!" com a ligadura desenhada.
- **Ambientais:** DUST 5 · DUST_SMALL 3 · CANDLE_DRIP 6 · MOTH_EDGE 4 · EMBER 4 · PAGE_TEAR 6.
- **Números de dano:** normal 7px CHALK com contorno INK; crítico 14px BLOOD com contorno INK; dígitos 0–9 nas duas versões.
- Durações só na escala 50 / 100 / 200 / 400 / 700 / 2500ms.

## 10. Cenário (25)

- `ENV_PAGE_*` · 640×360. Margem de 24px = parede de colisão. Área jogável X24–615, Y24–335.
- 5 arenas (uma por capítulo). Camadas do Cap. 1 separadas. 4 estágios de degradação (exibidos em 320×180).
- `ENV_PAGE_TURN`: 12F @60ms, sem loop.
- Cratera do Cap. 5: 64×64, 4F @80ms.
- Obstáculos: 4 furos 16×16 · banco 32×8 · vitral 20×40 · altar 60×16.
- Texto-fantasma com alpha máximo de 0.12, feito em dithering.

## 11. HUD (26)

- `UI_<ENTIDADE>_<ANIMACAO>.PNG` · layout 640×360. **A área central X160–480, Y60–300 fica sempre livre.**
- **Velas (vida):** LIT 4 · FLICKER 3 · EXTINGUISH 5 · RELIGHT 4 · LAST_CANDLE · 3 alturas de derretimento.
- **Atril:** FILL 4 · REJECT 3 · PARTIAL 2 · VALID 6 · CAST 6 · PURGE 4 · HERESY 6 · UPGRADE 5.
- **Timer:** pop em 3 escalas + sino 12×12 em 4F · "Onda N" com 5F de entrada.
- **Barra do chefe:** 400×10, entrada em 5F e dano recente em 4F.
- **Teclas:** W A S D, Espaço, Shift, Tab, soltas e pressionadas. Abade (tutorial) em 6F.
- **Balão de fala:** 160×28 com rabicho, fonte pixel 7px.

## 12. Telas (27–30)

| # | Telas | Animações-chave |
|---|---|---|
| 27 | Splash, Menu, Personagem, Capítulo | Sino 6F @90ms · chama 4 · pena-cursor 2 · fita hover 4 · livro abrindo 10 @60ms · medalhão hover 6 · cadeado 3 · carimbo de cera 5 @50ms · correntes 4 · 3 páginas na demo, 5 na versão completa |
| 28 | Loja: Scriptorium Noturno | Carta: entrada 5 @80ms · comprar 5+6 · reroll 6 · travada 2 · vendida. 8 estados. Escriba sentado 6F @200ms. Tinta dourada 4F @150ms, roll-up de 20ms, pop 1.2× |
| 29 | Pausa, Game Over, Vitória | Pausa: fita 5F @50ms, nav 4 · Game Over: 21F @100ms (3.5s), queima em 10 e título em 14 @60ms · Vitória: 22F (luz 8, capitular P 12, selo 5 @50ms) · Codex Completus: 20F |
| 30 | Opções, Grimório, Créditos, Loading | Slider 6 · WaxToggle 3 @50ms · Grimório com 4 abas e virada de página 8F @50ms · créditos com rolos 4F e gárgula tropeçando 3F · loading com vela em 0/25/50/75/100% e chama 4F · shell web 2F |

Todas as telas: 640×360 exato, sem botão retangular genérico (todo botão é fita, selo ou pergaminho) e navegação 100% por teclado.

## 13. Ícones de itens (31)

`ITM_<ITEM>` · 24×24 · pivot no centro · moldura circular INK_SOFT com R=11 · área útil 20×20 · luz de cima para a direita · **9 itens** · idle de 4 ou 6F entre 100 e 150ms · no máximo 1 cor de destaque (nunca GOLD e BLOOD juntos) · a loja exibe em 2×. Inclui o template `ITM_TEMPLATE_24.PNG`.

## 14. Lacunas

| Item | Situação |
|---|---|
| Fichas 32, 33 | Não recebidas (talvez não existam) |
| Pixels de todas as fichas | Estão em `scribe-*.js`, `pixel-canvas.js`, `support.js` e `_ds/`. Não exportados |
| Hex da paleta | Estão em `_ds/…/tokens/colors.css`. Não exportados |
| Nomes das animações por personagem e inimigo | Estão dentro dos `.js`. As fichas só trazem as contagens |
| Nomes dos 9 itens da loja | Estão em `scribe-items.js` |
| Cutscenes | Existe um `scribe-cutscenes.js` referenciado, mas não há ficha de cutscene |
