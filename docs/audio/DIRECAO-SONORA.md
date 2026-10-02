# Direção sonora — Scribe of the Damned

> Documento do audio-agent (pipeline team_audio em 4 papéis: direção → sound design → técnica → integração).
> Fontes: `narrative.md` §5 e §8 (tom), `docs/voice/VOICE-LINES.md`, `docs/audio/sfx_manifest.json`, `data/audio/`, `src/audio/`.
> Não decide números de jogo; volumes e prioridades seguem o `event_map` e a D-069 (pool 24+4, cooldowns).

---

## 1. Direção (audio-director)

### 1.1 Identidade em uma frase
**Um scriptorium de 1348 ouvido de dentro do livro:** pena, pergaminho, cera, sinos e pedra são o mundo físico; órgão e canto gregoriano são o sagrado; o que é demoníaco soa como **erro de escrita** (raspar, rasurar, borrar, coro desafinado), nunca como monstro de filme.

### 1.2 Pilares sonoros
1. **Horror doméstico** (narrativa §8): o perigo soa como papel, tinta, traça, cera e sino. Nada de vísceras, nada de grito humano.
2. **A Palavra é coro.** Toda conjuração tem um corpo coral ou de órgão (sagrado), com um elemento concreto do efeito por cima (luz, água, fogo, madeira).
3. **O erro é dissonância.** Heresia, Rasura e o chefe usam o mesmo material sagrado **desafinado ou raspado**; o jogador aprende que "som torto = errei".
4. **Silêncio de igreja.** Reverb de pedra longa só nos momentos grandes (fim de onda, capítulo, chefe). No combate, efeitos secos e curtos, para não embolar com 300 mortes.
5. **Fé com respeito.** Nada de paródia de liturgia, nada de letra de canto real; o coro canta vogais ("ah", "oh", "u") sem texto.

### 1.3 Paleta

| Família | Material | Onde |
|---|---|---|
| Escrita | pena riscando, ponta da pena batendo, pergaminho grosso virando, raspar de rasura | coleta, menu da letra, UI, Rasura |
| Tinta | gota, borrão, espirro molhado, poça borbulhando | mortes, inimigos, Borrão, projéteis |
| Cera e vela | sopro apagando, fósforo, chama, pingo de cera | vida (velas), Graça, poções |
| Metal sagrado | sino de mosteiro, sininho de mão, moedas pequenas, sino rachado | onda, ouro, campeão, bênção |
| Madeira e pedra | baque de madeira, estaca cravada, pedra rachando, porta rangendo | CRUX, Crucifixo, Gárgula, loja |
| Sagrado | órgão (nota sustentada, acorde), coro masculino em vogais, sopro em igreja | conjurações, atril, música |
| Profano | coro desafinado, raspar grave, rosnado de pedra, papel rasgando | heresia, chefe, degradação da página |

**Proibido:** sintetizador "sci-fi" óbvio, guitarra, bateria moderna, voz falando palavras nos efeitos (só coro em vogais quando pedido), qualquer melodia reconhecível, marca, letra de música real, voz que imite pessoa real.

### 1.4 Prioridades de mix (do mais alto ao mais baixo)

| # | Categoria | Barramento hoje | Alvo de pico | Regra |
|---|---|---|---|---|
| 1 | Falas (cutscene e frases na partida) | SFX (`_line_player`) | −6 dBFS | Abafa a música em −8 dB enquanto toca (ver §4.3, pedido ao code-agent: barramento `Voice`). |
| 2 | Retorno do jogador (dano, vela, coleta, conjuração) | SFX | −6 a −3 dBFS | Nunca roubado pelo pool: `priority` alta no `.tres`. |
| 3 | Chefe (telegrafia e ataque) | SFX | −6 dBFS | A telegrafia precisa ser ouvida por cima de qualquer coisa (é aviso de jogo). |
| 4 | Inimigos e mortes | SFX | −12 dBFS | Cooldown 50 ms e no máximo 3 vozes (D-069); curto (< 0,25 s no genérico). |
| 5 | UI e menu | UI | −12 dBFS | Seco, curto, sem reverb longo. |
| 6 | Música | Music | −14 dBFS | Abafada por fala e por conjuração grande (MORTIS, MISERERE, REQUIEM). |
| 7 | Ambiente | Music (hoje) | −20 dBFS | Primeiro a sumir. |

Todos os arquivos gerados são normalizados no pico (−3 dBFS efeitos, −1 dBFS falas); o volume final se acerta no `volume_db` do `.tres`, não no arquivo.

### 1.5 Música adaptativa

**Capítulo 1 — Mosteiro de São Wendelino (1348):** 3 camadas **verticais** no mesmo andamento e no mesmo tom, começando juntas, todas em loop do mesmo comprimento. O `MusicDirector` já sobe/desce as camadas pela intensidade da onda (`intensity_thresholds` 0 / 0,34 / 0,67; rampa 700 ms em tempo real; 400 ms na morte).

| Camada | Entra em | Conteúdo | Notas |
|---|---|---|---|
| 1 Base | sempre | órgão de tubos grave em acordes longos + drone de pedal (ré), respiração de igreja | Ré dórico. Nada de melodia; o "chão" do capítulo. |
| 2 Canto | intensidade ≥ 0,34 | coro masculino em uníssono, estilo cantochão, **só vogais**, frases longas que respiram a cada 2 compassos | Não é texto litúrgico real. |
| 3 Tensão | intensidade ≥ 0,67 | tambor grave de pele (tipo tímpano medieval) no 1 e no 3, cordas graves em ostinato tenso, sino distante a cada 4 compassos | Tira a sensação de "paz"; é a onda apertando. |

- **Andamento:** 64 BPM, 4/4, **16 compassos = 60,0 s** por loop (as três camadas com exatamente o mesmo número de amostras). O `chapter_1.tres` precisa de `bpm = 64` quando as camadas chegarem.
- **Formato:** OGG Vorbis 44,1 kHz estéreo, loop ligado no import, sem silêncio no começo nem no fim.
- **Estado (2026-10-01):** a API de música do ElevenLabs é **só para plano pago** (402 `paid_plan_required`). A camada 1 provisória foi feita pela API de efeitos em modo loop: `assets/audio/music/chapter_1_layer_1_base.wav` (órgão + drone em ré, **29,75 s**, pico −14 dBFS, loop no import). **Não foi ligada** no `chapter_1.tres` (sem as camadas 2 e 3 e sem ouvir no jogo); para ligar: `layers = [esse arquivo]`. As camadas 2 e 3 precisam ter **o mesmo comprimento em amostras** da base (ou refazer as três juntas num plano pago, 60 s a 64 BPM).
- **Prompts das camadas (para o plano pago ou um compositor):** (1) "Instrumental loop, 64 BPM, 4/4, D dorian. Slow medieval church pipe organ, long sustained low chords over a deep pedal drone on D, dark stone abbey reverb, no melody, no percussion, no vocals." (2) "Same tempo and key. Male choir in unison, plainchant style, wordless vowels only, long phrases breathing every two bars, abbey reverb, no instruments." (3) "Same tempo and key. Deep medieval frame drum on beats 1 and 3, low strings in a tense ostinato, distant church bell every four bars, no vocals."
- **Transições:** fim de onda → a camada 3 sai em 700 ms, a 2 fica até a próxima onda; morte → tudo em 400 ms e o `player_died` assume.
- **Chefe (Asmodeus):** troca **horizontal** (outra faixa, não uma camada): fase 1 = base do capítulo com o coro **desafinado** um quarto de tom; fase 2 = entra percussão e raspar rítmico (pena riscando no tempo); fase 3 = tudo + órgão em cluster dissonante. A troca de fase acontece no próximo compasso (fila por batida, 64 BPM = 0,94 s), com o `boss_phase_changed` por cima como stinger.
- **Loja / Grimório / Menu:** só a camada 1 em −6 dB (sem combate).
- **Stingers:** `wave_started` (sino), `wave_ended` (acorde que resolve), `chapter_completed` (coro), `player_died` (velas) já estão no manifesto; tocam por cima da música, sem cortar.

### 1.6 Vozes (direção por personagem)

Vozes **prontas (premade)** do ElevenLabs, as mesmas nos dois idiomas, modelo `eleven_multilingual_v2` (o plano gratuito não usa vozes da biblioteca pela API: testei a "Leo Antonio" pt-BR e a API recusou). Nenhuma imita pessoa real.

| Personagem | Voz (voice_id) | Ajustes | Por quê |
|---|---|---|---|
| Irmão Anselmo | **Chris** `iP95p4xoKVk53GoZ742B` | estabilidade 0,40 · semelhança 0,75 · estilo 0,15 · velocidade 0,95 | Homem de meia-idade, "pé no chão": contido, sem tom heroico; a estabilidade baixa dá o medo. |
| Abade Gerbrand (fantasma) | **Bill** `pqHfZKP75CvOlQylNhV4` | estab. 0,55 · sem. 0,75 · estilo 0,25 · vel. 0,90 | Única voz premade "old/wise": gentil e paternal. O "etéreo" vem do motor (reverb no barramento de voz, §3.3). |
| Abade Caído | **Bill** (mesma voz) | estab. 0,35 · sem. 0,80 · estilo 0,35 · vel. 0,80 | A mesma voz, mais lenta e instável: cansada e culpada. |
| Frei Ambrósio, o Alfarrabista (vendedor, D-098) | **George** `JBFqnCBsd6RMkjVDRZzb` | estab. 0,30 · sem. 0,75 · estilo 0,40 · vel. 0,85 | O Bill já é o Abade; o George instável e lento soa seco e cansado de arquivista. |
| Irmã Hildegarda (010) | **Camille Martin** `hFgOzpmS0CMtL2to8sAl` | estab. 0,60 · estilo 0,15 · vel. 0,90 | Madura, grave e calma (ficha). |
| Frei Tomé (010) | **Brian** `nPczCjzI2devNBz1zQrb` | estab. 0,55 · estilo 0,05 · vel. 0,88 | Grave e deadpan. |
| O Iluminador (010) | **Adolpho Azevedo** `GPrWfMLdMqObUgameh5J` | estab. 0,35 · estilo 0,45 · vel. 0,95 | Teatral; português nativo. |
| Noviço Beda (010) | **Liam** `TX3LPaxmHKxFdv7VOQHJ` | estab. 0,30 · estilo 0,30 · vel. 1,08 | Jovem e atropelado. |
| Asmodeus, o Rasurador | **Callum** `N2lVS1w4EtoT3dr4eOWO` | estab. 0,30 · sem. 0,70 · estilo 0,55 · vel. 0,78 | Rouca e arranhada; lenta. A palavra em maiúsculas (APAGO/ERASE) vem forte. |
| Narrador | **Daniel** `onwK4e9ZLuTAKqWW03F9` | estab. 0,70 · sem. 0,75 · estilo 0,05 · vel. 0,92 | Locutor formal e firme: lê a crônica sem drama. |
| Padre Malaquias | **Eric** `cjVigY5qzO86Huf0OWal` | estab. 0,65 · sem. 0,75 · estilo 0,30 · vel. 0,85 | Macia e confiável demais; a lentidão a deixa ameaçadora. |
| O vazio (HÆRESIS!) | — | — | Latim: ver §1.7. |

### 1.7 Latim
A regra do audio-agent diz que **o latim das palavras não é falado** (o jogador lê). A D-072 (008, FR-816) previa uma voz do latim em `assets/audio/voice/latin/`. **Conflito aberto para o autor:** nada de latim foi gerado; se o autor confirmar a D-072, são 24 arquivos curtos (~200 créditos), com a voz do Anselmo (estab. 0,80, "firme e clara").

---

## 2. Sound design (sound-designer)

### 2.1 Categorias e eventos
O inventário completo está em `docs/audio/sfx_manifest.json` (145 itens). Campos: `id`, `event` (`evento` ou `evento:variante`), `exists_in_event_map`, `file`, `duration_s`, `loop`, `prompt_en`, `desc_pt`, `priority` (**prioridade de produção**: 1 = fazer primeiro; não é a prioridade de mix do `.tres`). Campo adicionado por esta passada: `generated` (true quando o arquivo existe em `file`). Item novo: `letter_menu_open_rare` (`letter_menu_opened:rare`); `letter_menu_lost` passou a usar o evento que existe no código (`letter_lost`).

**Cortes por mixagem:** os efeitos frequentes de prioridade de mix 1 (mortes de inimigo, coleta, coleta rara, ouro, recusa, ampulheta do combo) foram cortados para **0,24 s** com fade de 40 ms (regra: prioridade 1 < 0,25 s); o `duration_s` do manifesto foi atualizado.

### 2.2 Regras dos prompts (`prompt_en`)
- Descrever **material + ação + cauda** ("thick ink drop splashing on parchment with a wet slap").
- Dizer "no music", "no voice/no words" quando houver risco; coro sempre "wordless vowels".
- Duração curta pedida no próprio texto quando < 0,5 s ("under 0.3 seconds").
- Nunca citar obra, marca, artista ou jogo.

### 2.3 Parâmetros por categoria

| Categoria | Duração | Variação de pitch (`pitch_jitter`) | Vozes / cooldown | Reverb |
|---|---|---|---|---|
| Mortes de inimigo | 0,25–0,9 s | ±0,08 | 3 / 50 ms | seco |
| Coleta, ouro, Graça | 0,25–0,5 s | ±0,10 | 4 / 30 ms | seco |
| Armas (disparo/acerto) | 0,2–0,6 s | ±0,06 | 3 / 40 ms | seco |
| Conjurações | 0,8–2,5 s | ±0,02 | 1 / 0 | igreja (no arquivo) |
| Chefe | 0,3–4 s | ±0,03 | 2 / 0 | igreja |
| UI | 0,15–0,6 s | 0 | 2 / 30 ms | seco |
| Stingers (onda, capítulo, morte) | 1,5–4 s | 0 | 1 / 0 | igreja longa |

### 2.4 Ducking
- Fala tocando → Música −8 dB (ataque 50 ms, soltura 400 ms).
- Conjuração grande (MORTIS, MISERERE, REQUIEM, MARTYRIUM) → Música −4 dB durante o som.
- Menu da letra (câmera lenta) → Música com passa-baixa 1,2 kHz enquanto aberto (o tempo "afunda").

---

## 3. Técnica (technical-artist)

### 3.1 Formatos e pastas

| Tipo | Formato | Pasta | Import |
|---|---|---|---|
| Efeitos | **WAV 16-bit 44,1 kHz estéreo** (pedido ao ElevenLabs em PCM, cortado e com fade na hora) | `assets/audio/sfx/<id>.wav` | padrão do Godot (compressão QOA); loop: `edit/loop_mode=2` |
| Falas | MP3 44,1 kHz 128 kbps | `assets/audio/voice/<pt_BR|en>/<id>.mp3` | AudioStreamMP3, sem loop |
| Música | OGG Vorbis (ou MP3 da API se não houver conversor) | `assets/audio/music/` | loop ligado |

**Por que WAV nos efeitos e não MP3:** o MP3 tem atraso de decodificação e preenchimento do codificador (~25–50 ms de silêncio), ruim para um efeito de 0,25 s, e não fecha loop sem buraco. A API do ElevenLabs só gera a partir de 0,5 s; com PCM o script corta exatamente no `duration_s` do manifesto, aplica fade-out de 15 ms (sem clique) e cruza o fim com o começo nos loops.

### 3.2 Orçamento
Download web atual 11,2 MB (meta 25, D-069). Efeitos em QOA ≈ 1/4 do WAV: ~145 efeitos × ~1 s ≈ 6 MB. Falas MP3 ≈ 1,5 MB. Música 3 camadas × 60 s em OGG 96 kbps ≈ 2,2 MB. Cabe na meta.

### 3.3 Barramentos ✅ (D-097)
Hoje: Master → Music, SFX, UI. Proposta: adicionar **`Voice`** (falas e latim, com `AudioEffectReverb` leve só no Abade — sala 0,35, wet 0,15) e o ducking de §2.4 via `AudioEffectCompressor` com sidechain `Voice` no barramento Music.

### 3.4 Geração (reproduzível)
Scripts fora do repositório (a chave nunca entra no repo). Parâmetros: efeitos `prompt_influence = 0,5`, `duration_seconds = max(0,5, duration_s)`; falas `eleven_multilingual_v2`, `language_code` `pt`/`en`, ajustes da §1.6.

---

## 4. Integração (gameplay-programmer)

### 4.1 Já ligado nesta passada
Cada efeito gerado cujo evento já existe no `event_map` foi posto como `stream` do `data/audio/sfx/<id>.tres` (troca do provisório `assets/audio/placeholders/sfx_*.tres` pelo `assets/audio/sfx/<id>.wav`). As falas tocam sozinhas: o `AudioManager.voice_path()` procura `assets/audio/voice/<locale>/<id>.mp3`.

### 4.2 Sinais que faltavam ✅ (D-097)
**Feito:** os 101 efeitos estão ligados.
- O `tools/gen_audio_data.gd` lê este manifesto e grava um `data/audio/sfx/<id>.tres` para cada efeito sem `.tres`, com vozes, recarga, barramento e variação de tom pela categoria da §2.3.
- O `AudioManager._connect_events_018()` liga os sinais que já existiam e o bloco "Áudio" do `EventBus`: `weapon_fired`/`weapon_hit`/`weapon_windup_started`/`weapon_beam_toggled`, `boss_attack_telegraphed`/`started`/`finished`, `boss_stunned`, `enemy_spawn_telegraphed`, `enemy_telegraphed`/`enemy_attacked`, `enemy_projectile_hit`, `hazard_entered`, `letter_menu_cursor_moved`, `shop_purchase_denied`, `shop_lock_toggled` e `ui_focus_changed`/`ui_confirmed`/`ui_backed`/`ui_slider_changed`/`ui_key_remapped`.
- Loops com início e fim: `AudioManager.start_loop`/`stop_loop` para o raio da Bíblia, o aviso da rasura, a cruz giratória e a contagem do menu da letra.
- Barramento `Voice` com compressor na Music (sidechain = Voice): é o ducking da §2.4.
- Poções por id: Óleo → `potion_1_healing`, Água Benta → `potion_4_shield`, Vinho → `potion_3_speed`, Iluminura → `potion_2_ink`.
- Arma ou inimigo sem som próprio fica mudo, sem cair no som base (Rosário, Turíbulo, Aspersório no disparo).

- Opções: linha **FALAS** (volume do barramento `Voice`, salvo como os outros).
- Menu da letra: passa-baixa de 1,2 kHz na Music enquanto aberto (`AudioManager.set_music_muffled`; §2.4).

**Não ligado:** `weapon_ready` (opcional; tocaria o tempo todo).

Lista original:
Itens do manifesto com `exists_in_event_map = false`: o arquivo já existe (quando gerado) mas não há `.tres` nem sinal. Agrupados:

- **Armas (017):** `weapon_fired(weapon_id)`, `weapon_hit(weapon_id)`, `weapon_loop(weapon_id)` (início/fim do raio da Bíblia), `weapon_charge(weapon_id)`, `weapon_switched`, `weapon_equipped`, `weapon_leveled`, `weapon_cooldown_ready`.
- **Palavras novas:** variantes `word_cast:purgo|miserere|fides|lumen|verbum|gloria|sanctus|dominus|angelus|spiritus|salvator` (só criar os `.tres`; o sinal `word_cast` já existe).
- **Menu da letra (D-090):** `letter_menu_cursor`, `letter_chosen`, `letter_menu_expired`, `letter_menu_countdown` (loop).
- **Graça (016) e nível (018):** `grace_gained`, `wax_drop_collected`, `grace_leveled`, `seals_shown`, `seals_hidden`, `blessing_chosen[:id]`.
- **Poções (018):** `potion_drunk[:1..4]`, `potion_denied`.
- **Chefe:** `boss_spawned`, `boss_telegraph:<ataque>`, `boss_attack:<ataque>`, `boss_damaged`, `boss_exposed`, `boss_stunned`, `boss_phase_changed`, `boss_defeated`, `boss_letters_burst`, `erasure_warned` (loop), `letter_erased`, `atril_erase_requested`.
- **Inimigos:** `enemy_spawned`, `enemy_spawn_telegraph`, `enemy_telegraph:gargoyle`, `enemy_attack:<tipo>`, `enemy_projectile_hit`, `hazard_damage`, `champion_spawned`, `shield_broken`, `magnet_reverse_push`.
- **Loja e UI:** `shop_opened`, `shop_closed`, `item_bought`, `shop_purchase_denied`, `shop_rerolled`, `shop_lock_toggled`, `gold_ink_spent`, `ui_focus_changed`, `ui_confirm`, `ui_back`, `ui_slider_changed`, `ui_key_remapped`, `pause_menu_toggled:open|close`, `screen_changed:options`, `codex_discovered`, `word_unlocked`, `game_restart_requested`, `cutscene_skipped`.
- **Página e ritmo:** `page_stage_changed`, `page_degraded`, `wave_closing`, `combo_window_closed`, `heresy_forgiven`, `heresy_absolved`, `verbum_echoed`, `verbum_failed`.

Para cada um: criar o `data/audio/sfx/<id>.tres` (via `tools/gen_audio_data.gd`), apontar o `stream` para o arquivo e conectar o sinal no `AudioManager._connect_events()`. Os loops precisam de `stop` explícito no fim do estado.

### 4.3 Testes
`tests/unit/test_audio_*`: cada `.tres` com `stream` não nulo carrega; nenhum efeito de `priority` 1 no `.tres` passa de 0,25 s; loops têm `loop_mode` ligado.
