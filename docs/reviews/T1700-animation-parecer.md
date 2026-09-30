# T1700 — Parecer do animation-agent: tempo e sensação da 017 "Arsenal sagrado"

> 2026-09-30. Mesmas premissas do T1600: degraus de 50/100 ms, px inteiros, sem easing.
> - A UI e os contadores usam o relógio real.
> - O ataque das armas usa o `delta` do jogo: fica lento na câmera lenta e para no hit-stop.
> - **Onde o parecer fala em "xadrez 50%" nas cartas do menu ou em sprites pequenos, vale a regra de pixel art do autor (D-075/D-076, C1 do T1600):** trocar por quadros lisos. O tempo continua o mesmo.

## 0. Dono do `Engine.time_scale` (bloqueante)
- **O problema:** hoje o `Hitstop` volta o `time_scale` para 1.0 ao terminar, e as Overlays, o ScreenRouter e a sonda também escrevem nele. Um hit-stop durante o menu da letra devolveria o jogo a ×1.
- **A proposta:** um dono só, o autoload TimeScale (o `Hitstop` renomeado), com 3 camadas:
  - `base`: 1 no jogo, 4 na sonda;
  - `slow`: a câmera lenta do menu;
  - `freeze`: o hit-stop.
- **A regra:** `time_scale = 0 se freeze; senão base × slow`. `reset()` na troca de tela e no restart.
- **Prioridade:** um hit-stop de 40 ms (morte de campeão) é ignorado durante o hit-stop de uma palavra e até 200 ms depois dele (`min_gap_after_word`).

## 1. Troca de arma
- **Saque de 100 ms:** a arma sobe de 2 px abaixo até o repouso. O movimento do escriba nunca trava.
- **Recarga:** cada arma tem a própria recarga, que continua correndo guardada (regra, a confirmar com o rules-agent).
- **Dano de quem sai:** termina na hora da troca.
  - A Bíblia desliga.
  - O Crucifixo em antecipação cancela sem gastar a recarga.
  - O Rosário recolhe as contas em 2 × 50 ms, sem dano.
  - **O rastro do Turíbulo que já está no chão continua ferindo.**
- **HUD:** o espaço ativo sobe 1 px com contorno CHALK (nunca GOLD).

## 2. Ataques
| Arma | Tempo | Detalhes |
|---|---|---|
| Pena | 1 quadro | Como hoje |
| Bíblia | start 2×50 ms · loop 200 ms (largura W / W−2) · end 2×50 ms | Dano em ticks de 100 ms. Mira em 32 direções. O flash no inimigo sai no 1º contato e depois a cada 400 ms (evita piscar a 10 Hz) |
| Crucifixo | windup 4×50 ms (sobe 2 px; brilho CHALK) · strike 2×50 ms | Congelamento local de 50 ms só nos inimigos atingidos (precisa de `freeze_until` por inimigo). Shake 1 px / 100 ms |
| Rosário | volta de 1400 ms · entra e sai 2×50 ms | Mesmo inimigo só leva outro acerto depois de 400 ms (rules-agent aprova) |
| Turíbulo | 8 quadros de 50 ms por lado (−60…+60°), corrente de 16 px | Nuvem nova a cada 100 ms, 4 estágios 700/700/700/400 ms (total 2,5 s); sobe 1 px a cada 400 ms; teto de 25 nuvens |
| Aspersório | 4×50 ms | O golpe acontece no quadro 1 |

- **Nenhuma arma tem hit-stop global.** O hit-stop forte fica com as palavras.

## 3. Menu de escolha da letra
- **Câmera lenta:** entra em 0,5 e 0,2 (50 ms cada) e sai em 0,5 e 1,0 (100 ms cada). O som não muda de tom.
- **Os 2,5 s** contam do `menu_enter` em diante; o Espaço e o clique ficam travados nos primeiros 100 ms.
- **Barra do tempo:** 25 degraus de 100 ms. Nos últimos 700 ms só a barra pisca (0,3 ↔ 1 a cada 100 ms; nos últimos 200 ms, a cada 50 ms).
- **Foco:** a carta sobe 2 px.
- **Escolha:** pop CHALK de 50 ms e o glifo voa até o atril em 200 ms (QUAD_IN, px inteiros); as outras duas somem em 100 ms.
- **Tempo esgotado:** as cartas somem em 100 ms e a letra se perde.
- **Fila:** `queue_max` 1; os drops a mais se perdem. Depois de uma sequência, 400 ms a ×1 antes da próxima (`reopen_gap`) — números do rules-agent.
- **Palavra:** os drops da zona letal esperam o hit-stop da palavra + 200 ms.
- **Pausa e selos:** com o jogo pausado o contador para. O GraceFlow espera o menu fechar antes de anunciar o nível.
- **CONFLITO DE TECLAS:** as setas também movem o escriba e o Espaço é conjurar. Durante o menu, as setas e o Espaço são do menu, e o WASD continua movendo.

## 4. Palavras como "ultimate"
| Tipo | Hit-stop | Shake | Flash |
|---|---|---|---|
| Palavra de ataque | 100 ms | 2 px / 400 ms | Squash do Anselmo 1.1/0.9 por 100 ms; pena CHALK; tela CHALK 25% por 50 ms |
| Tela e combos (MARTYRIUM, PURGO, REQUIEM, MISERERE) | 100 ms | 3 px / 400 ms | O mesmo, mais a página escurecida 25% por 200 ms |
| Ferramenta | 60 ms (como hoje) | — | — |

- A constante `CAST_HITSTOP_MS` sai do `caster.gd` e vai para os dados (`word_feel.tres`). O art bible §14 muda.

## 5. Ímã reverso
- **Aviso** (charge): 2×100 ms.
- **Onda INK_SOFT de 2 px:** 4×50 ms, com o empurrão e o dano no quadro 0.
- **Empurrão do inimigo:** 40/70/90/100% da distância em 4×50 ms, com o movimento dele suspenso nesse tempo.
- **Sem hit-stop nem shake.**

## Números para os dados
Os campos de tempo de `WeaponData`, `letter_menu.tres`, `word_feel.tres` e `reverse_magnet.tres` são os valores listados acima.
