# D-085 (proposta) — Parecer do game-design-agent: armas, poções e palavras como "ultimate"

> 2026-09-30 · **AJUSTAR.** Aceita a nova direção do autor como uma emenda à game bible (a constituição não muda).

## Pilar 1 e fantasia
- **Pilar 1 proposto:** "Escrever é o milagre. As armas seguram a linha; as palavras decidem a luta. Escolher qual letra pegar continua sendo a decisão central, porque cada letra é rara."
- **Fantasia:** um monge copista preso num códice amaldiçoado. Os objetos sagrados o mantêm vivo; as letras arrancadas dos demônios viram milagres que apagam a página.
- **Regra de cor:** armas só em INK, INK_SOFT e CHALK. **O dourado fica só para as palavras.**

## O que muda
- **D-082:** o ritmo de 3,5 palavras/min é revogado. Os instrumentos (item 5) viram armas de verdade.
- **D-083 / 016:** a estrutura fica (Graça, pausa, 3 selos, fila, pingo de cera). Muda o conteúdo dos selos: nível de arma, status ou poção. Deixam de valer o FR-1602 (2/3 da Graça vêm das palavras) e o FR-1613 (nada supera as palavras); o FR-1614 (loja) é reescrito.
- **D-084:** combina com o "ultimate". Terminar a Fase 4. O rules-agent revê o `hp_mul` 6 do campeão.

## Estrutura
- **Inventário:** 2 espaços; só a arma ativa ataca.
  - Troca com **Q** ou com a roda do mouse.
  - O nível fica na arma: se ela for trocada, perde o nível.
  - Anselmo começa com a Pena.
- **As 6 armas:**

| Arma | Como ataca | Papel |
|---|---|---|
| **Pena do Copista** | Automática, rajada rápida em 1 alvo (é o ataque de hoje) | Inicial |
| **Bíblia** | Mirada, luz de página contínua em linha, dano baixo | Precisão |
| **Crucifixo** | Automático, rajada lenta e forte que atravessa em linha | Dano bruto |
| **Rosário** | Contas orbitando o escriba | Defesa contra enxame |
| **Turíbulo** | Balança em arco e deixa rastro de incenso | Controle de área |
| **Aspersório** | Mirado, rajada em leque curto | Abrir caminho de perto |

- **As 4 poções:** cargas compradas na loja, teclas 1–4, sem recarga.
  1. **Óleo da Unção:** acende 1 vela.
  2. **Água Benta:** círculo de refúgio onde os inimigos não entram.
  3. **Vinho do Fervor:** a arma ativa ataca mais rápido.
  4. **Tinta Iluminada:** o ímã puxa as letras da tela toda e a letra-alvo aparece mais.
- **Loja:** armas, cargas de poção e apócrifos.
- **Level-up:** +1 nível de uma das 2 armas, status ou poção.
- **Status:** as bênçãos de hoje, mais a Estante Nova e o Tinteiro Duplo.
  - A Pena de Ganso Fina passa a valer para a cadência de todas as armas.
  - A bênção Rosário muda de nome para **Escapulário**.
- **XP:** cresce com a força do inimigo; as mortes viram a fonte principal.

## Ritmo das palavras
- A raridade vem das letras (caem menos), não de recarga ou barra de carga.
- Inimigos mais fortes soltam mais letras.
- **Alvo:** ~1 palavra/min, com uma decisão de letra a cada 10–20 s.
- **Cuidado:** letras raras + vida de 12 s + Traças podem frustrar.

## Ordem proposta
1. D-084 Fase 4.
2. Fechar a 016.
3. Emenda da game bible (D-085).
4. **017 "Arsenal sagrado":**
   - (a) inventário e troca, com a Pena convertida;
   - (b) Bíblia e Crucifixo, seguidos de playtest;
   - (c) Rosário, Turíbulo e Aspersório;
   - (d) nível das armas nos selos e armas na loja.
5. **018 Poções.**
6. Passada de ritmo (rules-agent).
7. 009 → 010 → 011.

## Riscos
- Escopo alto: atrasa a demo.
- Identidade: se as letras ficarem raras demais, o jogo vira "mais um survivors".
- Legibilidade.
- Desempenho no web.
- Controles: Q e 1–4 estão livres.
