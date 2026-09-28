# 002 — Vocabulário e combos

> Status: **Complete** (2026-09-28). Aprovada em 2026-09-26 ("1b 2sim 3ok"). Fechamento: D-057.
> Depende de: 001 e 005 (Complete). Game bible §3.5–§3.6. Decisões D-006, D-013, D-015, D-016, D-017. Narrativa §11 (verbetes).
> Pareceres (2026-09-26): game-design-agent **AJUSTAR** e rules-agent **VÁLIDO COM RESSALVAS**. Os ajustes estão aplicados (marcados **[P]**). Onde divergiram, prevaleceu a opção que preserva o risco do jogo.

## Objetivo

Ampliar o vocabulário: os 5 **apócrifos** (liberados pela loja na 003; aqui, a mecânica e um desbloqueio por API), as 6 **Grandes Orações** de 7 e 8 letras (conhecidas desde o início, mas só cabem com o atril ampliado) e os 5 **combos** entre palavras base, com a janela de 2.5 s.

## Fora do escopo

| Item | Feature |
|---|---|
| Carta de apócrifo e upgrade de atril na loja | 003 |
| Janela de combo maior da Hildegarda | 010 |
| Tradução e lore no Grimório | 007 |
| Arte final dos VFX (placeholders em código até a arte gerada) | D-024 |

## Histórias de usuário

- **US-1 (P1):** como jogador, conjuro duas palavras seguidas dentro de 2.5 s e vejo um **combo**, mais forte que as duas palavras separadas.
- **US-2 (P1):** como jogador, vejo no HUD a **janela de combo** correndo depois de uma conjuração, e as dicas mostram quais palavras fecham um combo.
- **US-3 (P1):** como jogador, um apócrifo liberado entra no meu vocabulário (dicas, Tab, drop ponderado) e tem um efeito único.
- **US-4 (P2):** como jogador, com o atril em 7 ou 8 conjuro uma **Grande Oração**, o momento mais forte do jogo.
- **US-5 (P1):** como jogador, PURGO limpa a tela sem derrubar o FPS.

## Requisitos funcionais

### Vocabulário conhecido
- **FR-201** Cada `WordData` ganha `group` (`base`, `apocrypha`, `oration`) e `requires_unlock`. Uma palavra é **conhecida** se não exige desbloqueio ou está em `GameState.unlocked_words`. Só as conhecidas valem para o atril (VALID/PARTIAL), as dicas, a lista do Tab e o drop ponderado. As desconhecidas continuam no Lexicon, mas invisíveis.

### Combos
- **FR-202** Duas palavras conjuradas dentro da **janela de combo** formam um combo **se o par estiver em `ComboData`**. A ordem não importa. **O combo substitui o efeito da 2ª palavra**, mas **contém visualmente o efeito dela e nunca faz menos que ela** **[P]**. **Janela (D-044):** depois de uma conjuração, a janela fica aberta até `max_open` = 8 s; ela só começa a contar `window` = 2.5 s quando o jogador **coleta a 1ª letra da próxima palavra**. Conjurar dentro desses 2.5 s fecha o combo.
- **FR-202b** **[P]** Combo pronto: com a janela aberta e o atril VALID numa palavra que fecha combo, o atril mostra o estado `COMBO_READY` antes do Espaço. Ao disparar, o nome do combo aparece na página, em blackletter GOLD, **em latim** (D-045): VAPOR, FLAMMA, CAECITAS, MARTYRIUM, REQUIEM. O Grimório traduz.
- **FR-202c** **[P]** O combo **herda as marcas das duas palavras**: um combo com LUX conta como LUX (fere o Semíhaza na F3); um combo com CRUX bloqueia o XURC.
- **FR-203** Os 5 combos (D-016):

  | Combo | Par | Efeito **[PROPOSTA]** |
  |---|---|---|
  | Vapor | AQUA + IGNIS | Nuvem de vapor (raio 80, 4 s, dano 1/0.5 s). **[P]** O escriba dentro da nuvem fica **oculto**: os inimigos fora dela perdem o jogador de vista (`stealth_aggro_mul`). A ocultação é mostrada com **dithering**, não com alpha (Princípio VII) |
  | Chama Radiante | LUX + IGNIS | Raio de LUX que deixa fogo ao longo da linha por 3 s **[P]** (160 × 20 px, 2 de dano a cada 0.25 s) |
  | Cegueira | LUX + PAX | **[P]** Clarão: 6 de dano e stun de 2.5 s num raio de 140. Os inimigos **continuam causando dano de contato** (não há meia-invulnerabilidade) |
  | Martírio | CRUX + LUX | Laser GOLD em cruz girando em volta do escriba por 3 s **[P]** (2 de dano, cooldown de 0.25 s por inimigo). GOLD em projétil: exceção a validar com o design-agent |
  | Réquiem | MORTIS + PAX | Onda de MORTIS em que cada inimigo morto solta letra com certeza, **[P]** até `guaranteed_drop_cap` = 40 |

- **FR-204** Não entram em combo: GLORIA, PURGO. VERBUM não repete VERBUM **nem Grandes Orações nem combos**, e não abre combo **[P]**. Um combo não inicia outro combo: a janela recomeça do zero depois dele.
- **FR-205** O HUD mostra a **janela de combo** (`UI_COMBO_WINDOW`, 12 quadros) encolhendo durante os 2.5 s, e as dicas destacam as palavras que fecham combo com a última conjurada.

### Apócrifos (D-017)
- **FR-206** FIDES: escudo com `charges` = 1 que absorve o próximo golpe (1 ou 2 velas) e dura até ser consumido ou até o fim da onda. Reconjurar renova, não acumula **[P]**.
- **FR-207** LUMEN: por 10 s, `magnet_mul` 2× e `target_weight_mul` 2× **[P]**.
- **FR-208** PURGO: limpa a tela. Mata os inimigos comuns em **lotes escalonados** (`kill_batch_per_frame` = 30, SC-202) e dá **10** de dano em campeões e chefes **[P]**: forte contra a massa, fraco contra a elite. O mesmo caminho em lotes serve para MORTIS, Réquiem, DOMINUS e MISERERE.
- **FR-209** GLORIA: por 6 s, o **dano** (e a cura) dos milagres e combos sai ×1.5. Não escala limiar de morte, stun nem duração. Reconjurar renova **[P]**.
- **FR-210** VERBUM: repete a última palavra conjurada (não VERBUM), com o mesmo poder. Desbloquear VERBUM libera o **B** no drop (D-015).
- **FR-211** Desbloqueio: `GameState.unlock_word(id)` (a loja da 003 chama). Para playtest: parâmetro de debug `?unlock=all`.

### Grandes Orações (7–8 letras, D-006)
- **FR-212** Conhecidas desde o início. Só cabem com o atril em 7 ou 8 (upgrades da 003). Efeitos **[PROPOSTA]**:

  | Palavra | Letras | Efeito |
  |---|---|---|
  | SANCTUS | 7 | Solo consagrado (raio 90, 6 s): dano contínuo e lentidão 50% nos inimigos dentro |
  | DOMINUS | 7 | Todos os inimigos da tela atordoados por 3 s e com **20** de dano **[P]** (= MORTIS + atordoamento) |
  | ANGELUS | 7 | Três penas de luz orbitam o escriba (raio **40**) por 10 s, ferindo quem tocam, com cooldown por inimigo **[P]** |
  | SPIRITUS | 8 | **[P]** Por 6 s o escriba fica **intangível a corpos**: atravessa os inimigos e fere quem toca, 1.5× mais rápido. **Projéteis e heresia continuam doendo** |
  | SALVATOR | 8 | **[P]** Acende **3 velas** e apaga os projéteis inimigos da tela. **Sem invulnerabilidade** |
  | MISERERE | 8 | **[P]** Absolvição: 40 de dano em toda a tela, apaga as poças de heresia e as letras corrompidas, e **perdoa a próxima heresia** (sem stun e sem perder as letras) |

### Técnica
- **FR-213** Todo efeito é uma cena de milagre pooled + `.tres` (Princípio IV). Todo número fica nos `.tres`.
- **FR-214** Nenhum `instantiate()` durante a onda: os pools de milagre cobrem as palavras e os combos novos.

## Critérios de sucesso
- **SC-201** Os 5 combos disparam só com o par certo, dentro da janela, em qualquer ordem. O efeito da 2ª palavra não acontece (teste).
- **SC-202** PURGO com 300 inimigos: nenhum frame acima de 33 ms no Chrome (lotes escalonados).
- **SC-203** Palavra desconhecida não vale: o atril não fica VALID com ela, as dicas e o Tab não a mostram, o drop não mira as letras dela (teste).
- **SC-204** O `power_budget` continua monotônico com o tamanho, agora com 18 palavras (`test_word_power`).
- **SC-205** Os SC-001 e SC-503 se mantêm.
- **SC-206** **[P]** Nenhum efeito deixa o jogador totalmente intocável por mais de 1 s (o risco é pilar); a heresia nunca é anulada por invulnerabilidade.
