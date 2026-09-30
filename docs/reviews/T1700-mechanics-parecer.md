# T1700 — Parecer do mechanics-agent: sistema da 017 "Arsenal sagrado"

> 2026-09-30 · **AJUSTAR**: implementável com o que existe (PlayerProjectileManager, SpatialHash, padrão das zonas D-084, GraceFlow, RunUpgrade). Antes das tasks, 7 pontos de sistema:
> 1. **Tempo:** o `Hitstop` escreve `Engine.time_scale` direto. Solução: autoload `TimeScale` com donos.
> 2. **Teclas 1/2:** servem para arma e para selo. Solução: contextos de tecla no Settings.
> 3. **Menu × movimento:** as setas e o Espaço já movem e conjuram.
> 4. **Purge:** joga as letras no chão, e o chão deixa de existir.
> 5. **Letra de segurança do chefe:** conta letras no chão.
> 6. **Rajadas de drops:** zonas letais, REQUIEM e Tinteiro Duplo soltam várias letras de uma vez; falta a política da fila.
> 7. **Dano no chefe:** as armas precisam marcar `&"auto"` no `DamageSource`, para o filtro do chefe continuar igual.

## Armas
- **`WeaponData`** (`data/weapons/<id>.tres`):
  - `id`, textos, `icon`;
  - `mode` (`auto`/`aimed`);
  - `pattern` (`burst`/`beam`/`orbit`/`swing_trail`/`fan`);
  - `projectile_kind`, `muzzle`, `travel_mul`;
  - `levels`: uma tabela de `WeaponLevelData` (dano, intervalo, alcance, velocidade, largura, pierce, count, spread, órbita, arco, rastro);
  - `boss_tag` = `&"auto"`.
- **`ArsenalTuning`:** slots 2, `swap_draw_time`, lista das 6 armas, `zone_eval_stride`.
- **`PlayerData.start_weapon`.**
- **Pena em dados, sem mudar o que se sente:**
  - `pen.tres` nível 1 = dano 1, intervalo 0,8, alcance 160, velocidade 220, `travel_mul` 1,25.
  - A Pena de Ganso passa a mexer em `weapon_interval_mul` (stat novo; mul 0,85, teto 0,5).
  - Prova: a sonda com a mesma seed dá os mesmos tiros e as mesmas mortes antes e depois.
- **`Loadout`** (em `GameState`):
  - 2 `WeaponSlot` (arma + nível), `active`, `passives` (id → nível);
  - `equip` (preenche o vazio ou substitui a ativa), `set_active`, `level_up`.
- **`Arsenal`** (substitui o nó AutoAttack):
  - os 5 componentes nascem no `_ready`; só o do padrão da arma ativa fica ligado;
  - lê `weapon_1/2`;
  - espera o saque antes de atacar;
  - a cadência de cada componente continua contando mesmo desligada (sem exploit de troca).
- **Componentes:**

| Componente | Armas | Como fere |
|---|---|---|
| `BurstWeapon` | Pena, Crucifixo | Projéteis com `kind` e `pierce` |
| `FanWeapon` | Aspersório | Projéteis em leque |
| `BeamWeapon` | Bíblia | `WeaponZones` LINE |
| `OrbitWeapon` | Rosário | `WeaponZones` POINTS |
| `SwingTrailWeapon` | Turíbulo | Cabeça CIRCLE + rastro POINTS (anel de 32) |

- **`WeaponZones`:** registro estático não letal.
  - A geometria sai do `KillZone` para uma base `ZoneShape`.
  - O `EnemyManager` aplica as zonas de arma e as letais no mesmo passe.
  - O toque tem canal próprio (`weapon_touch_ready`), sem conflito com o ANGELUS.
  - Consulta por segmento na grade (`query_segment`, DDA) e avaliação a cada 2 ticks.
  - A arma nunca mata o comum na hora: isso é só das palavras.
- **Mira:** função comum `Aim.direction(origin, facing)` (mouse ou direção do movimento; regra da D-067), usada pelo Caster, pela Bíblia e pelo Aspersório.

## Menu de escolha da letra
- **Estados (`LetterMenu`):**
  - IDLE com fila → OPEN: sorteia as 3 opções na hora de abrir e liga a câmera lenta.
  - OPEN → CHOSEN (`collect`) ou EXPIRED (`letter_lost`).
  - CHOSEN ou EXPIRED → o próximo da fila (a câmera lenta continua) ou IDLE.
  - Com o jogo pausado, o relógio congela e a entrada é ignorada.
- **Relógio:** `clock += delta / TimeScale.factor_product()`. São 2,5 s reais; na sonda, escalam com a base 4×.
- **`LetterOfferRoll`:**
  - 1 espaço garantido, sorteado só entre `lexicon.next_letters(atril)`; com o atril vazio, a primeira letra de uma palavra que cabe;
  - as outras 2 opções vêm do `dropper.roll`;
  - as 3 são distintas; rara e alvo ficam marcadas;
  - usa o RNG das letras.
- **Atril cheio ou palavra pronta:** o menu espera na fila.
- **Fila:** `queue_cap` (ex.: 2); o excedente se perde.
- **Autoload `TimeScale`:**
  - `base` (4 na sonda) × fatores por dono (`hitstop` 0, `letter_menu` 0,2, `potion` reservado para a 018);
  - só ele escreve `Engine.time_scale`; quem hoje põe 1,0 passa a chamar `TimeScale.reset()`.
- **Prioridades:** os selos da Graça e a loja esperam o menu fechar; o fim da onda descarta a fila; a morte cancela o menu.
- **O que sai do LetterField:**
  - `spawn_letter`, o pool e a cena `Letter`, ímã e coleta, marcação por clique, ímã seletivo;
  - Traça comendo letras, `drop_safety_letter`;
  - campos do `DropTuning` do chão.
- **O que fica:** Lexicon, Atril, Dropper, `collect`, Rasura, `emit_atril`. A tinta dourada segue no chão com o ímã.
- **Propostas para os casos que perdem o sentido:**
  - **Traça:** rouba a última letra do atril ao tocar o escriba e a devolve na fila quando morre.
  - **Purge:** Shift esvazia o atril sem heresia.
  - **LetterSafety do chefe:** passa a contar "tempo sem oferta" e abre uma oferta de segurança.
  - **LUMEN:** um substituto para o efeito de ímã (rules-agent).
- **Entrada:**
  - ações `letter_prev`, `letter_next` e `letter_pick` (← → Espaço), mais o clique na carta;
  - com o menu aberto, o Caster ignora `cast`/`purge` e **o escriba fica parado** (o `Input.get_vector` lê as setas mesmo com o evento consumido);
  - trava `pick_guard` e tecla apertada depois de abrir.
- **Contextos de tecla no Settings:**
  - `play`: movimento, cast, purge, `weapon_1/2`, poções;
  - `seals`, `letter_menu`, `shop`.
  - A troca de tecla só vale dentro do mesmo contexto.

## Ímã reverso
- **`RepulseData`:** níveis com intervalo, raio, knockback, stun e dano.
- **`RepulseAura`:**
  - o timer anda em tempo de jogo;
  - empurra via `stun_in_radius` e, se o nível tiver dano, fere com `damage_in_radius` (`auto`);
  - emite `repulse_pulsed`.
- **Propostas:** segura o pulso quando não há ninguém no raio; não empurra o chefe.

## Selos, loja e RunUpgrade
- **`SealOption`** (kind: `blessing`, `weapon_level`, `passive_level`; `potion` na 018) e **`SealPool.draw`**:
  - pesos em `GraceTuning`;
  - no máximo 1 opção por espaço de arma;
  - fica fora do sorteio a arma no nível máximo e o passivo que não se tem ou que já está no máximo.
- **Sinais:** `seals_shown(options)` e `seal_chosen`; `blessing_chosen` continua saindo.
- **`RunUpgrade`:** `apply_option`, `equip_weapon`, `buy_passive`.
- **Bênçãos:**
  - Estante Nova e Tinteiro Duplo viram bênção;
  - a Pedra-Ímã sai;
  - a Pena de Ganso passa a mexer em `weapon_interval_mul`.
- **Loja:**
  - `ShopItemData.kind` ganha `weapon` e `passive`;
  - `ShopOffer` exclui o que já se tem;
  - vaga garantida de arma na 1ª loja com o espaço 2 vazio;
  - confirmar a substituição com os 2 espaços cheios.

## Eventos
- **Novos:**
  - `weapon_equipped`, `weapon_switched`, `weapon_leveled`, `passive_leveled`, `repulse_pulsed`;
  - `letter_drop_requested`, `letter_menu_opened`, `letter_picked`, `letter_lost`, `letter_menu_closed`;
  - `seals_shown` e `seal_chosen` com as opções.
- **Saem:** `letter_dropped` e `letter_eaten`.

## Testes
- **Fase 1:** `auto_attack.enabled` vira `arsenal.enabled` em cerca de 20 testes; `test_auto_attack` vira `test_burst_weapon` (paridade da Pena).
- **Fase 3:** saem ou são reescritos:
  - `test_letter_mark` inteiro;
  - os testes da Traça em `test_behaviors`;
  - o purge em `test_miracles`;
  - a coleta pelo chão em `test_cast_lux`.
- **Todos os testes:** o teardown com `Engine.time_scale` vira `TimeScale.reset()`.
- **Novos:** `test_loadout`, `test_weapon_data`, `test_letter_offer_roll`, `test_letter_menu`, `test_time_scale`, `test_weapon_zones`, `test_repulse`, `test_seal_pool`, `test_arsenal_flow`, `test_letter_menu_flow`.

## Sonda
- `TimeScale.base = 4`.
- **Opções novas:**
  - `letters=smart|first|random|none` e `react=F` (reação em s);
  - `weapons=pen,bible`, `wlevel`, `repulse`;
  - `swap=auto|none|every:N`.
- **A sonda mira escrevendo `GameState.aim_point`** (campeão ou Monge mais próximo).
- **Linhas novas:** WEAPON e LETTERS.
- **Stress:** `?stress=bible` e `?stress=arsenal`.
- **Debug:** `?weapons=bible,crucifix&wlevel=3`.

## Fases e tasks
| Fase | Tarefas | O que entra |
|---|---|---|
| 1 | T1701–T1709 | TimeScale, contextos de tecla, WeaponData, Loadout, Arsenal + Pena, `weapon_interval_mul`, WeaponBar, troca nos testes, paridade na sonda |
| 2 | T1710–T1717 | ZoneShape, WeaponZones, `query_segment`, Aim, Bíblia, Crucifixo (pierce), `?stress=bible` → **playtest do autor** |
| 3 | T1718–T1728 | LetterOfferRoll, LetterMenu, a tela do menu, guardas, sai o chão, Traça, purge, LetterSafety, áudio, testes, sonda |
| 4 | T1729–T1735 | SealPool, selos por tipo, `apply_option`, bênçãos novas, loja de armas e passivos, ímã reverso |
| 5 | T1736–T1739 | Rosário, Turíbulo, Aspersório, `?stress=arsenal` |
| 6 | T1740–T1742 | SC-001, sonda por arma e por onda com o rules-agent, docs |

## Riscos
- **Bíblia contínua no web:** mitigada por `query_segment`, avaliação a cada 2 ticks e um rebuild da grade só.
- **Rastro do Turíbulo:** um `query_rect` do envelope do rastro por tick.
- **Leque:** respeitar o teto de 200 projéteis.
- **Legibilidade:** tinta contra inimigos em INK.
- **Nada instanciado na onda.**
