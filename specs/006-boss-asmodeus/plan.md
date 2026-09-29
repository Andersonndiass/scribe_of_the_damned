# 006 — Plano

## Arquitetura

- **Dados:** `BossData` (id, nome, `max_hp`, fases, raio do corpo, contato, arte), `PhaseData` (limiar, ataques + pesos, intervalo), `AttackData` (id, tipo, telegrafia, ativo, recuperação, dano, forma: largura/alcance/ângulo/velocidade, cooldown, `min_distance`/`max_distance`), `BossDamageFilter` (tetos), `LetterSafetyTuning`. Tudo em `.tres`.
- **Lógica pura (testável sem cena):**
  - `AttackPicker`: sorteio ponderado da fase, sem 3 iguais seguidos, respeitando cooldown e condição de distância.
  - `BossDamageFilter` (RefCounted): recebe `(amount, source_tag, cast_id)`; soma por `cast_id` para o teto por conjuração; para no limiar da fase; aplica o +25% da exposição às palavras; ignora dano durante a invulnerabilidade.
  - `LetterSafety` (RefCounted): conta letras úteis no chão e o tempo abaixo de N; decide quando soltar uma.
- **Boss** (`src/bosses/boss.gd`, Node2D, fora do EnemyManager) + **FSM** (`Enter → Idle → Telegraph → Attack → Recover → Idle`, `PhaseShift`, `Exposed`, `Stunned`, `Dead`) com os estados como nós, no padrão do `StateMachine` do escriba. Os ataques são executores (`src/bosses/attacks/*.gd`) que desenham a telegrafia e aplicam o dano no escriba pela mesma API do contato (`take_hit(amount, tag)`).
- **Como as palavras ferem o chefe** (sem reescrever os milagres):
  - O `EnemyManager` ganha um **alvo extra opcional** (`boss_target`): cada função de dano (`damage_line`, `damage_in_radius`, `damage_cross*`, `damage_touch`, `query_hit`, e as varreduras em lotes) também testa o círculo do chefe e repassa o dano.
  - **Origem do dano:** `Miracle.dmg()` marca `DamageSource.current = (word.id, cast_id)` antes de cada golpe; o `PlayerProjectileManager` marca `(&"auto", 0)`. O chefe lê essa marca ao receber.
  - **Varreduras de tela** (MORTIS, DOMINUS, MISERERE, PURGO, REQUIEM): o chefe recebe **uma vez por conjuração** (dedupe por `cast_id`).
  - O chefe ignora lentidão, cegueira e empurrão; stun só do DOMINUS, reduzido a 1 s.
- **Rasura:** o chefe pede ao `LetterField` para apagar a última letra do atril (`atril.pop_last()`), respeitando as proteções (VALID, letra recente, vazio).
- **Fluxo (main):** a loja da onda 9 fecha → `BossArena` começa: inimigos restantes se dissolvem, o chefe entra; `boss_defeated` → `chapter_completed`; morte do escriba → Game Over existente.
- **Câmera e shake:** `Camera2D` na cena principal com `ScreenShake` (componente) que escuta `shake_requested(strength, duration)`; `GameState.shake_enabled`.
- **HUD:** `boss_bar.gd` (nome, vida, marcas das fases), só durante a luta, fora da área central.
- **Arte:** placeholder de Asmodeus 64×64 gerado por script (ficha 16: rasura viva, olho BLOOD) com as animações mínimas (idle, telegrafia, ataque, dano, morte).

## Ajustes do mechanics-agent (2026-09-29)

- **Contrato do alvo:** `EnemyManager.boss_target` (`center`, `radius`, `take(amount, tag, cast_id)`, `stun(seconds)`), testado uma vez por chamada; `query_nearest` e `query_hit` testam o chefe **antes** do retorno antecipado com `count == 0`; `damage_touch` usa um `boss_touch_ready` próprio. `slow`, `blind` e o stun do PAX não afetam o chefe.
- **Origem:** `Miracle.cast_id` e `Miracle.tag`, preenchidos pelo `Caster._start_miracle` (contador; o eco do VERBUM é conjuração nova). `Miracle.begin_hit()` marca `DamageSource` no início de cada `_on_start`/`_physics_process`; o projétil marca `(&"auto", 0)` e limpa depois. Marca vazia no chefe = `push_warning`.
- **Varreduras:** `EnemyManager.hit_boss_sweep(amount)` no `_on_start` das 5 varreduras (só o dano; PURGO usa o valor de elite); DOMINUS chama `boss_target.stun(1.0)`. O dedupe fica só no teto por `cast_id` do filtro.
- **FSM:** estados como nós (`src/core/state_machine.gd`); executores pré-instanciados na entrada da arena; `AttackData.executor: Script`; `Stunned`/`PhaseShift` podem vir de qualquer estado (menos Dead/PhaseShift) e chamam `executor.cancel()`; `Exposed` = variante do `Recover`.
- **Rasura:** o chefe emite `atril_erase_requested()`; o `LetterField` aplica as proteções e emite `letter_erased(letter, pos)`.

## Arquivos

```
src/data/{boss_data,phase_data,attack_data,boss_damage_filter_data,letter_safety_tuning}.gd
src/bosses/{boss.gd,boss.tscn,attack_picker.gd,boss_damage_filter.gd,letter_safety.gd,damage_source.gd}
src/bosses/states/*.gd · src/bosses/attacks/{beam,swipe,summon,double_beam,rotating_cross,erasure}.gd
src/core/screen_shake.gd · src/ui/hud/boss_bar.gd
data/bosses/asmodeus.tres · asmodeus_phase_{1,2,3}.tres · attacks/*.tres · data/tuning/{boss_damage_filter,letter_safety}.tres
tools/gen_placeholders.gd (BSS_ASMODEUS) · tools/balance_probe.gd (modo boss)
tests/unit/test_attack_picker.gd · test_boss_damage_filter.gd · test_letter_safety.gd
tests/integration/test_boss_fight.gd
```

## Riscos

| Risco | Mitigação |
|---|---|
| Palavras não saberem ferir o chefe | alvo extra no EnemyManager + `DamageSource`; teste por palavra |
| Uma palavra grande apagar a luta | DamageFilter por conjuração e por fase (SC-603) |
| Chefe sem letras para montar palavras | LetterSafety + Summon (SC-604) |
| Frame caro no web | chefe é 1 nó; ataques desenham com `_draw`; stress `?stress=boss` (SC-607) |
