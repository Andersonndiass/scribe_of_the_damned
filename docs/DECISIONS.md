# Log de decisões

Formato: data · decisão · motivo · alternativas descartadas · status.

---

### D-001 · 2026-09-24 · Godot 4.7.2 em vez de 4.3
- **Decisão:** o projeto usa Godot 4.7.2 stable (build padrão). As menções a 4.3 em BOOTSTRAP, PLANO e PROMPTS foram trocadas.
- **Motivo:** pedido do autor ("estou usando a godot 4.7"); é a versão instalada em `D:\Godot`.
- **Descartado:** voltar para 4.3.
- **Status:** ✅ aprovada.

### D-002 · 2026-09-24 · Constituição e game bible escritas pelo Claude
- **Decisão:** como as specs originais não existem, o Claude escreveu a constituição, a game bible, o art bible e os design tokens a partir dos documentos de planejamento e das fichas.
- **Status:** ✅ aprovada pelo autor no Checkpoint 0 ("pode seguir, aprovado").

### D-003 · 2026-09-24 · Numeração dos princípios casada com o PROMPTS.md
- **Decisão:** Princípio IV = conteúdo é dado; Princípio IX = cutscenes in-engine.
- **Status:** ✅ aprovada.

### D-004 · 2026-09-24 · Hex da paleta provisórios (substituída pela D-048)
- **Decisão:** `design-tokens.json` usa hex escolhidos pelo Claude até o `colors.css` do design system chegar.
- **Como reverter:** trocar os valores e rodar `tools/gen_palette.gd`.
- **Status:** ⏳ provisória.

### D-005 · 2026-09-24 · Art bible organizada pelas referências das fichas
- **Status:** ✅ aprovada.

---

## Checkpoint 0: respostas do autor (2026-09-24)

### D-006 · Palavras de 3 a 8 letras (emenda ao Princípio VIII)
- **Decisão:** o limite de letras por palavra sobe de 6 para **8**. Quanto mais longa a palavra, mais forte o milagre. Palavras de 7–8 letras são "muito fortes".
- **Motivo:** resposta 1a do autor. **Conflita com a constituição v1.0.0** (máx. 6); o conflito foi apontado e o autor é quem decide. A constituição sobe para v1.1.0.
- **Consequência:** a feature 002 ganha um grupo de palavras longas (proposta em `000/spec.md` §3.5).
- **Status:** ✅ aprovada.

### D-007 · Atril variável, padrão 5, máximo 8
- **Decisão:** o atril começa com **5** espaços e sobe por upgrades até **8**.
- **Consequência:** MORTIS (6 letras) exige pelo menos 1 upgrade de atril. O drop ponderado **nunca** mira palavras maiores que o atril atual.
- **Consequência:** a passiva original do Beda ("atril 5") deixou de ser diferencial. Nova proposta: atril **4** + 20% de velocidade (ver D-019).
- **Status:** ✅ aprovada (Beda: proposta).

### D-008 · Atril cheio recusa a letra
- **Decisão:** com o atril cheio e sem palavra válida, a letra nova é recusada e fica no chão (animação REJECT).
- **Status:** ✅ aprovada.

### D-009 · Sem reordenar; o purge devolve as letras ao chão
- **Decisão:** as letras entram na ordem em que foram coletadas e não podem ser reordenadas. O **purge (Shift)** joga as letras do atril **no chão**, em volta do jogador, para que ele tente de novo. As letras não são destruídas.
- **Consequência:** recoletar em outra ordem é a forma legítima de "reordenar".
- **Purge não custa nada** (resposta 4b) e não tem recarga.
- **Status:** ✅ aprovada.

### D-010 · Velas: 3 iniciais, máximo 8, i-frames de 1s
- **Decisão:** o jogador começa com 3 velas; upgrades aumentam até 8. Invulnerabilidade de 1s depois do dano (a ajustar em teste).
- **Status:** ✅ aprovada.

### D-011 · Recuperação de vela
- **Decisão:** a vela é recuperada por (a) **ficar 5s parado e sem atacar**, (b) upgrade, (c) matar um **inimigo raro (campeão)**, e (d) VITA.
- **Interpretação a confirmar:** o ataque automático nunca para, então "sem atacar" = **sem conjurar palavra e sem levar dano**. Enquanto parado, recupera 1 vela a cada 3s [valor inicial, rules-agent].
- **Status:** ✅ aprovada · ⏳ interpretação de "sem atacar" a confirmar.

### D-012 · Dano em velas por tipo de ataque
- **Decisão:** ataque **fraco** tira 1 vela, ataque **forte** tira 2. Cada ataque e cada inimigo declara o seu nível no `.tres`.
- **Status:** ✅ aprovada.

### D-013 · Efeitos das 7 palavras base, sem recarga, dicas por letra
- **Decisão:** os efeitos propostos pelo Claude foram aceitos (LUX raio, PAX empurrão e atordoamento, CRUX cruz com bloqueio, VITA +1 vela, AQUA poça de lentidão, IGNIS área de fogo, MORTIS onda na tela toda). O poder cresce com o tamanho da palavra. **Nenhuma palavra tem recarga.** As 7 são conhecidas desde o início.
- **Dicas:** a cada letra coletada, o HUD mostra as palavras que ainda são possíveis com o prefixo atual.
- **Status:** ✅ aprovada.

### D-014 · Heresia só ao conjurar errado; poça no local do erro
- **Status:** ✅ aprovada.

### D-015 · Letra B ativada (resolve C-001)
- **Decisão:** o B entra no alfabeto, mas **só cai depois que VERBUM é desbloqueado** na partida.
- **Status:** ✅ aprovada.

### D-016 · Combos
- **Decisão:** Vapor = AQUA+IGNIS · Chama Radiante = LUX+IGNIS · Cegueira = LUX+PAX · Martírio = CRUX+LUX · Réquiem = MORTIS+PAX. A ordem não importa. Janela de 2.5s.
- **Status:** ✅ aprovada.

### D-017 · Apócrifos comprados na loja, só para a partida
- **Decisão:** FIDES (escudo de 1 golpe), LUMEN (ímã e letra-alvo reforçados por 10s), PURGO (limpa a tela), GLORIA (milagres reforçados por alguns segundos), VERBUM (repete a última palavra). São cartas especiais da loja e valem só naquela partida.
- **Status:** ✅ aprovada.

### D-018 · Economia
- **Decisão:** a tinta dourada **não passa** de uma partida para outra. Os preços sobem por onda. O custo do reroll é escolhido pelo Claude (rules-agent). Os 9 itens são criados pelo Claude a partir do design (feature 003).
- **Status:** ✅ aprovada.

### D-019 · Inimigos, ondas, campeões e personagens
- **Decisão:** a tabela de inimigos por capítulo foi confirmada. A onda 1 é a mais curta e as seguintes crescem (60s → 90s). Há 1 campeão por onda a partir da onda 3.
- **Desbloqueios:** Hildegarda ao vencer o Cap. 1 · Beda com 100 palavras · Iluminador com 10 combos · Tomé com 20 heresias sobrevividas.
- **Passivas (propostas do Claude, sem objeção do autor):** Hildegarda com janela de combo +50% · Tomé sem stun de heresia e 1 vela a menos · Iluminador com 25% de chance de letra dupla · Beda com atril 4 e +20% de velocidade.
- **Demo:** Anselmo e Hildegarda.
- **Status:** ✅ aprovada.

### D-020 · Controles
- **Decisão:** segurar Tab mostra a lista de palavras conhecidas; Esc pausa. Gamepad fica para o futuro.
- **Status:** ✅ aprovada.

### D-021 · Sem git, CI nem itch por enquanto
- **Decisão:** não criar repositório, CI nem página no itch agora. A T006 (CI + butler) fica **adiada**. O M0 passa a ser "build web vazio gerado localmente + GUT verde".
- **Status:** ✅ aprovada.

### D-022 · Arte por script; itens pendentes do autor
- **Decisão:** os PNGs serão gerados por script a partir dos módulos do Claude Design. Enquanto os `scribe-*.js` não chegam, os sprites entram como placeholders.
- **Pendente do autor:** ficha 03 (Tomé), `scribe-*.js` e `_ds/`, história (o autor vai mandar uma imagem) e áudio.
- **Cutscenes:** o Claude as cria no motor quando a história chegar.
- **Status:** ✅ aprovada.

### D-023 · 2026-09-24 · Bíblia Narrativa canônica
- **Decisão:** a Bíblia Narrativa v1.0 do autor vira `specs/000-game-bible/narrative.md`. As cutscenes seguem o mapa §12 dela e o Grimório usa os verbetes §11.
- **Consequência:** o Modo Heresiarca fica anotado como feature futura, fora do roadmap atual.
- **Status:** ✅ aprovada (texto do autor).

### D-024 · 2026-09-24 · Arte gerada por script sem o export do Claude Design
- **Decisão:** o autor não vai mandar os `scribe-*.js`. Os sprites serão **gerados por script pelo Claude** a partir do que as fichas descrevem (tamanho, pivot, frames, anatomia, mapa de cor), com a paleta travada. Até lá, placeholders.
- **Consequência:** a arte final não será pixel a pixel igual à do Claude Design; ela segue as fichas como especificação. Os hex da paleta continuam sendo os da D-004.
- **Status:** ✅ aprovada ("vai fazer assim mesmo do jeito que a gente falou").

### D-025 · 2026-09-24 · GUT 9.7.1 e só os templates web
- **Decisão:** GUT 9.7.1 (a versão oficial para Godot 4.7). Dos templates de export do 4.7.2 foram instalados **só** `web_nothreads_debug/release` (baixados por HTTP range, sem o pacote de 1,2 GB).
- **Status:** ✅ feito na Etapa 1.

### D-026 · 2026-09-24 · Separação com chegada suave e força limitada
- **Decisão:** inimigos desaceleram a menos de 3× o raio do alvo e a separação é limitada a 1,5× a velocidade deles.
- **Motivo:** sem isso, 20 Diabretes no mesmo ponto se empilhavam (bug encontrado pelo teste de separação).
- **Status:** ✅ implementada.

### D-027 · 2026-09-24 · Dados da sonda de balanceamento da onda 1 (sem palavras)
- **Dados:** parado → morre aos 14,7s (3 mortes). Bot fugindo → morre aos ~50s (7–11 mortes, até 46 vivos, ~55% dos tiros acertam).
- **Leitura:** esperado nesta fase (o dano principal virá das palavras). **Não mexer nos números agora.** Rodar a sonda de novo no T069 com as 7 palavras e levar o resultado ao rules-agent.
- **Status:** ⏳ em observação.

### D-028 · 2026-09-24 · target_bonus 6 → 10
- **Decisão:** bônus da letra-alvo no drop ponderado passa de 6.0 para 10.0 (`data/tuning/drop_tuning.tres`).
- **Motivo:** com 6.0, um prefixo com uma única continuação (ex.: "L" → U) dava 33% de letra-alvo, abaixo do SC-005 (≥ 40%). Com 10.0: ~43%.
- **Status:** ✅ aplicada (valor inicial; rules-agent revisa no T069).

### D-029 · 2026-09-24 · Enum do atril se chama `Atril.Status`
- **Motivo:** `State` colidia com a classe global `State` da StateMachine.
- **Status:** ✅.

### D-030 · 2026-09-24 · Diabrete com HP 2 (recomendação da C-004 aplicada)
- **Decisão:** `data/enemies/imp.tres` max_hp 3 → 2.
- **Motivo:** o autor respondeu "ok" sem escolher opção na C-004; pela regra combinada, aplica-se a recomendação e registra-se. Reversível trocando um número.
- **Status:** ✅ aprovada pelo autor ("ok1 ok2 ok3", 2026-09-24).

### D-030b · 2026-09-24 · Espaço com atril vazio não é heresia
- **Motivo:** sem letras não há "fala sem sentido"; evita punir toque acidental.
- **Status:** ✅ aprovada pelo autor ("ok1 ok2 ok3", 2026-09-24).

### D-031 · 2026-09-24 · Letras do purge ficam soltas (o ímã as ignora)
- **Motivo:** com o anel do purge (20px) dentro do raio do ímã (40px), as letras voltavam sozinhas em 0.3s na mesma ordem — o purge não servia para "tentar de novo". Agora o jogador escolhe a ordem andando por cima.
- **Status:** ✅ aprovada pelo autor ("ok1 ok2 ok3", 2026-09-24).

### D-032 · 2026-09-24 · Poça de aggro com raio
- **Decisão:** a poça atrai só os inimigos a até `heresy_pool_radius` (64px), como diz o FR-019.
- **Status:** ✅.

### D-033 · 2026-09-24 · `selective_magnet` como alavanca de playtest
- **Decisão:** novo campo em `DropTuning` (padrão false): quando true, o ímã só puxa letras que continuam uma palavra. Sem efeito medido pelo bot; fica para o playtest humano.
- **Status:** 🧪 experimento.

### D-034 · 2026-09-24 · Fonte pixel própria para o HUD
- **Decisão:** `PixelFont` desenha texto com glifos 5×6 feitos à mão (os 20 das letras + H J K W Y Z Æ, dígitos, pontuação). O atlas é branco e só serve de máscara; a cor vem da paleta. Acentos são normalizados (Á→A) até a localização da 007.
- **Motivo:** a fonte do design system não foi exportada e não se adiciona fonte de terceiros sem o autor.
- **Status:** ✅ provisório.

### D-035 · 2026-09-24 · Loop de ondas no protótipo
- **Decisão:** ao fim da onda, espera 3s e recomeça a onda 1 como "Onda 2, 3…"; a página degrada 1 estágio por onda (loop 0→3). A loja (003) entra nesse intervalo.
- **Status:** ✅.

### D-036 · 2026-09-24 · `atril_changed` ganha `rare_mask`
- **Motivo:** o HUD precisa mostrar vogais raras em GOLD. Plan §4.3 atualizado.
- **Status:** ✅.

### D-037 · 2026-09-25 · `PoolManager.try_acquire` para o que é dispensável
- **Decisão:** letras e dissoluções usam `try_acquire` (nunca instancia; devolve null se o pool esgotou). Sob carga extrema (MORTIS em 300), o excedente não aparece em vez de criar nós na onda.
- **Status:** ✅ (SC-002 provado por `test_zero_instantiate`).

### D-038 · 2026-09-25 · T082 revisado: otimizar script, não desenho
- **Decisão:** não migrar para MultiMesh agora. O profiler mostrou o desenho em ~1 ms e o script em 7–50 ms no web. Laços quentes sem alocação, grade de 16 px e chamada tipada ao EnemyManager.
- **Motivo:** o PROMPTS pedia MultiMesh "se ficar abaixo de 60"; os dados mostram que isso não resolveria.
- **Status:** ✅ ("pode seguir", 2026-09-25).

### D-039 · 2026-09-25 · Steering escalonado com interpolação
- **Decisão:** cada inimigo recalcula steering e separação a cada 2 ticks (metade dos inimigos em cada tick), com passo dobrado; o contato com o jogador continua checado todo tick; o EnemyRenderer interpola entre o passo anterior e o atual (atraso ~1 tick).
- **Resultado:** web Chrome de 7–39 FPS (instável) para 86–90 FPS médios e p95 67–68.
- **Status:** ✅.

### D-040 · 2026-09-25 · Spec 005: campeões e estreia da Traça
- **Decisão:** 1 campeão por onda a partir da 3 (mantém a D-019; resposta "1 ok"). A Traça estreia na onda 2 com os números reduzidos pelo rules-agent (recomendação aplicada: item sem resposta).
- **Status:** ✅ aprovada pelo autor ("1 ok", "2 e 3 ok", 2026-09-25).

### D-041 · 2026-09-25 · Correção: máximo de velas no início da partida
- **Bug (da 001):** `GameState.start_run` gravava o teto absoluto (8) como máximo atual; o HUD mostrava 8 espaços de vela até o primeiro dano. Encontrado na vitrine da 005.
- **Correção:** o máximo atual começa em `start_candles` (3), como diz a D-010. Teste `test_hud_starts_with_three_candle_slots`.
- **Status:** ✅.

### D-042 · 2026-09-25 · Tinta dourada não expira; sobra da onda é recolhida
- **Decisão:** as gotas de tinta dourada não expiram. No fim da onda, as que sobraram voam até o jogador. Não existe perder tinta por timing.
- **Motivo:** a tinta é recompensa do campeão (evento raro); expirar puniria o jogador por ter lutado. As letras continuam expirando (FR-012).
- **Status:** ✅ aprovada ("ok", 2026-09-25).

### D-043 · 2026-09-25 · Caches por slot e renderer que só escreve o que muda
- **Problema:** a 005 deixou o SC-001 instável no web (41–72 FPS): cada inimigo buscava o comportamento, lia `needs_tick` e chamava funções com várias leituras de propriedade.
- **Decisão:** o EnemyManager guarda por slot o comportamento, a flag de tick e a velocidade; a perseguição pura (Diabrete) é calculada direto no laço. O EnemyRenderer só escreve textura, material, escala e espelho quando mudam.
- **Resultado:** SC-001 81–89 / p95 64–69 · SC-503 78–80 / p95 60–65 (Chrome, 3 execuções cada).
- **Status:** ✅.

### D-044 · 2026-09-26 · Janela de combo conta a partir da 1ª letra da próxima palavra
- **Decisão:** depois de uma conjuração, a janela fica aberta por até 8 s; os 2.5 s (D-016) só começam a correr quando o jogador coleta a 1ª letra da próxima palavra. Emenda a D-016.
- **Motivo:** com o ritmo atual de letras (C-004), 2.5 s corridos desde a conjuração tornariam os combos quase impossíveis (parecer do game-design-agent).
- **Status:** ✅ aprovada pelo autor ("1b").

### D-045 · 2026-09-26 · Nomes dos combos em latim na tela
- **Decisão:** VAPOR, FLAMMA, CAECITAS, MARTYRIUM, REQUIEM; tradução só no Grimório.
- **Status:** ✅ aprovada pelo autor ("2sim").

### D-046 · 2026-09-26 · Spec 002 aprovada com os pareceres aplicados
- **Decisão:** SPIRITUS intangível (não invulnerável), SALVATOR +3 velas sem invulnerabilidade, Cegueira sem cancelar contato, MISERERE como absolvição, PURGO 10 em elites, VERBUM não repete orações nem combos, DOMINUS 20.
- **Status:** ✅ aprovada pelo autor ("3ok").

### D-047 · 2026-09-26 · Respostas do autor às perguntas abertas
- **D-011 revisada (1C):** recuperar vela exige ficar **sem se mover e sem levar dano**; conjurar parado **não** zera a contagem.
- **Ritmo de palavras (2B):** construir uma sonda com o jogador invencível que mede letras úteis por minuto; depois o playtest do autor confirma.
- **Firefox (3B):** o Claude instala o Firefox nesta máquina e mede.
- **Paleta (4C):** o Claude gera 2–3 variações numa página para o autor escolher.
- **Áudio (5):** agora só a arquitetura de áudio (sem sons); sons provisórios por script na feature 009.
- **Screen shake (6B):** entra na feature 006 (Asmodeus), com opção de desligar.
- **Sprites (7C):** arte gerada por script aos poucos, junto com a feature que usa cada coisa; o que já existe, antes da demo.
- **Build web (8A):** a meta de 25 MB vale para o **download comprimido** (hoje 9,9 MB). Resolve a C-003.
- **Git (9B):** repositório local com commits a cada fase, sem GitHub por enquanto.
- **Ordem (10B→A):** sonda + git antes dos combos da 002.
- **Status:** ✅ respostas do autor ("1c 2b 3b 4c 5 sigo sua recomendacao 6b 7c 8a 9b 10b depois a").

### D-048 · 2026-09-26 · Paleta C (ferro-gálica fria)
- **Decisão:** das 3 variações mostradas no artefato "Paletas do Códice", o autor escolheu a C: tinta #15171C, tinta rala #3E4450, pergaminho #E4DDCB, pergaminho velho #BDB39A, giz #F5F3EC, sangue #7E1627, sangue seco #4E0D18, ouro #B89436, ouro claro #DCC06A. Substitui os hex provisórios da D-004.
- **Status:** ✅ aprovada pelo autor ("gostei do C").

### D-049 · 2026-09-26 · Otimizações para o Firefox (C-005, opção 1)
- **Decisão:** (a) as gotas do ataque automático saem de 200 nós pooled (`InkDrop`) para o `PlayerProjectileManager` (arrays + 1 `_draw`, teto 200, recusa sem instanciar); (b) `STEER_STRIDE` 2 → 3; (c) o contato inimigo→jogador usa a posição desenhada (`_drawn_position`), não a lógica.
- **Motivo:** C-005 (Firefox 31–35 FPS). (c) é a ressalva do animation-agent: no stride 3 a Gárgula em investida (220 px/s) anda ~11 px por passo lógico e acertaria antes do sprite chegar.
- **Resultado:** seções −25–40%, FPS do Firefox +~15%; SC-001 continua ❌ no Firefox (T085 §1.4). Nenhum número de jogo mudou.
- **Status:** ✅ aprovada pelo autor ("1", "pode seguir").

### D-050 · 2026-09-26 · Firefox abaixo do SC-001 aceito por enquanto
- **Decisão:** o Chrome é a referência do SC-001; o Firefox é medido de novo na feature 011 (publicação), de preferência em outro computador. Sem mais otimizações agora.
- **Status:** ✅ escolha do autor ("1").

### D-051 · 2026-09-28 · Combos: power só no dano e números ajustados pelo rules-agent
- **Decisão:** nos combos, `power` multiplica **só o dano** (e a cura); raio, comprimento, duração, stun e limiar são literais. Ajustes para cumprir a FR-202 ("nunca faz menos que a 2ª palavra"): **Vapor** raio 120, dano 2 a cada 0,25 s; **Flamma** linha 320 × 20; **Martyrium** duração 4, dano 3. Caecitas e Requiem sem mudança.
- **Critério da FR-202:** compara por **área coberta**, não por alvo parado (o Martyrium dá ~36 num alvo parado contra ~77 da CRUX, mas cobre um braço de 160 contra 48).
- **Status:** ✅ parecer do rules-agent; critério por área escolhido pelo autor ("1").

### D-052 · 2026-09-28 · Detalhes de implementação dos combos (002 Fase 2)
- **Cegueira (D-046 prevalece sobre a T212):** a `tasks.md` dizia "sem contato", mas a D-046 (posterior) manda manter o dano de contato. O cego vaga a 50% da velocidade, não persegue nem ataca; encostado, fere.
- **Vapor:** quem está fora da nuvem trata o escriba oculto como cegueira (vaga). O escriba oculto é desenhado em xadrez 2×2 pelo shader do flash (sem alpha).
- **Sinais:** além dos da spec, `combo_window_closed` e o parâmetro `partners` em `combo_window_opened` (latim das palavras que fecham combo), para o HUD não depender do Caster.
- **ComboData estende WordData:** reusa os parâmetros e o `Miracle.start`; os combos não entram no Lexicon.
- **Visual (design-agent):** GOLD no laser do Martyrium é a exceção prevista no art bible §2.2; Vapor e o fogo da Flamma ficam no FxLayer, abaixo das letras; venda CHALK no cego; nome do combo em GOLD 2× sobre o escriba por 1 s.
- **Status:** ✅ dentro do plano aprovado ("pode").

### D-053 · 2026-09-28 · Spec 009 (áudio) aprovada
- **Decisão:** arquitetura de áudio completa em silêncio (barramentos, `SoundData` por evento, pool de vozes com anti-spam, música em camadas pela intensidade da onda, gate do web, lista do que gravar). Sons provisórios por script na Fase 2; arquivos do autor na Fase 3.
- **Música:** camadas entram conforme a onda aperta e voltam à base quando o escriba morre.
- **Status:** ✅ aprovada pelo autor ("1a, 2a").

### D-054 · 2026-09-28 · Números de áudio (parecer do animation-agent)
- **Decisão:** pool de 24 vozes de SFX + 4 de UI; pitch ±0,05; voz silenciosa ocupada 0,2 s. Morte de inimigo: cooldown **50 ms** (era 40). Música: rampa **700 ms** (era 800) e **400 ms** na morte do escriba (`death_fade_ms`, novo). A rampa da música usa o **relógio real**, para não desacelerar no hit-stop. O som não obedece ao `time_scale`.
- **Detalhe:** `AudioManager.sound_played(id)` existe para métricas e testes. Palavras sem som próprio (orações, apócrifos) caem no `word_cast` genérico até a 002 Fase 3–4.
- **Status:** ✅ parecer do animation-agent.

### D-055 · 2026-09-28 · Apócrifos (002 Fase 3)
- **VERBUM:** não mexe na janela de combo (não abre, não fecha, não completa). Sem o que repetir, falha: as letras se perdem, sem heresia. Repete a última palavra **base ou apócrifa** com o mesmo poder, e o eco sai como `word_cast` da palavra repetida (marcas, FR-202c). Autor: "1.a 2.1" (lido como 2A).
- **GLORIA:** `Miracle.dmg()` concentra o dano (× power × GLORIA); VITA cura `heal_candles × GLORIA`, arredondado. Raio, stun, duração e limiar não mudam.
- **PURGO:** mata os comuns seja qual for o HP e dá **10 literais** nos campeões (o power 2,4 não entra; a GLORIA sim), como a FR-208 escreve.
- **FIDES:** absorver o golpe dá os i-frames normais, sem perder vela.
- **Visual (design-agent):** arco GOLD_LIGHT sobre a cabeça (FIDES), 4 pontos CHALK em órbita (LUMEN), colchetes GOLD nos pés (GLORIA), anel CHALK tracejado (PURGO), eco INK_SOFT em xadrez no atril (VERBUM) e letras piscando INK_SOFT na falha.
- **SC-202 (medição):** `?stress=purgo` e o controle `?stress=purgoctl` no Chrome. Pior frame com PURGO de 25 a 53 ms, contra 19 a 45 ms no controle. O ruído desta máquina é do tamanho da diferença. Limitar as dissoluções a 64 não mudou o quadro de forma clara. Veredito fica para a T240 (Fase 5, com MISERERE e DOMINUS); o suspeito principal são as 300 dissoluções redesenhando ao mesmo tempo.
- **Status:** ✅ plano aprovado ("pode seguir").

### D-056 · 2026-09-28 · Grandes Orações (002 Fase 4)
- **Escala (rules-agent):** mesma regra dos combos, `power` só no dano. Efetivos: SANCTUS 15 a cada 0,25 s (raio 90, 6 s), DOMINUS 100 + stun 3 s, ANGELUS 20 por toque, SPIRITUS 21 por toque, MISERERE 280, SALVATOR 3 velas (GLORIA multiplica a cura). O dano literal foi rejeitado: DOMINUS (7 letras) ficaria abaixo da MORTIS efetiva (70).
- **Ressalvas para a 006:** num chefe parado, SANCTUS (360) passa a MISERERE (280); conferir MISERERE × GLORIA contra uma fase inteira de chefe.
- **Números novos (provisórios, parecer final na T240):** ANGELUS `rotation_speed` 1.0 e alcance da pena (`width`) 8 px; SPIRITUS toque a cada 0,25 s em raio 10. `rotation_speed` subiu do `ComboData` para o `WordData`.
- **Toques:** ANGELUS e SPIRITUS conferem o toque todo tick, com intervalo por inimigo (`EnemyManager.damage_touch`); antes a pena "pulava" o inimigo (animation-agent).
- **SPIRITUS:** o contato não fere o escriba; projéteis e heresia sim (D-046). **MISERERE:** apaga a poça e o aggro dela; a próxima heresia é perdoada sem stun e sem perder as letras. Letras corrompidas: gancho no Caster para o Cap. 5.
- **Visual (design-agent):** as 6 ficam abaixo das letras (`draw_below_world`, agora no `WordData`); coroa GOLD nos atordoados; xadrez CHALK no escriba do SPIRITUS; selo GOLD no canto do atril com o perdão guardado. Tempos ajustados pelo animation-agent (flash do SANCTUS 50 ms só quando fere; fantasmas do SPIRITUS só em movimento).
- **Debug:** `?atril=8` / `-- atril=8` para testar antes da loja (003).
- **Status:** ✅ plano aprovado ("pode").

### D-057 · 2026-09-28 · Fechamento da 002 (T240–T241)
- **Parecer final do rules-agent:** VÁLIDO COM RESSALVAS. Única correção: o número de penas do ANGELUS saiu do código para o `.tres` (`WordData.orbit_count` = 3). Os números da D-056 ficam.
- **SC-202 (varreduras):** nova sonda `?stress=purgo|dominus|miserere` contra o controle `?stress=ctl` (mesmo ciclo, sem conjurar), 8 ciclos cada, frames da janela de 0,8 s depois da conjuração. Chrome, 2 rodadas: frames acima de 33 ms — controle 20–29, PURGO 7–8, DOMINUS 4–7, MISERERE 5–8. **As varreduras em lotes não criam pico**; os frames lentos vêm do peso normal dos 300 inimigos vivos nesta máquina. Critério absoluto (nenhum frame > 33 ms) não verificável aqui: nem o controle o cumpre hoje.
- **SC-205:** A/B intercalado no Chrome entre o build do fim do áudio (`cec562e`) e o atual: 43–52 contra 45–49 FPS, custos por seção iguais. **Sem regressão.** A máquina está mais lenta que em 2026-09-26 (o mesmo build antigo deu 65–88 então); o SC-001 absoluto no Chrome fica para remedir, junto com a C-005, na 011.
- **Ressalvas para a 003 (rules-agent):** PURGO deve ser o apócrifo mais barato enquanto os comuns tiverem HP ≤ 5; desbloquear VERBUM libera o B no mesmo instante; o atril sobe para 7 antes do 8.
- **Ressalvas para a 006:** limitar por fase (DamageFilter) SPIRITUS colado no chefe (até 504), SANCTUS (360) e MISERERE (280, × GLORIA); ANGELUS não fere a menos de 27 px do escriba.
- **Status:** ✅ feature 002 Complete.

### D-058 · 2026-09-28 · Spec 003 (loja) aprovada
- **Decisão:** (1A) dízimo de 4 de tinta ao fim de cada onda, além dos campeões; comum não solta tinta. (2A) oferta de 3 itens + 1 vaga fixa de apócrifo. (3A) a letra extra do Tinteiro Duplo é um segundo sorteio independente. (4A) há loja depois da última onda, antes do chefe.
- **Pareceres aplicados:** loja sem tempo limite; 1 carta travada, pelo preço da visita em que foi travada; reroll 5 +3; preços base e tetos do rules-agent; Círio no teto só acende 1 vela.
- **Status:** ✅ aprovada pelo autor ("1a 2a 3a 4a").

### D-059 · 2026-09-28 · Tela da loja (003 Fase 2)
- **Visual (design-agent):** medidas e cores da especificação de 2026-09-28 (os dados de pixel das fichas 28/31 não estão no repositório): parede INK com juntas INK_SOFT, janela com lua, mesa INK_SOFT; cartas 100×140 (itens em PARCHMENT; apócrifo em PARCHMENT_OLD com rolos); ícones 24×24 gerados por script; carta vendida só com ícone, selo GOLD e "VENDIDO". Fonte ganhou `+ % [ ] ; < >`.
- **Tempos (animation-agent):** entrada 400 ms com 100 ms entre cartas; compra 200 + 400 ms; sem tinta treme 200 ms e o preço fica BLOOD 400 ms; reroll vira as cartas; tinta sobe 20 ms/unidade até 700 ms; o "pop" 1,2× virou 1 px de subida com contorno GOLD (sem subpixel); saída em dithering 400 ms.
- **Comportamento:** Enter fecha a loja na hora (a onda recomeça por baixo) e a tela sai em dithering; Esc não faz nada na loja (o jogo já está parado); qualquer tecla termina a entrada das cartas.
- **Debug:** `index.html?shop` abre a loja em 0,5 s com 30 de tinta.
- **Testes:** com a árvore pausada, esperar com `get_tree().create_timer(t, true)` (o `wait_seconds` do GUT pausa junto).
- **Status:** ✅ dentro do plano aprovado ("pode").

### D-060 · 2026-09-28 · Fechamento da 003 (T320–T321)
- **SC-306 (sonda):** `balance_probe -- cast god chapter buy` joga as 9 ondas com a loja; o bot compra sempre as cartas mais baratas que cabem. Resultado: **6 compras**, 40 de tinta ganha (36 do dízimo; o bot foge e quase não mata campeão), capítulo completo. Um jogador que mata os 7 campeões ganha ~28 a mais.
- **SC-307:** A/B no Chrome contra o fim da 002 (`5ec49f4`): SC-001 88–101 → 87–91 FPS (p95 66–79 → 67–70); SC-503 87–93 → 87–88 (p95 68–75 → 68–70). Sem regressão; SC-001 ✅ de novo no Chrome (a máquina voltou ao normal).
- **Sonda:** o modo de compra se chama `buy` (não `shop`, que colide com o `?shop` de debug do jogo).
- **Status:** ✅ feature 003 Complete.

### D-061 · 2026-09-29 · Sons provisórios por script (009 Fase 2)
- **Decisão:** `tools/gen_placeholder_sfx.gd` sintetiza 36 sons (ondas simples, envelope, deslizamento, acordes, sinos inarmônicos) para os eventos de prioridade ≥ 1 e os liga nos `.tres` (`assets/audio/placeholders/sfx_*.tres`, 22 kHz mono 16 bits, ~1 MB cru). Não mexe em `.tres` cujo som já seja do autor. O `AUDIO-LIST.md` continua listando os provisórios como "falta gravar". Queda de letra comum e letra comida seguem em silêncio (prioridade 0).
- **Ajustes do animation-agent:** Monge Oco 200 ms; ataque do VAPOR 10 ms; coleta de letra mais baixa e menos aguda (vol 0,12, filtro 0,6); Gárgula e Borrão mais baixos; combo genérico acima da conjuração.
- **Web:** console sem erro de áudio no Chrome e no Firefox. Download comprimido 11,2 MB (meta 25). Desempenho: carga normal igual; na varredura do PURGO (300 mortes com som) o p95 subiu de 17 para 23–24 ms e 0–4 frames passaram de 33 ms (antes 0). Alavanca se precisar: `enemy_killed*` com 2 vozes em vez de 3.
- **Status:** ✅ plano aprovado ("pode").

### D-062 · 2026-09-29 · Spec 006 (Asmodeus + framework de chefes) aprovada
- **Decisão:** (1A) Rasura nas F2–F3, com proteções (nunca apaga palavra pronta nem a letra pega há < 0,5 s); (2A) janela de exposição de 1 s com +25% das palavras depois de Raio/Swipe errado; (3A) DOMINUS atordoa o chefe só 1 s; (4A) luta de 3–4 min.
- **Pareceres aplicados:** HP 1500, fases 66/33; teto por conjuração (120 inteiro, 120–240 pela metade) e por fase (para no limiar + 1,5 s invulnerável); telegrafia mínima 600 ms; LetterSafety 3 letras / 4 s; derrota = Game Over normal.
- **Status:** ✅ aprovada pelo autor ("1a2a3a4a").

### D-063 · 2026-09-29 · Asmodeus na tela (006 Fase 2)
- **Arquitetura (mechanics-agent):** `EnemyManager.boss_target` (BossHurtbox) testado em cada função de dano; origem pelo `DamageSource` (`Miracle.cast_id`/`tag`, marcados em `dmg()`/`begin_hit()`); varreduras por `hit_boss_sweep` no início; Rasura pelo EventBus (`atril_erase_requested` → `LetterField` aplica as proteções → `letter_erased`). FSM do chefe com estados como nós (Dormant, Enter, Idle, Telegraph, Attack, Recover, Exposed, PhaseShift, Stunned, Dead); executores dos ataques criados no `_ready` (nunca na luta).
- **Placeholder (design-agent):** 64×64 gerado por script com idle 3, telegraph 1, hit 1, invuln 2, death 4 e overlays de rachadura (F2) e fogo (F3) — **exceção aceita** aos 60 quadros da ficha 16 até o PNG real. Telegrafias em BLOOD tracejado; na Rasura a última letra do atril ganha um traço BLOOD. Barra do chefe 400×10 em Y44–53 com marcas em 66/33%; o cronômetro da onda some na luta.
- **Tempos (animation-agent):** entrada 2,5 s invulnerável; telegrafia pisca 100 → 50 ms no último terço; palavra no chefe = flash 60 ms; golpe forte no escriba = hit-stop 60 ms + shake médio; troca de fase 1,5 s (hit-stop 60 ms + shake médio); morte 1,5 s (hit-stop 100 ms + shake forte, letras douradas em 0,9 s), capítulo acaba 2,5 s depois. Escala de shake: fraco 1 px/200 ms, médio 2 px/400 ms, forte 4 px/700 ms (a câmera vem na T620).
- **Fluxo:** loja da onda 9 → `start_boss()` (inimigos restantes se dissolvem) → `boss_defeated` → `chapter_completed`; derrota = Game Over existente. `ChapterData.boss`. Debug `?boss`.
- **Status:** ✅ dentro do plano aprovado ("pode").

### D-064 · 2026-09-29 · Repositório no GitHub (revê a D-047 9B)
- **Decisão:** o repositório local passa a ter `origin` = https://github.com/Andersonndiass/scribe_of_the_damned.git (público), com tudo o que está no Git (código, testes, specs, fichas de design, docs). O commit inicial do GitHub (`README.md`) foi juntado ao histórico local, sem force push. CI e itch continuam fora por enquanto.
- **Status:** ✅ pedido do autor ("se conecte com esse repositório", opção "1" = subir tudo).

### D-065 · 2026-09-29 · Fechamento da 006 (T620–T622)
- **Shake (T620):** `ShakeCamera` na cena principal (px inteiros, o mais forte substitui, tempo real, `GameState.shake_enabled`); morte de campeão = shake fraco 1 px/200 ms (pendência da 005 resolvida; números no `ChampionTuning`).
- **Sonda (T621):** `balance_probe -- cast god boss [unlock=all atril=8]` roda a luta em tempo quase real. Em 3 min o bot tirou ~376 de 1500 (≈2 de dano/s; 6 palavras na base, 3 com tudo liberado): projeção de ~12 min. O rules-agent calculou 3–4 min supondo 1 palavra a cada ~5 s. O bot monta palavras muito devagar (mesma limitação da C-004), então **não calibra a vida** → C-006.
- **Stress (T622):** `?stress=boss` (fase 3 forçada, Summon, 150 letras, 200 projéteis): Chrome 157–189 FPS, p95 120–149 (SC-607 ✅). SC-001 na mesma sessão: 87–97 / p95 62–71.
- **Status:** ✅ feature 006 Complete; vida do chefe pendente de playtest.

### D-066 · 2026-09-29 · Spec 007 (telas e menus) aprovada
- **Decisão:** 9 telas + Créditos simples (Splash, Menu, Personagem, Capítulo, Pausa, Game Over, Vitória, Opções, Grimório). **Remapear teclas e alto contraste entram agora** (1B). **PT-BR e EN completos agora**, com troca nas Opções (2B, "quero conseguir trocar de português e inglês nas configurações"). Loading HTML vai para a 011 (3A).
- **Do parecer do game-design-agent:** Grimório sem bônus mecânico (D-018); chefe descoberto ao enfrentar; Vitória com um botão (Menu) e o Cap. 2 acorrentado. O corte de remap sugerido por ele partia da ideia de que as letras são digitadas; aqui são coletadas andando, então o remap é seguro.
- **Status:** ✅ aprovada pelo autor ("1b2b … 3a").

### D-067 · 2026-09-29 · Controles com mouse (feedback de playtest do Francisco)
- **Pedido:** "marcar com o mouse qual letra quer pegar" e "mirar as habilidades com o mouse".
- **Decisão do autor:** clicar numa letra faz o ímã trazer só ela (mesmo raio; sem clique, nada muda); as palavras direcionais miram no cursor, o ataque automático não muda; sem mouse, mira = direção do escriba; opção ligada por padrão; feito antes da 007 (respostas "1… 2a 3a 4a 5a").
- **Regra que o Claude acrescentou:** ao marcar, as outras letras perto ficam de lado até saírem do raio — senão, coletada a marcada, as indesejadas viriam logo em seguida.
- **Visual (design-agent):** mira = pena de tinta 11×11 (ponta = ponto quente, contorno CHALK) no lugar do cursor do sistema; letra marcada = 4 cantos em L de INK (16×16, pop de 80 ms), sem GOLD nem pulso. Divergência: a pena fica visível enquanto a mira pelo mouse vale (a ficha a escondia após 2 s parada).
- **Pareceres:** game-design-agent aprovou a forma (1c: raio não aumenta; mira só nas direcionais); sem números novos (rules-agent não precisou).
- **Limitação:** sem mouse não há como marcar letra (o ímã funciona como antes).
- **Status:** ✅ aprovado pelo autor ("pode").

---

### D-068 · 2026-09-29 · Telas da 007 (Fase 2, Checkpoint 007-B)
- **O que entrou:** Splash → Menu → Personagem → Capítulo → Jogo pelo `ScreenRouter` (transição Bayer INK por shader: 100+100 ms entre menus, 200+200 ms entrando/saindo do jogo, entrada travada); Créditos; Pausa, Game Over e Vitória em `GameOverlays` (substituem os overlays mínimos da 001). Estatísticas por `GameState.run_record()`; entradas novas por `Codex.new_this_run()`.
- **Dados:** personagens, capítulos e créditos em `data/ui/*.json`; todo texto por chave em `i18n/ui.csv` (PT e EN).
- **Divergências pequenas das fichas (do Claude):** (1) fitas do Menu com 100 px e do Game Over com 112 px (a ficha pede 128), para caber na página do livro e não encostarem; (2) toda fita tem contorno (INK_SOFT em repouso, GOLD no foco) — sem isso, fita de pergaminho some sobre a página de pergaminho; (3) a pena-cursor dos menus é a da mira espelhada (ponta para a fita); (4) títulos e dicas da Pausa/Game Over ficam sobre uma faixa lisa para ler por cima do jogo escurecido; (5) Game Over e Vitória pausam a árvore (a 001 deixava o jogo rodando atrás); (6) os botões do Game Over saem 3,5 s depois da morte, como a spec (o parecer de tempos falava em 2,5 s).
- **Pendências:** Grimório e Opções aparecem desabilitados no Menu e na Pausa até a Fase 3 (feito na D-069); o personagem escolhido só vale na 010 (só o Anselmo é livre). *Créditos:* o autor pediu "FRANCISCO", o nome de quem fez o jogo (a linha separada de testes saiu, era a mesma pessoa).
- **Status:** feito; aguardando o autor ver no build.

---

### D-069 · 2026-09-29 · Opções e Grimório (007 Fase 3)
- **Opções:** layout do design-agent (ficha 30). Volumes em passos de 10%, selo de cera (Tremor, Mouse, Contraste; 3 quadros @50 ms), idioma PT-BR/EN trocado com ←/→, remapear teclas (a próxima tecla vira a da ação; Esc cancela e não é remapeável). Cada mudança vale na hora e é salva (`Settings.commit`; os testes não gravam no arquivo real). Fitas Restaurar · Voltar lado a lado; Restaurar pede confirmação.
- **Conflito de tecla:** a regra da D-066 (troca) vale para **todas** as ações que tinham a tecla. Reiniciar e Loja: trocar dividem o R de fábrica (contextos diferentes), então pegar o R troca as duas, e o aviso cita as duas.
- **Grimório:** 4 abas; ←/→ vira a entrada (8 quadros @50 ms, guarda 1 comando), ↑/↓ troca a aba. O design-agent sugeriu Q/E como atalho; ficou de fora porque são teclas fixas (ruins em AZERTY e sem remap). Verbetes da narrativa §11 em PT e EN (a tradução EN é do Claude). Significado das palavras e combos em `word_*`/`combo_*` (latim nunca traduzido fora do Grimório).
- **Sem verbete na narrativa:** ANGELUS, DOMINUS, MISERERE, SALVATOR, SANCTUS, SPIRITUS e os 5 combos mostram "SEM VERBETE AINDA" — **o autor escreve** (até 40 caracteres × 6 linhas).
- **Campeão:** verbete de inimigo próprio, descoberto quando o primeiro aparece (sinal novo `EventBus.champion_spawned`). Ilustração provisória: o sprite do Diabrete.
- **Chefes futuros** (Mãe das Traças, Abade Caído, Malaquias, Semíhaza) aparecem como "?????" até existirem.
- **Pela Pausa:** Grimório e Opções abrem por cima (embutidos), com o jogo parado; Esc volta à Pausa.
- **Status:** feito; aguardando o autor ver no build.

---

### D-070 · 2026-09-29 · Fechamento da 007 (T730)
- **Resultado:** telas completas (Splash, Menu, Personagem, Capítulo, Jogo, Pausa, Game Over, Vitória, Opções, Grimório, Créditos), PT-BR e EN, 100% teclado (teste do fluxo), opções salvas, Grimório salvo entre partidas.
- **SC-706 / SC-001:** Chrome com GPU, `?stress`: 102–105 FPS de média, p95 76–80 (antes 87–91 / 67–70). As telas não rodam durante a onda.
- **Fica para depois:** o personagem escolhido só vale na 010; o HTML de Loading é da 011 (D-066); verbetes que faltam (D-069) e o Campeão com arte própria.
- **Status:** ✅ 007 Complete.

---

### D-071 · 2026-09-29 · Spec 008 (cutscenes do Cap. 1) aprovada
- **Respostas do autor:** "1A. 2A. 3A pressionar por 3 segundos e aparece uma animação de carregamento subindo e quando finalizar pula a cena."
- **Repetição:** C1-01 e C1-02 só na primeira vez (gravado ao terminar ou pular); C1-03 e C1-04 sempre.
- **Falas:** as propostas [P] aprovadas; ajustes de canon do game-design-agent aplicados (arca no subsolo, a heresia fere quem a diz, o Abade queria que Anselmo entrasse).
- **Pular:** segurar Esc **3 s** (a proposta era 1 s), com animação de carregamento subindo.
- **Vozes (novo):** o autor vai gerar as falas no ElevenLabs. Todas as falas do jogo, em PT-BR e EN, com direção por personagem, ficam em `docs/voice/VOICE-LINES.md` e `docs/voice/voice_lines.csv` (inclui as falas âncora dos caps. 3–5, para os roteiros futuros). O jogo toca `assets/audio/voice/<idioma>/<id>.mp3` quando existir (FR-814). Na tela, "…" vira "..." e sem apóstrofo (a PixelFont não tem esses sinais).
- **Status:** ✅ aprovada.

---

### D-072 · 2026-09-29 · Falas na partida e voz do latim (emenda à 008)
- **Pedido do autor:** "todas as frases durante o jogo também, frases que o jogador fala ou quando o boss entra". Até aqui não havia falas na partida fora das cutscenes.
- **Decisão ("1a 2a 3a"):** entram as 7 frases propostas (Asmodeus nas fases 2 e 3, na Rasura e na morte; Anselmo depois da heresia, na última vela e no fim de onda), num balão de fala curto com voz opcional (FR-815); o jogo toca a voz do latim ao conjurar e o HÆRESIS! quando os arquivos existirem (FR-816).
- **Arquivos:** `docs/voice/` (texto, pronúncia do latim, direção de voz); `data/barks/barks.json` na Fase 3.
- **Status:** ✅ aprovado.

---

### D-073 · 2026-09-29 · Palco das cutscenes (008 Fase 2)
- **Tempos (animation-agent):** texto a 30 letras/s; `end` de cada fala = t + 1,0 + n/20 s; C1-01 15,65 s + C1-02 17,2 s (33 s até a partida, teto 40), C1-03 10,3 s (teto 12), C1-04 9,5 s (teto 15); corte seco C1-01 → C1-02 (a virada de página fica dentro da C1-01); espera de 0,4 s entre a morte do chefe e a C1-04; balão na partida 1,5–2,5 s, 4 s entre frases (as do Asmodeus têm prioridade).
- **Visual (design-agent, ficha T810):** faixa INK embaixo com close 128×128 saindo por cima (Anselmo à esquerda, os outros à direita, narrador sem close); legenda em placa de pergaminho no canto de cima à esquerda; pular = placa no canto de cima à direita com um **tinteiro de vidro que enche de tinta de baixo para cima** (o "carregamento subindo" do autor). Closes desenhados ao vivo: Anselmo (3 expressões), Abade = o Abade vivo com "filtro fantasma" (o catálogo só tinha `abade_vivo`), Asmodeus = o sprite em 2×. Dither de 25% novo no `UiStyle`.
- **Divergências pequenas (do Claude):** linhas de texto a 16 px (a ficha pedia 14; com o glifo de 12 px as linhas colavam); a placa de pular só aparece depois de 100 ms segurando (tempo do animation-agent; a ficha a mostrava no primeiro quadro).
- **Validação nova:** fala com mais de 2 linhas (39 caracteres; 48 do narrador; 32 na legenda) em qualquer idioma é erro no load.
- **Achado do design-agent (pendente, fora da 008):** os PNGs provisórios de `assets/placeholders/` saem 1 abaixo do token em algum canal (ex.: INK 21,23,27 em vez de 21,23,28) porque o `palette.gd` guarda floats de 4 casas e o `set_pixel` trunca. Correção proposta: gerar a paleta a partir do hex e arredondar nos geradores, com um teste byte a byte. Invisível a olho; fica para uma tarefa própria.
- **Status:** feito.

---

### D-074 · 2026-09-29 · Qualidade da arte: ilustrações maiores e arte importada
- **Pedido do autor:** "ainda está estranho, aumente a resolução e melhore a qualidade, pode fazer isso com tudo no design". O Claude apontou o conflito com a constituição VII (640×360, pixel-perfect, 9 cores) antes de agir.
- **Decisão ("1A 2A 3A"):** (1A) o jogo continua em pixel art 640×360, mas as **ilustrações das cutscenes ficam maiores**: close de **192×192** (era 128; emenda ao art bible §12 e ao catálogo §2, só para os closes de cutscene) — a faixa de diálogo muda junto (moldura 196, texto com 34 caracteres por linha); (2A) a paleta segue com as 9 cores; (3A) a arte final vem do autor (IA de imagem ou artista) e passa pela ferramenta nova **`tools/import_art.gd`** (`ArtQuantizer`), que redimensiona para o tamanho do asset e reduz às 9 cores com pontilhado (Floyd–Steinberg para ilustrações, Bayer para UI), usando o hex exato do `design-tokens.json`.
- **Closes:** `data/cutscenes/speakers.json` aponta `assets/cutscenes/closes/<falante>_<expressão>.png`; se o arquivo existir, o jogo usa a arte; senão, o placeholder por script (redesenhado com hachura cruzada, olhos com íris e pálpebras, cabelo, pregas; o Abade com rosto velho e triste, como pede o art bible).
- **A constituição não mudou.**
- **Status:** ✅ aprovado.

---

### D-075 · 2026-09-29 · Regras de pixel art: sem hachura na pele
- **Pedido do autor:** "as hachuras estão comendo muito o rosto... feio e com cara de IA; pesquise, pegue referência, veja o melhor jeito de criar esses sprites, crie essa regra, salve em memória e siga nas futuras".
- **Pesquisa:** Pixel Joint (tutorial de pixel art), Androidarts (Arne), Derek Yu, Lospec (dithering) — consenso: xadrez em pele vira plano duro ou ruído; pixel solto é ruído; sombra deve ser forma de borda definida, sem pillow shading; poucas linhas internas; hachura/dither só em textura e área grande.
- **Decisão:** o art bible §3 troca "sombreamento só por hachura (135° no rosto)" pelas regras novas (pele em blocos lisos com a rampa CHALK → PARCHMENT → PARCHMENT_OLD → INK_SOFT; hachura só em tecido e cenário). Os closes placeholder foram refeitos assim; `import_art` com `dither=none` para rostos e personagens.
- **Memória:** regra salva para valer em toda arte futura (por script, importada ou revisada pelo design-agent).
- **Status:** ✅ aplicado.

---

### D-076 · 2026-09-29 · Regras de pixel art em itens, HUD e UI; closes em camadas
- **Pedido do autor:** "de acordo com essa nova regra modifique os sprites dos itens, e todas as UI e HUDs"; "busque mais na internet e coloque regras"; "use o conceito de camada, crie os sprites separados e junte na cena"; "tudo o que aprendeu vá guardando em memória".
- **Pesquisa e regras:** Derek Yu (erros comuns), Pixel Parmesan (anti-aliasing), Pixnote (UI/ícones), guias de ícone 16/24 px — regras novas no art bible §3 (ícones: silhueta em 1 cor, nada importante com 1 px, mesmo molde, 1 destaque, círculos por ponto médio; acabamento: sem banding, AA só em degrau interno; UI: 9-slice, contraste, desabilitado = tom apagado + traço, xadrez só em tela inteira e fantasmas).
- **Paleta exata:** `palette.gd` agora grava n/255 (antes, 4 casas decimais faziam a Image gravar 1 abaixo); PNGs regenerados; teste byte a byte.
- **Itens:** 14 ícones da loja e a gota dourada refeitos pelos mapas do design-agent (`tools/item_icon_maps.json`).
- **HUD:** letra do atril sempre INK (rara/pronta = fundo GOLD_LIGHT; pronta com anel que pulsa), dicas em etiqueta, selo 7×7 com contorno, cruz de 2 px, eco do VERBUM sem xadrez, diagonal da Rasura em degraus, marcas de fase de 2 px, "Onda completa" em etiqueta, tinta em INK, lista de palavras em painel.
- **UI:** `UiStyle.draw_panel/draw_tag/disc/ring/frame/dim_screen`; fitas desabilitadas lisas com traço; cadeado 8×10; medalhões e páginas bloqueadas lisos; Grimório (silhueta, texto ilegível em blocos, sombra da folha), Opções (painel, selo, setas, espera de tecla), loja (vendida com selo, sem tinta apagada + traço, estrelas, luz da vela na argamassa), placas da cutscene, sino com luz à direita.
- **BLOOD_DARK na UI (autor: "A"):** liberado para fita da próxima onda, selo de cera, capa do Grimório e borda queimada (art bible §2).
- **Closes em camadas:** fundo, roupa, cabeça, cabelo/barba, contorno + olhos, sobrancelhas, boca, detalhes por expressão; `CloseView` empilha as camadas na cena; arte importada por camada em `art_dir` do `speakers.json`.
- **Status:** ✅ feito (GUT 373/373).

---

### D-077 · 2026-09-29 · Fechamento da 008 (cutscenes do Cap. 1)
- **Resultado:** as 4 cenas in-engine (roteiro JSON → builder → AnimationPlayer), cada elemento em camada própria (`src/cutscenes/fx/`, `CutsceneFx`); C1-01 e C1-02 entre o Capítulo e a onda 1 só na primeira vez (gravado no Grimório ao terminar ou pular), C1-03 no lugar da entrada do chefe (o fim da cena solta o chefe já lutando), C1-04 entre o fim do capítulo e a Vitória; `?cutscene=c1_0N` toca uma cena e volta ao Menu. Frases na partida (7, balão de fala, voz opcional, intervalos 4 s / 20 s / 15 s, prioridade do Asmodeus).
- **Pular:** segurar Esc 3 s com o tinteiro enchendo (D-071); Espaço/Enter/clique adianta; o Esc não abre a Pausa durante a cena.
- **Bug achado no teste:** um tocador carregado e parado prendia a entrada (o Menu do Game Over não respondia) — agora só prende enquanto toca.
- **Sons:** ids `cs_*` com provisórios gerados; as vozes entram quando o autor gravar (`docs/voice/`).
- **Desempenho:** SC-001 no Chrome 75–79 FPS, p95 57–62; os custos subiram por igual também em sistemas que a 008 não tocou (máquina mais lenta nesta medição). A remedir na 011 (C-005).
- **Status:** ✅ 008 Complete.

---

### D-078 · 2026-09-29 · Spec 004 (arena e degradação) aprovada
- **Respostas do autor:** "1a 2a 3b".
- **Estágios:** acumulados no capítulo (0, 0, 1, 1, 2, 2, 3, 3, 3; chefe no 3), aplicados no fim da onda anterior, antes da loja; tema do Cap. 1 = a rasura; sem BLOOD na degradação; legibilidade em toda a área jogável (parecer do game-design-agent).
- **Ameaça:** sutil nos últimos 10 s, só na moldura, sem piscar no ritmo das telegrafias.
- **Obstáculos já no Cap. 1 (contra a recomendação, decisão do autor):** furo, banco, vitral, altar em dados; quantidade, posições e o que bloqueiam pelo rules-agent; colisão pelo mechanics-agent (inimigos comuns sem física); a sonda de balanceamento confere que as 9 ondas e o chefe continuam nas faixas aprovadas.
- **Status:** ✅ aprovada.

---

### D-079 · 2026-09-29 · Faixas do A/B dos obstáculos (SC-407)
- **Resposta do autor:** "1a" — aceitas as faixas propostas pelo rules-agent no T413 (a 005/006 não tinham faixa numérica).
- **Faixas:** (a) média das 9 ondas, letras/min e mortes/min em ±20% do jogo sem obstáculos; (b) nenhuma onda abaixo de 50% das letras/min sem obstáculos (8+ rodadas); (c) STUCK ≤ 5% na pior rodada; (d) SC-506 julgado pela forma da curva com × sem obstáculos.
- **Resultado:** passa com ressalva (onda 5 em 56%). Parecer: `docs/reviews/T413-rules-parecer.md`. Alavanca guardada: afastar os 4 furos 8 px para os cantos, só se o playtest confirmar ondas lentas.
- **Status:** ✅ aceita.

### D-080 · 2026-09-29 · Altar e banco saem de baixo do HUD; página sem dourado (T420)
- **Resposta do autor:** "1a2a".
- **Layout:** o design-agent viu o altar (290,24) sob o cronômetro e a barra do chefe, e o banco (304,328) sob a janela de combo e colado no atril; trocar os dois de lugar não resolvia. Novas posições: **altar (556,172)**, encostado na parede direita, espelhando o vitral; **banco (104,328)**, encostado embaixo à esquerda. Folgas 0 ou ≥ 40 px mantidas (T402).
- **Cores:** ornamentos e degradação só em tinta e pergaminho (INK, INK_SOFT, PARCHMENT_OLD, CHALK); sem GOLD no cenário (art bible §2). Brasa = anel INK_SOFT com miolo CHALK, sem BLOOD.
- **Tempo e movimento (animation-agent):** revelação em 4 degraus de 100 ms (dissolve em blocos 2×2, shader), sem hit-stop nem tremor; ameaça, poeira e brasas até 6 de cada, só na moldura, fora do HUD, números em `data/tuning/arena_ambience.tres`.
- **Status:** ✅ aceita. O SC-407 é medido de novo com o layout novo.

### D-081 · 2026-09-29 · Fechamento da 004 (arena e degradação)
- **Resultado:** a página segue o capítulo (estágios 0,0,1,1,2,2,3,3,3; chefe no 3), só piora no fim da onda (revelação em 4 degraus) e ameaça nos últimos 10 s; 7 peças jogáveis (colisão do escriba, inimigos contornando, Traça por cima, dash e tiro do Monge param, nada nasce ou cai dentro); página em camadas geradas por script (rasura na moldura, sem BLOOD), com a arte do autor por camada em `assets/arena/chapter_1/`.
- **SC-407:** dentro das faixas da D-079 com o layout da D-080 (`docs/reviews/T413-rules-parecer.md` §7).
- **SC-405 (desempenho):** 6 camadas de tela cheia custavam 4–7 FPS no estágio 3 → as camadas estáticas agora são montadas numa textura só fora do combate (estágio 3 = estágio 0). Build de antes da 004 e o atual, alternados na mesma sessão: iguais (68,5 × 67,2; 41,3 × 44,1 FPS). O p95 abaixo de 55 veio desta máquina hoje, também no build antigo → remedir na 011 (C-005).
- **Achados:** as sondas do chefe (`balance_probe boss`) travam no meio da fase 3 e ficam rodando; já acontecia antes da 004. Pendente para a próxima vez que a sonda do chefe for usada. Com mais de 2 Godot rodando, os números da sonda mudam 2–3×: medir com no máximo 2.
- **Para o playtest do autor:** ondas 1, 5 e 7 com as peças; esquivar Cruz, Duplo e Swipe perto do vitral e do banco; letras empurradas perto das peças (T413 §6).
- **Status:** ✅ 004 Complete.

### D-082 · 2026-09-29 · "A gameplay tá meio chata": ritmo das palavras, Graça (XP), instrumentos
- **Pedido do autor:** dropar vida; ganhar XP e subir de nível no meio da onda escolhendo dano/vida; loja com coisas mais importantes e armas novas.
- **Diagnóstico (game-design-agent):** só ~0,7 palavra por minuto (1 milagre a cada ~90 s); o ataque automático faz o jogo e nada cresce dentro da onda. XP/armas sem corrigir isso só "mascaram".
- **Respostas do autor:** "1a 2b e quando eu fecho uma palavra 3a e o jogo pausa 4a 5a 6b".
  1. **Primeiro a correção de ritmo:** palavras bem mais frequentes (alvo 1 a cada 10–20 s), só ajuste de números em dados; o autor testa jogando. Números pelo rules-agent.
  2. **XP ("Graça") vem de matar inimigos e de fechar palavras.**
  3. **Escolha no level-up:** o jogo pausa e 3 selos aparecem desenhados na página; escolha por tecla (1, 2, 3) ou clique (C-007 → "a").
  4. **Loja:** as melhorias pequenas (ímã, velocidade, vela…) viram escolhas do level-up; a loja fica com palavras, atril e instrumentos (emenda à 003).
  5. **"Armas" = instrumentos do escriba** (penas, tintas), 1 equipado por vez, que mudam como as palavras funcionam; 3 na demo.
  6. **Vida:** drop raro (pingo de cera), além das fontes atuais.
- **Plano:** (1) correção de ritmo → (2) feature nova 016 "Graça" (XP + level-up; emenda à 003) → (3) instrumentos na loja. Tudo antes da 011 (demo).
- **Correção de ritmo aplicada (item 1; rules-agent, autor "1a 2pode"):** `drop_tuning.tres` ímã seletivo **ligado**, `target_bonus` 10 → **25**, `letter_lifetime` 8 → **12**; `imp.tres` `letter_drop_chance` 0,6 → **0,8** (Pacote B, porque o A sozinho deu 2,25/min); Lentes do Copista +3/teto 9 → **+6/teto 18**. A letra marcada com o clique sempre vem, mesmo com o ímã seletivo (D-067; autor "1a").
- **Sonda (cast god, 3 rodadas por onda, 2 Godot por vez):** mediana das 9 ondas **0 → 3,5 palavras/min** (1 a cada ~17 s); ondas 1–4 em 4–5,5/min, ondas 5–9 em 1,5–3,5/min (SC-506 em 55%: as últimas ondas ficam atrás); sem god, a onda 1 passou a ser vencida com 4 palavras e a onda 9 do zero continua derrota. Muitos purges: o bot pisa em letras inúteis ao correr atrás da útil (um jogador desvia) — veredito final é o playtest do autor. Se as últimas ondas ficarem lentas: letras de abertura (2) e garantia da letra-alvo depois de 3 inúteis (precisam de código; rules-agent). A/B dos obstáculos (D-079) a refazer com os números novos.
- **Status:** ✅ direção aprovada; correção de ritmo aplicada; 016 e instrumentos a especificar.

### D-083 · 2026-09-30 · Spec 016 "Graça" aprovada
- **Respostas do autor:** "1a 2A 3A" — ~17 níveis no capítulo (2–3 por onda no começo, 1–2 no fim); a XP se chama **Graça** no jogo; spec aprovada, começar pela Fase 0.
- **Números (rules-agent):** 6 de Graça por letra (combo ×1,5), inimigos 1–2, campeão ×5; curva 30 + 6·(n−1); 8 bênçãos com teto (Tinta Consagrada +15% até +60%, só dano); loja com 2 vagas de item, dízimo 5, reroll 3+2; pingo de cera 1%, 12 s.
- **Sistema (mechanics-agent):** `GraceLedger` (GameState), `BlessingOffer`, `GraceFlow` (FSM no Main, relógio real), `GraceSeals`, `GraceBar`, `RunUpgrade` comum à loja; `damage_mul` × `heal_mul` separados (a Tinta não aumenta a cura); a Pausa não despausa por baixo dos selos; sorteios próprios (não mexem nas letras).
- **Status:** ✅ aprovada.

### D-084 · 2026-09-30 · Palavras de ataque matam quem estiver no alcance (pedido do autor)
- **Pedido do autor:** "quero que todos os inimigos que entrem no range do LUX morram, e que sirva para todas as outras palavras". Hoje o dano sai só no instante da conjuração (o raio visível não fere quem entra depois) e os ataques que ficam na tela batem em intervalos.
- **Respostas do autor:** "1a 2a 3a" —
  1. **Inimigo comum morre na hora**, qualquer que seja a vida, enquanto o ataque estiver na tela (quem já está e quem entra); **campeão** leva dano forte (morre em 2–3 acertos); **chefe** leva o dano normal com o filtro que já existe.
  2. Vale só para as **palavras de ataque** (e combos de ataque); as de ferramenta (PAX, AQUA, VITA, SPIRITUS, DOMINUS…) continuam como são.
  3. O jogo fica mais fácil: **medir com a sonda** e o rules-agent reequilibra em dados (sem desfazer o pedido).
- **Mouse nos menus:** pedido no mesmo recado ("quero que seja possível mexer com o mouse no menu, clicar nos botões") — plano a aprovar.
- **Pareceres:** `docs/reviews/D084-rules-parecer.md` (campeão: golpe de 40% da vida por conjuração, `hp_mul` 4 → 6; janela letal = `duration` em dados) e `docs/reviews/D084-mechanics-parecer.md` (`KillZone` + `KillZones`, aplicadas pelo EnemyManager com a SpatialHash; o chefe nunca é tocado pela zona).
- **Respostas do autor (2º recado):** "1sim 2b 3a 4a" — mouse nos menus aprovado; **LUX dura 0,5 s** na tela; **MISERERE é ataque**; lista fechada: ataque = LUX, IGNIS, CRUX, MORTIS, PURGO, SANCTUS, ANGELUS, CAECITAS, VAPOR, FLAMMA, MARTYRIUM, REQUIEM, MISERERE; ferramenta = PAX, AQUA, VITA, SALVATOR, LUMEN, FIDES, GLORIA, DOMINUS, SPIRITUS (VERBUM herda a da palavra repetida).
- **Status:** ✅ direção aprovada; ordem: medir a 016 → mouse nos menus → zonas letais (6 fases) → fechar a 016.

### D-085 · 2026-09-30 · Arsenal sagrado: armas, poções e palavras como "ultimate" (emenda à game bible)
- **Pedido do autor:** XP proporcional à força do inimigo; loja vende armas e poções; level-up melhora armas, status e poções; palavras viram "ultimate" (mais raras e bem mais fortes); inventário de 2 armas trocáveis na onda (ex.: Bíblia = laser mirado contínuo, Crucifixo = automático forte); 6 armas iniciais; 4 poções; itens atuais entram no sistema novo. Parecer: `docs/reviews/D085-game-design-arsenal.md` (AJUSTAR).
- **Respostas do autor:** "1a 2a [+ menu de escolha da letra] 3a 4[teclas 1/2] 5a 6a 7a[teclas 3–6] 8a 9a 10a 11a 12a".
  1. **Pilar 1:** "Escrever é o milagre. As armas seguram a linha; as palavras decidem a luta." Armas só em tinta (INK/INK_SOFT/CHALK); **dourado exclusivo das palavras**.
  2. Palavras raras porque **caem menos letras**; e, novo: **quando uma letra cai, abre um menu de escolha com 3 opções e 2,5 s para escolher; 1 das opções completa a palavra** (detalhes: C-008).
  3. Alvo ~**1 palavra/min** (1–2 por onda).
  4. Inventário de 2 armas; **só a ativa ataca; as teclas 1 e 2 escolhem a arma**.
  5. Anselmo começa com a **Pena**; o 2º espaço enche na 1ª loja.
  6. Armas: **Pena do Copista, Bíblia, Crucifixo, Rosário, Turíbulo, Aspersório**.
  7. **4 poções** em cargas compradas na loja, **teclas 3, 4, 5 e 6**, sem recarga: Óleo da Unção, Água Benta, Vinho do Fervor, Tinta Iluminada.
  8. Loja: armas + poções + apócrifos.
  9. Estante Nova e Tinteiro Duplo viram status do level-up.
  10. A arma é **Rosário**; a bênção vira **Escapulário**.
  11. Ordem: D-084 Fase 4 → fechar 016 → emenda da game bible → 017 "Arsenal sagrado" (fatia Bíblia + Crucifixo) → playtest → outras armas → 018 Poções → passada de ritmo.
  12. Armas e poções antes da demo (011).
- **Revoga/muda:** D-082 item 1 (3,5 palavras/min) e item 5 (instrumentos → armas); 016 FR-1602, FR-1613, FR-1614 (conteúdo dos selos e loja). Os selos usam 1/2/3 só com o jogo pausado — sem conflito com armas/poções.
- **Status:** ✅ direção aprovada; C-008 aberto.

### D-086 · 2026-09-30 · Fechamento da 016 (Graça) e da D-084 (zonas letais)
- **016:** Graça (mortes e palavras), subir de nível com pausa e 3 selos (fila, trava de 0,4 s, 0,5 s de invulnerabilidade, Pausa por cima), barra no HUD, pingo de cera, 7 itens da loja viraram bênçãos, Tinta Consagrada só no dano. Mouse nos menus entrou no caminho (D-084).
- **D-084:** as 13 palavras/combos de ataque abrem zonas letais (linha, círculo, cruz girada, pontos, tela com anel) aplicadas pelo EnemyManager; campeão leva 40% da vida por conjuração (`hp_mul` 6); chefe intocado pela zona.
- **Medições:** SC-001 igual ao build de antes da 016 (alternado no Chrome). Sonda da Graça: nível 14 no capítulo, 44% da Graça de palavras — a meta (15–20; 2/3 de palavras) é revista na passada de ritmo da D-085, que torna as mortes a fonte principal.
- **Sonda:** `only_waves` (termina na onda 9; "noboss" abria o chefe porque contém "boss") e o time_scale volta a 4× depois do hit-stop.
- **Abertos:** playtest do autor (T1654, C-004, C-006); a sonda do chefe trava na fase 3 (D-081).
- **Status:** ✅ 016 Complete; D-084 feita. Próximo: emenda da game bible (D-085) e spec da 017.

### D-087 · 2026-09-30 · Spec 017 "Arsenal sagrado" aprovada
- **Pareceres:** `docs/reviews/T1700-{rules,mechanics,design,animation}-parecer.md` (+ `T1700-design-maps.json`).
- **Respostas do autor:** "1a 2a 3a 4b 5a 6a 7a 8a 9a 10a 11a" —
  1. **Shift** esvazia o atril sem heresia (as letras se perdem).
  2. **Traça** rouba a última letra do atril ao encostar no escriba e a devolve ao morrer.
  3. Durante o menu da letra o **escriba fica parado** (setas e Espaço são do menu).
  4. **Sem marca** nas letras úteis do menu: o jogador lê o atril e decide.
  5. **Bíblia** sempre ligada quando ativa.
  6. Bíblia **×1,5** contra campeão e chefe (`precision_mul`).
  7. **Lentes do Copista:** +0,5 s no menu (teto +1 s).
  8. **LUMEN:** chance de letra ×2 por 10 s.
  9. Comprar arma com os 2 espaços cheios **substitui a ativa** com confirmação.
  10. Fila de letras: **1**; o excedente se perde.
  11. Spec aprovada; começar pela Fase 1.
- **Status:** ✅ aprovada.

### D-088 · 2026-09-30 · 017 Fase 2: Crucifixo projétil, Bíblia nos 2 mais próximos
- **Respostas do autor:** "1b 2a 3a" —
  1. **Crucifixo é projétil de verdade** que atravessa (pode errar quem se mexe), não linha instantânea.
  2. **Bíblia** fere os **2 mais próximos** ao longo do raio (o chefe e o campeão disputam a vaga).
  3. **Congelamento de 50 ms** em quem a cruz acerta, já nesta fase.
- **Números (rules-agent, 2026-09-30):** Crucifixo 360 px/s, alcance 140/180 (× `travel_mul` 1,25), raio de acerto = largura/2 (4/6), atravessa até 8, cada inimigo 1× por cruz; antecipação 0,2 s **dentro** do intervalo. Bíblia: o "tick" é o relógio de cada inimigo, checado todo frame (0,33 s vale 0,33 s); `precision_mul` 1,5 com a fração guardada por alvo (1, 2, 1, 2…).
- **Sistema:** `ZoneShape` (base do `KillZone`), `WeaponZone`/`WeaponZones` (não letal, no mesmo passe do `EnemyManager`), `SpatialHash.query_segment`, `Aim`, `BeamWeapon`, `EnemyManager.query_hit_pierce` + `freeze_left`.
- **Status:** ✅ implementado; espera o playtest (SC-1705).

### D-089 · 2026-09-30 · HUD novo (T1800)
- **Pedido do autor:** "melhore este HUD, pesquise como construir um HUD da melhor forma… e aplique". Pesquisa + parecer: `docs/reviews/T1800-hud-parecer.md` (design-agent), maquetes em `docs/reviews/img/t1800_hud_*`.
- **Sistema:** painel único `UiStyle.draw_plate` (borda INK, luz CHALK, assento INK_SOFT), barra `UiStyle.draw_bar` (trilho e preenchimento opostos ≥ 3:1), grade 6/4/3 px. Painéis: A vida + Graça (Graça em 10 segmentos sobre trilho INK_SOFT), B tempo, C tinta, D atril (+ dicas em painel), E armas.
- **Muda a T1700:** o nível da arma vai para a etiqueta de baixo à direita (sem contas); a **recarga** aparece numa barra sob cada arma (`WeaponSlot.charge`).
- **Muda a 006:** barra do chefe no topo (Y18), no lugar do tempo.
- **Menu da letra (Fase 3):** limite de cima `My ≥ 44`.
- **Arena:** capitular "I" removida dos ornamentos (game-design: aprovado). **Banco não mudou:** o game-design pediu ajuste (a posição proposta deixa fresta de ~15 px que prende no dash) — volta na 018, com rules-agent + sonda, antes do painel das poções cobrir o banco.
- **Status:** ✅ aplicado; GUT 502/502.

### D-090 · 2026-09-30 · 017 Fase 3: menu da letra (as letras saem do chão)
- **Sistema:** `LetterMenu` (filho do LetterField; FSM IDLE/OPEN/GAP) + `LetterOfferRoll` + `LetterMenuView` + `LetterMenuTuning` (`data/tuning/letter_menu.tres`). Morte de inimigo → `menu.offer()`; 3 opções (1 continua a palavra; 2 pelo peso base, 5% raras); 2,5 s de jogo a ×1 (o relógio desconta a câmera lenta e o hit-stop); câmera lenta ×0,2 em degraus (0,5→0,2 em 50 ms; 0,5→1 em 100 ms) pelo `TimeScale` (dono `letter_menu`); fila 1; 0,25 s entre menus; trava de 0,1 s; teclas `letter_prev/next/pick` (← → / A D, Espaço/Enter) + clique; escriba parado (`GameState.letter_menu_open`).
- **Números (rules-agent T1700):** chance de letra 0,04×HP (Traça 0,04 · Diabrete 0,08 · Borrão 0,12 · Monge 0,16 · Gárgula 0,20) × `WaveData.letter_drop_mul` (1,00 … 0,38) × LUMEN; campeão = letra garantida rara; no máximo 1 letra por conjuração; REQUIEM `guaranteed_drop_cap` 2; LetterSafety do chefe 8 s sem menu.
- **Respostas do autor aplicadas (D-087):** Shift esvazia o atril sem heresia; Traça rouba a última letra ao encostar e a devolve (sempre, na frente da fila) ao morrer; sem marca nas letras úteis; Lentes +0,5 s (teto +1); LUMEN chance ×2 por 10 s.
- **Saíram:** `Letter` e o pool, ímã de letras, marcação por clique, letras do stress (SC-001 agora mede 300 inimigos + 200 projéteis).
- **Medido (sonda onda 1, god):** o menu abre e a sonda conjura; com a chance normal saíram ~2 menus/min (alvo 5–6,5): as armas matam menos que o rules-agent supôs. Vai para a passada de ritmo.
- **Fora desta fase:** o voo da letra até o atril e o pop de 50 ms (animation-agent) ficaram simples (a letra entra direto).

### D-091 · 2026-10-01 · 017 Fase 4: selos de arma, loja de armas e ímã reverso
- **Selos (`SealPool`):** cada selo sorteia o tipo — arma ativa 30%, arma guardada 15%, status 45%, ímã reverso 10% (se comprado) — e o tipo sem nada a oferecer sai; no máximo 1 selo por espaço; pelo menos 1 selo de arma quando houver arma para subir. Os selos de arma/ímã são `BlessingData` com `kind` (`weapon_level`, `passive_level`) montados na hora; a conta desta escolha é CHALK (sem GOLD).
- **Bênçãos:** Estante Nova (+1, teto 8) e Tinteiro Duplo (+0,08, teto 0,24) saíram da loja e viraram selo; a Pedra-Ímã saiu; o Rosário aparece como Escapulário (id `rosary` mantido).
- **Loja:** cartas de arma (Bíblia, Crucifixo; base 6) e do ímã reverso (8, compra única); o que já se tem não aparece; 1ª loja com o espaço 2 vazio = as 2 vagas são armas; com os 2 espaços cheios, o 1º Comprar pergunta "TROCAR <arma>?" e o 2º troca a ativa (D-087 item 9). Dízimo 5 → 6.
- **Ímã reverso (`RepulseData` + `RepulseAura`):** níveis 6,0/5,0/4,5/4,0/3,5 s · raio 56/56/64/72/72 · empurrão 40/40/48/48/56 · dano 0/0/1/1/2 (rules-agent §6); campeão leva meio empurrão; o chefe não é empurrado, só ferido; sem ninguém no raio, o pulso espera; anel INK_SOFT abaixo dos inimigos.
- **Status:** ✅ GUT 513/513.

### D-092 · 2026-10-01 · 017 Fase 5: Rosário, Turíbulo e Aspersório
- **Rosário (`OrbitWeapon`, zona POINTS):** contas 2/3/3/3/4, dano 1/1/1/2/2, raio 32/32/40/40/40, volta 1,6 s (1,3 no nível 5); cada inimigo leva no máximo 1 acerto a cada 0,4 s; a 1ª conta é a cruz; a troca recolhe as contas.
- **Turíbulo (`SwingTrailWeapon`, zonas CIRCLE + POINTS):** com inimigo ao alcance, balança num arco de 150° alternando os lados (0,4 s), raio 40/40/40/52/52, intervalo 1,2 s (1,0 no nível 5), dano 1/1/2/2/2; a cabeça fere 1× por balanço; nuvens de incenso a cada 0,1 s (teto 25) que ferem a cada 0,5 s e duram 1,5/2,5 s; o rastro continua depois da troca.
- **Aspersório (`fan`):** mirado, leque de 50° com 4/5/5/5/5 gotas, alcance 64/64/80/80/80, intervalo 1,10/…/0,85, dano 1 (2 no nível 5), não atravessa; só atira com inimigo ao alcance.
- **Divergências resolvidas pelo número do rules-agent:** arco de 150° com raio 40 (o animation-agent previa ±60° e corrente de 16 px); volta do Rosário 1,6 s (animation: 1,4 s).
- **Proposta sem parecer:** velocidade das gotas do Aspersório 240 px/s (o rules-agent não deu número) — conferir na passada de ritmo.
- **Loja:** as 3 armas a 6 de tinta. **Stress:** `?stress=arsenal` (Turíbulo + Rosário no nível 5, trocando a cada 2 s): 60 FPS no desktop.

### D-093 · 2026-10-01 · 017 Fase 6 e fechamento: palavras ultimate, sonda por arma, ajuste da onda 1
- **Palavras como ultimate (T1740, rules-agent T1700 §3):** medidas ×1,5 e dano ×2,5 (tabela; PAX/AQUA/DOMINUS/SPIRITUS pela regra geral); `word_feel.tres` (ataque 100 ms + 2 px, tela/combos grandes 100 ms + 3 px, ferramenta 60 ms); filtro do chefe 250/500; golpe no campeão 0,5; Graça 1/2/3/5/6 por inimigo, 10 por letra, curva 40 + 24.
- **Sonda por arma e por onda (T1742):** achou o bug do float32 (Crucifixo nos níveis 2–4 não atirava; relógios em 64 bits). Parecer `docs/reviews/T1742-rules-parecer.md`: Pena 2 gotas desde o nv 1 (0,80/0,70/0,60/0,60/0,55; 3 gotas no nv 4–5), onda 1 `spawn_rate_end` 1,6 e `letter_drop_mul` 1,2, Rosário 3 contas e raio 36/40/44, Bíblia tick 0,70/0,60/0,55 nos nv 1–3, Turíbulo rastro 1,0/1,5/2,0 nos nv 1–3. Depois: a Pena vence a onda 1 sem god em 3 de 3.
- **Não medido:** SC-001/SC-1703 no Chrome (o Chrome do Claude não alcança o servidor local; com o autor). Desktop: `?stress=bible` e `?stress=arsenal` a 60 FPS.
- **Fica para a passada de ritmo (018):** Rosário nv 1 fraco; menus/min com muita variação; onda 9 4–4,7 menus/min; Crucifixo nv 1 errando; velocidade do Aspersório; eficiência da Pena; vida do chefe.
- **Status:** 017 ✅ Complete (GUT 518/518). Pendentes do autor: playtest (SC-1705) e medição no Chrome.

### D-094 · 2026-10-01 · 018 Poções: direção aprovada
- **Parecer:** `docs/reviews/T1800G-game-design-018.md` (game-design-agent, AJUSTAR).
- **Respostas do autor:** "1a 2a 3a 4a 5a 6a" —
  1. **Tinta Iluminada = "Iluminura":** abre um menu da letra na hora (regras de sempre; bloqueada com menu aberto ou na fila).
  2. **Selo de poção = +1 nível da poção** (efeito maior), só das já compradas.
  3. **Começa com 1 Óleo da Unção.**
  4. **Loja:** prateleira fixa de poções, separada das vagas sorteadas.
  5. **Água Benta:** heresia dentro do círculo apaga o círculo; parado no círculo não recupera vela.
  6. **Banco da arena** decidido na Fase 1 da 018, antes do painel das poções.
- **Pedido do autor no mesmo recado:** "subir do nível 1 para o 2 está demorando muito — encurte" → custo do 1º nível da Graça (rules-agent, na 018).
- **Status:** ✅ direção aprovada; números, sistema e arte nos pareceres T1801.

### D-095 · 2026-10-01 · 018: subir de nível com feixe de luz e câmera lenta; VITA 2 velas; Iluminura
- **Pareceres:** `docs/reviews/T1801-{rules,mechanics,animation}-parecer.md` (design em andamento).
- **Respostas do autor:** "1a 2.5seg se camera lenta e uma barra de carregamento mostrando quando acaba a camera lenta. 2a. 3a. 4a. 5a" —
  1. **Subir de nível:** um feixe de luz desce sobre o Anselmo e o jogo entra em **câmera lenta por 2,5 s**, com **uma barra mostrando quando a câmera lenta acaba**; depois pausa e os 3 selos aparecem (como hoje).
  2. **Feixe dourado** (a cor da Graça).
  3. **VITA acende 2 velas** (o Óleo da Unção fica com 1; SALVATOR continua 3).
  4. **Iluminura por nível:** nv 1 = 1 das 3 letras continua a palavra; nv 2 = 2; nv 3 = 3.
  5. **Regras do mechanics-agent:** beber Água Benta de novo recentraliza o círculo; o Vinho fica na arma ativa do momento; atordoado não bebe.
- **Também (rules-agent T1801):** curva da Graça `level_costs [16, 40]`, base 8, passo 28 (1º nível aos ~15 s, pedido D-094); banco da arena em (184, 272); poções com 3 níveis, tetos e preços do parecer.
- **Arte:** os 4 ícones do HUD foram desenhados com a skill `pixel-art-gen` (pedido do autor), em `docs/reviews/T1801-potion-icons.json`.

### D-096 · 2026-10-01 · 018 Fase 6: passada de ritmo (fechamento da 018)
- **Sonda (T1819):** `balance_probe` ganhou `kite` (o bot mantém distância = 0,8 × alcance da arma ativa) e `potions` (bebe Óleo com 1 vela, Água Benta cercado, Vinho com > 5 vivos, Iluminura com palavra começada; compra poções até 40% da tinta da visita; não troca a arma que já tem). Linhas novas: RHYTHM (palavras/min, menus por onda, nível final, nível da arma por onda, tinta, gasto em poções) e POTIONS.
- **Escolha automática dos selos** (`GraceFlow._auto_pick_all`, usada só pela sonda e pelo stress): prefere o selo de arma. Antes pegava o 1º, e a garantia de arma fica por último, então uma rodada travou a Pena no nv 2 (156 vivos, a Traça comeu 25 letras, 0,08 palavras/min).
- **Parecer:** `docs/reviews/T1820-rules-parecer.md` (rules-agent). Aplicado:
  1. Crucifixo `interval` 1,6/1,4/1,4/1,4/1,2 → **0,8/0,7/0,6/0,6/0,5** (onda 1 sem god 0/3 → 3/3; nv 1→5 agora cresce: 85/86/106/119/129 mortes/min; o nv 3 deixou de ser morto).
  2. Loja `price_growth` 0,10 → **0,08**; `wave_clear_ink` 6 → **7** (compras 5–6 → 7/7/7).
  3. Onda 1 `Group_late.spawn_rate_end` 1,6 → **1,5** (Pena sem god com poções 3/5 → 5/5; Aspersório 3/3).
  4. Onda 9 `letter_drop_mul` 0,38 → **0,45** (menus/min da o9 3,9 → 6,0).
- **Medido no fim** (capítulo ×3, god): palavras/min 0,83/1,08/1,08; 1º nível 15–16 s; nível final 15–16; tinta 80/92/101; poções ≤ 20% da tinta; mortes/min por arma ≤ 1,25× a mediana nas ondas 1/5/9.
- **Ressalvas para o playtest (SC-1705):**
  - a arma ativa chega ao nv 5 nas ondas 3–4 (o bot sempre pega o selo de arma);
  - os menus da onda 1 ficaram em 8–10/min na última bateria (alvo 5–6,5; na anterior foram ~6,3), com a alavanca `wave_01.letter_drop_mul` 1,2 → 1,0 se o autor sentir excesso;
  - Pena e Aspersório rendem ~0,6× das armas de área na onda 5 (a regra não tem piso).
- Não medidos pela sonda: eficiência da Pena, acerto do Aspersório, campeão, banco com/sem, desempenho (o Crucifixo nv 5 dispara ~2,4× mais cruzes; conferir `?stress=arsenal`).

### D-097 · 2026-10-01 · Áudio: os 101 efeitos do ElevenLabs ligados
- **Gerador:** `tools/gen_audio_data.gd` lê `docs/audio/sfx_manifest.json` e cria o SoundData de cada efeito sem evento (categoria → vozes, recarga, barramento e tom).
- **Sinais:** o `EventBus` ganhou um bloco "Áudio" com 21 sinais (armas, ataques do chefe, inimigos, UI, loja, menu da letra), emitidos onde o momento acontece.
- **Loops e barramento:** o `AudioManager` liga os sinais, toca os loops com início e fim explícitos e manda falas e latim para o barramento novo `Voice`, que abaixa a música por compressor (sidechain).
- **Poções:** os 4 sons foram mapeados pelo id da poção (o manifesto usava 1–4).
- **Teste:** `tests/integration/test_audio_events_018.gd`.
- **Opções e menu:** linha FALAS nas Opções (volume do `Voice`); passa-baixa de 1,2 kHz na música com o menu da letra aberto.
- **Pendente:**
  - ~~13 falas em latim~~: geradas pelo autor com `tools/gen_latin_voices.py` (2026-10-01); as 24 palavras e a heresia têm voz;
  - camadas 2–3 da música (plano pago).

### D-098 · 2026-10-01 · Feedback do playtest do autor (1ª rodada)
- **Recado:** efeitos altos demais, botões sem som, efeitos faltando; level-up com 1 s de câmera lenta; menu da letra pausando o jogo; dicas de letra fora (só o TAB); painel de teclas à esquerda; mais falas (dano, nível, morte); cutscene sempre; letras mais difíceis ("as palavras são um milagre"); Bíblia seguindo o mouse até a ponta; upgrades melhores; diálogo do vendedor; música do Gemini (menu com bispos e eco; batalha com clímax ao avançar a onda; chefe).
- **Respostas do autor** ("1a2b3b … 4b5a"):
  1. ~1 palavra a cada 2 min.
  2. O selo deixa escolher o atributo da arma (cadência, quantidade, tamanho…).
  3. O menu pausa, com os 2,5 s correndo, uma barra de carregamento embaixo das cartas e clique do mouse.
  4. Painel de teclas nas 2 primeiras ondas; depois a tecla H mostra e esconde.
  5. Fala de dano no máximo a cada ~20 s; nível e morte sempre.
- **Fase 1 (som), feita:**
  - **Mixagem:** `tools/mix_sfx.py` + `data/audio/mix_targets.json` (volume médio por categoria; os frequentes em −34 dB RMS, palavras em −23).
  - **Som de interface:** `UiScreen.ui_sound` em toda entrada que uma tela consome (Menu, Opções, Capítulo, Personagem, Códex, Pausa/Fim, loja, selos).
  - **Efeitos novos:** 14 no manifesto, gerados por `tools/gen_missing_sfx.py`, que o autor roda; os sinais já estão ligados.
  - **Música** (`MusicData.mode = sections`): batalha calma → crescendo (40% da onda) → clímax (75%), volta à calma no fim da onda; menu nas telas de menu; chefe ao surgir o Asmodeus. Volume −12 dB, para ajustar de ouvido.
- **Fase 2, em andamento:**
  - `levelup_slow_time` 2,5 → 1,0.
  - Menu da letra com `pause_game`: pausa a árvore, conta em tempo real, só despausa o que pausou, congela com o Esc/selos/loja. Substitui a câmera lenta da D-090.
  - Barra do tempo do menu (design-agent): 94×9, INK sobre CHALK, 23 degraus; no fim a moldura engrossa e o preenchimento pisca. O clique na carta funciona com o jogo pausado.
  - Dicas de letra ao lado do atril removidas (o TAB continua); retângulos do HUD recalculados.
  - Painel de teclas à esquerda (`HelpKeys`, ficha UI_HELP_KEYS): cheio nas ondas 1–2, recolhe na 3, tecla H (`help_toggle`, nas Opções) alterna; segue o remap.
  - Cutscenes c1_01 e c1_02 tocam sempre (`"play": "always"`).
  - Bíblia: o raio vai até o cursor, entre `beam_min_length` 32 e o alcance do nível.
  - Falas (story-agent): 38 novas em `data/barks/barks.json` (Anselmo: dano, nível, morte; Frei Ambrósio, o vendedor: abrir, comprar, sem tinta, sair). `BarkDirector`: sorteio no grupo sem repetir, intervalo por grupo (dano 20 s; nível e morte sempre), balão fixo do vendedor na loja.

### D-099 · 2026-10-01 · Letras raras, upgrades por atributo e combo guardado (respostas do autor)
- **Respostas:** "1a2b3a4a" — Frei Ambrósio aprovado; combo com palavra guardada (2b); upgrades por atributo como a T1830 (3a); a voz do vendedor escolhida pelo Claude (George; o Bill já é o Abade).
- **Letras (T1830 Parte 1):** `letter_drop_mul` ×0,55 (o1 0,75 e o2 0,56 pela reserva, porque a 1ª palavra chegava tarde); `per_letter` 16. Medido em 8 capítulos: 0,40–0,48 palavras/min, nível final 15–16.
- **Upgrades (T1830 Parte 2; mechanics-agent):**
  - `WeaponData` = `base` + `upgrades: Array[WeaponUpgradeData]` + `max_upgrades` 6.
  - `WeaponSlot.ranks` com cache; nível = 1 + compras (teto 7).
  - `SealPool` sorteia um atributo livre (até 3 selos da mesma arma, nunca o mesmo atributo 2×). O selo mostra o atributo e "ARMA AGORA > PRÓXIMO".
  - Lentidão de arma por `EnemyManager.apply_slow`: a mais forte vence; metade no campeão; o chefe é imune.
  - `?wlevel=N`, sonda e stress sobem N−1 postos pela ordem dos dados.
  - Stress no teto sem regressão (arsenal p95 55, crucifixo 51).
- **Pendente:**
  - ficha do design-agent para o cartão do selo (hoje o texto fica nas linhas do nome e da descrição; a seta é ">");
  - ~~combo guardado~~ feito (abaixo);
  - remedir o ritmo com os atributos.

### D-100 · 2026-10-01 · Combo pela palavra guardada (respostas do autor "1B2A3A")
- **Regra:**
  - A palavra pronta sai do atril sozinha para a guarda (1 espaço; `WordGuard` no `LetterField.settle()`).
  - Espaço com a parceira pronta no atril → COMBO (gasta as duas).
  - Espaço com uma palavra sem par no atril → conjura a do atril; a guardada fica.
  - Espaço com o atril vazio ou pela metade → conjura a guardada; as letras ficam e não há heresia.
  - Sem guardada, atril pela metade → heresia, como antes.
- **A janela de 2,5 s saiu:** o `ComboBook` só resolve pares e parceiras; a barra 48×3 do HUD saiu e o nome do combo continua.
- **Guarda imune:** heresia, Traça, Rasura e fim de onda não mexem na guardada.
- **Graça e Códex:** a guardada gasta num combo dá a Graça das letras dela (`stored_word_released`); o Códex a descobre ao guardar.
- **Sinais:** `word_stored(word, rare_count, partners)` e `stored_word_released(word, cause)` substituem `combo_window_opened/closed`.
- **Som:** ao guardar toca a nota de "palavra pronta"; o tique toca só quando há parceira de combo.
- **HUD provisório:** `HudWordGuard` em (404,310) 60×28, latim em GOLD; moldura GOLD quando o combo está pronto. Falta a ficha do design-agent (o agente parou no limite da API).

### D-101 · 2026-10-02 · 010 Personagens: decisões do autor ("1a2a3a4a5a6a6b7b8b9a10a")
- **Pareceres:** game-design-agent (010).
- **Passivas:**
  - Hildegarda: guarda de palavra com 2 espaços.
  - Tomé: sem atordoamento na heresia e 2 velas.
  - Iluminador: letra dupla.
  - Beda: atril 4 e +20% de velocidade.
  - Anselmo: a base.
- **Arma inicial:** Anselmo Pena, Hildegarda Aspersório, Tomé Turíbulo, Iluminador Bíblia, Beda Crucifixo. A Pena não vai para a loja (só o Anselmo a tem).
- **Poção inicial:** Óleo, Água Benta, Óleo, Iluminura, Vinho.
- **Desbloqueio misto com o Grimório (6b; o autor marcou 6a e 6b, valeu a última, a confirmar):** Hildegarda vencer o Cap. 1; Tomé 10 heresias sobrevividas; Iluminador 3 combos diferentes descobertos; Beda as 7 palavras-base descobertas.
- **Abertura curta própria para cada escriba (7b)** e falas com voz para os 4 agora (8b).
- **Na história, desbloquear = reescrever o nome do escriba no registro do mosteiro (10a).**
- Os números vão para o rules-agent.

### D-102 · 2026-10-02 · 012 Capítulo 2: decisões do autor ("1a2a3a4a5a6a")
- **A Mãe das Traças é imune às armas.** As armas matam as crias, que soltam muitas letras na luta; só as palavras ferem a Mãe. Meta: ~1 palavra a cada 20–30 s e luta de 3–4 min.
- **9 ondas + chefe;** a game bible §3.8 dizia 10.
- **C2-01 na entrada do chefe;** o capítulo abre com a virada de página.
- **Eat_Page:** uma palavra que acerta a Mãe durante o aviso cancela a mordida; a página não volta a crescer; a borda comida só empurra.
- **Arena:** biblioteca roída, com os obstáculos atuais e mais furos.
- **Inimigo novo:** Traça-Mãe pequena, que estoura em traças comuns.
- **Ordem:** os capítulos antes da demo (pedido do autor).

### D-103 · 2026-10-02 · 019 Relíquias e venda (pedido do autor; "1a2a3a" + "5a" lido como 4a)
- **Relíquias:** passivos que disparam sozinhos, comprados na loja, em 2 espaços, que sobem por selos de atributo como as armas.
- **As 5 relíquias:**
  - Ímã Reverso: o pulso passa a ser a cada 5 s no nível base.
  - Sino de Vésperas: atordoamento em pulso.
  - Sal Bento: aura de lentidão.
  - Relicário do Santo: explosão ao tomar dano.
  - Selo de Cera: escudo de 1 golpe.
- **Venda na loja:** poções, relíquias e armas; quanto mais upadas, mais valem.
- **Ordem:** a 019 vem antes da 010 e da 012, porque as duas usam a loja e os selos.

### D-104 · 2026-10-02 · 019 Relíquias e venda implementada (respostas do autor "1b2a3a4a")
- **Pareceres:** rules-agent T1900, mechanics-agent e design-agent (HUD, alforje, ícones).
- **Relíquias:** `RankedSlot` (postos com cache) é compartilhado com as armas; `RelicData`/`RelicSlot`/`RelicTuning`; `RelicRunner` substitui o `RepulseAura`. Atordoamento do Sino com coroa CHALK. O Selo de Cera fica depois da FIDES no `take_hit`.
- **Venda:** `Shop.sell_*`; trocar arma ou relíquia vende a que sai; com espaço de arma vazio, a loja garante uma arma.
- **Respostas do autor:** 1b (Selo de Cera 25/22/20 s); 2a (troca = venda automática); 3a (garantia de arma); 4a (nomes curtos no selo).
- **HUD e loja:** 2 células de relíquia; alforje com 8 células e escolha de qual relíquia sai.
- **Ícones:** pixel-art-gen.
- **Aberto:** com relíquias saem ~metade das palavras (T1900 §Medição) — rules-agent e playtest.

### D-105 · 2026-10-02 · 010 Personagens implementada (respostas do autor "1a…8a")
- **Pareceres:** rules-agent T1000, mechanics-agent e story-agent.
- **Respostas do autor:**
  - Tomé com 2 velas e Óleo ×2;
  - Hildegarda: as 2 guardadas parceiras fazem combo; sem par, sai a mais nova;
  - Iluminador 24%;
  - desbloqueio misto (6b confirmado);
  - abertura própria no lugar da C1-01/C1-02;
  - falas do escriba na C1-03/C1-04 (variantes);
  - game bible §3.11 atualizada.
- **Código:**
  - `PlayerData` com nome, passiva, falante, abertura, guarda, poções e passivas; `UnlockData`; `CharacterRoster`.
  - Passivas lidas pelo `RunStats`.
  - O `Main._enter_tree` usa `GameState.picked_character`.
  - `WordGuard` em lista.
  - `Progress` (autoload) com latch e anúncio; só conta no jogo de verdade.
  - Tela de Personagem pelo progresso.
  - `pending_intro(chapter, scribe)`; falante `"@player"`.
  - `BarkDirector` só faz falar o escriba da partida.
  - `?char=<id>` e sonda `char=`.
- **Save:** sonda, GUT e ferramentas não gravam no Grimório nem no progresso.
- **Pendente:**
  - sprites e closes próprios dos 4 (hoje usam o placeholder do Anselmo e os bustos por script);
  - vozes das 92 falas novas (o autor roda `tools/gen_bark_voices.py`);
  - medição por escriba (T1000 C1–C12).

### D-106 · 2026-10-02 · Beda começa com 4 velas (rules-agent; autor "1a")

- **Medido** (sonda `cast wave=1 kite potions`, sem god): Anselmo 3/3, Iluminador 3/3, Hildegarda 3/3, Tomé 2/3, **Beda 3/6** (morre aos 49–55 s por 3 golpes; a onda acaba em ~61 s). As kills/min dele (~46) estão na faixa, então o problema é o dano recebido.
- **Decisão:** `data/player/beda.tres` `start_candles` 3 → 4. Arma, atril e velocidade não mudam.
- **Aceitação:** ≥ 8/10 na onda 1 sem god (C1). C2 (onda 9 sem god: derrota 3/3, tempo vivo ≤ 1,5× o Anselmo). Se der < 8/10: `iframes` 1.25.
- **Remedido (10 rodadas):** 4 velas = **7/10**; 4 velas + `iframes` 1.25 = 5/10 (ruído; o iframes não ajuda e foi revertido). C2 ok: onda 9 sem god perde 3/3, tempo vivo 19–26 s (igual ao Anselmo). Fica 4 velas; C1 do Beda segue **aberto** (playtest do autor / rules-agent).
- **Sonda:** passou a mirar sozinha a arma mirada inicial (Bíblia, Aspersório); antes o Iluminador e a Hildegarda morriam sem abater nada.

## Conflitos abertos

- ~~**C-008 · Menu de escolha da letra (D-085 item 2).**~~ Resolvido: autor "1a 2b 3b e mouse clicando 4a" —
  1. nos 2,5 s o jogo fica em **câmera lenta** (não pausa);
  2. se o tempo acabar, **a letra é perdida**;
  3. escolha por **setas + Espaço** ou **clique do mouse**;
  4. **as letras não caem mais no chão**: cada letra que cairia abre o menu na hora (3 opções, 1 continua a palavra). O ímã de letras, a Traça comendo letras e o ímã seletivo (D-082) perdem o sentido.
  - **Ímã reverso (pedido no mesmo recado):** o ímã vira um **poder passivo comprado na loja** que **empurra os inimigos** a cada X s; subindo de nível, **o intervalo diminui e o empurrão passa a dar dano** (números do rules-agent). A bênção Pedra-Ímã sai.

- ~~**C-007 · Escolha do level-up: "3 selos na página" + "o jogo pausa".**~~ Resolvido: autor respondeu "a" — o jogo pausa e os 3 selos aparecem desenhados na página; escolha por tecla (1, 2, 3) ou clique.

- **C-006 · Vida do Asmodeus (DECISÃO DO AUTOR, playtest).** 1500 (rules-agent) supõe uma palavra a cada ~5 s. A sonda não mede isso. No playtest (`index.html?boss`, ou jogando o capítulo), se a luta passar muito de 4 min, baixar `max_hp` em `data/bosses/asmodeus.tres` (ex.: 1000); se ficar abaixo de 2 min, subir.

- ~~C-001 · VERBUM usa B~~ → resolvido pela D-015.
- **C-004 · Ritmo de palavras por onda (DECISÃO DO AUTOR).** *Atualização 2026-09-26:* a sonda antiga conjurava em todo frame (heresia constante), então os dados de palavras do T069 e do T533 subestimavam. Com a sonda corrigida e invencível (`docs/reviews/T533-curva-cap1.md` §6): ~25 letras caídas/min, ~6 úteis/min, **mediana ~0,7 palavra/min** nas 9 ondas, 0 heresias. O gargalo é a ordem das letras úteis, não a quantidade. Continua esperando o playtest do autor. *Atualização T069:* HP 2 aplicado (D-030); com as 7 palavras e o purge, a sonda automática deixou de ser confiável (laços de purge, ímã puxando letras inúteis). Próximo passo: **playtest humano** no build web; alavancas listadas em `docs/reviews/T069-rules-parecer.md` §4. Dados originais: Sonda na onda 1 (2 execuções por cenário; bot que foge, busca só letras úteis e conjura):

  | Diabrete | Letras caídas | Palavras conjuradas | Sobreviveu? |
  |---|---|---|---|
  | HP 3, drop 60% (atual) | 5–10 | 0–1 | 1 de 2 |
  | HP 3, drop 100% | 13–15 | 0–1 | 0 de 2 |
  | HP 2, drop 60% | 17–22 | 1–2 | 1 de 2 |
  | HP 2, drop 100% | 24–28 | 0 | 2 de 2 |

  **Leitura:** o mecanismo funciona (CRUX, AQUA e PAX saíram no jogo real), mas com os números atuais o jogador monta **no máximo ~1 palavra por onda**, e as palavras deveriam ser o dano principal. O gargalo é a morte de inimigos (ataque automático fraco contra HP 3), que limita as letras. O bot é pior que um humano (o ímã puxa letras inúteis e ele não usa purge), então o real deve ser um pouco melhor.
  **Opções:** (a) Diabrete com HP 2; (b) drop de letra 100%; (c) mais de uma letra por morte; (d) letras iniciais no começo da onda; (e) esperar a Fase 5 (purge + 6 palavras) e medir de novo no T069. **Recomendação do Claude:** (a) HP 2 agora + medir de novo no T069 com purge.
- **C-005 · SC-001 no web.** ⏸️ Adiado pela D-050 (remedir o Firefox na 011). *Atualização D-049:* otimizado; Firefox ainda 29–31 FPS nesta máquina (cena vazia já dá 55). Falta o autor decidir: aceitar, reduzir a carga no web ou otimizar o acerto dos projéteis. *Atualização 2026-09-26:* medido no Firefox com GPU: **31–35 FPS, p95 12–15 ❌**; os scripts custam ~2,5× o Chrome. O Chrome desta vez deu 58–69 (p95 40–56, variação da máquina; código igual). Opções em `docs/reviews/T085-performance.md` §1.3 e §4. Antes: ✅ **Resolvido no Chrome** pela D-039 (média 86–90, p95 67–68). Histórico: Scripts em WebAssembly custam ~5–8× o desktop. O Chrome sem janela desta máquina deu de 7 a 39 FPS para o mesmo build (inconclusivo) e não há Firefox. Próximo passo: o autor mede `index.html?stress` no Chrome e no Firefox de verdade. Opções de otimização em `docs/reviews/T085-performance.md` §4.
- ~~**C-003 · Tamanho do build web.**~~ Resolvido pela D-047 (8A): a meta vale para o download comprimido. O build vazio tem **38 MB crus / 9,9 MB comprimidos** (quase tudo é o `index.wasm` do motor). A meta da constituição é "até 25 MB". Proposta para a feature 011: medir a meta como **download comprimido** e, se precisar, compilar um template web próprio sem 3D (o wasm cai bastante). Decidir até a 011.
- **C-002 · FEATURES.md marca 001–015 como "Tasked ✅"**, mas os arquivos não existem. As specs serão escritas just-in-time.
