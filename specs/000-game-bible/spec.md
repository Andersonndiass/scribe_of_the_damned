# 000 — Game Bible: Scribe of the Damned

> Versão 1.0, **APROVADA** (Checkpoint 0, 2026-09-24). As decisões do autor estão em `docs/DECISIONS.md` (D-006 a D-022).
> Legenda: **[D-xxx]** = decisão registrada · **[FICHA]** = consta numa ficha de arte · **[INICIAL]** = valor inicial proposto, ajustável pelo rules-agent em playtest · **[PENDENTE]** = aguardando material do autor.
> Arte: `art-bible.md` · Números por asset: `docs/ASSET-CATALOG.md`.
> **Emenda 1 (D-085, 2026-09-30, pedido do autor):** armas sagradas viram o ataque principal; as palavras viram o "ultimate" raro e fortíssimo. Mudam o pilar 1, a fantasia, o loop, os controles e as seções 3.1, 3.2 e 3.9 (detalhes nas specs 017 "Arsenal sagrado" e 018 "Poções"). Parecer: `docs/reviews/D085-game-design-arsenal.md`.

---

## 1. Visão

**Gênero:** roguelite survivors-like em arena fechada: armas sagradas no dia a dia, palavras em latim como milagre final [D-085].
**Plataforma:** Web (itch.io) primeiro. Godot 4.7.2.
**Fantasia do jogador:** *sou um monge copista preso num códice amaldiçoado. Meus objetos sagrados me mantêm vivo; as letras que arranco dos demônios viram milagres que apagam a página.* [D-085]

### Pilares
1. **Escrever é o milagre.** As armas seguram a linha; as palavras decidem a luta. Escolher *qual* letra pegar continua sendo a decisão central, porque cada letra é rara [D-085]. *(Antes: "Escrever é lutar".)*
2. **Tudo é página.** Arena, inimigos, milagres e interface são tinta, pergaminho e iluminura.
3. **Risco na caligrafia.** Conjurar errado é heresia. Quem monta palavras longas ganha milagres fortes; quem erra paga.
4. **Curto e intenso.** Ondas curtas, loja entre ondas, um chefe por capítulo.

### O que torna o jogo único
O jogador **soletra** o próprio milagre em tempo real. A raridade das letras substitui a recarga: não existe cooldown, existe caligrafia [D-013, D-085]. **Regra de leitura:** as armas são desenhadas só em tinta (INK, INK_SOFT, CHALK); **o dourado é exclusivo das palavras** [D-085].

---

## 2. Loop principal

**Loop depois da Emenda 1 [D-085]:**
```
Onda começa → a ARMA ATIVA (1 de 2, teclas 1/2) mata inimigos → XP (Graça) pela força do inimigo
   → subir de nível: pausa, 3 selos (nível de arma, status ou poção)
   → às vezes um inimigo solta uma LETRA → MENU DE ESCOLHA: 3 letras, 2,5 s em câmera lenta,
     1 continua a palavra → a escolhida entra no ATRIL (letra não escolhida se perde)
   → atril forma palavra válida → Espaço → MILAGRE ("ultimate": mata tudo no alcance)
   → conjurou sem palavra válida → HERESIA
   → poções nas teclas 3–6 (cargas compradas na loja)
Onda termina → página degrada → LOJA (armas, poções, apócrifos) → próxima onda
Última onda → CHEFE → cutscene → próximo capítulo
```

**Loop original (v1.0), mantido como histórico:**
```
Onda começa → ataque automático mata inimigos → inimigos soltam letras
   → jogador coleta (ímã) → letras entram no ATRIL, na ordem da coleta
   → HUD mostra as palavras ainda possíveis (dicas)
   → atril forma palavra válida → Espaço → MILAGRE (mais forte quanto mais longa)
   → conjurou sem palavra válida → HERESIA (stun, poça de aggro, atril limpo)
   → quer recomeçar → Shift: as letras caem no chão ao redor → recoleta em outra ordem
Onda termina → página degrada → LOJA → próxima onda
Última onda → CHEFE → cutscene → próximo capítulo
```

### 2.1 Controles [D-020]

| Tecla | Ação |
|---|---|
| W A S D | Mover em 8 direções |
| Espaço | Conjurar a palavra do atril |
| Shift | Purge: joga as letras do atril no chão |
| Tab (segurar) | Mostra a lista de palavras conhecidas |
| Esc | Pausa |
| 1 / 2 | Escolher a arma ativa do inventário [D-085] |
| 3 · 4 · 5 · 6 | Usar a poção 1–4 [D-085] |
| Setas + Espaço ou clique | Escolher a letra no menu de escolha (2,5 s) [D-085] |

Gamepad fica para depois da demo.

---

## 3. Sistemas

### 3.1 Jogador
> **[D-085]** O ataque automático vira a arma **Pena do Copista** (inicial); o inventário tem 2 armas (Pena, Bíblia, Crucifixo, Rosário, Turíbulo, Aspersório) e só a ativa ataca — spec 017. Poções — spec 018.

- Movimento de 8 direções a **90 px/s**, com colisão na margem de 24px.
- **Ataque automático** a cada **0.8s** com `PRJ_INK_DROP` no inimigo mais próximo. Nunca para.
- **Velas (vida):** começa com **3**, máximo de **8** por upgrades [D-010].
- **Invulnerabilidade** de **1s** depois de levar dano [D-010].
- **Dano recebido:** ataque fraco = 1 vela, ataque forte = 2 velas; o nível é declarado no `.tres` [D-012].
- **Recuperar vela** [D-011]:
  - **parado por 5s**, sem conjurar e sem levar dano → +1 vela a cada **3s** enquanto continuar parado [INICIAL];
  - upgrade da loja;
  - matar um **campeão**;
  - conjurar **VITA**.

### 3.2 Letras
> **[D-085]** As letras **não caem mais no chão**: cada letra solta abre o **menu de escolha** (3 opções, 1 continua a palavra, 2,5 s em câmera lenta, perdida se o tempo acabar). Ímã de letras, vida útil no chão e Traça comendo letras deixam de valer; o ímã vira o **ímã reverso** (passivo da loja que empurra inimigos). Alvo: ~1 palavra por minuto. Números: rules-agent (spec 017).

- **Alfabeto:** A C D E F G I L M N O P Q R S T U V X, mais **B**, que só cai depois que VERBUM é desbloqueado na partida [D-015].
- **Vogais raras** (A E I O U douradas): valem como letra comum, mas dão +50% de poder à palavra que as contém [INICIAL].
- **Drop ponderado (FR-013):** favorece letras que continuam algum prefixo possível no atril. **Nunca mira palavra maior que a capacidade atual do atril** [D-007]. A letra-alvo tem indicador visual, ligado por padrão no Cap. 1.
- **Vida útil no chão:** **8s**, piscando nos últimos 2s [INICIAL].
- **Ímã:** raio de **40px** [INICIAL].
- **Traças** podem comer letras do chão.
- **Letra corrompida (Pena Negra, Cap. 5):** no meio de uma palavra, causa heresia automática.

### 3.3 Atril [D-007, D-008, D-009]
- Fila ordenada, **sem reordenação**. Capacidade **5** no padrão, até **8** por upgrades.
- Letra coletada com o atril cheio e sem palavra válida → **recusada**; fica no chão (estado `full_reject`).
- Estados (art bible §8.3): fill, partial_match, valid, cast_consume, purge, heresy, full_reject, upgrade.
- **Dicas:** a cada letra, o HUD lista as palavras conhecidas que começam com o conteúdo do atril e cabem na capacidade atual [D-013].
- **Purge (Shift):** as letras do atril voltam para o chão num anel ao redor do jogador. Sem custo e sem recarga. As letras voltam a ter a vida útil normal.

### 3.4 Lexicon
Dicionário carregado de `.tres`. Toda palavra é latim real, tem **3 a 8 letras** e usa só o alfabeto do jogo. O load **falha** se não for assim (Princípio VIII).

### 3.5 Palavras (milagres) [D-006, D-013]

**O poder cresce com o tamanho**, e há um teste que garante essa curva.

| Nível | Letras | Força |
|---|---|---|
| Menor | 3 | Fraco, rápido de montar |
| Médio | 4–5 | Médio |
| Maior | 6 | Forte (exige atril 6+) |
| Grande Oração | 7–8 | Muito forte (exige atril 7–8) |

**Base (feature 001), todas conhecidas desde o início:**

| Palavra | Letras | Efeito |
|---|---|---|
| LUX | 3 | Raio reto na direção do movimento, dano alto em linha. Única que fere o Semíhaza na F3 |
| PAX | 3 | Onda circular que empurra e atordoa por 1.5s |
| CRUX | 4 | Cruz fixa no chão: dano em + (4 direções) e bloqueio de projéteis por alguns segundos. Única que bloqueia o XURC |
| VITA | 4 | +1 vela |
| AQUA | 4 | Poça grande de lentidão |
| IGNIS | 5 | Área de fogo com dano contínuo; queima a página |
| MORTIS | 6 | Onda na tela toda que mata inimigos fracos (exige atril 6) |

**Apócrifos (feature 002)**, cartas da loja válidas só na partida [D-017]: FIDES (escudo de 1 golpe) · LUMEN (ímã e letra-alvo reforçados por 10s) · PURGO (limpa a tela em lotes; não entra em combo) · GLORIA (milagres reforçados por alguns segundos; não entra em combo) · VERBUM (repete a última palavra; não repete VERBUM; libera o B).

**Grandes Orações (7–8 letras, feature 002). Proposta para o rules-agent:**
SANCTUS (7, "santo") · DOMINUS (7, "Senhor") · ANGELUS (7, "anjo") · SPIRITUS (8, "espírito") · SALVATOR (8, "salvador") · MISERERE (8, "tende piedade"). Todas usam só o alfabeto ativo. Efeitos: [a definir na spec 002].

### 3.6 Combos [D-016]
Duas palavras dentro de **2.5s** formam combo. A **ordem não importa**, e **o combo substitui o efeito da 2ª palavra** (FR-202).

| Combo | Par |
|---|---|
| Vapor | AQUA + IGNIS |
| Chama Radiante | LUX + IGNIS |
| Cegueira | LUX + PAX |
| Martírio | CRUX + LUX |
| Réquiem | MORTIS + PAX |

GLORIA e PURGO não entram em combos. VERBUM não repete VERBUM. A Hildegarda tem janela de 3.75s.

### 3.7 Heresia [D-014]
- **Gatilho:** apertar Espaço sem palavra válida no atril, ou ter uma letra corrompida na palavra.
- **Efeito:** stun de **0.5s** + **poça de aggro** de **2s** no **local do erro**, que atrai os inimigos + atril limpo. As letras são perdidas, ao contrário do purge.
- O Tomé não sofre o stun.

### 3.8 Inimigos e ondas [D-019]

| Inimigo | Comportamento | Cap. |
|---|---|---|
| Diabrete | Persegue; ataque fraco de contato | 1 |
| Traça Gigante | Voa até letras no chão e as come | 1 |
| Gárgula-Marginália | Dash em linha com telegrafia tracejada; ataque forte | 1 |
| Monge Oco | Mantém distância e atira | 1 |
| Borrão de Tinta | Deixa poça de lentidão (24×10, 3s) | 1 |
| Traça-Mãe pequena | Ao morrer, solta traças pequenas | 2 |
| Noviço Espectral | Fantasma; atravessa obstáculos | 3 |
| Coroinha Possuído | Anda em fila de 4 | 4 |
| — (Pena Negra corrompe letras) | — | 5 |

- **Ondas:** Cap. 1 tem 9; caps. 2–5 têm 10. A onda 1 dura **60s** e as seguintes crescem até **90s** [INICIAL].
- **Campeões:** **1 por onda a partir da onda 3**. Na morte: 3–5 gotas de tinta dourada e +1 vela.
- Comportamentos são Resources stateless (feature 005).

### 3.9 Economia e loja [D-018]
> **[D-085]** A loja vende **armas, cargas de poção e apócrifos**; o subir de nível (016) melhora **armas, status e poções** (os itens pequenos — Círio, Sandálias, Lentes, Escapulário (ex-Rosário), Bolsa, Pena de Ganso, Tinta Consagrada, Estante Nova, Tinteiro Duplo — viram status). Specs 017 e 018.

- **Tinta dourada** só vale dentro da partida.
- **Loja Scriptorium Noturno** entre ondas: cartas com preço, comprar, travar, reroll, itens únicos e cartas de apócrifo.
- **Preços** sobem por onda. **Reroll:** 5 de tinta, +3 a cada reroll na mesma visita [INICIAL].
- Itens alteram o **RunStats** por modifiers (FR-306).

**Os 9 itens (proposta; detalhados na spec 003):**

| Ícone | Item | Efeito |
|---|---|---|
| Estante | Estante Nova | +1 espaço no atril (até 8) |
| Círio | Círio Bento | +1 vela máxima e acende 1 vela |
| Pena | Pena de Ganso Fina | Ataque automático 15% mais rápido |
| Sandália | Sandálias do Peregrino | +10% de velocidade |
| Ímã | Pedra-Ímã | +30% no raio do ímã |
| Óculos | Lentes do Copista | A letra-alvo cai com mais frequência |
| Tinteiro | Tinteiro Duplo | +10% de chance de letra dupla |
| Rosário | Rosário de Contas | Stun da heresia −50% |
| Bolsa | Bolsa do Esmoler | +20% de tinta dourada |

### 3.10 Arena e degradação
Página de 640×360 com margem de 24px. Degrada em 4 estágios ao longo das ondas. Obstáculos: furos, banco, vitral, altar. Virada de página entre capítulos; cratera no Cap. 5.

### 3.11 Personagens [D-019]

| Personagem | Passiva | Desbloqueio | Demo |
|---|---|---|---|
| Irmão Anselmo | Padrão (sem passiva) | Inicial | ✅ |
| Irmã Hildegarda | Janela de combo +50% | Vencer o Cap. 1 | ✅ |
| Frei Tomé | Imune ao stun de heresia; começa com 2 velas | Sobreviver a 20 heresias | — |
| O Iluminador | 25% de chance de letra dupla | Conjurar 10 combos | — |
| Noviço Beda | +20% de velocidade; atril começa em 4 | Conjurar 100 palavras | — |

### 3.12 Chefes
Framework comum (feature 006): BossData, PhaseData, AttackData; FSM; escolha ponderada com anti-repetição; DamageFilter por `source_tag`; LetterSafety. Cada ataque declara o nível de dano (fraco ou forte).

| Cap. | Chefe | Regra central |
|---|---|---|
| 1 | Asmodeus, o Rasurador | Raio, Swipe, Summon, raio em cruz |
| 2 | A Mãe das Traças | Só palavras ferem; Eat_Page encolhe a arena |
| 3 | O Abade Caído | Palavras profanas; Mirror_Cast bloqueia palavras por 4s; só CRUX bloqueia o XURC |
| 4 | Padre Malaquias | Penance exige palavra que **caiba no atril atual**; heresia o cura em 5% |
| 5 | Semíhaza | Pena Negra corrompe letras; na F3 só LUX causa dano |

Fases completas: `docs/ASSET-CATALOG.md` §5.

---

## 4. Narrativa [D-023]

Canônica em **`narrative.md`** (Bíblia Narrativa v1.0, do autor). Resumo: 1348, peste negra, Mosteiro de São Wendelino. O Abade Gerbrand abre o **Codex Damnatus**, a prisão do anjo Semíhaza, e libera Asmodeus, que começa a apagar o mundo. O Irmão Anselmo entra no livro para reescrevê-lo. Regra do livro: **a Palavra sustenta a página**.
- 12 cutscenes (C1-01 … C5-02), in-engine (feature 008 e as de cada capítulo), seguindo o mapa do `narrative.md` §12.
- Os verbetes do Grimório estão no `narrative.md` §11.
- Regra de tom: nenhuma fala passa de 2 linhas; o latim nunca é traduzido em tela.
- **Modo Heresiarca** (o gancho do final) fica **fora do roadmap atual**; é candidato a uma feature futura.

## 5. Áudio [PENDENTE]
O autor vai mandar os arquivos. Até lá, os eventos usam placeholders silenciosos.

## 6. Telas
Splash · Menu · Seleção de personagem · Seleção de capítulo · HUD · Loja · Pausa · Game Over · Vitória · Codex Completus · Opções · Grimório · Créditos · Loading. Todas em 640×360 e 100% navegáveis por teclado. Idiomas: PT-BR e EN.

## 7. Critérios de sucesso globais
- **SC-G1:** 60 FPS no build web com 300 inimigos, 150 letras e 200 projéteis.
- **SC-G2:** um jogador novo conjura LUX na primeira onda com a ajuda das dicas.
- **SC-G3:** demo do Cap. 1 (Anselmo e Hildegarda) com build de até 25 MB.
- **SC-G4:** palavra, inimigo, onda e item novos são só arquivos de dados.

## 8. Pendências do autor
- Áudio (o autor manda depois).
- Imagem da história (opcional; se chegar, ajusta o `narrative.md`).
- Confirmar a interpretação de "parado e sem atacar" (D-011).
