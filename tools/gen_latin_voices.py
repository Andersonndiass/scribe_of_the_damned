"""Gera as falas em latim que faltam (ElevenLabs) em assets/audio/voice/latin/<palavra>.mp3.

O AudioManager.play_latin(word_id) procura exatamente esse caminho. Pula as que já existem
(não gasta crédito à toa) e para se o saldo cair abaixo de 2500.

A chave NÃO fica neste arquivo: é lida da configuração local do Claude Code (~/.claude.json,
mcpServers.elevenlabs.env.ELEVENLABS_API_KEY) ou da variável de ambiente ELEVENLABS_API_KEY.

Uso (na raiz do projeto):
    python -m uv tool run --from elevenlabs-mcp python tools/gen_latin_voices.py
"""
import csv
import json
import os
import sys

import requests

API = 'https://api.elevenlabs.io/v1'
VOICE_ID = 'iP95p4xoKVk53GoZ742B'  # a voz do conjurador (DIRECAO-SONORA §1.6–1.7)
OUT_DIR = 'assets/audio/voice/latin'
MIN_BALANCE = 2500


def api_key() -> str:
    key = os.environ.get('ELEVENLABS_API_KEY')
    if key:
        return key
    cfg = json.load(open(os.path.expanduser('~/.claude.json'), encoding='utf-8'))
    servers = [cfg.get('mcpServers', {})] + [p.get('mcpServers', {}) for p in cfg.get('projects', {}).values()]
    for s in servers:
        if 'elevenlabs' in s:
            return s['elevenlabs']['env']['ELEVENLABS_API_KEY']
    sys.exit('Sem chave: defina ELEVENLABS_API_KEY ou configure o MCP elevenlabs.')


def main() -> None:
    headers = {'xi-api-key': api_key()}

    def balance() -> int:
        s = requests.get(f'{API}/user/subscription', headers=headers, timeout=30).json()
        return s['character_limit'] - s['character_count']

    os.makedirs(OUT_DIR, exist_ok=True)
    rows = [r for r in csv.DictReader(open('docs/voice/voice_lines.csv', encoding='utf-8-sig'))
            if r['id'].startswith('latin_')]
    todo = [r for r in rows if not os.path.exists(f"{OUT_DIR}/{r['id'][len('latin_'):]}.mp3")]
    print(f'{len(rows)} falas em latim; faltam {len(todo)}; saldo {balance()}')
    for r in todo:
        if balance() < MIN_BALANCE:
            print('PARE: saldo baixo')
            break
        word = r['id'][len('latin_'):]
        heresy = word == 'haeresis'
        text = 'Hæresis!' if heresy else r['texto_pt_BR'].strip().capitalize() + '.'
        body = {'text': text, 'model_id': 'eleven_multilingual_v2',
                'voice_settings': {'stability': 0.3 if heresy else 0.8, 'similarity_boost': 0.75,
                                   'style': 0.35 if heresy else 0.1, 'speed': 0.9}}
        res = requests.post(f'{API}/text-to-speech/{VOICE_ID}?output_format=mp3_44100_128',
                            headers=headers, json=body, timeout=120)
        if res.status_code != 200:
            print(word, res.status_code, res.text[:200])
            continue
        open(f'{OUT_DIR}/{word}.mp3', 'wb').write(res.content)
        print('ok', word, len(res.content))
    print('saldo depois', balance())
    print('Depois rode: /d/Godot/godot --headless --path . --import')


if __name__ == '__main__':
    main()
