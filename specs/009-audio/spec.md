# 009 — Áudio

> Status: **Aprovada** (2026-09-28, "1a, 2a"; D-053). Fase 1 ✅ (Checkpoint 009-A). Próxima: Fase 2 (sons provisórios por script).
> Depende de: 001 (Complete). Game bible §5 [PENDENTE]. Decisões D-047 (5: arquitetura agora, sem sons; sons provisórios por script nesta feature). PROMPTS D4.
> Os arquivos de áudio reais são do autor e chegam depois; até lá tudo toca em silêncio.

## Objetivo

Deixar o jogo **pronto para receber som**: todo evento que deveria soar já passa por um sistema de áudio, com limite de vozes, anti-spam e música em camadas. Trocar o silêncio por um som vira **só trocar um arquivo** num `.tres` (SC-G4). Depois da arquitetura, uma fase gera sons provisórios por script.

## Fora do escopo

| Item | Feature |
|---|---|
| Arquivos de áudio finais (SFX e trilhas) | autor |
| Tela de Opções com os volumes | 007 (aqui só a API de volume) |
| Música e sons específicos de cada chefe | 006, 012–015 (usam esta arquitetura) |
| Sons de menu, loja e cutscene | 007, 003, 008 (idem) |
| Dublagem | fora do jogo (nenhuma fala é gravada) |

## Histórias de usuário

- **US-1 (P1):** como autor, troco o silêncio de um evento por um som só apontando o arquivo no `.tres`, sem mexer em código.
- **US-2 (P1):** como jogador, 300 inimigos morrendo de uma vez não viram um estouro de ruído nem derrubam o FPS.
- **US-3 (P1):** como jogador web, o jogo não dá erro nem toca nada antes do meu primeiro clique ou tecla; depois disso o som funciona.
- **US-4 (P2):** como jogador, a música ganha camadas quando a onda aperta, sem cortar nem sair do tempo.
- **US-5 (P1):** como autor, recebo a lista do que falta gravar, gerada a partir dos dados.

## Requisitos funcionais

### Barramentos e volume
- **FR-901** Quatro barramentos: `Master` → `Music`, `SFX`, `UI`. O `AudioManager` expõe `set_bus_volume(bus, linear)` e `get_bus_volume(bus)` (0–1); a tela de Opções (007) usa isso.

### Sons
- **FR-902** Cada som é um `SoundData` (`data/audio/sfx/<id>.tres`): `stream` (vazio = silêncio), barramento, volume, variação de pitch, `max_voices`, `cooldown_ms` e `priority`. Um som sem `stream` passa por todo o caminho (voz, anti-spam, contagem), só não emite nada.
- **FR-903** O `AudioManager` (autoload) toca por id: `play(id)`. Tem um **pool fixo de vozes** criado no início (nenhum nó criado durante a onda, SC-002). Regras, nesta ordem: (1) dentro do `cooldown_ms` do mesmo som, ignora; (2) com `max_voices` do som ocupadas, rouba a voz mais antiga **desse som**; (3) com o pool cheio, rouba a voz mais antiga de **prioridade menor ou igual**; se não houver, ignora.
- **FR-904** Sons não obedecem ao `time_scale` (o hit-stop não distorce o áudio). Com o jogo pausado, `SFX` pausa e `UI` continua.

### Eventos
- **FR-905** Um `AudioEventMap` (`data/audio/event_map.tres`) liga sinais do EventBus a sons. A chave pode ter variante: `word_cast:lux`, `combo_cast:flamma`, `enemy_killed:imp`, `letter_collected:rare`; se a variante não existir no mapa, vale a chave base (`word_cast`). Nenhum sistema de jogo chama o áudio direto: o `AudioManager` escuta o EventBus.
- **FR-906** Eventos cobertos agora: ondas (início, fim), inimigo (morte por tipo, campeão), jogador (dano, cura, morte), letras (queda comum e rara, coleta comum e rara, recusa, comida pela Traça, tinta dourada), atril (ficou VALID), conjuração (cada palavra, cada combo, heresia, purge, janela de combo aberta), capítulo concluído.
- **FR-907** Cutscenes e animações (008 e chefes) tocam som por id numa trilha de método do `AnimationPlayer` chamando `AudioManager.play(id)`.

### Música
- **FR-908** Cada música é um `MusicData` (`data/audio/music/<id>.tres`): `layers` (streams do mesmo tamanho e BPM) e `bpm`. O `MusicDirector` toca todas as camadas **juntas e em sincronia** e liga ou desliga cada camada por volume, com rampa de `fade_ms`. Sem streams, fica em silêncio sem erro.
- **FR-909** Intensidade (0 = só a base … N = todas as camadas): a onda define a intensidade pela fração dela no capítulo; a morte do jogador baixa para a base. Os limiares ficam no `.tres`.

### Web
- **FR-910** No web, nada toca antes do primeiro input do jogador (política dos navegadores). O `AudioManager` só começa a tocar depois do primeiro evento de tecla, clique ou toque; o que for pedido antes é descartado sem erro no console.

### Ferramentas
- **FR-911** `tools/audio_report.gd` lista todo `SoundData` e `MusicData` sem `stream`, com o evento que o usa, e escreve `docs/AUDIO-LIST.md` (o que falta gravar).
- **FR-912** **[Fase 2]** `tools/gen_placeholder_sfx.gd` gera sons provisórios curtos por script (ondas simples, `AudioStreamWAV`) para os eventos principais, em `assets/audio/placeholders/`, até os arquivos do autor chegarem.

## Critérios de sucesso

- **SC-901** Trocar o silêncio por um som é editar só o `.tres` (teste: um `SoundData` com stream toca pelo evento, sem código novo).
- **SC-902** MORTIS matando 300 inimigos toca no máximo `max_voices` vozes do som de morte, e o pool nunca passa do tamanho fixo (teste).
- **SC-903** Zero `instantiate` durante a onda com o áudio ligado (o teste do SC-002 continua passando).
- **SC-904** Build web: nenhum erro de áudio no console antes nem depois do primeiro input (medição no Chrome e no Firefox).
- **SC-905** `docs/AUDIO-LIST.md` lista todos os eventos da FR-906 enquanto não houver arquivos.
- **SC-906** O SC-001 no Chrome não piora com o áudio ligado.
