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
