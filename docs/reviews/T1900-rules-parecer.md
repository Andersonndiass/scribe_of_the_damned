# T1900 — Parecer do rules-agent: 019 Relíquias e venda (D-103)

> 2026-10-02 · Skill: `game-development/game-design`. **PARECER: VÁLIDO COM RESSALVAS** (R1–R6).

## Regras comuns das relíquias
- Base = nível 1; cada selo sobe 1 posto de um atributo; nível = 1 + compras, até `1 + max_upgrades`. A soma dos postos é maior que `max_upgrades` (exceto o Selo de Cera), então não dá para pegar tudo.
- Relógios em tempo de jogo; sem inimigo ao alcance o pulso espera pronto (`hold_when_empty`).
- Campeão: metade do controle (empurrão, atordoamento, lentidão); dano inteiro. Chefe: nunca empurrado, atordoado nem lento; só leva dano (`auto`).
- Números em `data/relics/<id>.tres` (`RelicData` = base + upgrades + max_upgrades).

## As 5 relíquias
| Relíquia | Atributos: base / postos (teto) | `max_upgrades` | Preço |
|---|---|---|---|
| Ímã Reverso | RECARGA 5,0/4,5/4,0/3,5 (3) · RAIO 56/64/72 (2) · EMPURRÃO 40/48/56 (2) · DANO 0/1/2 (2) | 5 | 8 |
| Sino de Vésperas | RECARGA 8,0/7,0/6,0 (2) · RAIO 48/56/64 (2) · ATORDOAMENTO 0,5/0,65/0,8 (2) | 4 | 9 |
| Sal Bento (aura) | RAIO 40/48/56/64 (3) · LENTIDÃO 0,90/0,85/0,80 (2) | 4 | 8 |
| Relicário do Santo | DANO 2/3/4 (2) · RAIO 48/56/64 (2) · INVULNERÁVEL +0,2/0,35/0,5 s (2); empurrão fixo 48 | 4 | 8 |
| Selo de Cera | RECARGA 20/17,5/15 (2) · +1 CARGA 1/2 (1) | 3 | 10 |

- **Sino:** pior caso 13,3% do tempo atordoado (campeão 6,7%); o atordoamento usa `maxf` e não soma com PAX/DOMINUS; atordoado não fere por contato.
- **Sal:** aplica `apply_slow` a cada 0,1 s com 0,25 s de duração; piso 0,80 (acima do de arma, 0,75); AQUA/SANCTUS seguem mais fortes.
- **Relicário:** dispara quando o jogador perde vela (não com golpe absorvido, heresia ou golpe que mata); invulnerabilidade total ≤ 1,5 s.
- **Selo de Cera:** vem com 1 carga; recarrega só em onda e só abaixo do máximo; o golpe absorvido dá a invulnerabilidade normal; **contador separado do FIDES**, e a cera é gasta primeiro. Onda 9 do zero continua derrota (~40–50 s de vida).

## Pesos dos selos (escritos no `grace.tres`)
`seal_weapon_active` 0,30 · `seal_weapon_reserve` 0,15 · `seal_status` 0,37 · `seal_relic` **0,12 por relíquia** (substitui `seal_passive` 0,10) · `seal_potion` 0,08. No máximo 1 selo por relíquia por oferta. O cartão é igual ao da arma.

## Venda (`shop_tuning.tres`)
`valor = clamp(floor(0,4 × pago) + 1 × postos, 1, pago − 1)` para arma e relíquia. "Pago" é o preço efetivamente pago; a Pena vale como se custasse 4. Poção por carga: `max(1, floor(0,4 × preço atual))`; o nível da poção fica.
- Nunca dá lucro; o item comprado na visita vende por `floor(0,4 × pago)`; o vendido volta ao baralho sem postos.
- A arma ativa pode ser vendida se sobrar 1 arma; com 1 arma só, VENDER fica desligado.

## Aceites para a sonda
S1 onda 1 sem god igual · S2 onda 9 sem god, do zero, com cada relíquia no teto: derrota 3/3, vida ≤ 3× sem relíquia · S3 Sino no teto: comum ≤ 15% atordoado · S4 mortes/min na onda 5 ≤ 1,15× sem relíquia · S5 cera ≤ 7 golpes absorvidos na onda 9 · S6 tinta 80–100, compras 6–8, venda ≤ 15% da tinta · S7 1–2 relíquias, selos de relíquia 15–25%, arma nv 7 entre as ondas 4 e 7 · S8 nível final 15–17, palavras/min 0,40–0,60 · S9 (GUT) venda < pago em tudo · S10 stress com Sal no teto sem regressão.

## Rótulos
RECARGA/COOLDOWN · RAIO/RADIUS · EMPURRÃO/PUSH · DANO · ATORDOAMENTO/STUN TIME · LENTIDÃO · INVULNERÁVEL/INVULNERABLE · +1 CARGA/+1 CHARGE · VENDER/SELL.

## Ressalvas
- **R1 (autor):** o Selo de Cera no teto absorve ~6 golpes na onda 9, mais que a palavra FIDES (1 carga a cada ~2 min). Alavanca: RECARGA 25/22/20.
- **R2 (design-agent):** o atordoamento desenha uma coroa GOLD; o do Sino precisa de marcador INK/CHALK (GOLD só palavras/Graça).
- **R3:** os pesos dos selos passam a morar no `grace.tres`.
- **R4 (autor):** P1 — TROCAR com espaços cheios vira venda automática do que sai? P2 — com espaço de arma vazio, garantir 1 arma na próxima loja?
- **R5:** "SINO DE VÉSPERAS" e "RELICÁRIO DO SANTO" passam de 14 caracteres no subtítulo do selo (formas curtas: SINO, RELICÁRIO).
- **R6:** migrar `RepulseData`/`GameState.repulse_level` para `RelicData` + postos.

## Medição da implementação (2026-10-02)
- **S2 ✅:** onda 9 sem god, do zero, com cada relíquia no teto, é derrota: morre em 16–27 s (sem relíquia, 23 s). O Selo de Cera segurou 4 golpes.
- **Capítulo ×3 (god), o bot compra relíquias só com espaço livre:** palavras/min 0,16 / 0,16 / 0,24 (média 0,19); letras 32–40; a Traça comeu 19–23; nível final 13–15; tinta 67–82; 5–7 compras.
- **A/B sem relíquias (`norelics`):** palavras/min 0,32 / 0,64 / 0,24 (média 0,40); letras 27–45; nível 14–15.
- **Leitura (aberto, para o rules-agent e o playtest):** com relíquias saem ~metade das palavras. Hipóteses: o Ímã e o Sal tiram os inimigos do alcance das armas curtas (menos mortes, menos menus de letra); as relíquias competem com os apócrifos (LUMEN) pela tinta e com as armas pelos selos. Alavancas possíveis: chance de letra por morte mais alta com relíquia de controle, ou relíquias mais caras. Com n = 3 o ruído é alto; medir com ×5.
