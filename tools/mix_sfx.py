"""Mixagem dos efeitos: escreve o volume_db de cada data/audio/sfx/<id>.tres para que o volume
médio (RMS) do arquivo fique no alvo da categoria (data/audio/mix_targets.json).

Uso (raiz do projeto): python tools/mix_sfx.py   (depois, nada a importar: só .tres mudam)
"""
import glob
import json
import os
import re
import wave

import numpy as np

TARGETS = json.load(open('data/audio/mix_targets.json', encoding='utf-8'))


def rms_db(path: str) -> float:
    w = wave.open(path)
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
    return 20 * np.log10(max(np.sqrt((a ** 2).mean()), 1e-9)) if a.size else -60.0


def category(sid: str, event: str) -> str:
    if sid.startswith('cs_'):
        return 'cutscene'
    if event.startswith(('weapon_hit', 'grace_gained', 'enemy_killed', 'enemy_spawn', 'wax_drop')) \
            or sid in ('letter_collected', 'letter_collected_rare', 'gold_ink_collected', 'enemy_projectile_hit'):
        return 'frequent'
    if event.startswith(('ui_', 'screen_changed', 'pause_menu', 'letter_menu', 'shop', 'item_bought',
                         'gold_ink_spent', 'seals', 'blessing', 'letter_chosen', 'letter_lost',
                         'letter_rejected', 'codex', 'cutscene_skipped', 'game_restart', 'potion_denied')):
        return 'ui'
    if event.startswith('weapon_') or event.startswith('magnet'):
        return 'weapon'
    if event.startswith(('enemy_', 'hazard', 'champion', 'letter_eaten', 'shield_broken')):
        return 'enemy'
    if event.startswith(('player_', 'potion_drunk', 'grace_leveled', 'heresy')):
        return 'player'
    if event.startswith(('word_cast', 'combo_cast', 'atril_', 'verbum', 'word_stored', 'stored_word')):
        return 'word'
    if event.startswith(('boss', 'erasure', 'letter_erased')):
        return 'boss'
    if event.startswith(('wave_', 'chapter_', 'page_')):
        return 'stinger'
    return 'default'


def main() -> None:
    lo, hi = TARGETS['clamp_db']
    n = 0
    for tres in sorted(glob.glob('data/audio/sfx/*.tres')):
        s = open(tres, encoding='utf-8').read()
        m = re.search(r'path="res://(assets/audio/sfx/[^"]+\.wav)"', s)
        if not m or not os.path.exists(m.group(1)):
            continue
        sid = re.search(r'^id = &"([^"]+)"', s, re.M).group(1)
        event = re.search(r'^event = &"([^"]+)"', s, re.M).group(1)
        cat = category(sid, event)
        target = TARGETS['categories'][cat]
        vol = round(min(hi, max(lo, target - rms_db(m.group(1)))), 1)
        if re.search(r'^volume_db = ', s, re.M):
            s = re.sub(r'^volume_db = .*$', f'volume_db = {vol}', s, flags=re.M)
        else:
            s = re.sub(r'^(stream = .*)$', rf'\1\nvolume_db = {vol}', s, count=1, flags=re.M)
        open(tres, 'w', encoding='utf-8', newline='\n').write(s)
        n += 1
        print(f'{sid:32s} {cat:9s} {vol:+.1f} dB')
    print(n, 'efeitos mixados')


if __name__ == '__main__':
    main()
