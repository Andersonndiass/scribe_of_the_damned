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
- **Pendências:** Grimório e Opções aparecem desabilitados no Menu e na Pausa até a Fase 3 (feito na D-069); o personagem escolhido só vale na 010 (só o Anselmo é livre). *Créditos:* o autor pediu "FRANCISCO" (é ele mesmo; a linha separada de testes saiu).
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

## Conflitos abertos

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
