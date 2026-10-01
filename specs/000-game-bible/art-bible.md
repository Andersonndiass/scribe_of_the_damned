# Art Bible — Scribe of the Damned

> Versão 0.1, **PROPOSTA** (2026-09-24). Reúne as regras das 31 fichas do Claude Design (`design/claude-design/`).
> Os números por asset (tamanho, pivot, frames) ficam em `docs/ASSET-CATALOG.md`; este documento guarda as **regras**.
> As seções numeradas batem com as referências das fichas (§6.1 dissolução, §7.1–7.4 cenário, §8.3 atril, §15 ficha).

---

## 1. Direção

O jogo inteiro é **tinta sobre pergaminho**: um manuscrito iluminado medieval que ganhou vida. Nada é 3D, nada é "moderno". Inimigos são rasuras, borrões, traças e marginália. Milagres são luz sagrada (CHALK e GOLD) sobre um mundo de tinta.

## 2. Paleta travada

Os valores estão em `design-tokens.json`. **Nenhuma outra cor é permitida.**

| Token | Uso permitido |
|---|---|
| `ink` | Contorno, hachura, sombra, vazio do rosto; contraste nos milagres |
| `ink_soft` | Corpo secundário, fumaça, pó, texto ilegível, verso das letras, moldura de itens |
| `parchment` | Fundo (a arena é uma página), pele, páginas |
| `parchment_old` | Bordas gastas, dobras, asas das traças, lâminas |
| `chalk` | Olhos, núcleo dos milagres, contorno dos fantasmas, números de dano normais |
| `blood` | **Só** dano, telegrafia, projéteis inimigos, contorno e aura de campeão, heresia e UI crítica |
| `blood_dark` | Boca de Hildegarda, cruz invertida do Abade, borda da sombra do campeão; na UI (D-076, autor "A"): fita da próxima onda, selo de cera ligado, capa do Grimório, borda queimada do Game Over |
| `gold`, `gold_light` | **Só** milagres, UI, tinta dourada, vogais raras, letra-alvo e redenção dos chefes. Nos heróis, só na ponta da pena ou do pincel em CAST e VICTORY |

### 2.1 Exceções declaradas de BLOOD
Borda das chamas do IGNIS (é fogo) · olho de Asmodeus · estola de Malaquias · gola, olhos e chama do Coroinha · 2 olhos do Monge Oco · mandíbulas da Mãe das Traças · órbitas do Abade Caído.

### 2.2 Regras invioláveis
- Projétil do jogador **nunca** usa BLOOD; projétil inimigo **sempre** usa. GOLD só no laser de Martírio.
- Nunca BLOOD em milagre (exceto a borda do IGNIS).
- Nenhum GOLD em Malaquias. Em Semíhaza, GOLD só na morte.
- A vitória não usa BLOOD (exceto nos selos de desbloqueio). A loja não usa BLOOD fora dos estados de alerta.

## 3. Técnica

- Pixel art em 1×, filtro Nearest, sem sub-pixel. Respiro e flutuação andam sempre em pixel inteiro.
- **Proibido:** degradê, blur, antialiasing, sombra difusa, canto arredondado e alpha desenhado.
- Transparência visual se faz com **dithering** (só em área grande, D-076): vitral, fantasmas, sombra do Semíhaza e texto-fantasma da arena (alpha máximo de 0.12).
- **Sombra (D-075, substitui a regra da hachura no rosto):** luz única da direita (nos itens, de cima para a direita).
  - **Pele e rosto: sombra em blocos lisos, nunca hachura nem xadrez.** Rampa: CHALK (luz) → PARCHMENT (base) → PARCHMENT_OLD (sombra) → INK_SOFT só em vincos fundos. A sombra é uma forma de borda definida que descreve a estrutura (órbita, lado do nariz, sob o lábio, sob o queixo), sem pillow shading.
  - **Hachura (45°) só em tecido, cenário e áreas grandes**, no máximo uma área por retrato; se em 100% parecer ruído, vira cor sólida.
  - Sem pixel órfão (detalhe em clusters); curvas com segmentos em progressão (1-1-2-3, 2-1-2), sem jaggies; poucas linhas internas.
  - Traços do rosto simples: olho = massa escura + 1 brilho; sobrancelha = massa; nariz pela sombra lateral + ponta; boca = 1 linha + sombra sob o lábio.
  - **Ícones e sprites pequenos (D-076):** silhueta reconhecível em 1 cor e em tamanho real; nenhum elemento importante com 1 px de espessura; mesmo molde para a família (moldura, contorno, luz, escala); 1 cor de destaque; 3 tons por material; círculos pelo algoritmo de ponto médio, fechados.
  - **Acabamento (D-076):** sem banding (faixas paralelas acompanhando o contorno); anti-aliasing só nos degraus de canto, nunca na borda externa de sprite nem em sprite pequeno.
  - **UI e HUD (D-076):** painéis em 9-slice; bordas de 1–2 px consistentes; contraste alto sobre o pergaminho; desabilitado = cor sólida apagada + traço (não xadrez); xadrez só no escurecimento de tela inteira e na transparência de fantasmas.
- Todo sprite precisa ser legível em 1× sobre `parchment` e ter silhueta própria em INK sólido.

## 4. Personagens jogáveis

- 16×16 (Beda 14×14), pivot base-centro, 12 FPS, mesmo rig.
- Cabeça grande (~44% da altura). Sem nariz nem orelhas. Cada um tem um elemento de leitura: pena diagonal, véu com livro, óculos com avental, cuia com mochila.
- Partes secundárias (véu, avental) animam com **1 frame de atraso**.
- Efeitos que não são frame: flash de acerto de 60ms (shader) · squash de corrida 1.1/0.9 e de dano 1.2/0.8 · pulso de HP=1 a 100ms · anel do ímã (CHALK pontilhado, 30°/s).

## 5. Inimigos

- Cada um com silhueta única e um "ponto de leitura": chifres com cauda, antenas, focinho, capuz, hastes com olhos, bolsa de ovos, mãos em oração, vela.
- **Nenhum BLOOD no corpo**, exceto nas exceções do §2.1. BLOOD entra só na telegrafia e no campeão.
- **Campeão:** redesenho a 1.5× (não é escala), contorno de 1px BLOOD nos 8 vizinhos (shader), sombra com borda BLOOD_DARK, aura de 4 partículas BLOOD numa volta por segundo, com raio = metade da largura + 3px.

## 6. VFX

### 6.1 Dissolução (morte de inimigo)
6 frames @60ms, em três tamanhos (12×12, 16×16, 16×24). **Sempre sobe**, virando fumaça de tinta; nenhum pixel cai. Deixa um decal 8×4 que desbota em 4 passos ao longo de 2s.

### 6.2 Milagres
- Toda conjuração tem flash CHALK 8×8 na ponta da pena (1 frame). Hit-stop e tremor por tipo (017, `data/tuning/word_feel.tres`): palavra de ataque 100ms + 2px/400ms; tela e combos grandes (MARTYRIUM, PURGO, REQUIEM, MISERERE) 100ms + 3px/400ms; palavra-ferramenta 60ms.
- Núcleo CHALK, borda GOLD, INK só para contraste.
- Nome da palavra em blackletter GOLD de 24px sobre o escriba.
- Start, loop e end são animações separadas.
- Nenhum efeito esconde o atril nem o menu da letra (017: as letras não caem mais no chão).

### 6.2b Armas sagradas (017)
- Toda arma é miolo CHALK com contorno INK; **nenhuma usa GOLD** (o dourado é das palavras) nem BLOOD.
- Bíblia: raio de 5px por Bresenham (miolo CHALK 3, borda INK 1), 32 direções; Crucifixo: sempre de pé, rastro de 1 silhueta INK_SOFT; Rosário: a 1ª conta é a cruz; Turíbulo: fumaça abaixo dos inimigos; ímã reverso: anel INK_SOFT de 3px abaixo dos inimigos (+1px INK quando fere).
- Mapas de pixels: `docs/reviews/T1700-design-maps.json` (`tools/item_icon_maps.json`).

### 6.3 Combos, heresia e ambientais
- Heresia: 6F @60ms + "HÆRESIS!" com a ligadura desenhada.
- Números de dano: normal 7px CHALK com contorno INK; crítico 14px BLOOD com contorno INK.

## 7. Cenário

### 7.1 Camadas
A arena do Cap. 1 é montada em camadas separadas (fundo, texto-fantasma, ornamentos, obstáculos, degradação).

### 7.2 Degradação por onda
4 estágios por capítulo, acumulados.

### 7.3 Virada de página
`ENV_PAGE_TURN`: 12F @60ms, 640×360, sem loop.

### 7.4 Arenas por capítulo
5 arenas de 640×360, margem de 24px = parede de colisão, área jogável X24–615, Y24–335. Todo obstáculo tem sombra e borda clara para que a colisão seja legível.

## 8. Interface

### 8.1 Regras gerais
- Área central X160–480, Y60–300 **sempre livre** do HUD.
- Sem canto arredondado e sem sombra difusa: só assento de 1px e hachura.
- Todo botão é fita, selo ou pergaminho, nunca um retângulo genérico.
- Foco visível: pena-cursor ao lado ou borda GOLD.

### 8.2 HUD
Velas (vida), atril, timer com sino, "Onda N", barra do chefe (400×10), teclas, balão de fala (160×28, fonte 7px).
Sistema do HUD (T1800, `docs/reviews/T1800-hud-parecer.md`): um painel só (`UiStyle.draw_plate`), grade 6/4/3px, barras com trilho e preenchimento opostos (≥3:1), recurso segmentado e tempo contínuo, nada só por cor. Inventário embaixo à esquerda (2 armas com recarga e nível em etiqueta; 4 poções da 018 ao lado, teclas 3–6, com cargas em quadradinhos, recarga e o "não" piscando quando a poção é recusada). Subir de nível (018): feixe GOLD/GOLD_LIGHT/CHALK sobre o escriba na FxLayer (sem `top_level`) e barra 25×3 acima da cabeça durante os 2,5 s de câmera lenta. Loja: prateleira das poções na mesa (4 células 32×42, preço com gota, "MAX" no teto). Menu da letra acima do escriba (3 cartas 28×28, barra de tempo, moldura INK de 2px na borda da tela durante a câmera lenta).

### 8.3 Estados do atril
| Estado | Frames | Quando |
|---|---|---|
| fill | 4 | Letra entra |
| full_reject / reject | 3 | Atril cheio recusa a letra |
| partial_match | 2 | As letras formam prefixo de palavra |
| valid | 6 | Palavra completa. **Nada na tela brilha mais** |
| cast_consume | 6 | Conjuração consome as letras |
| purge | 4 | Shift |
| heresy | 6 | Heresia |
| upgrade | 5 | Item de loja amplia o atril |

## 9. Letras
Losango 10×10 com cantos cortados. Glifo 5×6 desenhado à mão, com traço e serifa de 1px; não usa a fonte blackletter. Vogal rara: contorno do próprio losango em GOLD.
**017:** as letras não caem mais no chão; aparecem só no menu de escolha (ampliadas 2×) e no atril. Sem marca de letra útil no menu (D-087). O anel da letra-alvo saiu.

## 10. Projéteis
No máximo 10×10, exceto raios e paredes (XUL 24×8, SINGI 32×16, XURC 16×24, Sermão 64×6). Pivot no centro.

## 11. Chefes
- Cada chefe tem uma cor forte num único ponto: o olho de Asmodeus, as mandíbulas da Mãe, as órbitas do Abade, a estola de Malaquias, as brasas de Semíhaza.
- A telegrafia e as zonas são desenhadas em escala de arena num quadro à parte.
- **Sem clichês:** Asmodeus não tem chifres, pele vermelha nem asas; o Abade tem rosto humano e triste; Malaquias não tem traço demoníaco; Semíhaza não tem dentes, garras nem chifres.

## 12. Retratos
Busto 48×48 (contorno 1px) e close 128×128 (contorno 2px). A expressão muda só olhos, sobrancelhas e boca; o crânio é idêntico. Blink de 100ms a cada 3–5s; respiro de 1px em 1200ms, ping-pong.

## 13. Telas
Todas em 640×360 exato. Dessaturação, overlay e fade são **código**. Nos mockups aparecem como dithering.

## 14. Tempos
- Escala de durações para VFX e UI: **50 / 100 / 200 / 400 / 700 / 2500ms**.
- Hit-stop: 100ms na palavra de ataque, 60ms na palavra-ferramenta (`word_feel.tres`); 40ms na morte de campeão. Nenhuma arma tem hit-stop global.
- Menu da letra: câmera lenta ×0,2 (entra 0,5→0,2 em 50ms cada; sai 0,5→1,0 em 100ms cada), 2,5s, trava de 100ms.
- Frames com evento de código ficam marcados com GOLD na ficha e viram *method tracks* ou sinais no AnimationPlayer.

## 15. Ficha de entrega (obrigatória para todo asset novo)

```
ID do arquivo:        <PREFIXO>_<NOME>_<ANIMACAO>.png
Tamanho:              W×H px (exato)
Pivot:                (x,y) — base-centro para quem pisa no chão, centro para quem flutua
Sombra:               W×H (+offset)
Animações:            nome · frames · ms por frame · loop sim/não
Eventos de código:    animação · frame · nome do evento
Mapa de cor:          token → região
Versão campeão:       W×H (se for inimigo)
Checagem:
  [ ] contagem exata de frames
  [ ] só cores da paleta travada; BLOOD/GOLD só onde §2 permite
  [ ] tamanho e pivot exatos
  [ ] legível em 1× sobre parchment
  [ ] silhueta própria em INK sólido
  [ ] sem degradê, blur, antialiasing ou alpha desenhado
```

## 16. Prefixos de arquivo
`CHR_` personagens · `ENM_` inimigos · `BSS_` chefes · `LTR_` letras · `PRJ_` projéteis · `VFX_` efeitos · `ENV_` cenário · `UI_` interface · `ITM_` itens.
