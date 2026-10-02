"""Gera as vozes das falas da partida que ainda não têm arquivo (docs/voice/voice_lines.csv), em
PT-BR e EN, com a voz de cada personagem (docs/audio/DIRECAO-SONORA.md §1.6). Pula as que já
existem e para se o saldo cair abaixo de 1500.

A chave NÃO fica neste arquivo (ver gen_latin_voices.api_key).

Uso (na raiz do projeto):
    python -m uv tool run --from elevenlabs-mcp python tools/gen_bark_voices.py
Depois: /d/Godot/godot --headless --path . --import
"""
import csv
import os
import sys

import requests

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_latin_voices import api_key  # noqa: E402

API = 'https://api.elevenlabs.io/v1'
MIN_BALANCE = 1500
# personagem → (voice_id, stability, similarity, style, speed)
VOICES = {
    'Irmão Anselmo': ('iP95p4xoKVk53GoZ742B', 0.40, 0.75, 0.15, 0.95),
    # D-098: Frei Ambrósio, o Alfarrabista. George (o Bill já é o Abade): instável e lento = seco, cansado.
    'Frei Ambrósio, o Alfarrabista': ('JBFqnCBsd6RMkjVDRZzb', 0.30, 0.75, 0.40, 0.85),
}
LANGS = (('texto_pt_BR', 'arquivo_pt_BR', 'pt'), ('texto_en', 'arquivo_en', 'en'))


def main() -> None:
    headers = {'xi-api-key': api_key()}

    def balance() -> int:
        s = requests.get(f'{API}/user/subscription', headers=headers, timeout=30).json()
        return s['character_limit'] - s['character_count']

    rows = list(csv.DictReader(open('docs/voice/voice_lines.csv', encoding='utf-8-sig')))
    todo = [(r, t, f, lang) for r in rows if r['personagem'] in VOICES
            for t, f, lang in LANGS if not os.path.exists(r[f])]
    print(f'{len(todo)} arquivos a gerar; saldo {balance()}')
    for r, text_col, file_col, lang in todo:
        if balance() < MIN_BALANCE:
            print('PARE: saldo baixo')
            break
        vid, stab, sim, style, speed = VOICES[r['personagem']]
        body = {'text': r[text_col].strip(), 'model_id': 'eleven_multilingual_v2', 'language_code': lang,
                'voice_settings': {'stability': stab, 'similarity_boost': sim, 'style': style, 'speed': speed}}
        res = requests.post(f'{API}/text-to-speech/{vid}?output_format=mp3_44100_128',
                            headers=headers, json=body, timeout=120)
        if res.status_code != 200:
            print(r['id'], lang, res.status_code, res.text[:200])
            continue
        os.makedirs(os.path.dirname(r[file_col]), exist_ok=True)
        open(r[file_col], 'wb').write(res.content)
        print('ok', r['id'], lang, len(res.content))
    print('saldo depois', balance())
    print('Depois rode: /d/Godot/godot --headless --path . --import')


if __name__ == '__main__':
    main()
