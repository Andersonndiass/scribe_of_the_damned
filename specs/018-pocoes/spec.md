# 018 — Poções, subir de nível com luz e passada de ritmo

> Status: **Aprovada** (2026-10-01, o autor: "depois disso tudo pode seguir") · Fase 1 ✅. Direção: D-085 item 7, D-094, D-095.
> Pareceres: `docs/reviews/T1800G-game-design-018.md` (direção) · `T1801-rules-parecer.md` (números) · `T1801-mechanics-parecer.md` (sistema) · `T1801-design-parecer.md` + `T1801-design-maps.json` + `T1801-potion-icons.json` (arte; ícones do HUD com a skill pixel-art-gen) · `T1801-animation-parecer.md` (tempos).
> Depende de: 017 (armas, menu da letra, selos, loja, HUD T1800), 016 (Graça).

## Objetivo
Dar ao escriba **4 poções** de uso na hora (teclas 3–6), compradas na loja em cargas, que ajudam sem competir com as palavras; fazer o **subir de nível** ser um momento (feixe de luz dourado + câmera lenta) e mais cedo; e fechar o ritmo do capítulo com uma sonda nova.

## Requisitos

### Subir de nível (D-094, D-095)
- **FR-1801** Curva da Graça: `level_costs [16, 40]`, `level_base` 8, `level_step` 28 (16, 40, 64, 92, 120, …); 1º nível aos ~15 s da onda 1. `GraceTuning.validate()` passa a checar `level_costs[0]`.
- **FR-1802** Ao subir de nível: um **feixe de luz dourado** desce sobre o Anselmo e o jogo entra em **câmera lenta por 2,5 s** (pelo `TimeScale`), com **uma barra mostrando quanto falta**; ao fim, o jogo pausa e os 3 selos aparecem como hoje. Tempos e desenho do feixe: animation-agent e design-agent (na Fase 1). Níveis na fila: um feixe só, depois os selos em sequência.

### Poções
- **FR-1803** 4 poções em dados (`data/potions/*.tres`), 3 níveis cada, teclas **3, 4, 5, 6** (`potion_1..4`, trocáveis, contexto de jogo):

| Poção | nv 1 | nv 2 | nv 3 | Teto | Preço base |
|---|---|---|---|---|---|
| Óleo da Unção | 1 vela | 1 vela + 1,0 s invulnerável | 1 vela + 1,5 s invulnerável | 2 | 3 |
| Água Benta | círculo raio 32, 3 s | 40, 4 s | 48, 5 s | 2 | 4 |
| Vinho do Fervor | intervalo da arma ×0,80, 8 s | ×0,75, 10 s | ×0,70, 12 s | 2 | 4 |
| Tinta Iluminada | abre 1 menu (1 das 3 letras útil) | 2 úteis | 3 úteis | 1 | 6 |

- **FR-1804** Regras de uso: intervalo mínimo de **1,5 s** entre poções; a mesma poção renova a duração; poções diferentes coexistem; bloqueadas com o menu da letra aberto, nos selos, na Pausa, na loja, morto e **atordoado**; o Óleo não gasta com as velas cheias; a Iluminura não gasta com menu aberto ou na fila. Recusa não gasta carga e dá feedback (tremor = sem carga; cadeado/X = bloqueada; flash = intervalo).
- **FR-1805** **Água Benta:** círculo fixo onde foi bebida (beber de novo recentraliza); comuns, voadores e campeões não entram e quem estava dentro vai para a borda, sem dano; projéteis passam; o chefe ignora; **heresia dentro apaga o círculo**; parado dentro **não recupera vela**.
- **FR-1806** **Vinho:** só na arma ativa no momento de beber (trocar não leva o efeito); vale para o tick da Bíblia e a volta do Rosário; com a Pena de Ganso, o produto nunca desce de **0,55**.
- **FR-1807** **VITA acende 2 velas** (Óleo 1 < VITA 2 < SALVATOR 3).
- **FR-1808** Começa a partida com **1 Óleo da Unção** (nível 1).
- **FR-1809** **Loja:** prateleira fixa com as 4 poções, separada das vagas sorteadas (sem reroll nem trava); pode comprar várias vezes até o teto; preço cresce por onda (`price_growth` 0,1).
- **FR-1810** **Selo de poção:** +1 nível de uma poção já comprada, abaixo do nível 3; peso 0,08 (status 0,45 → 0,37); nunca dá carga.
- **FR-1811** Arte em tinta, **zero GOLD** nas poções; HUD com os 4 espaços no painel do inventário (estados do parecer do design-agent); nenhuma poção tem hit-stop nem tremor de tela.

### Arena
- **FR-1812** Banco (o6) de (104, 328) para **(184, 272)**; aceite pela sonda ARENA/STUCK (STUCK ≤ 5%).

### Passada de ritmo (fase final)
- **FR-1813** Sonda nova (distância = alcance da arma, ≥ 3 rodadas, capítulo inteiro com selos e loja, onda 9 sem god) e os ajustes da lista fechada do rules-agent (T1801 §5: palavras/min 0,8–1,3; menus/min 5–6,5; Rosário/Crucifixo/Aspersório/Pena; campeão 4–15 s; tinta e compras; gasto em poções ≤ 40%; Iluminura ≤ 10% das letras).

## Fora do escopo
Poção que recarrega ou cai de inimigo; 5ª poção; poção que conjura, dá Graça ou dourado; selo que dá carga; vida do Asmodeus (C-006, autor); sonda do chefe (D-081); Firefox.

## Critérios de sucesso
- **SC-1801** 1º nível da onda 1 entre 12 e 20 s; o feixe e os 2,5 s de câmera lenta com barra aparecem a cada subida.
- **SC-1802** Testes: cada poção faz o efeito por nível; as recusas não gastam; Água Benta barra comuns/voadores/campeões e não o chefe; heresia apaga; Vinho só na arma do momento e piso 0,55; prateleira fixa; selo de poção.
- **SC-1803** Desempenho: `?stress=refuge` (300 inimigos com a Água Benta) sem regressão no desktop.
- **SC-1804** Passada de ritmo: a lista do T1801 §5 dentro das faixas.

## Fases
1. Subir de nível (curva + feixe + câmera lenta com barra) e banco da arena.
2. Dados das poções, cinto de poções, teclas, uso (Óleo) e HUD.
3. Vinho e Iluminura.
4. Água Benta.
5. Loja (prateleira) e selo de poção; VITA 2 velas.
6. Passada de ritmo.
