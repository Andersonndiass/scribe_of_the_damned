# Falas do jogo (dublagem)

Lista de todas as falas faladas do jogo, em PT-BR e EN, para gerar as vozes (ElevenLabs).
A mesma lista está em `docs/voice/voice_lines.csv` (abre no Excel/Sheets).

- **Onde salvar:** `assets/audio/voice/pt_BR/<id>.mp3` e `assets/audio/voice/en/<id>.mp3` (id em minúsculas, como na coluna do CSV). O jogo toca a voz do idioma escolhido; sem o arquivo, a fala só aparece escrita.
- **Texto na tela:** vem de `i18n/ui.csv` (mesmas frases, com "..." no lugar de "…").
- **Se mudar uma fala:** mude aqui, no CSV da dublagem e no `i18n/ui.csv` (mesma chave).
- **Latim:** nenhuma fala tem latim (as palavras conjuradas não são faladas).

## Vozes (direção)

| Personagem | Direção |
|---|---|
| Irmão Anselmo | Homem de 31 anos, copista. Fala curta e prática, voz contida, com medo, mas com humor seco que escapa (narrativa §5.1). Nunca heroico nem gritado. |
| Abade Gerbrand (fantasma) | Homem idoso, gentil, paternal e um pouco dramático; sabe mais do que conta e tem vergonha (§5.2). Voz suave, levemente etérea. |
| Asmodeus, o Rasurador | Feito de rasuras: voz áspera, arranhada, como pena riscando papel; lenta, com a última palavra dita com força (§5.3). |
| Narrador | Neutro e solene, como quem lê uma crônica antiga; sem drama exagerado. |
| Abade Caído | A culpa do Abade com corpo: a mesma voz do fantasma, mais grave e cansada (§5.3). |
| Frei Ambrósio, o Alfarrabista (vendedor do Scriptorium) | Homem de uns 70 anos, monge meio apagado que ficou no scriptorium noturno e vende os apócrifos. Voz seca e rouca de bibliotecário, ritmo vagaroso e mercantil, com esquecimentos e humor negro de quem já foi riscado. Nunca simpático demais; cobra com calma. Sugestão ElevenLabs: voz masculina idosa, grave e rouca, tipo velho arquivista/comerciante (buscar na biblioteca por "old man, raspy, dry"). |
| Padre Malaquias, o Confessor | Padre acolhedor na superfície, ameaçador por baixo: voz macia e paciente demais (§5.3). |

## Capítulo 1 (spec 008)

| id | cena | personagem | expressão | PT-BR | EN |
|---|---|---|---|---|---|
| `cs_c1_01_caption_1` | C1-01 | Narrador | neutral | Mosteiro de São Wendelino. 1348, o ano da peste. | Monastery of Saint Wendelin. 1348, the year of the plague. |
| `cs_c1_01_anselmo_1` | C1-01 | Irmão Anselmo | scared | O códice… o Abade disse para nunca abri-lo. | The codex… the Abbot said never to open it. |
| `cs_c1_01_anselmo_2` | C1-01 | Irmão Anselmo | scared | …Mas o Abade não está aqui. | …But the Abbot is not here. |
| `cs_c1_01_narrator_1` | C1-01 | Narrador | neutral | Dentro do livro, só a Palavra pode salvá-lo. | Inside the book, only the Word can save him. |
| `cs_c1_02_abbot_1` | C1-02 | Abade Gerbrand (fantasma) | smiling | Irmão Anselmo… Você abriu. Claro que abriu. | Brother Anselmo… You opened it. Of course you did. |
| `cs_c1_02_abbot_2` | C1-02 | Abade Gerbrand (fantasma) | neutral | A Palavra sustenta a página. Onde ela some, há o vazio. | The Word holds up the page. Where it fades, there is the void. |
| `cs_c1_02_anselmo_1` | C1-02 | Irmão Anselmo | scared | …E se eu errar? | …And if I get it wrong? |
| `cs_c1_02_abbot_3` | C1-02 | Abade Gerbrand (fantasma) | neutral | Então o vazio fala pela sua boca. E fere você. | Then the void speaks through your mouth. And it wounds you. |
| `cs_c1_03_asmodeus_1` | C1-03 | Asmodeus, o Rasurador | neutral | Tuas palavras… eu as APAGO. | Thy words… I ERASE them. |
| `cs_c1_03_anselmo_1` | C1-03 | Irmão Anselmo | scared | …Catorze anos copiando. E ele apaga assim. | …Fourteen years of copying. And he erases it just like that. |
| `cs_c1_04_abbot_1` | C1-04 | Abade Gerbrand (fantasma) | smiling | Uma página limpa. Há muitas outras. | One clean page. There are many more. |
| `cs_c1_04_anselmo_1` | C1-04 | Irmão Anselmo | relieved | …Traças. Eu detesto traças. | …Moths. I hate moths. |

## Falas âncora dos próximos capítulos (roteiro completo virá na feature de cada capítulo)

| id | cena | personagem | expressão | PT-BR | EN |
|---|---|---|---|---|---|
| `cs_c3_01_abbot_1` | C3-01 | Abade Gerbrand (fantasma) | neutral | Não… aquele sou eu. O que restou de mim. | No… that is me. What is left of me. |
| `cs_c3_02_fallen_abbot_1` | C3-02 | Abade Caído | neutral | Obrigado, filho. Leve isto. | Thank you, son. Take this. |
| `cs_c4_01_malachi_1` | C4-01 | Padre Malaquias, o Confessor | smile | Venha, filho. Confesse. | Come, son. Confess. |
| `cs_c5_02_anselmo_1` | C5-02 | Irmão Anselmo | relieved | …Foi um sonho? | …Was it a dream? |

## Durante o jogo — latim (já está no jogo)

O jogador **pronuncia** cada palavra ao conjurar (narrativa §3.3). O latim nunca é traduzido: **um áudio só**, em `assets/audio/voice/latin/<palavra>.mp3`, vale para PT-BR e EN. Pronúncia eclesiástica (a da Igreja), sílaba forte em maiúsculas. Voz de Anselmo, firme e clara (é o único momento em que ele não hesita).

| id | palavra | tipo | pronúncia |
|---|---|---|---|
| `latin_lux` | LUX | palavra | LUKS |
| `latin_pax` | PAX | palavra | PAKS |
| `latin_crux` | CRUX | palavra | KRUKS |
| `latin_vita` | VITA | palavra | VI-ta |
| `latin_aqua` | AQUA | palavra | A-kwa |
| `latin_ignis` | IGNIS | palavra | I-nyis |
| `latin_mortis` | MORTIS | palavra | MOR-tis |
| `latin_fides` | FIDES | palavra | FI-des |
| `latin_lumen` | LUMEN | palavra | LU-men |
| `latin_purgo` | PURGO | palavra | PUR-go |
| `latin_gloria` | GLORIA | palavra | GLO-ri-a |
| `latin_verbum` | VERBUM | palavra | VER-bum |
| `latin_angelus` | ANGELUS | palavra | AN-dje-lus |
| `latin_dominus` | DOMINUS | palavra | DO-mi-nus |
| `latin_miserere` | MISERERE | palavra | mi-se-RE-re |
| `latin_salvator` | SALVATOR | palavra | sal-VA-tor |
| `latin_sanctus` | SANCTUS | palavra | SANK-tus |
| `latin_spiritus` | SPIRITUS | palavra | SPI-ri-tus |
| `latin_vapor` | VAPOR | combo | VA-por |
| `latin_flamma` | FLAMMA | combo | FLAM-ma |
| `latin_caecitas` | CAECITAS | combo | TCHE-tchi-tas |
| `latin_martyrium` | MARTYRIUM | combo | mar-TI-ri-um |
| `latin_requiem` | REQUIEM | combo | RE-kwi-em |
| `latin_haeresis` | HÆRESIS! | heresia | E-re-sis — a voz de Anselmo distorcida, como se o vazio falasse por ele |

## Durante o jogo — frases curtas (aprovadas, D-072; entram na 008)

Aparecem num balão de fala curto, com a voz se o arquivo existir. No máximo 2 linhas cada (game bible).

| id | quem | quando | PT-BR | EN |
|---|---|---|---|---|
| `bark_asmodeus_phase_2` | Asmodeus, o Rasurador | Fase 2 do chefe | Cada erro teu me alimenta. | Every mistake of thine feeds me. |
| `bark_asmodeus_phase_3` | Asmodeus, o Rasurador | Fase 3 do chefe | Eu sou tudo o que foi riscado. | I am all that was struck out. |
| `bark_asmodeus_erasure` | Asmodeus, o Rasurador | A Rasura apaga uma letra do atril | Apagado. | Erased. |
| `bark_asmodeus_death` | Asmodeus, o Rasurador | Morte do chefe (antes da C1-04) | Alguém… sempre… erra… | Someone… always… errs… |
| `bark_anselmo_heresy` | Irmão Anselmo | Logo depois de uma heresia | …Isso não era latim. | …That was not Latin. |
| `bark_anselmo_last_candle` | Irmão Anselmo | Sobra só uma vela | Só mais uma vela… | Just one more candle… |
| `bark_anselmo_wave_clear` | Irmão Anselmo | Fim de onda | Mais uma linha no lugar. | One more line back in place. |

## Durante o jogo — frases novas (D-098)

Mesmo formato. A chave no jogo é o id em maiúsculas; o arquivo é o id em minúsculas. Anselmo: medo e humor seco, nunca heroico (expressão: scared no dano e na morte, relieved no nível). Frei Ambrósio: ver tabela de vozes (expressão neutral; smiling ao vender).

| id | quem | quando | PT-BR | EN |
|---|---|---|---|---|
| `bark_anselmo_hurt_01` | Irmão Anselmo | Leva dano (máx. 1 a cada ~20 s) | Ai. Isso estava no contrato? | Ow. Was that in the contract? |
| `bark_anselmo_hurt_02` | Irmão Anselmo | Leva dano | Minha mão! Eu preciso dela. | My hand! I need it. |
| `bark_anselmo_hurt_03` | Irmão Anselmo | Leva dano | Tinta e sangue nunca combinam. | Ink and blood never mix. |
| `bark_anselmo_hurt_04` | Irmão Anselmo | Leva dano | Isso vai manchar o hábito. | That will stain the habit. |
| `bark_anselmo_hurt_05` | Irmão Anselmo | Leva dano | Senhor, poupai-me. | Lord, spare me. |
| `bark_anselmo_hurt_06` | Irmão Anselmo | Leva dano | Eu só queria copiar em paz. | I only wanted to copy in peace. |
| `bark_anselmo_hurt_07` | Irmão Anselmo | Leva dano | Ainda bem que não sou o pergaminho. | Good thing I am not the parchment. |
| `bark_anselmo_hurt_08` | Irmão Anselmo | Leva dano | Isso doeu. Anotem aí. | That hurt. Write it down. |
| `bark_anselmo_level_01` | Irmão Anselmo | Sobe de nível de Graça | Algo se acendeu em mim. | Something lit up inside me. |
| `bark_anselmo_level_02` | Irmão Anselmo | Nível de Graça | A graça chegou. Sem avisar. | Grace arrived. Unannounced. |
| `bark_anselmo_level_03` | Irmão Anselmo | Nível de Graça | Sinto a mão do Abade... ou a de Deus. | I feel the Abbot's hand... or God's. |
| `bark_anselmo_level_04` | Irmão Anselmo | Nível de Graça | Mais luz. Aceito. | More light. I accept. |
| `bark_anselmo_level_05` | Irmão Anselmo | Nível de Graça | Não mereço, mas aceito. | I do not deserve it, but I accept. |
| `bark_anselmo_level_06` | Irmão Anselmo | Nível de Graça | A página ficou um pouco mais clara. | The page grew a little brighter. |
| `bark_anselmo_death_01` | Irmão Anselmo | Morte | Perdoe a letra torta, Senhor. | Forgive the crooked letter, Lord. |
| `bark_anselmo_death_02` | Irmão Anselmo | Morte | Então... é esse o fim da linha. | So... this is the end of the line. |
| `bark_anselmo_death_03` | Irmão Anselmo | Morte | Eu avisei que ia errar. | I did say I would get it wrong. |
| `bark_anselmo_death_04` | Irmão Anselmo | Morte | Riscado. Como todo o resto. | Struck out. Like everything else. |
| `bark_anselmo_death_05` | Irmão Anselmo | Morte | Abade... eu não devia ter aberto. | Abbot... I should not have opened it. |
| `bark_vendor_open_01` | Frei Ambrósio | Abre a loja | Entre, entre. Não toque nas páginas. | Come in. Do not touch the pages. |
| `bark_vendor_open_02` | Frei Ambrósio | Abre a loja | Apócrifos frescos. Quer dizer, antigos. | Fresh apocrypha. I mean ancient. |
| `bark_vendor_open_03` | Frei Ambrósio | Abre a loja | Tenho o que o Abade escondeu. Por um preço. | I have what the Abbot hid. For a price. |
| `bark_vendor_open_04` | Frei Ambrósio | Abre a loja | Lembro de você. Acho. Compre algo. | I remember you. I think. Buy something. |
| `bark_vendor_open_05` | Frei Ambrósio | Abre a loja | O vazio não paga. Eu cobro. | The void pays nothing. I charge. |
| `bark_vendor_open_06` | Frei Ambrósio | Abre a loja | Bem-vindo ao scriptorium. Ainda estou aqui. | Welcome to the scriptorium. I am still here. |
| `bark_vendor_bought_01` | Frei Ambrósio | Compra | Boa escolha. Ou, ao menos, cara. | Good choice. Or at least, costly. |
| `bark_vendor_bought_02` | Frei Ambrósio | Compra | Vendido! Que Deus o perdoe. | Sold! May God forgive you. |
| `bark_vendor_bought_03` | Frei Ambrósio | Compra | Sem devolução. Nem rasuras. | No returns. No erasures either. |
| `bark_vendor_bought_04` | Frei Ambrósio | Compra | Obrigado. É a tinta que me mantém. | Thank you. Ink is what keeps me. |
| `bark_vendor_bought_05` | Frei Ambrósio | Compra | Anotado no livro. Se o livro ficar. | Noted in the ledger. If it lasts. |
| `bark_vendor_denied_01` | Frei Ambrósio | Compra negada (sem tinta) | Sem tinta, sem apócrifo. | No ink, no apocrypha. |
| `bark_vendor_denied_02` | Frei Ambrósio | Compra negada | Falta tinta, irmão. | You are short of ink, brother. |
| `bark_vendor_denied_03` | Frei Ambrósio | Compra negada | Fé não paga. Só tinta. | Faith does not pay. Only ink. |
| `bark_vendor_denied_04` | Frei Ambrósio | Compra negada | Volte com mais tinta. | Come back with more ink. |
| `bark_vendor_close_01` | Frei Ambrósio | Fecha a loja | Vá com Deus. Ou sem. | Go with God. Or without. |
| `bark_vendor_close_02` | Frei Ambrósio | Fecha a loja | Volte, se ainda houver página. | Come back, if there is a page left. |
| `bark_vendor_close_03` | Frei Ambrósio | Fecha a loja | Cuidado lá fora. Está tudo apagado. | Careful out there. Everything is erased. |
| `bark_vendor_close_04` | Frei Ambrósio | Fecha a loja | Feche a porta. O vazio tem pressa. | Close the door. The void is in a hurry. |
