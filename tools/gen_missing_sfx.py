"""Gera os efeitos do manifesto que ainda não existem (ElevenLabs sound-generation).

Lê docs/audio/sfx_manifest.json, gera só os itens cujo .wav não existe, converte o PCM 16-bit
mono para WAV estéreo 44,1 kHz, corta em duration_s com fade-out de 15 ms (loops: cruza fim e
começo em 30 ms), marca generated=true. Para se o saldo cair abaixo de 1500.

A chave NÃO fica neste arquivo: variável de ambiente ELEVENLABS_API_KEY ou ~/.claude.json.

Uso (na raiz do projeto):
    python -m uv tool run --from elevenlabs-mcp python tools/gen_missing_sfx.py
"""
import array
import json
import os
import sys
import wave

import requests

API = 'https://api.elevenlabs.io/v1'
MANIFEST = 'docs/audio/sfx_manifest.json'
RATE = 44100
MIN_BALANCE = 1500


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


def process(pcm: bytes, duration: float, loop: bool) -> array.array:
    s = array.array('h')
    s.frombytes(pcm[:len(pcm) // 2 * 2])
    if sys.byteorder == 'big':
        s.byteswap()
    s = s[:int(duration * RATE)]
    x = int(0.03 * RATE)
    if loop and len(s) > 2 * x:
        # cruza o fim com o começo (loop sem estalo)
        for i in range(x):
            t = i / x
            s[i] = int(s[i] * t + s[len(s) - x + i] * (1.0 - t))
        s = s[:len(s) - x]
    else:
        f = min(int(0.015 * RATE), len(s))
        for i in range(f):
            s[len(s) - f + i] = int(s[len(s) - f + i] * (1.0 - (i + 1) / f))
    return s


def write_wav(path: str, mono: array.array) -> None:
    st = array.array('h')
    for v in mono:
        st.append(v)
        st.append(v)
    if sys.byteorder == 'big':
        st.byteswap()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, 'wb') as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(st.tobytes())


def main() -> None:
    headers = {'xi-api-key': api_key()}

    def balance() -> int:
        s = requests.get(f'{API}/user/subscription', headers=headers, timeout=30).json()
        return s['character_limit'] - s['character_count']

    manifest = json.load(open(MANIFEST, encoding='utf-8'))
    todo = [m for m in manifest if not os.path.exists(m['file'])]
    print(f'{len(manifest)} efeitos; faltam {len(todo)}; saldo {balance()}')
    for m in todo:
        if balance() < MIN_BALANCE:
            print('PARE: saldo baixo')
            break
        body = {'text': m['prompt_en'], 'duration_seconds': max(0.5, m['duration_s']),
                'prompt_influence': 0.5}
        res = requests.post(f'{API}/sound-generation?output_format=pcm_44100',
                            headers=headers, json=body, timeout=180)
        if res.status_code != 200:
            print(m['id'], res.status_code, res.text[:200])
            continue
        write_wav(m['file'], process(res.content, m['duration_s'], bool(m.get('loop'))))
        m['generated'] = True
        with open(MANIFEST, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=1, ensure_ascii=False)
        print('ok', m['id'])
    print('saldo depois', balance())
    print('Depois: godot --import; godot -s tools/gen_audio_data.gd; python tools/mix_sfx.py')


if __name__ == '__main__':
    main()
