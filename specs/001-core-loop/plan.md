# 001 — Plan

## 1. Resumo técnico
Godot 4.7.2 com renderer Compatibility, 640×360 pixel-perfect e export web single-threaded. A lógica de palavras (Lexicon, Atril, LetterDropper) é pura (`RefCounted`) e testável sem cena. Os inimigos vivem em arrays dentro do EnemyManager e são desenhados via MultiMesh ou sprites pooled. Os sistemas conversam pelo EventBus.

## 2. Stack e configuração (T003–T006)

| Item | Valor |
|---|---|
| `display/window/size/viewport_width/height` | 640 × 360 |
| `window_width/height_override` | 1280 × 720 |
| `stretch/mode` · `aspect` · `scale_mode` | `canvas_items` · `keep` · `integer` |
| `rendering/textures/canvas_textures/default_texture_filter` | Nearest |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | true |
| Renderer | `gl_compatibility` (incluindo web) |
| Física 3D | não usada (remover a config do Jolt) |
| Input map | `move_up/down/left/right` (WASD + setas), `cast` (Espaço), `purge` (Shift), `word_list` (Tab), `pause` (Esc) |
| GUT | **9.7.1** (branch godot_4_7) em `addons/gut/` |
| Preset web | `Web`, **Thread Support desligado**, VRAM compression para desktop, saída em `build/web/` |
| CI | **Adiado** (D-021) |

## 3. Estrutura de pastas (T007)

```
addons/gut/
assets/
  sprites/{chr,enm,bss,ltr,prj,vfx,env,ui,itm}/
  placeholders/            # gerados por tools/gen_placeholders.gd
  fonts/
  shaders/                 # hit_flash.gdshader, dither_fade.gdshader, outline.gdshader
data/
  player/  words/  lexicon/  enemies/  waves/chapter_1/  tuning/
src/
  core/        # event_bus.gd, game_state.gd, palette.gd (gerado), pool_manager.gd,
               # spatial_hash.gd, state_machine.gd, state.gd, hitstop.gd
  data/        # os 7 Resources
  components/  # health.gd, hitbox.gd, hurtbox.gd, flash.gd
  player/      # player.tscn/.gd, states/, auto_attack.gd, ink_drop.tscn/.gd
  enemies/     # enemy_manager.gd, enemy_renderer.gd, spawn_telegraph.tscn
  waves/       # wave_director.gd
  letters/     # lexicon.gd, atril.gd, letter_dropper.gd, letter.tscn/.gd, magnet.gd
  miracles/    # miracle.gd (base), caster.gd, lux/, pax/, crux/, vita/, aqua/, ignis/, mortis/
  arena/       # arena.tscn/.gd, page_degradation.gd
  ui/hud/      # hud.tscn, candles.gd, atril_view.gd, hints.gd, word_list.gd, wave_timer.gd
  ui/minimal/  # pause_overlay.tscn, game_over_min.tscn
  main/        # main.tscn/.gd (monta arena, jogador, sistemas)
  debug/       # stress_scene.tscn/.gd, fps_probe.gd
tests/
  unit/        # test_spatial_hash, test_lexicon, test_atril, test_letter_dropper, test_word_power, test_pool_manager
  integration/ # test_wave_flow, test_cast_lux, test_zero_instantiate
tools/
  gen_palette.gd  gen_placeholders.gd
build/web/      # ignorado pelo git
```

## 4. Arquitetura

### 4.1 Autoloads (nesta ordem)
`EventBus` → `GameState` → `PoolManager` → `Hitstop`. `Palette` **não** é autoload: é uma `class_name` com constantes, gerada por `tools/gen_palette.gd`.

### 4.2 Cena principal
```
Main (Node2D)
├─ Arena (página, colisão da margem, SubViewport de decals)
├─ World (y-sort)
│  ├─ EnemyManager + EnemyRenderer
│  ├─ LetterLayer (letras pooled)
│  ├─ Player
│  └─ MiracleLayer / ProjectileLayer
├─ WaveDirector
├─ LetterDropper (nó que embrulha a lógica pura)
├─ Caster (liga Atril → Lexicon → milagre / heresia / purge)
└─ HUD (CanvasLayer)
```

### 4.3 EventBus: os 15 sinais

| # | Sinal | Parâmetros |
|---|---|---|
| 1 | `wave_started` | `index: int, duration: float` |
| 2 | `wave_ended` | `index: int` |
| 3 | `enemy_spawned` | `slot: int, data: EnemyData` |
| 4 | `enemy_killed` | `slot: int, data: EnemyData, position: Vector2` |
| 5 | `player_damaged` | `amount: int, candles: int` |
| 6 | `player_healed` | `amount: int, candles: int` |
| 7 | `player_died` | — |
| 8 | `letter_dropped` | `letter: String, rare: bool, target: bool, position: Vector2` |
| 9 | `letter_collected` | `letter: String, rare: bool` |
| 10 | `letter_rejected` | `letter: String` |
| 11 | `atril_changed` | `letters: PackedStringArray, state: int, hints: PackedStringArray, rare_mask: int` |
| 12 | `word_cast` | `word: WordData, power: float, origin: Vector2, direction: Vector2` |
| 13 | `heresy_committed` | `position: Vector2` |
| 14 | `atril_purged` | `letters: PackedStringArray, position: Vector2` |
| 15 | `hitstop_requested` | `duration_ms: int` |

Sinais acrescentados pela 005: `champion_killed`, `letter_eaten`, `gold_ink_collected`, `chapter_completed` (005 data-model §8).

### 4.4 StateMachine
`StateMachine` (Node) com `State` (Node): `enter(msg: Dictionary)`, `exit()`, `update(dt)`, `physics_update(dt)` e sinal `transition_requested(to: StringName, msg)`. O jogador tem os estados `Idle`, `Run`, `Stunned`, `Hurt` (i-frames paralelos via timer) e `Dead`.

### 4.5 PoolManager
`register(key: StringName, scene: PackedScene, prewarm: int)`, `acquire(key) -> Node`, `release(node)`. Contador `instantiate_count` exposto e com `assert` durante a onda (SC-002). Os nós liberados ficam desativados (process off, invisíveis), nunca são removidos da árvore.

### 4.6 SpatialHash
Grade de células de 32px, com chave `Vector2i` → `PackedInt32Array` de slots. `clear()`, `insert(slot, pos)`, `query_radius(pos, r) -> PackedInt32Array`. É reconstruído a cada frame pelo EnemyManager (custo O(n)).

### 4.7 Jogador
`CharacterBody2D` (é único). A velocidade vem do `PlayerData`. O `AutoAttack` é um timer que pede ao EnemyManager o `nearest(pos, range)` e dispara um `InkDrop` do pool. Os componentes `Hurtbox`, `Health` (velas) e `Flash` (shader de hit flash) são compostos na cena. A regeneração parado é um contador no jogador (FR-004).

### 4.8 Inimigos
- **O EnemyManager guarda arrays paralelos** (`PackedVector2Array` de posição e velocidade, `PackedInt32Array` de HP e estado, `Array[EnemyData]`) com capacidade fixa (ex.: 400).
- Um único `_physics_process`: steering até o jogador (ou até a poça de aggro, se houver) + separação via SpatialHash + clamp na área jogável + teste de contato com o raio do jogador.
- Dano recebido: `damage_at(slot, amount)` e `damage_in_radius/line/…`. Os milagres consultam o SpatialHash, nunca iteram todos.
- **Render:** `EnemyRenderer` com um `MultiMeshInstance2D` por tipo de inimigo. O frame da animação é passado por `INSTANCE_CUSTOM` e o shader escolhe a região do atlas. Se a medição mostrar que Sprite2D pooled é suficiente, fica o mais simples (T082 é condicional).
- Morte: libera o slot e pede a dissolução (VFX pooled) e o decal.

### 4.9 Letras, Atril e Lexicon
- `Lexicon` (RefCounted): `load(data)` valida (FR-014); `is_word(s)`, `is_prefix(s, max_len)`, `words_with_prefix(s, max_len, limit)` usando uma trie construída no load.
- `Atril` (RefCounted): `push(letter, rare) -> bool` (false = recusada), `clear()`, `take_all()`, `state(lexicon)`.
- `LetterDropper` (RefCounted): `roll(atril, lexicon, tuning, rng, unlocked) -> {letter, rare, target}` (FR-013).
- `Letter` (Area2D leve, pooled): vida, pisca-pisca, trava de coleta, tween do ímã.

### 4.10 Milagres
`Caster` escuta `cast`/`purge`. VALID → `word_cast` + hitstop 60ms + `PoolManager.acquire(word.miracle_scene)`. A classe base `Miracle` tem `start(word, power, origin, dir)` e `finish()` (volta ao pool). Cada palavra estende `Miracle` e lê **só** os campos do `WordData`, multiplicados por `power`.

### 4.11 HUD
CanvasLayer em 640×360, com os elementos fora do retângulo seguro (X160–480, Y60–300): velas no canto superior esquerdo, timer e onda no topo central (Y < 60), atril e dicas na base (Y > 300). Tudo reage a sinais do EventBus; nada consulta os sistemas diretamente.

### 4.12 Degradação da página
Um `SubViewport` (`render_target_clear_mode = NEVER`) desenha decals uma única vez e é exibido como textura sob o World. O estágio da onda troca a camada de desgaste de fundo.

## 5. Testes (GUT)

| Arquivo | Cobre |
|---|---|
| `test_spatial_hash` | 1000 pontos aleatórios; `query_radius` bate com força bruta |
| `test_lexicon` | load válido; falha com 2, 9 letras, letra fora do alfabeto, duplicata; prefixos; `words_with_prefix` respeita `max_len` |
| `test_atril` | ordem; recusa quando cheio; estados FILL/PARTIAL/VALID/FULL_REJECT; `take_all` |
| `test_letter_dropper` | seed fixa, 10 mil sorteios: alvo ≥ 40% com prefixo parcial; nunca mira palavra > capacidade; B nunca cai sem VERBUM; rare só em vogais |
| `test_word_power` | `power_budget` cresce com o tamanho em todo o LexiconData |
| `test_pool_manager` | acquire/release sem instanciar depois do prewarm |
| `test_wave_flow` (integração) | a onda começa, faz spawn, termina em 60s simulados, emite `wave_ended` |
| `test_cast_lux` (integração) | coletar L, U, X → VALID → Espaço → `word_cast(LUX)` e inimigos na linha perdem HP |
| `test_zero_instantiate` (integração) | onda simulada com 300 inimigos: `instantiate_count` não muda |

## 6. Export web
Preset `Web`: single-threaded, `html/canvas_resize_policy` adaptativo, fundo INK. O export roda no fim de cada fase pelo comando do `CLAUDE.md`, e o tamanho do `.pck` + `.wasm` vai para o relatório.

## 7. Riscos

| Risco | Mitigação |
|---|---|
| MultiMesh + atlas animado ficar complexo | Começar com Sprite2D pooled e medir; só migrar se o SC-001 falhar (T082) |
| Colisão do jogador com 300 inimigos | Teste de contato por distância dentro do EnemyManager, sem Area2D por inimigo |
| Milagre "de tela" (MORTIS) travar | Aplicar em lotes de 50 por frame (mesmo padrão previsto para o PURGO, SC-202) |
| Sprites reais faltando | `gen_placeholders.gd` gera PNGs nas dimensões do catálogo, com cores da paleta |
