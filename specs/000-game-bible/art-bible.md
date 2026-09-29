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
| `blood_dark` | Boca de Hildegarda, cruz invertida do Abade, borda da sombra do campeão |
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
- Transparência visual se faz com **dithering**: vitral, eco do VERBUM, fantasmas, sombra do Semíhaza e texto-fantasma da arena (alpha máximo de 0.12).
- **Sombra (D-075, substitui a regra da hachura no rosto):** luz única da direita (nos itens, de cima para a direita).
  - **Pele e rosto: sombra em blocos lisos, nunca hachura nem xadrez.** Rampa: CHALK (luz) → PARCHMENT (base) → PARCHMENT_OLD (sombra) → INK_SOFT só em vincos fundos. A sombra é uma forma de borda definida que descreve a estrutura (órbita, lado do nariz, sob o lábio, sob o queixo), sem pillow shading.
  - **Hachura (45°) só em tecido, cenário e áreas grandes**, no máximo uma área por retrato; se em 100% parecer ruído, vira cor sólida.
  - Sem pixel órfão (detalhe em clusters); curvas com segmentos em progressão (1-1-2-3, 2-1-2), sem jaggies; poucas linhas internas.
  - Traços do rosto simples: olho = massa escura + 1 brilho; sobrancelha = massa; nariz pela sombra lateral + ponta; boca = 1 linha + sombra sob o lábio.
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
- Toda conjuração tem hit-stop de 60ms e flash CHALK 8×8 na ponta da pena (1 frame).
- Núcleo CHALK, borda GOLD, INK só para contraste.
- Nome da palavra em blackletter GOLD de 24px sobre o escriba.
- Start, loop e end são animações separadas.
- Nenhum efeito esconde as letras do chão por mais de 1s (exceto o PURGO).

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
Losango 10×10 com cantos cortados. Glifo 5×6 desenhado à mão, com traço e serifa de 1px; não usa a fonte blackletter. Vogal rara: contorno do próprio losango em GOLD. Letra-alvo: anel extra de fora, 12×12, pulsando a 700ms. As duas marcas nunca se confundem.

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
- Hit-stop: 60ms na conjuração; 40ms na morte de campeão.
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
