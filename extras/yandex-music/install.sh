#!/bin/bash
# Яндекс Музыка для DigiNeo: служба ymusicd + страница yandex.php в меню Fox Remote.
# Запуск на плате (нужен интернет):
#   cd /root/yandex-music && bash install.sh            — установить / обновить
#   bash install.sh --remove                             — удалить (токен останется)
# Собирает ymusicd на самой плате (как digifox-firstsetup собирает pfrate):
# доставляет build-essential, libcurl4-openssl-dev и libssl-dev, если их нет.
set -e
cd "$(dirname "$(readlink -f "$0")")"
[ "$(id -u)" = 0 ] || { echo "Нужен root"; exit 1; }
WWW=/var/www

if [ "$1" = "--remove" ]; then
    systemctl disable --now ymusicd 2>/dev/null || true
    rm -f /etc/systemd/system/ymusicd.service /usr/local/bin/ymusicd /usr/local/bin/pfctl-ym $WWW/yandex.php $WWW/ym_amp_lib.php
    systemctl daemon-reload
    sed -i '/href="yandex.php"/d' $WWW/index.php
    echo "Удалено. Токен остался в /etc/digifox/ymusic_token (удалить вручную, если не нужен)."
    exit 0
fi

echo "== зависимости"
need=""
command -v gcc >/dev/null 2>&1 || need="$need build-essential"
ls /usr/include/curl/curl.h /usr/include/*/curl/curl.h >/dev/null 2>&1 || need="$need libcurl4-openssl-dev"
[ -f /usr/include/openssl/hmac.h ] || need="$need libssl-dev"
dpkg -s ca-certificates >/dev/null 2>&1 || need="$need ca-certificates"
if [ -n "$need" ]; then
    apt-get update
    apt-get install -y $need
fi

echo "== сборка ymusicd"
gcc -O2 -Wall -o /tmp/ymusicd.new ymusicd.c cJSON.c -lcurl -lcrypto -lpthread
systemctl stop ymusicd 2>/dev/null || true
install -m 0755 /tmp/ymusicd.new /usr/local/bin/ymusicd
rm -f /tmp/ymusicd.new

echo "== служба"
mkdir -p /etc/digifox /tmp/ymusic
install -m 0644 ymusicd.service /etc/systemd/system/ymusicd.service
systemctl daemon-reload
systemctl enable ymusicd
systemctl restart ymusicd

echo "== веб-интерфейс"
install -m 0644 yandex.php $WWW/yandex.php
install -m 0644 ym_amp_lib.php $WWW/ym_amp_lib.php
install -m 0755 pfctl-ym /usr/local/bin/pfctl-ym
bash ./pfctl-ym-patch.sh || echo "pfctl: команду ym встроить не удалось"
python3 - "$WWW" <<'PY'
import re, sys
www = sys.argv[1]

def patch(path, fn):
    try:
        s = open(path, encoding='utf-8').read()
    except OSError:
        print('  нет', path); return
    n = fn(s)
    if n != s:
        open(path, 'w', encoding='utf-8').write(n)
        print('  исправлен', path)
    else:
        print('  без изменений', path)

def index(s):
    if 'href="yandex.php"' in s:
        return s
    s = s.replace('<a class="hifi player-ui" id="player-ui" target="_blank" rel="noopener" hidden></a>',
                  '<a class="hifi player-ui" id="player-ui" target="_blank" rel="noopener" hidden></a>\n'
                  '        <a class="hifi player-ui" href="yandex.php">ЯНДЕКС МУЗЫКА</a>', 1)
    s = re.sub(r'(\n(\s*)<a class="menu-item" href="amplifier.php"[^\n]*)',
               r'\1\n\2<a class="menu-item" href="yandex.php">Яндекс Музыка</a>', s, count=1)
    return s

def track(s):
    if 'ym_cover' in s:
        return s
    fn = ("// Яндекс Музыка (ymusicd): обложку трека из очереди MPD кладут yandex.php и ymusicd в /tmp/ymusic/<id>\n"
          "function ym_cover($file) {\n"
          "    if (!preg_match('#^http://127\\.0\\.0\\.1:\\d+/track/(\\d+)#', $file, $m)) return '';\n"
          "    return trim((string)@file_get_contents('/tmp/ymusic/' . $m[1]));\n"
          "}\n\n")
    i = s.find('function mpd_track() {')
    if i < 0:
        return s
    s = s[:i] + fn + s[i:]
    j = s.find("'cover' => '', 'dur' => $dur,", i)
    if j >= 0:
        s = s[:j] + "'cover' => ym_cover($kv['file'] ?? ''), 'dur' => $dur," + s[j + len("'cover' => '', 'dur' => $dur,"):]
    return s

def css(s):
    return s.replace('.player-ui { display: block; margin-top: 8px; text-align: center; text-decoration: none; }',
                     '.player-ui { display: block; margin-top: 8px; text-align: center; text-decoration: none; line-height: 44px; }')

patch(www + '/index.php', index)
patch(www + '/track.php', track)
patch(www + '/assets/css/digifox.css', css)
PY

sleep 1
echo "== проверка"
if curl -s -m 3 http://127.0.0.1:6601/status; then
    echo
    echo "Готово. Откройте http://$(hostname).local/yandex.php и войдите в Яндекс."
else
    echo "ymusicd не отвечает: journalctl -u ymusicd -n 30"
    exit 1
fi
