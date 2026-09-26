# T080–T085 — Relatório de performance

> 2026-09-25 · Carga do SC-001: **300 inimigos + 150 letras + 200 projéteis**, na cena principal real
> (`src/debug/stress_scene.tscn`; no web: `index.html?stress`). Medição: 3s de aquecimento + 30s.

## 1. Resultados

| Ambiente | FPS médio | p95 | Movimento/separação dos inimigos | Projéteis (total) | Veredito SC-001 (≥60 / ≥55) |
|---|---|---|---|---|---|
| Desktop nativo, sem janela (só CPU dos scripts) | 130 | 46 | 1,4 ms | 0,7 ms | referência de custo |
| Web · Chrome sem janela · GPU (1ª medição, antes das otimizações) | 39,5 | 21,7 | 7,6 ms | 2,8 ms | ❌ |
| Web · Chrome sem janela · GPU (depois) | 7–27 | 4–12 | 12–54 ms | 5–28 ms | **inconclusivo** |
| Web · Chrome sem janela · SwiftShader (CPU) | 9,6 | 6,2 | 50 ms | 19 ms | ❌ (renderização por software) |
| Firefox | — | — | — | — | medido em 2026-09-26, ver §1.3 |

**Leitura honesta:**
1. O mesmo build variou de 7 a 39 FPS entre execuções no Chrome sem janela desta máquina. Esse ambiente **não serve** para dar o veredito do SC-001. É preciso medir num navegador de verdade (T084).
2. Mesmo no melhor caso, o custo dos scripts em WebAssembly é **~5–8× o do desktop nativo**. O gargalo é **CPU de script, não desenho**: desenhar os 300 inimigos custa ~1 ms.

### 1.1 Depois do steering escalonado (D-039) — resultado final

| Ambiente | FPS médio | p95 | Pior frame | Mover/separar | Desenho | Projéteis |
|---|---|---|---|---|---|---|
| Desktop sem janela | 145 | 99 | 16,7 ms | 0,44 ms | 0,65 ms | 0,40 ms |
| **Web · Chrome · GPU (3 execuções)** | **86,5–90,2** | **66,7–68,5** | 23–29 ms | 1,2 ms | 1,0 ms | 0,9–1,0 ms |

**SC-001 ✅ no Chrome** (meta: média ≥ 60, p95 ≥ 55), estável entre execuções. A instabilidade anterior era uma espiral: ticks de física acima de 16 ms faziam o motor rodar 2–3 ticks no frame seguinte. **Firefox: medir no computador do autor** (`index.html?stress`, leitura no canto superior esquerdo após ~35 s).

### 1.2 Depois da feature 005 (comportamentos, 5 inimigos, campeões) — D-043

A 005 deixou o laço dos inimigos ~50% mais caro no web (chamadas de comportamento por inimigo), e o SC-001 passou a oscilar (41–72 FPS). Duas correções: caches por slot com a perseguição simples calculada direto no laço, e o renderer escrevendo no Sprite2D só quando o valor muda.

| Chrome · GPU (3 execuções cada) | FPS médio | p95 | Mover/separar | Desenho |
|---|---|---|---|---|
| SC-001 (300 Diabretes) | 81–89 | 64–69 | 1,2–1,4 ms | 0,85 ms |
| **SC-503** (mistura da onda 9 + 60 tiros + 20 poças) | **78–80** | **60–65** | 1,3–1,4 ms | 0,87–0,91 ms |

### 1.3 Firefox e nova rodada no Chrome (2026-09-26, depois da paleta C e da 002 Fase 1)

Firefox 156.0.1 instalado pelo Claude (D-047 3B), **com janela** e GPU. O Firefox sem janela desenha por software e dá o mesmo que o SwiftShader (~17–28 FPS), então não serve. Na janela foi preciso desligar o rastreamento de oclusão do Windows (`widget.windows.window_occlusion_tracking.enabled=false`); sem isso a aba congela (0,1 FPS).

| Navegador | Cena | FPS médio | p95 | Mover/separar | Projéteis (total) | Desenho |
|---|---|---|---|---|---|---|
| Chrome · GPU (4 exec.) | SC-001 | 58–69 | 40–56 | 1,8–1,9 ms | 1,4–1,5 ms | 0,9 ms |
| Chrome · GPU | SC-503 (onda 9) | 58 | 40 | — | — | — |
| **Firefox · GPU · janela (3 exec.)** | SC-001 | **34–35** | **12–15** | 4,2–4,7 ms | 3,8–4,1 ms | 1,3 ms |
| **Firefox · GPU · janela (2 exec.)** | SC-503 (onda 9) | **31–33** | **13–14** | 4,8 ms | 4,6 ms | 1,4 ms |

**Leitura:**
1. **Chrome:** o código dos inimigos e projéteis não mudou desde a D-043, mas todos os custos subiram ~40% por igual (o desenho também), e o desktop nativo caiu de 145 para 131 FPS. É variação da máquina, não regressão. Mesmo assim o SC-001 no Chrome ficou **no limite** (p95 50–56 contra a meta 55).
2. **Firefox:** os scripts em WebAssembly custam **~2,5× o Chrome** em todas as seções. **SC-001 ❌ no Firefox** (metade da meta). Quando o frame passa de 16 ms, o motor roda 2 ticks de física no frame seguinte, o que agrava tudo (a mesma espiral da D-039).
3. As saídas estão na §4: itens 1 (lógica a 30 Hz) e 2 (projéteis em laço único) atacam as duas maiores seções; o item 5 é decisão do autor.

### 1.4 Otimizações da C-005 (D-049): projéteis em laço único + STEER_STRIDE 3

**Diagnóstico antes (Firefox, janela):** sem inimigos e sem projéteis (só letras e HUD) o Firefox já fica em **55 FPS, p95 37** (o Chrome, 163). O Firefox sincroniza com o monitor de 60 Hz: um frame de 17–20 ms vira 33 ms, e a média cai para 30–40. Parte do custo é do navegador e não está ao nosso alcance.

**A/B intercalado** (build anterior × novo, alternados, mesma sessão; a máquina estava mais lenta que na §1.3):

| Navegador (SC-001) | Antes (3 exec.) | Depois (3 exec.) | Mover/separar | Projéteis (total) |
|---|---|---|---|---|
| Chrome · GPU | 61–64 / p95 40–48 | 54–70 / p95 32–52 | 1,9–2,2 → 1,4–2,0 ms | 1,5–1,7 → 1,1–1,7 ms |
| Firefox · GPU · janela | 25–31 / p95 7–15 | 29–31 / p95 12–15 | 5,1–7,7 → 3,9–4,7 ms | 4,5–6,7 → 4,0–4,6 ms |

**Leitura:** ganho real de ~25–40% nas duas seções, mas **~15% no FPS do Firefox**, e o ruído da máquina (o mesmo build variou de 32 a 64 no Chrome) é do tamanho do ganho. **SC-001 continua ❌ no Firefox.** A maior seção restante é `projeteis_acerto` (200 consultas ao hash por tick, 2–2,7 ms no Firefox).

## 2. Os 5 maiores custos por frame (T085) — medição anterior às otimizações

| # | Seção | Desktop | Web (melhor medição) | O que é |
|---|---|---|---|---|
| 1 | `inimigos_mover_separar` | 1,43 ms | 7,6 ms | steering + separação dos 300 (laço único) |
| 2 | `projeteis_total` | 0,72 ms | 2,8 ms | 200 nós `InkDrop` com `_physics_process` próprio |
| 3 | `projeteis_acerto` (dentro do 2) | 0,37 ms | 1,4 ms | consulta de acerto na grade |
| 4 | `inimigos_desenho` | 0,84 ms | 1,0 ms | atualizar 300 Sprite2D |
| 5 | `letras` | 0,19 ms | 0,9 ms | vida/ímã/coleta das 150 letras |

## 3. O que foi feito

- **T080** cena de stress + `FpsProbe` (média, p95, pior frame, custos por seção) + `Prof` (profiler por seção, desligado fora do stress).
- **T081** prewarm de todos os pools (842 nós) antes da onda. `DissolveFx` passou a pré-aquecer a capacidade toda do EnemyManager (400).
- **T082 (revisado, ver D-038)** MultiMesh **não** foi feito: o desenho não é o gargalo (~1 ms). Em vez disso:
  - separação e teste de acerto percorrem a grade direto, sem criar arrays (antes eram ~500 alocações por frame);
  - célula da grade de 32 → 16 px (≈ raio de separação);
  - `EnemyQuery` chama o EnemyManager tipado, sem `call()` dinâmico.
  - Um limite de "8 vizinhos" foi testado e **descartado**: ele empilhava os inimigos (o teste de separação pegou).
- **T083** `test_zero_instantiate`: carga do SC-001 + MORTIS matando 300 → `instantiate_count` inalterado ✅ (SC-002).
- Letras e dissoluções usam `PoolManager.try_acquire`: sob carga extrema o excedente é pulado, nunca instanciado (D-037).

## 4. Próximas otimizações possíveis (não necessárias hoje; reservas para chefes e capítulos 2–5)

| # | Mudança | Ganho esperado no web | Custo |
|---|---|---|---|
| 1 | ~~Lógica dos inimigos a 30 Hz~~ | D-039 (stride 2) e D-049 (stride 3, 20 Hz por inimigo) | — |
| 2 | ~~Projéteis num gerenciador de laço único~~ | feito na D-049 (`PlayerProjectileManager`) | — |
| 3 | ~~Separação escalonada~~ | feito na D-039 | — |
| 4 | ~~Renderer só escreve o que muda~~ | feito na D-043 | — |
| 5 | Baixar a carga-alvo do SC-001 no web (ex.: 200 inimigos) | — | decisão do autor |

GDExtension/C++ está fora: a constituição exige GDScript puro.
